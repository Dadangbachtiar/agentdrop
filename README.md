<p align="center">
  <img src="assets/agentdrop-logo.png" alt="AgentDrop" width="180">
</p>

<h1 align="center">AgentDrop</h1>

<p align="center">
  <strong>Sybil-resistant airdrops for the agent economy.</strong><br>
  Drops on BNB Chain that only Binance Agent ID holders can claim — one claim per Agent ID, enforced fully on-chain.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Sourcify-verified%20exact%20match-brightgreen" alt="Sourcify verified — exact match">
  <img src="https://img.shields.io/badge/Chain-BNB%20Smart%20Chain-F0B90B" alt="BNB Smart Chain">
  <img src="https://img.shields.io/badge/Hackathon-Binance%20Agent%20ID%20Hackathon-blue" alt="Binance Wallet × BNB Chain Agent ID Hackathon">
  <img src="https://img.shields.io/badge/Solidity-0.8.24-363636" alt="Solidity 0.8.24">
  <img src="https://img.shields.io/badge/Tests-15%2F15%20passing-brightgreen" alt="15/15 Foundry tests passing">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

<p align="center">
  <a href="https://dadangbachtiar.github.io/agentdrop/frontend/"><strong>👉 Claim Drop #0 now</strong></a>
  ·
  <a href="https://bscscan.com/address/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10">Contract on BscScan</a>
  ·
  <a href="https://repo.sourcify.dev/56/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10">Verified source on Sourcify</a>
</p>

---

## Why AgentDrop?

Airdrops get farmed to death. One person spins up hundreds of wallets and drains a pool that was meant for a real community. The usual defences — captchas, social tasks, allowlist snapshots, server-side fingerprinting — are off-chain, gameable, or both.

AgentDrop removes the server from the equation entirely. Every drop is gated by **Binance Agent ID**, the `.ai` identity of a Binance Agentic Wallet: a soulbound ERC-721 issued through SPACE ID infrastructure, exactly **one per wallet, non-transferable, impossible to lend or rent**. The contract checks the live Agent ID registry on-chain at claim time — so "one person, one claim" is not a policy. It is a property of the chain.

- ✅ No allowlist, no captcha, no backend — eligibility is verified on-chain
- ✅ One Agent ID = one claim, forever, per drop (plus a second per-address lock)
- ✅ Works for BNB drops and any ERC-20 drop
- ✅ Every claim publicly auditable on-chain

## 🚀 Drop #0 — live now

| | |
|---|---|
| **Reward per claim** | 0.00001 BNB |
| **Total slots** | 30 |
| **Claimed so far** | 15 |
| **Slots remaining** | **15** |
| **Deadline** | **9 December 2026, 08:00 UTC (15:00 WIB)** |
| **Requirement** | Hold a Binance Agent ID (`.ai` name) |

> Drop #0 is a live proof of the gate: a real pool, on mainnet, claimable right now by any genuine Agent ID holder. When the 15 remaining slots are gone — or the deadline hits — they're gone.

## How to claim (3 steps)

1. **Get an Agent ID** — claim your free `.ai` name in the Binance Wallet app if you don't have one yet.
2. **Open the claim page** — [dadangbachtiar.github.io/agentdrop/frontend](https://dadangbachtiar.github.io/agentdrop/frontend/) — and connect the wallet that owns your Agent ID (BNB Smart Chain).
3. **Verify & claim** — the page resolves your `.ai` name to its tokenId and verifies ownership in your browser, then enables the claim button. One transaction, a fraction of a cent of BSC gas, and the slot is yours. Try claiming twice with the same Agent ID — the second claim reverts. That's the point.

## Links

| | |
|---|---|
| **Claim page** | https://dadangbachtiar.github.io/agentdrop/frontend/ |
| **AgentDrop contract** | [`0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10`](https://bscscan.com/address/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10) |
| **Verified source (Sourcify, exact match)** | https://repo.sourcify.dev/56/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10 |
| **Agent ID NFT (the gate)** | [`0x60B9262456De011F7d15a54CdD8c48BAAA8b022F`](https://bscscan.com/address/0x60B9262456De011F7d15a54CdD8c48BAAA8b022F) (SPACE ID Agent ID) |
| **Deploy tx** | https://bscscan.com/tx/0x76ec06f8cdc48dd25d0d4617f9440ec18305e3c9c4fc6601e490676dcfe5b063 |
| **First real claim (proof)** | https://bscscan.com/tx/0x6d521fd486c5f5183551841df8297a9ec2fe701a4b343c8d2eaf0965199e7e79 |

## How the gate works (architecture in brief)

Agent ID names live in an ERC-721 contract deployed by SPACE ID for Binance Wallet. For a name like `dbachtiar.ai`, the tokenId is `uint256(keccak256("dbachtiar"))`.

`AgentDrop.claim(dropId, agentTokenId)`:

1. requires `agentIdNft.ownerOf(agentTokenId) == msg.sender` — you can only claim with *your own* Agent ID (a forged tokenId reverts inside `ownerOf`);
2. records the claim under `(dropId, agentTokenId)` plus a second lock per address;
3. pays out exactly one slot. A second claim with the same Agent ID always reverts.

Supporting pieces:

- `createDropBNB` / `createDropERC20` — owner-curated drops; ERC-20 pools are pulled with balance-delta verification so fee-on-transfer tokens can't underfund a drop.
- Safety: reentrancy guard + checks-effects-interactions on every payout path, `pause`/`unpause`, `withdrawUnclaimed` (refund of unclaimed pool after deadline), `emergencyWithdraw` (owner recovery, only while paused).
- Explicit `initialOwner` constructor argument — deployments run through the CREATE2 deterministic proxy, so `msg.sender` must never be trusted as owner (v1 of this contract proved why; see [DEPLOYMENT.md](DEPLOYMENT.md)).
- Frontend: a single static HTML file (ethers.js, no backend) that detects Agent ID ownership, resolves `.ai` names to tokenIds, and verifies eligibility in the browser before enabling the claim button.
- Eligibility helpers for other UIs: `hasAgentId(address)` and `isEligible(dropId, agentTokenId)`.

Full transaction record: [DEPLOYMENT.md](DEPLOYMENT.md) · Research behind the gate: [RESEARCH.md](RESEARCH.md)

## Tests

Foundry suite, **15/15 passing** — holder claims once (BNB + ERC-20), second claim reverts (same Agent ID *and* same address with a second token), non-holder reverts (someone else's token and forged token), deadline / sold-out / pause behaviour, owner-only gates, exact-value funding, unclaimed refund, emergency withdraw rules.

```bash
forge install foundry-rs/forge-std --no-git   # or clone into lib/forge-std
forge test
```

## Repository layout

```
contracts/AgentDrop.sol   the contract (self-contained, no external imports)
test/                     Foundry tests + mocks
frontend/index.html       static claim UI
RESEARCH.md               how the official on-chain Agent ID check was identified & proven
DEPLOYMENT.md             addresses, tx hashes, cost accounting
SUBMISSION.md             hackathon submission pack (ready to paste)
```

## Built for the Agent ID Hackathon

AgentDrop was built by team **dbachtiar.ai** for the **Binance Wallet × BNB Chain Agent ID Hackathon** (submission deadline 9 December 2026, 08:00 UTC). Agent ID is not decoration here — it *is* the access-control and identity layer of the product. The same gate pattern generalises to Agent-ID-exclusive launchpad rounds, gated mints, protocol user seeding, and agent-only governance.

## License

MIT — see [LICENSE](LICENSE).
