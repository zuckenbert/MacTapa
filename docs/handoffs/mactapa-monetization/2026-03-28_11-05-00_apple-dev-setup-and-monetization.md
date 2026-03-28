# Handoff: MacTapa - Apple Developer Setup & Monetization Planning

**Created:** 2026-03-28 11:05
**Status:** In Progress

## Summary

Session focused on understanding MacTapa distribution requirements, confirming Apple Developer Program enrollment, and planning monetization strategy inspired by SlapMac ($5K in 3 days).

## Current State

- Apple Developer Program enrollment **paid and processing** ($99, individual, lucasdbertol@icloud.com)
- Agreement signed email received. Awaiting final activation email (up to 48h).
- App builds and runs locally (`sudo` required for accelerometer). DMG exists but is **unsigned** — Gatekeeper blocks it for end users.
- Landing page live at https://mactapa-landing.vercel.app/ and http://localhost:8787
- No payment gate implemented yet. Download is free/direct from GitHub releases.
- No benchmarks or tests exist.

## Completed Work

- Confirmed no Apple license needed for **local dev**, only for **distribution**
- Diagnosed DMG opening issue: unsigned DMG + ad-hoc signed .app = Gatekeeper rejection
- Identified enrollment type: **Individual** (no DUNS, no org needed)
- Lucas completed Apple Developer Program enrollment (Mar 28, 2026)
- Researched competitor SlapMac: $3-7 price, $5K revenue in 3 days, viral via social media reels

## In-Progress Work

- **Apple Developer activation**: Waiting for Apple's activation email (could be minutes to 48h)
- **Build pipeline**: Need to update `build.sh` with code signing + notarization once Team ID is available
- **Monetization strategy**: User wants to plan this NOW (next session focus)

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Individual enrollment (not Org) | Faster, no DUNS needed, sole developer | Organization enrollment |
| Distribute via DMG on website (not App Store) | Faster iteration, no App Review, direct payment | Mac App Store |
| Charge Big Mac price (~R$35-40 / ~$7) | Matches SlapMac pricing, impulse buy territory | Free with donations, higher price |
| Code stays open source | Learning resource attracts devs, paid download for convenience | Closed source |

## What Worked

- Browser automation to check Apple enrollment page requirements
- Quick diagnosis of DMG signing issue via `codesign` and `spctl`

## What Didn't Work

- N/A (early stage)

## Open Questions

- [ ] How to implement payment gate? (AbacatePay/PIX, Lemon Squeezy, Gumroad?)
- [ ] How to drive viral social media growth without being an influencer?
- [ ] Reels refund program like SlapMac? (post a reel, get refund if it hits X views)
- [ ] Platforms like Real Oficial for UGC incentivization?
- [ ] Revenue projections: conversion rates, reach needed, cost structure
- [ ] Sound pack monetization: free base + premium packs?

## Next Steps

1. **Wait for Apple Developer activation** → then configure code signing + notarization in build.sh
2. **Plan monetization strategy** (ENTERING PLAN MODE):
   - Research viral growth tactics (reels refund, UGC platforms like Real Oficial)
   - Research payment platforms (AbacatePay, Lemon Squeezy, Gumroad)
   - Estimate conversion rates, pricing, revenue potential
   - Define growth flywheel: social proof → virality → downloads → revenue
3. **Implement payment gate** on landing page
4. **Create new signed DMG** once Apple Dev account is active

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `/Users/lucasbertol/MacTapa/build.sh` | Build script — needs code signing + notarization | To modify |
| `/Users/lucasbertol/MacTapa/docs/index.html` | Landing page — needs payment gate integration | To modify |
| `/Users/lucasbertol/MacTapa/MacTapa.dmg` | Current unsigned DMG | To rebuild |
| `/Users/lucasbertol/MacTapa/MacTapa.app/` | App bundle (ad-hoc signed) | To re-sign |
| `/Users/lucasbertol/MacTapa/Sources/MacTapa/Info.plist` | Bundle metadata | OK |

## Context for Resumption

- Git remote: `github.com/zuckenbert/MacTapa`, commits use author `zuckenbert`
- Vercel deploys from `docs/` folder on `main` branch
- Lucas's Apple ID: lucasdbertol@icloud.com
- Team ID will be available after activation — needed for `codesign --sign "Developer ID Application: NAME (TEAM_ID)"`
- Competitor reference: SlapMac (slapmac.com) — $3-7, viral reels, $5K/3days
- Lucas is NOT an influencer, needs UGC/viral strategy to drive awareness
- Project is open source but paid download (pay for convenience, build yourself for free)
