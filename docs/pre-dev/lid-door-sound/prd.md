# PRD: Lid Open/Close Door Sound

**Feature:** lid-door-sound
**Date:** 2026-03-28
**Status:** Draft
**Confidence Score:** 78/100 (Market: 15, Problem: 20, Solution: 23, Business: 20)

---

## Executive summary

MacTapa currently only reacts to physical slaps, missing the most frequent physical interaction users have with their MacBook: opening and closing the lid. By playing door sounds on lid state changes, MacTapa transforms a mundane daily action into an entertaining moment, increasing passive engagement and viral shareability.

---

## Problem statement

MacTapa users interact with the app only when they physically slap their MacBook — an intentional, somewhat rare action. Meanwhile, every MacBook user opens and closes their lid multiple times per day (estimates: 5-20 times). This high-frequency interaction goes completely unnoticed by the app, representing a missed opportunity for humor and engagement.

**Current workarounds:** None. Users have no way to trigger sounds on lid events. Competitor apps (SlapMac) also lack this capability.

**Impact:** Low passive engagement — the app only "lives" when users remember to slap. Between slaps, MacTapa is invisible.

---

## User personas

### Primary: "O Zoeiro do Escritorio"
- Brazilian tech professional (dev, designer, PM)
- Uses MacBook daily at home/office
- Enjoys pranks and meme culture
- Opens/closes lid 10-20x daily (meetings, commute, lunch)
- **Goal:** Make coworkers laugh or amuse themselves with unexpected sounds
- **Frustration:** MacTapa only works on slaps — wants more passive entertainment

### Secondary: "O Streamer/Content Creator"
- Creates tech content or streams
- Opens laptop on camera frequently
- **Goal:** Entertaining moments on stream/video when opening the Mac
- **Frustration:** Has to remember to slap for a reaction; lid open would be automatic

---

## User stories

### US-001: Door open sound on lid open
**As a** MacTapa user,
**I want** my Mac to play a door opening sound when I open the lid,
**So that** it feels like I'm "entering" my computer and gets a laugh from people around me.

**Acceptance criteria:**
- Sound plays within 1 second of the lid being physically opened
- Sound uses the app's current volume setting
- Sound plays even if slap detection is disabled (independent feature)

### US-002: Door close sound on lid close
**As a** MacTapa user,
**I want** my Mac to play a door closing sound when I close the lid,
**So that** it feels like I'm "leaving" and creates a funny moment.

**Acceptance criteria:**
- Sound plays completely before the system goes to sleep
- Sound is short enough to finish during the lid-close transition (under 2 seconds)
- Sound plays even if slap detection is disabled

### US-003: Independent toggle
**As a** MacTapa user,
**I want** to enable or disable lid sounds independently from slap detection,
**So that** I can choose which features I want active.

**Acceptance criteria:**
- Toggle visible in the menu bar popover UI
- Toggle state is independent of the main "Active/Inactive" slap toggle
- Toggle follows the same visual pattern as existing toggles (icon + label)
- Lid sounds are enabled by default on first use

### US-004: No false triggers
**As a** MacTapa user,
**I want** lid sounds to trigger ONLY on physical lid open/close,
**So that** I don't hear door sounds when my display turns off for other reasons (inactivity, hot corners).

**Acceptance criteria:**
- Display sleep from inactivity does NOT trigger door sounds
- Only physical clamshell (lid) state changes trigger sounds
- Works correctly on Apple Silicon MacBooks running macOS 14+

---

## Success metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Feature adoption | 70%+ of users enable lid sounds | Toggle state analytics (future) |
| Sound completion rate (lid close) | 95%+ of close events play full sound | Lid close sound finishes before sleep |
| False trigger rate | <1% of triggers are non-lid events | No sounds on display timeout/hot corners |
| Social sharing | 3+ user-generated videos of lid sound in first month | Social media monitoring |

---

## Scope

### In scope
- Detect physical lid open and close events
- Play dedicated door-style sounds (open and close)
- Independent toggle in menu bar UI
- Distinguish lid close from display sleep (inactivity/hot corners)
- Sound volume follows the existing app volume setting
- Works on Apple Silicon MacBooks, macOS 14+

### Out of scope
- Custom sound selection for lid events (future: let users pick door sounds)
- Separate volume control for lid sounds (uses main volume)
- Desktop Mac support (iMac, Mac mini, Mac Pro — no lid)
- Clamshell mode support (lid closed with external display connected)
- Sound pack integration (lid sounds are fixed, not part of selectable packs)
- Lid event counter (future: could add alongside slap counter)
- Settings persistence between app launches (existing limitation, not in this feature's scope)

### Assumptions
- Users have MacBooks with a physical lid (not desktop Macs)
- The system provides sufficient time during lid close to play a short sound (<2s)
- Door sounds are universally understood (not culturally specific like Brazilian memes)
- Users want lid sounds enabled by default (can always toggle off)

### Business dependencies
- Need royalty-free door open and door close sound effect files
- Sound files must be short (<2 seconds) to complete before sleep

---

## Go-to-market

- **Launch:** Bundle with next MacTapa release
- **Announcement:** Social media post with video demo of lid open/close sounds
- **Viral hook:** "Seu Mac agora tem porta" (Your Mac now has a door) — short video of someone opening MacBook and hearing a door creak
- **Differentiation:** No competitor (SlapMac, Thwack) offers lid-triggered sounds

---

## Gate 1 validation checklist

| Category | Requirement | Status |
|----------|-------------|--------|
| **Problem Definition** | Problem articulated (1-2 sentences) | Done |
| | Impact quantified/qualified | Done (5-20 lid events/day vs 0-5 slaps) |
| | Users specifically identified | Done (2 personas) |
| | Current workarounds documented | Done (none exist) |
| **Solution Value** | Features address core problem | Done (4 user stories) |
| | Success metrics measurable | Done (4 metrics) |
| | User value clear per feature | Done |
| **Scope Clarity** | In-scope items explicit | Done |
| | Out-of-scope with rationale | Done |
| | Assumptions documented | Done |
| | Business dependencies identified | Done (sound files) |
| **Market Fit** | Differentiation clear | Done (no competitor has this) |
| | Value proposition validated | Partial (user feedback pending) |

**Gate Result:** PASS — proceed to Feature Map
