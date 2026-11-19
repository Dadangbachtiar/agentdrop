# AgentDrop — Deployment Record (BNB Smart Chain, chainId 56)

Deployer/owner wallet: `0xf225065DcD5B3bAA0ff8C696b9ab203c353b50a1` (Agent ID `dbachtiar.ai`)
All transactions executed via Binance Agentic Wallet (`baw contract-call`), each previewed
(structured validation: simulationCode success, expected balance changes only, no
authority/allowance changes, no risks) and broadcast exactly once.
Deployments used the CREATE2 deterministic proxy `0x4e59b44847b379578588920cA78FbF26c0B4956C`.

## Live contract (v2 — the one to use)

- **AgentDrop: `0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10`**
- Deploy tx: `0x76ec06f8cdc48dd25d0d4617f9440ec18305e3c9c4fc6601e490676dcfe5b063`
- Verified on-chain after deploy: `owner()` = deployer wallet ✔, `agentIdNft()` =
  `0x60B9262456De011F7d15a54CdD8c48BAAA8b022F` ✔, code ≈ 8.2 KB ✔
- **Source verification: Sourcify `exact_match`** ✔
  (job `2ff16937-bcbe-436a-bf3b-bc952d0cda93`, https://sourcify.dev/server/verify-ui/jobs/2ff16937-bcbe-436a-bf3b-bc952d0cda93)
- BscScan: not yet verified there — no BscScan API key was available in env/files.
  Manual path: BscScan "Verify and Publish" with `AgentDrop.flat.sol`
  (solc v0.8.24, optimizer on / 200 runs, EVM paris) and constructor args
  `0x00000000000000000000000060b9262456de011f7d15a54cdd8c48baaa8b022f000000000000000000000000f225065dcd5b3baa0ff8c696b9ab203c353b50a1`.

## First drop (live)

- createDropBNB tx: `0x6ba738aee9a337ff4467a4beaf42ff2c12383fa131609f80fbf98db01f87fa58`
- Drop #0: 0.00001 BNB per claim × 30 slots, pool 0.0003 BNB, deadline 1796803200
  (2026-12-09 08:00 UTC, the hackathon submission deadline).

## Smoke test (real interaction, deployer's own Agent ID)

- claim tx: `0x6d521fd486c5f5183551841df8297a9ec2fe701a4b343c8d2eaf0965199e7e79`
- `claim(0, uint256(keccak256("dbachtiar")))` from the owner wallet → received 0.00001 BNB;
  `claimedByAgent` = true, slotsClaimed = 1, `isEligible` now false for that Agent ID.
  This is a genuine end-to-end proof of the gate, recorded as a smoke test.

## Superseded v1 deployment (dead artifact — do not use)

- `0xB4181195aEc8B04D20d9be818bf58D6609b28a07`, deploy tx
  `0x2e0144f9704f4c886a312c54a57205b020c40f324c68e6bd645c2d7cbb55d1ad` (gasUsed 1,867,604).
- v1's constructor took `msg.sender` as owner; via the CREATE2 proxy that made the
  proxy itself the owner, so nobody could operate it. No funds were ever sent to v1
  (deploy value 0, no drops created). Fixed in v2 with an explicit `initialOwner`
  constructor argument; the full test suite (15/15) was re-run before redeploying.

## Cost accounting (hard cap 0.0006 BNB — respected)

| Item | BNB |
|---|---|
| Deploy v1 gas | 0.000129479067290692 |
| Deploy v2 gas | 0.000137122077164300 |
| createDropBNB gas | 0.000009387620351200 |
| Drop #0 pool (locked in contract) | 0.000300000000000000 |
| Smoke-test claim gas | 0.000008371837416381 |
| **Total** | **0.000584360602222573** |

Wallet balance after everything: 0.000398186607599326 BNB (started 0.000972547209821899;
the 0.00001 BNB smoke-test payout came back to the wallet and is netted in this figure).
Contract balance after smoke test: 0.00029 BNB (29 of 30 slots still open).

## Tooling note

Mid-task, the globally installed `baw` CLI vanished (system dirs are ephemeral on this
machine). It was reinstalled durably at `~/workspace/tools/baw-cli` (v1.12.0); the login
session in `~/.baw` was intact, so no re-pairing was needed.
