# Handoff: MacTapa MVP — Deploy & Distribution

**Created:** 2026-03-27 18:30
**Status:** In Progress

## Summary

Built MacTapa from zero to working MVP — a macOS menu bar app that detects physical slaps on MacBook via Apple Silicon accelerometer (IOKit HID) and plays Brazilian meme sounds. App works, sounds are real (MyInstants), landing page exists. Next: deploy landing page, create downloadable DMG, wire up AbacatePay for premium packs.

## Current State

**App funciona 100%**: acelerômetro detecta tapas, 3 sound packs com 21 sons reais, UI de seleção de pack/som individual, menu bar popover. Landing page HTML criada mas não deployada ainda.

## Completed Work

- **Accelerometer detection**: Wake SPU drivers (`AppleSPUHIDDriver`) + IOKit HID callbacks on `AppleSPUHIDDevice` (usage page 0xFF00, usage 3). STA/LTA algorithm with high-pass filter. Needs `sudo`.
- **Microphone fallback**: For Macs where accelerometer doesn't work. Detects loud impacts via `AVAudioRecorder` metering.
- **Keyboard fallback**: `Ctrl+Shift+T` always available.
- **3 sound packs (21 sons reais do MyInstants)**:
  - GemidaoClassic (7): gemidao_zap, aiiii, fah, eita_giovana, eita_porra, eita_faustao, eita_peste
  - FutebolBR (6): e_tetra, haja_coracao, acabou, sai_tafarel, gol_brasil_globo, virou_passeio
  - MemesBR (8): nao_tem_aura, pou_estourado, tu_quer_madeira, vai_morrer, vai_morrer_faustao, para_nossa_alegria, undaia, trabalha_nego
- **Sound selector**: Pack picker + individual sound picker ("Aleatorio" or specific sound)
- **Menu bar UI**: SwiftUI popover with toggle, mode indicator, pack/sound pickers, sensitivity/volume sliders, test button
- **Landing page**: Dark theme, neon colors, "Dá um tapa. Ele geme.", testimonials, sound cards, premium pack FOMO. All PT-BR, casual Brazilian slang. At `landing/index.html`.
- **.app bundle**: `build.sh` creates MacTapa.app with Info.plist, binary, and bundled sounds
- **GitHub repo**: https://github.com/zuckenbert/MacTapa — all pushed to main

## In-Progress Work

