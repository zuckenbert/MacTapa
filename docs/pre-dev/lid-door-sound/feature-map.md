# Feature Map: Lid Open/Close Door Sound

**PRD Reference:** [prd.md](prd.md)
**Date:** 2026-03-28
**Status:** Draft
**Confidence Score:** 90/100 (Coverage: 25, Relationships: 23, Cohesion: 22, Journeys: 20)

---

## Feature inventory

### Core features

| ID | Name | Description | User Value | Dependencies |
|----|------|-------------|------------|--------------|
| F-001 | Lid state detection | Detect physical lid open and close events, distinguishing from display sleep | Foundation for all lid sound features | None (foundational) |
| F-002 | Door open sound | Play door opening sound when lid is opened | "Entering the computer" moment, laughs | F-001 |
| F-003 | Door close sound | Play door closing sound when lid is closed, completing before sleep | "Leaving the computer" moment | F-001 |

### Supporting features

| ID | Name | Description | User Value | Dependencies |
|----|------|-------------|------------|--------------|
| F-004 | Lid sound toggle | Independent on/off control for lid sounds in the menu bar UI | User choice over which features are active | None |
| F-005 | False trigger filtering | Ensure only physical lid events trigger sounds, not display timeout or hot corners | Trust that the feature works correctly | F-001 |

### Enhancement features

| ID | Name | Description | User Value | Dependencies |
|----|------|-------------|------------|--------------|
| F-006 | Door sound assets | Bundled royalty-free door open and door close audio files | Immediately works without user setup | None |

---

## Domain groupings

### Domain 1: Lid event detection
**Purpose:** Sense and classify physical lid state changes on the MacBook.

**Features:** F-001 (Lid state detection), F-005 (False trigger filtering)

**Boundaries:**
- **Owns:** Lid state (open/closed), event classification (lid vs non-lid)
- **Consumes:** Nothing from other domains
- **Provides:** Verified lid open/close events to Sound Playback domain

**Integration points:**
- Lid Event Detection → Sound Playback: Provides verified "lid opened" or "lid closed" events

### Domain 2: Sound playback
**Purpose:** Play the appropriate door sound in response to lid events.

**Features:** F-002 (Door open sound), F-003 (Door close sound), F-006 (Door sound assets)

**Boundaries:**
- **Owns:** Door sound files, sound selection (open vs close), playback timing
- **Consumes:** Verified lid events from Lid Event Detection domain; volume setting from existing app settings
- **Provides:** Audio output to user

**Integration points:**
- Sound Playback ← Lid Event Detection: Receives verified lid events
- Sound Playback ← Existing Settings: Reads current volume level

### Domain 3: User preferences
**Purpose:** Let users control whether lid sounds are active.

**Features:** F-004 (Lid sound toggle)

**Boundaries:**
- **Owns:** Lid sound enabled/disabled state
- **Consumes:** Nothing
- **Provides:** Enabled/disabled state to Lid Event Detection (gates whether events trigger sounds)

**Integration points:**
- User Preferences → Lid Event Detection: Gates event processing (if disabled, events are ignored)
- User Preferences ← Existing UI: Toggle lives alongside existing controls in menu bar popover

---

## User journeys

### Journey 1: First lid open after enabling
**User type:** O Zoeiro do Escritorio
**Goal:** Experience lid sounds for the first time

| Step | Action | Feature | Domain |
|------|--------|---------|--------|
| 1 | User installs/updates MacTapa | — | — |
| 2 | Lid sound toggle is ON by default | F-004 | User Preferences |
| 3 | User closes MacBook lid | F-001, F-005 | Lid Event Detection |
| 4 | App detects physical lid close (not display sleep) | F-001, F-005 | Lid Event Detection |
| 5 | Door closing sound plays before sleep | F-003, F-006 | Sound Playback |
| 6 | User opens MacBook lid later | F-001 | Lid Event Detection |
| 7 | Door opening sound plays | F-002, F-006 | Sound Playback |
| 8 | User laughs, shows coworkers | — | — |

**Cross-domain interactions:** Lid Event Detection → Sound Playback (steps 4→5, 6→7)

**Success:** User hears door sounds on both lid close and open.
**Failure:** Sound doesn't play, or plays on display timeout (false trigger).

### Journey 2: Disabling lid sounds while keeping slaps
**User type:** Any user
**Goal:** Turn off lid sounds but keep slap detection active

| Step | Action | Feature | Domain |
|------|--------|---------|--------|
| 1 | User opens menu bar popover | — | — |
| 2 | User toggles lid sounds OFF | F-004 | User Preferences |
| 3 | User closes/opens lid | F-001 | Lid Event Detection |
| 4 | No door sound plays | F-004 gates F-001 | User Preferences → Lid Event Detection |
| 5 | User slaps MacBook | — | Existing slap detection |
| 6 | Slap sound plays normally | — | Existing sound playback |

**Cross-domain interactions:** User Preferences gates Lid Event Detection (step 4)

**Success:** Lid sounds stop; slap sounds continue.
**Failure:** Lid sounds still play after toggling off; or slap sounds also stop.

### Journey 3: Lid close with sound completion
**User type:** Any user
**Goal:** Hear the full door close sound before Mac sleeps

| Step | Action | Feature | Domain |
|------|--------|---------|--------|
| 1 | User closes the MacBook lid | F-001 | Lid Event Detection |
| 2 | Physical lid close detected (not display timeout) | F-005 | Lid Event Detection |
| 3 | Door close sound starts immediately | F-003 | Sound Playback |
| 4 | Sound plays to completion (<2 seconds) | F-003, F-006 | Sound Playback |
| 5 | System goes to sleep after sound finishes | — | — |

