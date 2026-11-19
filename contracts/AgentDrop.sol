// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of the official Binance Agent ID NFT
///         ("SPACE ID Agent ID", symbol AI) on BNB Smart Chain.
///         Each Agent ID is a soulbound ERC-721; tokenId = uint256(keccak256(label)),
///         e.g. label "dbachtiar" for dbachtiar.ai.
interface IAgentIdNFT {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
}

/// @title AgentDrop
/// @notice A claim board where drops (BNB or ERC-20) can only be claimed by
///         wallets that hold a Binance Agent ID (.ai). One claim per Agent ID
///         per drop: the claim is bound to the caller's Agent ID tokenId and
///         the contract verifies `ownerOf(agentTokenId) == msg.sender`.
///         Because an Agent ID is soulbound and limited to one per wallet,
///         this makes every drop sybil-resistant by design.
contract AgentDrop {
    // ------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------
    event DropCreated(
        uint256 indexed dropId,
        address indexed token, // address(0) = BNB
        uint256 amountPerClaim,
        uint256 slotsTotal,
        uint256 deadline
    );
    event Claimed(
        uint256 indexed dropId,
        address indexed claimant,
        uint256 indexed agentTokenId,
        uint256 amount
    );
    event DropClosed(uint256 indexed dropId, uint256 refunded);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ------------------------------------------------------------------
    // Types & storage
    // ------------------------------------------------------------------
    struct Drop {
        address token; // address(0) = native BNB
        uint256 amountPerClaim;
        uint256 slotsTotal;
        uint256 slotsClaimed;
        uint256 deadline;
        bool closed;
    }

    /// @notice Official Agent ID NFT contract on BSC:
    ///         0x60B9262456De011F7d15a54CdD8c48BAAA8b022F ("SPACE ID Agent ID")
    IAgentIdNFT public immutable agentIdNft;

    address public owner;
    bool public paused;

    Drop[] public drops;

    /// @notice dropId => agentTokenId => already claimed
    mapping(uint256 => mapping(uint256 => bool)) public claimedByAgent;
    /// @notice dropId => claimant address => already claimed (second lock)
    mapping(uint256 => mapping(address => bool)) public claimedByAddress;

    uint256 private _reentrancyStatus = 1;

    // ------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "AgentDrop: not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AgentDrop: paused");
        _;
    }

    modifier nonReentrant() {
        require(_reentrancyStatus == 1, "AgentDrop: reentrant");
        _reentrancyStatus = 2;
        _;
        _reentrancyStatus = 1;
    }

    // ------------------------------------------------------------------
    // Constructor / ownership
    // ------------------------------------------------------------------
    /// @param agentIdNft_ The official Agent ID NFT contract.
    /// @param initialOwner_ Explicit owner. Do NOT rely on msg.sender here:
    ///        deployments go through the CREATE2 deterministic proxy
    ///        (0x4e59…956C), which would otherwise become the owner.
    constructor(address agentIdNft_, address initialOwner_) {
        require(agentIdNft_ != address(0), "AgentDrop: zero agentId nft");
        require(initialOwner_ != address(0), "AgentDrop: zero owner");
        agentIdNft = IAgentIdNFT(agentIdNft_);
        owner = initialOwner_;
        emit OwnershipTransferred(address(0), initialOwner_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "AgentDrop: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    receive() external payable {}

    // ------------------------------------------------------------------
    // Drop creation (owner only — the board is curated in v1)
    // ------------------------------------------------------------------
    function createDropBNB(uint256 slots, uint256 amountPerClaim, uint256 deadline)
        external
        payable
        onlyOwner
        returns (uint256 dropId)
    {
        require(slots > 0, "AgentDrop: zero slots");
        require(amountPerClaim > 0, "AgentDrop: zero amount");
        require(deadline > block.timestamp, "AgentDrop: deadline in past");
        require(msg.value == slots * amountPerClaim, "AgentDrop: value must equal slots*amountPerClaim");
        dropId = drops.length;
        drops.push(Drop(address(0), amountPerClaim, slots, 0, deadline, false));
        emit DropCreated(dropId, address(0), amountPerClaim, slots, deadline);
    }

    function createDropERC20(address token, uint256 slots, uint256 amountPerClaim, uint256 deadline)
        external
        onlyOwner
        returns (uint256 dropId)
    {
        require(token != address(0), "AgentDrop: zero token");
        require(slots > 0, "AgentDrop: zero slots");
        require(amountPerClaim > 0, "AgentDrop: zero amount");
        require(deadline > block.timestamp, "AgentDrop: deadline in past");
        uint256 total = slots * amountPerClaim;
        uint256 before = IERC20Minimal(token).balanceOf(address(this));
        _safeTransferFrom(token, msg.sender, address(this), total);
        require(
            IERC20Minimal(token).balanceOf(address(this)) - before == total,
            "AgentDrop: transfer amount mismatch"
        );
        dropId = drops.length;
        drops.push(Drop(token, amountPerClaim, slots, 0, deadline, false));
        emit DropCreated(dropId, token, amountPerClaim, slots, deadline);
    }

    // ------------------------------------------------------------------
    // Claiming
    // ------------------------------------------------------------------
    /// @notice Claim from a drop. The caller must own the Agent ID token
    ///         `agentTokenId` (tokenId = uint256(keccak256("yourname")) for
    ///         yourname.ai). One claim per Agent ID per drop.
    function claim(uint256 dropId, uint256 agentTokenId) external whenNotPaused nonReentrant {
        require(dropId < drops.length, "AgentDrop: no such drop");
        Drop storage drop = drops[dropId];
        require(!drop.closed, "AgentDrop: drop closed");
        require(block.timestamp <= drop.deadline, "AgentDrop: drop expired");
        require(drop.slotsClaimed < drop.slotsTotal, "AgentDrop: sold out");

        // The gate: caller must own this exact Agent ID. ownerOf reverts for
        // nonexistent tokens, which also rejects forged tokenIds.
        require(agentIdNft.ownerOf(agentTokenId) == msg.sender, "AgentDrop: not your Agent ID");
        require(!claimedByAgent[dropId][agentTokenId], "AgentDrop: Agent ID already claimed");
        require(!claimedByAddress[dropId][msg.sender], "AgentDrop: address already claimed");

        // Effects before interactions (CEI).
        claimedByAgent[dropId][agentTokenId] = true;
        claimedByAddress[dropId][msg.sender] = true;
        drop.slotsClaimed += 1;
        uint256 amount = drop.amountPerClaim;

        if (drop.token == address(0)) {
            (bool ok, ) = payable(msg.sender).call{value: amount}("");
            require(ok, "AgentDrop: BNB payout failed");
        } else {
            _safeTransfer(drop.token, msg.sender, amount);
        }
        emit Claimed(dropId, msg.sender, agentTokenId, amount);
    }

    // ------------------------------------------------------------------
    // Owner operations
    // ------------------------------------------------------------------
    /// @notice Close a drop after its deadline and refund the unclaimed pool.
    function withdrawUnclaimed(uint256 dropId) external onlyOwner nonReentrant {
        require(dropId < drops.length, "AgentDrop: no such drop");
        Drop storage drop = drops[dropId];
        require(!drop.closed, "AgentDrop: already closed");
        require(block.timestamp > drop.deadline, "AgentDrop: drop still running");
        drop.closed = true;
        uint256 remaining = (drop.slotsTotal - drop.slotsClaimed) * drop.amountPerClaim;
        if (remaining > 0) {
            if (drop.token == address(0)) {
                (bool ok, ) = payable(owner).call{value: remaining}("");
                require(ok, "AgentDrop: refund failed");
            } else {
                _safeTransfer(drop.token, owner, remaining);
            }
        }
        emit DropClosed(dropId, remaining);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Blunt owner recovery, only while paused. Using it can make
    ///         per-drop accounting unbacked — intended strictly as an
    ///         emergency exit, documented in the README.
    function emergencyWithdraw(address token, uint256 amount, address to) external onlyOwner nonReentrant {
        require(paused, "AgentDrop: pause first");
        require(to != address(0), "AgentDrop: zero recipient");
        if (token == address(0)) {
            require(amount <= address(this).balance, "AgentDrop: insufficient BNB");
            (bool ok, ) = payable(to).call{value: amount}("");
            require(ok, "AgentDrop: BNB withdraw failed");
        } else {
            _safeTransfer(token, to, amount);
        }
        emit EmergencyWithdraw(token, to, amount);
    }

    // ------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------
    function dropsCount() external view returns (uint256) {
        return drops.length;
    }

    function getDrop(uint256 dropId) external view returns (Drop memory) {
        require(dropId < drops.length, "AgentDrop: no such drop");
        return drops[dropId];
    }

    /// @notice True if the wallet holds any Binance Agent ID.
    function hasAgentId(address wallet) external view returns (bool) {
        return agentIdNft.balanceOf(wallet) > 0;
    }

    /// @notice Eligibility of a specific Agent ID token for a drop.
    function isEligible(uint256 dropId, uint256 agentTokenId) external view returns (bool) {
        if (dropId >= drops.length) return false;
        Drop storage drop = drops[dropId];
        if (drop.closed || block.timestamp > drop.deadline) return false;
        if (drop.slotsClaimed >= drop.slotsTotal) return false;
        if (claimedByAgent[dropId][agentTokenId]) return false;
        try agentIdNft.ownerOf(agentTokenId) returns (address holder) {
            return !claimedByAddress[dropId][holder];
        } catch {
            return false;
        }
    }

    // ------------------------------------------------------------------
    // ERC-20 helpers (tolerate non-standard return values)
    // ------------------------------------------------------------------
    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, amount)); // transfer(address,uint256)
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "AgentDrop: transfer failed");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, amount)); // transferFrom(address,address,uint256)
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "AgentDrop: transferFrom failed");
    }
}
