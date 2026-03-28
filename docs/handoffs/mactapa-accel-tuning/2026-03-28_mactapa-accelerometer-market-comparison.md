# Handoff: MacTapa Accelerometer Market Comparison & Tuning

**Created:** 2026-03-28
**Status:** In Progress

## Summary

Comparative analysis of MacTapa's accelerometer configuration vs. open-source market standards (taigrr/spank 3.5K stars, olvvier/apple-silicon-accelerometer 1K stars). Plan approved with 7 ordered implementation items.

## Current State

Analysis phase complete. Implementation plan approved but **no code changes made yet**. All findings are documented in the plan file. Ready to start implementing changes in priority order.

## Completed Work

- Full extraction of every numeric constant, threshold, timing parameter in `SlapDetector.swift` (362 lines)
- Research of taigrr/spank (Go) and olvvier/apple-silicon-accelerometer (Python) — both use identical hardware (Bosch BMI286 via AppleSPUHIDDevice)
- Identified 5 areas where MacTapa is well-aligned with market (HID access, data parsing, dual-band STA/LTA, warmup, fallback cascade)
- Identified 1 critical, 5 important, and 3 nice-to-have discrepancies
- Created prioritized implementation plan with specific parameter values

## In-Progress Work

- Nothing partially implemented — clean starting point for code changes

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Keep dual-band STA/LTA as-is | MacTapa's dual-band (fast+medium) is actually **superior** to spank's single-band | Could simplify to single-band, but dual is better |
| Butterworth 2nd order over Kalman | Good balance of complexity vs. quality. Kalman is overkill for gravity removal | Single-pole IIR (current), 4th order Butterworth, Kalman |
| Cooldown default 750ms not 500ms | Matches spank default. 350ms available as fast mode. Below 200ms risks audio overlap | 500ms, 1.0s (current), fully user-tunable |
| Intensity reference 0.8g not 1.0g | Practical slap range is 0.1-0.8g. 1.0g would under-utilize the scale for most slaps | 0.5g, 1.0g, 2.0g |

## What Worked

- Agent-based parallel research was efficient: one agent deep-dived MacTapa source, another searched open-source landscape
- STA/LTA is the correct algorithm family for this use case (borrowed from seismology, well-suited for impact detection)
- MacTapa's fallback cascade (accel -> mic -> keyboard) is unique in the market and a genuine differentiator

## What Didn't Work

- N/A (analysis phase only, no implementation attempts)

## Open Questions

- [ ] Actual native sample rate: MacTapa claims 1kHz (ReportInterval=1000us) but olvvier measured ~800Hz. Need runtime measurement to confirm. Affects all time constant calculations by ~25%.
- [ ] Should gyroscope (usage 9, same chip) be explored for rotational confirmation of slaps vs. bumps? No project does this yet.
- [ ] Escalation system design: how should slap history affect sound selection/volume? Spank uses 60-level exponential curve with 30s half-life.

## Next Steps

1. **Quick wins (2 trivial 1-line changes)**:
   - Change intensity reference from 0.2g to 0.8g (`SlapDetector.swift:249`)
   - Widen min amplitude range to 0.03-0.25g (`SlapDetector.swift:247`)

2. **Critical UX fix**:
   - Make cooldown configurable, default 750ms (`SlapDetector.swift:16,335` + `MenuBarView.swift`)
   - Add fast mode toggle at 350ms

3. **Signal processing upgrade**:
   - Replace single-pole IIR with 2nd-order Butterworth HPF at 4Hz (`SlapDetector.swift:26-28,214-217`)

4. **Detection robustness**:
   - Add CUSUM as secondary confirmation alongside STA/LTA (new block after `SlapDetector.swift:241`)

5. **Measurement**:
   - Add runtime sample rate measurement during warmup phase (`SlapDetector.swift:222-228`)

6. **Fun feature** (optional):
   - Escalation system with rolling slap count and intensity multiplier

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `Sources/MacTapa/SlapDetector.swift` | Motion detection engine (362 lines) — all accelerometer logic | To modify |
| `Sources/MacTapa/MenuBarView.swift` | SwiftUI UI — sensitivity slider, needs cooldown slider | To modify |
| `Sources/MacTapa/AudioEngine.swift` | Sound playback — volume formula, escalation target | To modify (for escalation only) |
| `Sources/MacTapa/AppDelegate.swift` | App lifecycle | Unchanged |
| `Sources/MacTapa/Info.plist` | Bundle metadata | Unchanged |
| `.claude/plans/shimmying-knitting-pizza.md` | Full analysis plan with comparison tables | Reference |

## Context for Resumption

- **Build**: `swift build` from `/Users/lucasbertol/MacTapa`
- **Run**: `sudo ./MacTapa` (requires sudo for IOKit HID access)
- **Reference projects**: taigrr/spank (Go, GitHub), olvvier/apple-silicon-accelerometer (Python, GitHub)
- **Key insight**: MacTapa's data pipeline is correct. The gaps are in tuning parameters and detection sophistication, not in the fundamental approach.
- **Sensitivity slider UI is inverted**: 0% in UI = sensitivity 1.0 internally (most sensitive). Keep this mental model in mind when adjusting formulas.
- **The plan file** at `.claude/plans/shimmying-knitting-pizza.md` has the full comparison tables and specific values to adopt — load it first when resuming.
