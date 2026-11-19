// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/AgentDrop.sol";
import "./mocks.sol";

contract AgentDropTest is Test {
    AgentDrop internal board;
    MockAgentId internal agentId;
    MockERC20 internal token;

    address internal owner = address(this);
    address internal holder = makeAddr("holder"); // owns Agent ID token 111
    address internal holder2 = makeAddr("holder2"); // owns Agent ID token 222
    address internal stranger = makeAddr("stranger"); // no Agent ID

    uint256 internal constant TOKEN_A = 111;
    uint256 internal constant TOKEN_B = 222;

    uint256 internal deadline;

    receive() external payable {}

    function setUp() public {
        agentId = new MockAgentId();
        token = new MockERC20();
        board = new AgentDrop(address(agentId), owner);
        agentId.mint(holder, TOKEN_A);
        agentId.mint(holder2, TOKEN_B);
        deadline = block.timestamp + 7 days;
        vm.deal(owner, 100 ether);
        token.mint(owner, 1_000_000 ether);
    }

    function _bnbDrop(uint256 slots, uint256 perClaim) internal returns (uint256 id) {
        id = board.createDropBNB{value: slots * perClaim}(slots, perClaim, deadline);
    }

    // ---------------------------------------------------------------
    // Happy path
    // ---------------------------------------------------------------
    function test_HolderCanClaimBNBOnce() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.deal(holder, 0);
        vm.prank(holder);
        board.claim(id, TOKEN_A);
        assertEq(holder.balance, 0.00001 ether);
        assertTrue(board.claimedByAgent(id, TOKEN_A));
        assertTrue(board.claimedByAddress(id, holder));
        (,,, uint256 claimed,,) = _dropTuple(id);
        assertEq(claimed, 1);
    }

    function test_HolderCanClaimERC20() public {
        token.approve(address(board), 30 * 5 ether);
        uint256 id = board.createDropERC20(address(token), 30, 5 ether, deadline);
        vm.prank(holder2);
        board.claim(id, TOKEN_B);
        assertEq(token.balanceOf(holder2), 5 ether);
    }

    function test_HasAgentIdView() public view {
        assertTrue(board.hasAgentId(holder));
        assertFalse(board.hasAgentId(stranger));
    }

    // ---------------------------------------------------------------
    // Gate failures
    // ---------------------------------------------------------------
    function test_SecondClaimSameAgentIdReverts() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.prank(holder);
        board.claim(id, TOKEN_A);
        vm.prank(holder);
        vm.expectRevert(bytes("AgentDrop: Agent ID already claimed"));
        board.claim(id, TOKEN_A);
    }

    function test_SecondClaimDifferentTokenSameAddressReverts() public {
        // Even if one address somehow held two Agent IDs, the address lock
        // still stops a second claim.
        agentId.mint(holder, 333);
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.prank(holder);
        board.claim(id, TOKEN_A);
        vm.prank(holder);
        vm.expectRevert(bytes("AgentDrop: address already claimed"));
        board.claim(id, 333);
    }

    function test_NonHolderCannotClaimWithOthersToken() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.prank(stranger);
        vm.expectRevert(bytes("AgentDrop: not your Agent ID"));
        board.claim(id, TOKEN_A);
    }

    function test_NonHolderCannotClaimWithForgedToken() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.prank(stranger);
        vm.expectRevert(); // mock ownerOf reverts for nonexistent token
        board.claim(id, 999_999);
    }

    function test_ClaimAfterDeadlineReverts() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.warp(deadline + 1);
        vm.prank(holder);
        vm.expectRevert(bytes("AgentDrop: drop expired"));
        board.claim(id, TOKEN_A);
    }

    function test_ClaimSoldOutReverts() public {
        uint256 id = _bnbDrop(1, 0.00001 ether);
        vm.prank(holder);
        board.claim(id, TOKEN_A);
        vm.prank(holder2);
        vm.expectRevert(bytes("AgentDrop: sold out"));
        board.claim(id, TOKEN_B);
    }

    function test_ClaimWhilePausedReverts() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        board.pause();
        vm.prank(holder);
        vm.expectRevert(bytes("AgentDrop: paused"));
        board.claim(id, TOKEN_A);
    }

    // ---------------------------------------------------------------
    // Owner gates
    // ---------------------------------------------------------------
    function test_NonOwnerCannotCreateDrop() public {
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        vm.expectRevert(bytes("AgentDrop: not owner"));
        board.createDropBNB{value: 0.001 ether}(10, 0.0001 ether, deadline);
    }

    function test_NonOwnerCannotPauseOrWithdraw() public {
        uint256 id = _bnbDrop(30, 0.00001 ether);
        vm.prank(stranger);
        vm.expectRevert(bytes("AgentDrop: not owner"));
        board.pause();
        board.pause();
        vm.prank(stranger);
        vm.expectRevert(bytes("AgentDrop: not owner"));
        board.emergencyWithdraw(address(0), 0.0001 ether, stranger);
        vm.warp(deadline + 1);
        vm.prank(stranger);
        vm.expectRevert(bytes("AgentDrop: not owner"));
        board.withdrawUnclaimed(id);
    }

    function test_CreateDropBNBRequiresExactValue() public {
        vm.expectRevert(bytes("AgentDrop: value must equal slots*amountPerClaim"));
        board.createDropBNB{value: 0.001 ether}(30, 0.00001 ether, deadline);
    }

    // ---------------------------------------------------------------
    // Refunds / emergency
    // ---------------------------------------------------------------
    function test_WithdrawUnclaimedAfterDeadline() public {
        uint256 id = _bnbDrop(3, 0.001 ether);
        vm.prank(holder);
        board.claim(id, TOKEN_A);
        uint256 before = owner.balance;
        vm.warp(deadline + 1);
        board.withdrawUnclaimed(id);
        assertEq(owner.balance - before, 0.002 ether); // 2 unclaimed slots back
    }

    function test_EmergencyWithdrawOnlyWhenPaused() public {
        _bnbDrop(3, 0.001 ether);
        vm.expectRevert(bytes("AgentDrop: pause first"));
        board.emergencyWithdraw(address(0), 0.001 ether, owner);
        board.pause();
        uint256 before = owner.balance;
        board.emergencyWithdraw(address(0), 0.001 ether, owner);
        assertEq(owner.balance - before, 0.001 ether);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------
    function _dropTuple(uint256 id)
        internal
        view
        returns (address, uint256, uint256, uint256, uint256, bool)
    {
        return board.drops(id);
    }
}
