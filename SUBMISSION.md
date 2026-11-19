# AgentDrop — DoraHacks Submission Pack (ready to paste)

Hackathon: **Agent ID Hackathon** (Binance Wallet × BNB Chain)
Submit at: https://dorahacks.io/hackathon/agent-id-hackathon/detail
Deadline: **2026-12-09 08:00 UTC**. No separate registration.

---

## Project name

AgentDrop

## Tagline (one-liner)

Sybil-resistant airdrops for the agent economy — drops on BNB Chain that only Binance Agent ID holders can claim, one claim per Agent ID, enforced fully on-chain.

## Description (paste into the project description field)

**The problem.** Airdrops and incentive drops are farmed to death. One person spins up hundreds of wallets and drains a pool meant for a community. The usual defences — captchas, social tasks, allowlist snapshots, server-side fingerprinting — are either off-chain, gameable, or both. For the emerging agent economy the problem is sharper: distributions increasingly target *agents*, and there has been no on-chain way to ask "is this claimant a unique, identified agent wallet?"

**The solution.** AgentDrop is a claim board on BNB Chain where every drop (BNB or any ERC-20) is gated by **Binance Agent ID**, the `.ai` identity of a Binance Agentic Wallet. An Agent ID is a soulbound ERC-721 NFT issued through SPACE ID infrastructure (`0x60B9262456De011F7d15a54CdD8c48BAAA8b022F`, "SPACE ID Agent ID"): exactly one per wallet, non-transferable, impossible to lend or rent. AgentDrop turns that identity primitive into a distribution primitive:

- A drop creator funds a pool split into equal claim slots with a deadline.
- To claim, a wallet presents its Agent ID tokenId (`uint256(keccak256(label))` for `label.ai`). The contract verifies `ownerOf(agentTokenId) == msg.sender` directly against the official Agent ID contract — no server, no signatures, no allowlist.
- The claim is recorded per `(dropId, agentTokenId)` with a second per-address lock. One Agent ID = one claim, forever, per drop. Sybil resistance is a property of the identity layer itself.

**How Agent ID is used.** Agent ID is not decoration here — it *is* the access-control and identity layer of the product (two of the use cases the hackathon announcement calls out). Eligibility checks (`balanceOf > 0`), ownership verification (`ownerOf`), and the claim key all read the live Agent ID registry on-chain. The frontend also resolves a user's `.ai` name to its tokenId in the browser and verifies ownership before enabling the claim button.

**Why it matters.** Any project that wants to reward real agent wallets — launchpads doing Agent-ID-exclusive rounds, protocols seeding agent users, communities paying agent contributors — gets fair distribution out of the box, with every claim publicly auditable on-chain. The same gate pattern generalises to allowlists, gated mints, and agent-only governance.

**Status.** Fully deployed and working on BNB Smart Chain mainnet (not a mockup): source verified (Sourcify exact match), first drop live with a real pool, and a complete claim executed end-to-end by a real Agent ID holder (dbachtiar.ai). 15/15 Foundry tests pass, covering the gate, double-claim prevention, deadlines, pause, and owner operations.

## How to try it

1. Claim a free Agent ID (.ai name) in the Binance Wallet app if you don't have one.
2. Open the frontend (`frontend/index.html`, hosted link in the Website field), connect your wallet on BNB Smart Chain.
3. The page detects your Agent ID, asks for your .ai name, and verifies ownership in your browser.
4. Claim from Drop #0 (0.00001 BNB per claim, 30 slots, open until 9 Dec 2026 08:00 UTC). A second claim with the same Agent ID reverts — try it.

## Contract addresses (BNB Smart Chain)

- AgentDrop: `0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10`
- Agent ID NFT (official, by SPACE ID for Binance Wallet): `0x60B9262456De011F7d15a54CdD8c48BAAA8b022F`

## Links to paste

- Contract (BscScan): https://bscscan.com/address/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10
- Verified source (Sourcify): https://repo.sourcify.dev/56/0xaF37d6b276B6423ac6AC491f3B56e197Dc386F10
- Deploy tx: https://bscscan.com/tx/0x76ec06f8cdc48dd25d0d4617f9440ec18305e3c9c4fc6601e490676dcfe5b063
- Live claim proof (smoke test by dbachtiar.ai): https://bscscan.com/tx/0x6d521fd486c5f5183551841df8297a9ec2fe701a4b343c8d2eaf0965199e7e79
- GitHub repository: **<paste repo URL after pushing — see action list below>**
- Website / demo: **<paste hosted frontend URL after hosting — see action list below>**

## Tech stack

Solidity 0.8.24 (self-contained, no external imports), Foundry (tests + build), single-file HTML/ethers.js frontend, deployed via Binance Agentic Wallet + CREATE2 deterministic proxy.

---

## ⚠️ Sisa aksi yang HARUS dilakukan Dadang sendiri (Muse tidak membuat akun / tidak submit atas nama Dadang)

1. **GitHub:** buat repo publik baru (mis. `agentdrop`) di akun GitHub Dadang, lalu push folder ini — git lokal sudah di-init + commit, tinggal:
   `git remote add origin <URL repo>` lalu `git push -u origin main` dari `~/workspace/agentdrop`.
   Tempel URL repo ke field GitHub di DoraHacks dan ganti placeholder di atas.
2. **Hosting frontend (untuk field Website):** cara termudah — aktifkan GitHub Pages dari repo yang sama (Settings → Pages → branch `main`, folder `/frontend` tidak bisa dipilih langsung; alternatif: pindahkan `frontend/index.html` ke folder `docs/` lalu pilih `main` + `/docs`), atau unggah `frontend/index.html` ke Netlify/Vercel dengan akun Dadang. Tempel URL-nya ke field Website.
3. **DoraHacks:** login dengan akun Dadang, buka halaman hackathon, klik Submit Project, tempel semua field dari dokumen ini (nama, tagline, deskripsi, alamat kontrak, link), lalu kirim **sebelum 2026-12-09 08:00 UTC (15:00 WIB)**.
4. **(Opsional, menaikkan engagement yang dinilai 20%):** posting di X menandai @BNBCHAIN dan @BinanceWallet dengan tagar #AgentIDHackathon #BNBChain, berisi link DoraHacks + ajakan pemegang Agent ID lain untuk klaim Drop #0. Semua klaim harus dari pemegang Agent ID asli — jangan pernah memakai traffic palsu (diskualifikasi).
5. **(Opsional) Verifikasi BscScan:** bila Dadang punya BscScan API key, verifikasi bisa diselesaikan via API; tanpa key, gunakan "Verify and Publish" manual di halaman kontrak BscScan dengan file `AgentDrop.flat.sol` + constructor args yang tercatat di DEPLOYMENT.md. (Sourcify sudah exact-match, jadi ini kosmetik.)