**Success:** Full sound heard before sleep.
**Failure:** Sound cuts off mid-playback; or system sleeps before sound starts.

---

## Feature interaction map

```
┌─────────────────────────────────────────────────┐
│                  MacTapa App                     │
│                                                  │
│  ┌──────────────────┐    ┌──────────────────┐   │
│  │  USER PREFERENCES │    │ EXISTING FEATURES│   │
│  │                   │    │                  │   │
│  │  F-004: Lid      │    │  Slap detection  │   │
│  │  sound toggle     │    │  Sound packs     │   │
│  │         │         │    │  Volume control  │   │
│  └─────────┼─────────┘    └────────┬─────────┘   │
│            │ gates                  │ provides    │
│            ▼                        │ volume      │
│  ┌──────────────────┐              │             │
│  │  LID EVENT       │              │             │
│  │  DETECTION       │              │             │
│  │                  │              │             │
│  │  F-001: Lid      │              │             │
│  │  state detection │              │             │
│  │  F-005: False    │              │             │
│  │  trigger filter  │              │             │
│  │         │        │              │             │
│  └─────────┼────────┘              │             │
│            │ verified events       │             │
│            ▼                       ▼             │
│  ┌──────────────────────────────────────────┐   │
│  │  SOUND PLAYBACK                           │   │
│  │                                           │   │
│  │  F-002: Door open sound                   │   │
│  │  F-003: Door close sound                  │   │
│  │  F-006: Door sound assets                 │   │
│  └───────────────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
```

### Dependency matrix

| Feature | Depends On | Blocks | Optional |
|---------|-----------|--------|----------|
| F-001: Lid state detection | — | F-002, F-003, F-005 | — |
| F-002: Door open sound | F-001, F-006 | — | — |
| F-003: Door close sound | F-001, F-006 | — | — |
| F-004: Lid sound toggle | — | — | — |
| F-005: False trigger filtering | F-001 | — | — |
| F-006: Door sound assets | — | F-002, F-003 | — |

---

## Phasing strategy

### Phase 1: Core lid detection + sounds (MVP)
**Goal:** Users hear door sounds when opening and closing the MacBook lid.
**Features:** F-001, F-002, F-003, F-005, F-006
**User value:** The core experience — "Seu Mac agora tem porta"
**Success criteria:** Door open sound plays within 1s of lid open; door close sound completes before sleep; no false triggers on display timeout.
**Triggers next phase:** MVP working and stable.

### Phase 2: User control
**Goal:** Users can toggle lid sounds independently.
**Features:** F-004
**User value:** Choice — use lid sounds, slap sounds, or both.
**Success criteria:** Toggle works independently from slap toggle; follows existing UI patterns.

**Note:** Phases are sequential but closely coupled — both should ship together in one release. Phase distinction is for implementation ordering only (detection first, then UI).

---

## Scope boundaries

### In scope
- Physical lid open/close detection on MacBook laptops
- Dedicated door sounds (open and close)
- Independent toggle control
- False trigger prevention (display sleep vs lid close)
- Integration with existing volume setting

### Out of scope (with rationale)
- **Custom lid sounds:** Future enhancement; MVP ships with fixed sounds
- **Desktop Mac support:** No physical lid to detect
- **Clamshell mode:** Complex edge case; lid closed with external display is a different UX
- **Lid event counter:** Nice-to-have; not core to the humor value
- **Separate volume:** Adds UI complexity; use existing volume for simplicity

### Assumptions
- MacBook hardware exposes lid state to the operating system
- Sufficient time exists between lid close and system sleep for a short sound
- Two sound files (open + close) are sufficient for MVP

### Constraints
- Door close sound must be under 2 seconds (sleep timing window)
- Feature only works on MacBooks (laptops with clamshell hardware)
- Sound files must be royalty-free for distribution

---

## Risk assessment

### Feature complexity risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Door close sound cut off by sleep | High — core feature broken | Medium | Keep sound under 2s; use sleep delay acknowledgment |
| False triggers on display timeout | Medium — annoying UX | Medium | Use true lid state detection, not display sleep proxy |
| No lid hardware on desktop Macs | Low — graceful degradation | Certain on desktops | Detect laptop vs desktop; disable feature silently |

### Integration risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Lid detection interferes with accelerometer | High — breaks existing slap detection | Low | Lid detection uses different sensing mechanism than slaps |
| Volume setting conflict | Low — minor UX issue | Low | Reuse existing volume; no separate control |
| Audio hardware not ready on wake | Medium — open sound delayed | Medium | Add brief delay after wake before playing open sound |

---

## Gate 2 validation checklist

| Category | Requirement | Status |
|----------|-------------|--------|
| **Feature Completeness** | All PRD features included | Done (US-001→F-002, US-002→F-003, US-003→F-004, US-004→F-005) |
| | Clear descriptions | Done |
| | Categories assigned | Done (3 Core, 2 Supporting, 1 Enhancement) |
| **Grouping Clarity** | Domains logically cohesive | Done (3 domains) |
| | Clear boundaries | Done (owns/consumes/provides per domain) |
| | Cross-domain deps minimized | Done (single direction: Detection → Playback) |
| **Journey Mapping** | Primary journeys documented | Done (3 journeys) |
| | Happy/error paths | Done |
| | Handoffs identified | Done |
| **Integration Points** | All interactions identified | Done |
| | Directional deps clear | Done |
| | No circular deps | Done |
| **Priority & Phasing** | MVP features identified | Done (Phase 1) |
| | Deps don't block MVP | Done |

**Gate Result:** PASS — proceed to TRD
