# Handoff: MacTapa MVP — Landing Upgrade & Product Refinement

**Created:** 2026-03-27 20:00
**Status:** Ready for next phase

## Summary

Completamos deploy e distribuição do MacTapa MVP. App funciona, landing page live na Vercel, DMG disponível via GitHub Release. Próximo: upgrade da landing page inspirada no SlapMac (nerdy tech details + pricing viral) e ajustes de produto.

## Current State

**Tudo deployado e funcionando:**
- Landing page: https://mactapa-landing.vercel.app (auto-deploy de `docs/` no repo MacTapa)
- GitHub Pages (backup): https://zuckenbert.github.io/MacTapa/
- DMG download: https://github.com/zuckenbert/MacTapa/releases/download/v1.0.0/MacTapa.dmg
- GitHub Release: https://github.com/zuckenbert/MacTapa/releases/tag/v1.0.0

## Completed Work

- **App completo**: Acelerômetro + mic + keyboard detection, 3 sound packs (21 sons), SwiftUI menu bar
- **Landing page deployada na Vercel**: Conectada ao repo original `zuckenbert/MacTapa`, root dir `docs/`
- **DMG criado**: 3.3MB, drag-to-Applications, GitHub Release v1.0.0
- **GitHub Pages**: Configurado como backup em `docs/`
- **Vercel configuração resolvida**: Author `zuckenbert@users.noreply.github.com` pra commits que trigeram deploy (Hobby plan exige match com dono do projeto)
- **Pricing model definido**: Cobrar ~1 Big Mac por download, código open source (salvo em memória)

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Vercel em vez de só GitHub Pages | URL mais limpa, CDN global, preview deploys |
| Root dir `docs/` | GitHub Pages só aceita `/` ou `/docs`, unificamos |
| Repo clone `mactapa-landing` (a deletar) | Criado pelo Vercel no fluxo Clone, agora desconectado — deletar |
| Author zuckenbert pra commits de deploy | Vercel Hobby bloqueia commits de outros authors |
| Preço de 1 Big Mac (~R$35-40) | Impulso, não precisa pensar, paga com PIX via AbacatePay |

## In-Progress / Next Steps

### 1. Landing Page Upgrade (PRÓXIMO)
- **Referência**: SlapMac — estudar seção "nerdy tech details" e pricing hero "$7 less than a burrito"
- **Adaptar pra vibe BR**: manter identidade viral/meme, casual, PT-BR
- **Seguir padrões Ring de design** (usar `ring:frontend-designer`)
- **Elementos a adicionar**:
  - Seção técnica divertida (como o acelerômetro funciona, mas com humor)
  - Pricing hero: "menos que um Big Mac" como elemento visual forte
  - Possivelmente demo interativo ou video placeholder

### 2. Ajustes de Produto
- **Sensibilidade**: calibrar detecção. Pesquisar repos open source (taigrr/spank, etc)
- **Novos triggers**: USB plug/unplug, abrir/fechar tampa do MacBook → sons diferentes
- **Roadmap formal**: priorizar features

### 3. Monetização
- **AbacatePay**: criar conta, configurar produto (~R$35-40), obter checkout URL com PIX
- **Wiring**: botão Baixar → AbacatePay checkout → redirect pra download do DMG
- **Sound packs premium**: FutebolBR e MemesBR como pagos (ou tudo junto no preço único)

### 4. Limpeza
- Deletar repo `zuckenbert/mactapa-landing` (precisa `gh auth refresh -s delete_repo`)
- Limpar commits vazios de trigger no histórico (opcional)

## Open Questions

- [ ] Comprar domínio custom (mactapa.com)? Ou mactapa-landing.vercel.app tá ok pro MVP?
- [ ] SlapMac cobra $7 — nosso preço de Big Mac (~R$35-40) é competitivo? Ou baixar pra R$19.90?
- [ ] Sons premium separados ou tudo incluso no preço único?
- [ ] Video demo: gravar pra landing page e social media?

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `docs/index.html` | Landing page (Vercel deploya daqui) | Live |
| `docs/vercel.json` | Vercel config | Live |
| `Sources/MacTapa/SlapDetector.swift` | Detecção de tapa | Complete |
| `Sources/MacTapa/AudioEngine.swift` | Engine de som | Complete |
| `Sources/MacTapa/MenuBarView.swift` | UI menu bar | Complete |
| `build.sh` | Build script | Complete |
| `Resources/Sounds/` | 21 MP3s em 3 packs | Complete |

## Context for Resumption

- **Working directory**: `/Users/lucasbertol/MacTapa`
- **GitHub**: https://github.com/zuckenbert/MacTapa (branch: main)
- **Vercel project**: `lucas-bertols-projects/mactapa-landing` → conectado a `zuckenbert/MacTapa`, root `docs/`
- **Vercel deploy precisa**: commits com author `zuckenbert` (email: `zuckenbert@users.noreply.github.com`)
- **Build**: `cd ~/MacTapa && swift build -c release && bash build.sh`
- **Referência principal**: SlapMac (site do concorrente) — estudar estrutura, adaptar pra BR
- **Memória salva**: pricing em `project_mactapa_pricing.md`, roadmap em `project_mactapa_roadmap.md`
