# AgentDrop — Fase 1: Riset Mekanisme Cek Agent ID On-Chain

Tanggal: 2026-11-19. Wallet acuan: `0xf225065DcD5B3bAA0ff8C696b9ab203c353b50a1` (Agent ID `dbachtiar.ai`).

## Kesimpulan

**ADA cara resmi dan terverifikasi untuk mengecek kepemilikan Agent ID secara on-chain di BSC.**
Agent ID adalah NFT ERC-721 yang diterbitkan lewat infrastruktur SPACE ID untuk Binance Wallet:

- **Kontrak:** `0x60B9262456De011F7d15a54CdD8c48BAAA8b022F`
- **name():** `SPACE ID Agent ID` · **symbol():** `AI`
- **Sifat:** soulbound (tidak pernah berpindah setelah mint), tepat 1 per wallet.

## Bukti verifikasi (semua dibaca langsung dari chain, 2026-11-19)

1. `baw wallet agent-id --json` → `{"claimed": true, "handle": "dbachtiar", "agentId": "dbachtiar.ai"}` untuk wallet Dadang.
2. `balanceOf(0xf225…50a1)` pada kontrak di atas = **1**.
3. `ownerOf(uint256(keccak256("dbachtiar")))` = **0xf225065DcD5B3bAA0ff8C696b9ab203c353b50a1** — jadi `tokenId = uint256(keccak256(label))`, pola registrar SPACE ID.
4. `tokenURI(tokenId)` = `https://agentid.prd.space.id/metadata/dbachtiar.json` — endpoint metadata produksi SPACE ID resmi.
5. Indeks independen BAS (agent.bas.io): 182.040 Agent ID terdaftar per 11 Nov 2026 dari kontrak yang sama (diawali `0x60B9…022F`, deployment block 127.950.748, 16 Okt 2026); tidak ada satu pun yang berpindah/burn — konsisten soulbound.
6. Ekosistem sudah memakai gate ini: Four.Meme "Binance Agent ID Exclusive" dan Flap ID Agent Curve hanya mengizinkan pemegang Agent ID (TokenPost, Okt 2026).

## Metode gate yang dipakai AgentDrop

- Kelayakan umum: `balanceOf(address) > 0`.
- Klaim terikat identitas: pemanggil menyampaikan `agentTokenId`-nya; kontrak mewajibkan
  `ownerOf(agentTokenId) == msg.sender`, lalu mencatat klaim per `(dropId, agentTokenId)`
  → **maksimal 1 klaim per Agent ID per drop**, tidak bisa dipindah/dipinjam karena soulbound.

## Sumber

- Pengumuman resmi Binance: "Agent ID Hackathon: Build Decentralized Applications (dApps) Around Agent ID to Win 60,000 USDC" (18 Nov 2026).
- TokenPost (21 Okt 2026): "Binance Wallet Opens .ai Name Claims for Agentic Wallets" — Agent ID memakai infrastruktur SPACE ID.
- BAS / agent.bas.io (12 Nov 2026): "Binance Agent ID, three weeks in" — indeks on-chain kontrak Agent ID.
- Skill resmi Binance Agentic Wallet v1.15.0 (terpasang lokal, `~/.claude/skills/binance-agentic-wallet/`): perintah `baw wallet agent-id` dan `baw wallet resolve-domain` untuk .ai.
- Pembacaan on-chain langsung via BSC RPC publik (eth_call) — dicatat di atas.
- Halaman detail DoraHacks hackathon tidak bisa diambil via text-fetch (HTTP 405 dari fetcher); field submission disiapkan mengikuti pengumuman resmi Binance + format standar DoraHacks.
