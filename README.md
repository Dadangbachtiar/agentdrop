# AgentDrop

**Sybil-resistant airdrop / claim board for BNB Chain, gated by Binance Agent ID.**

AgentDrop lets anyone running a distribution put up a drop (BNB or any ERC-20) that can
only be claimed by wallets holding a **Binance Agent ID** — the `.ai` identity of a
Binance Agentic Wallet. Because an Agent ID is a soulbound NFT, limited to exactly one
per wallet and non-transferable, "one claim per Agent ID" is enforced by the chain
itself, not by a server, a captcha, or a allowlist spreadsheet.

Built for the **Binance Wallet × BNB Chain Agent ID Hackathon** (November–December 2026).

## Live deployment (BNB Smart Chain)

| | |
|---|---|
| AgentDrop | `0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10` |
| Agent ID NFT (gate) | `0x60B9262456De011F7d15a54CdD8c48BAAA8b022F` ("SPACE ID Agent ID", symbol `AI`) |
| Source verification | Sourcify — exact match |
| First drop | Drop #0: 0.00001 BNB × 30 slots, open until 2026-12-09 08:00 UTC |

Full transaction record: [DEPLOYMENT.md](DEPLOYMENT.md) · Research behind the gate: [RESEARCH.md](RESEARCH.md)

## How the gate works

Agent ID names live in an ERC-721 contract deployed by SPACE ID for Binance Wallet.
For a name like `dbachtiar.ai`, the tokenId is `uint256(keccak256("dbachtiar"))`.

`AgentDrop.claim(dropId, agentTokenId)`:

1. requires `agentIdNft.ownerOf(agentTokenId) == msg.sender` — you can only claim
   with *your own* Agent ID (a forged tokenId reverts inside `ownerOf`);
2. records the claim under `(dropId, agentTokenId)` plus a second lock per address;
3. pays out exactly one slot. A second claim with the same Agent ID always reverts.

Eligibility helpers for UIs: `hasAgentId(address)` (balanceOf > 0) and
`isEligible(dropId, agentTokenId)`.

## Contract features

- `createDropBNB` / `createDropERC20` (owner-curated board in v1; ERC-20 pools are
  pulled with balance-delta verification so fee-on-transfer tokens can't underfund a drop)
- Complete events: `DropCreated`, `Claimed`, `DropClosed`, `Paused`, `Unpaused`,
  `EmergencyWithdraw`, `OwnershipTransferred`
- `pause` / `unpause`, `withdrawUnclaimed` (refund of unclaimed pool after deadline),
  `emergencyWithdraw` (owner recovery, only while paused — see caveat in the source)
- Reentrancy guard + checks-effects-interactions on every payout path
- Explicit `initialOwner` constructor argument (deployments run through the CREATE2
  deterministic proxy, so `msg.sender` must never be trusted as owner — v1 of this
  contract proved why; see DEPLOYMENT.md)

## Tests

Foundry suite, 15 tests, all passing — holder claims once (BNB + ERC-20), second claim
reverts (same Agent ID *and* same address with a second token), non-holder reverts
(someone else's token and forged token), deadline/sold-out/pause behaviour, owner-only
gates, exact-value funding, unclaimed refund, emergency withdraw rules.

```bash
forge install foundry-rs/forge-std --no-git   # or clone into lib/forge-std
forge test
```

## Frontend

`frontend/index.html` is a single static file (ethers.js via CDN, no backend):
connect a wallet on BSC, it detects whether the wallet holds an Agent ID, verifies
your `.ai` name → tokenId in the browser, lists drops, and claims.

## Repository layout

```
contracts/AgentDrop.sol   the contract (self-contained, no external imports)
test/                     Foundry tests + mocks
frontend/index.html       static claim UI
RESEARCH.md               how the official on-chain Agent ID check was identified & proven
DEPLOYMENT.md             addresses, tx hashes, cost accounting
SUBMISSION.md             hackathon submission pack (DoraHacks fields, ready to paste)
```

## License

MIT — see [LICENSE](LICENSE).