- **Landing page deploy**: HTML exists at `landing/index.html` but not deployed to Vercel yet
- **DMG creation**: App works as .app bundle but no DMG installer yet for easy download
- **AbacatePay integration**: Not started. Plan: FutebolBR and MemesBR as paid packs (R$9.90 each)

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Wake SPU drivers before HID | Without `wakeSPUDrivers()` setting ReportingState/PowerState/ReportInterval on AppleSPUHIDDriver, sensor sends zero data | Just opening HID device (doesn't work) |
| Use IOServiceGetMatchingServices not IOHIDManager | More reliable for finding AppleSPUHIDDevice specifically | IOHIDManager found keyboard/trackpad as false matches |
| Microphone as fallback | Accelerometer needs sudo and may not work on all models | Accelerometer-only (breaks on some Macs) |
| MyInstants for sounds | Real viral meme sounds, user-uploaded public content | TTS generation (sounds robotic), Freesound (less memes) |
| SwiftUI popover for UI | Native macOS feel, no external deps | Full window app (too heavy for menu bar app) |
| AbacatePay for payments | BR-native, PIX support, simple checkout | Lemon Squeezy, Gumroad (less BR-friendly) |
| No App Store | IOKit private API would get rejected | Only option for accelerometer access |

## What Worked

- **SPU driver wake pattern** from taigrr/spank — the missing piece that made accelerometer work
- **STA/LTA detection** with high-pass filter — good at distinguishing slaps from typing after tuning minAmplitude to 0.05g
- **MyInstants scraping via browser JS** — `document.querySelectorAll('.small-button')` + parse onclick for MP3 URLs
- **`say` command for TTS** — good for initial testing but replaced with real sounds
- **build.sh** creating proper .app bundle — solved menu bar not appearing when running bare binary

## What Didn't Work

- **IOHIDManager matching** — found `Apple Internal Keyboard / Trackpad` as false positive on usage page 0xFF00 usage 3
- **Running without sudo** — sensor opens but sends no data (except on some M2+ models)
- **Running with sudo + GUI** — `sudo` loses WindowServer connection, no menu bar icon. Solution: run app normally, accept that accelerometer needs sudo
- **Fixed contentSize on popover** — caused gap between menu bar and popover. Use auto-sizing instead
- **MyInstants unofficial API** (myinstants-api.vercel.app) — returns 403/404, dead
- **@main attribute with SPM** — doesn't start NSApplication run loop. Need explicit `main.swift` with `NSApplication.shared.run()`

## Open Questions

- [ ] How to distribute the app so users can easily install (DMG? Homebrew? just .app zip?)
- [ ] How to handle sudo requirement for end users (LaunchDaemon? install script? or just default to microphone mode?)
- [ ] AbacatePay: create account and configure products (needs user to do this in browser)
- [ ] Copyright: MyInstants sounds are user-uploaded — OK for viral product? Consider recording original sounds long-term
- [ ] Code signing: Apple Developer cert ($99/year) or unsigned with `xattr -cr` instructions?

## Next Steps

1. **Deploy landing page to Vercel** — `cd landing && vercel deploy` or connect GitHub repo
2. **Create downloadable package** — either DMG (via `create-dmg`) or ZIP of .app bundle, upload as GitHub Release
3. **Update landing page download link** to point to GitHub Release
4. **Setup AbacatePay** — create account, configure 2 products (FutebolBR R$9.90, MemesBR R$9.90), get checkout URLs
5. **Wire AbacatePay checkout links** into landing page "Me avise" buttons
6. **Create install.sh** that handles sudo/LaunchDaemon setup for accelerometer mode
7. **Record video demo** for landing page and social media (the viral content)
8. **Post on TikTok/Reels/Twitter** — "fiz o app que dá gemidão quando vc tapa o mac"

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `Sources/MacTapa/SlapDetector.swift` | Accelerometer + mic + keyboard detection | Complete |
| `Sources/MacTapa/AudioEngine.swift` | Sound loading, pack management, playback | Complete |
| `Sources/MacTapa/MenuBarView.swift` | SwiftUI popover UI | Complete |
| `Sources/MacTapa/AppDelegate.swift` | App lifecycle, menu bar setup | Complete |
| `Sources/MacTapa/main.swift` | Entry point (explicit NSApplication.run) | Complete |
| `Sources/MacTapa/Info.plist` | App bundle metadata (LSUIElement) | Complete |
| `build.sh` | Build script → .app bundle | Complete |
| `Resources/Sounds/GemidaoClassic/*.mp3` | 7 free sounds | Complete |
| `Resources/Sounds/FutebolBR/*.mp3` | 6 futebol sounds | Complete |
| `Resources/Sounds/MemesBR/*.mp3` | 8 meme sounds | Complete |
| `landing/index.html` | Landing page (dark, viral, PT-BR) | Complete, not deployed |
| `landing/vercel.json` | Vercel config | To create |

## Context for Resumption

- **Working directory**: `/Users/lucasbertol/MacTapa`
- **GitHub**: https://github.com/zuckenbert/MacTapa (branch: main)
- **Build**: `cd ~/MacTapa && swift build -c release && bash build.sh`
- **Run**: `cd ~/MacTapa && sudo ./MacTapa.app/Contents/MacOS/MacTapa`
- **Test without sudo** (mic mode): `cd ~/MacTapa && ./MacTapa.app/Contents/MacOS/MacTapa`
- **Mac model**: MacBook Air Apple Silicon (M-series) — accelerometer works with sudo
- **Vercel**: user has Vercel account (used for other projects like Rastro)
- **AbacatePay**: user mentioned it, account may need to be created
- **Payments**: user wants AbacatePay with PIX for Brazilian market
- **Landing page removed**: mentions of open source, sudo, technical requirements — kept casual/viral
