# TRD: Lid Open/Close Door Sound

**Feature:** lid-door-sound
**Gate:** 3
**Date:** 2026-03-28
**Status:** Draft
**Confidence Score:** 85/100 (Pattern Match: 35, Complexity: 25, Risk: 25)

**Tech stack:** Swift, macOS native (single-process desktop app)
**Deployment model:** Local (bundled .app, no cloud)
**Standards loaded:** None (not a backend service; Ring backend standards don't apply)

---

## Metadata

```yaml
feature: lid-door-sound
gate: 3
deployment:
  model: local-desktop
tech_stack:
  primary: swift-macos
  standards_loaded: []
project_technologies:
  - category: lid-state-sensing
    prd_requirement: "Detect physical lid open/close (US-001, US-002, US-004)"
    choice: "OS-level hardware state observer + power management callbacks"
    rationale: "Event-driven, no polling; fires before sleep; distinguishes lid from display timeout"
  - category: audio-playback
    prd_requirement: "Play sound before sleep completes (US-002)"
    choice: "Existing audio engine with sleep-delay acknowledgment pattern"
    rationale: "Reuse existing playback; OS provides 30s window to acknowledge sleep"
  - category: user-preferences
    prd_requirement: "Independent toggle (US-003)"
    choice: "Observable property binding to declarative UI"
    rationale: "Follows existing app pattern for all toggles"
```

---

## Architecture style

**Pattern:** Extended Observer within existing Monolithic Desktop App

MacTapa is a single-process menu bar application with an established pattern: a detector observes hardware events and fires callbacks to an audio engine. The lid feature extends this with a second observer type (lid state) alongside the existing detector (slap/impact).

**ADR-001: Extend existing detector vs. new component**
- **Context:** Lid detection is a new event source. Should it live inside the existing detector class or be a separate component?
- **Options:**
  1. Add to existing detector — simpler, reuses wiring, but grows class responsibility
  2. New dedicated component — clean separation, but duplicates wiring pattern
- **Decision:** New dedicated component (LidDetector)
- **Rationale:** The existing detector handles signal processing (accelerometer, microphone) with complex DSP. Lid detection uses fundamentally different OS-level notifications. Mixing them violates single responsibility. A separate component keeps both focused and testable.
- **Consequences:** AppDelegate wires two components instead of one. Small increase in setup code but cleaner architecture.

---

## Component design

### Component 1: Lid state observer

**Purpose:** Detect physical lid open/close events using OS hardware state notifications.

**Responsibilities:**
- Register for lid-specific hardware state change notifications from the OS
- Read current lid state (open/closed) on-demand
- Distinguish physical lid events from display sleep (inactivity, hot corners)
- Expose observable enabled/disabled state for UI binding

**Inbound:**
- OS hardware state change notifications (event-driven, push)
- UI toggle state (enabled/disabled)

**Outbound:**
- Lid event callback: `(LidEvent) -> Void` where LidEvent = `.opened` or `.closed`

**Boundaries:**
- Owns: lid state tracking, notification registration/teardown, false-trigger filtering
- Does NOT own: sound selection, audio playback, UI rendering

**Lifecycle:**
- Start: Register OS notifications on app launch
- Stop: Deregister on app termination
- Pause/Resume: Respect enabled/disabled toggle

### Component 2: Sleep-aware audio coordinator

**Purpose:** Ensure door-close sound plays completely before the system sleeps.

**Responsibilities:**
- On lid close: start audio immediately, delay sleep acknowledgment until playback completes (or timeout)
- On lid open: wait for audio hardware readiness after wake, then play door-open sound
- Manage sleep acknowledgment lifecycle (acknowledge promptly, never block indefinitely)

**Inbound:**
- Lid events from Lid State Observer
- OS power management callbacks (will-sleep, did-wake)

**Outbound:**
- Play commands to existing audio engine
- Sleep acknowledgment to OS power management

**Boundaries:**
- Owns: sleep/wake coordination, playback timing, acknowledgment lifecycle
- Does NOT own: lid detection logic, sound file selection, audio player management

**ADR-002: Sleep acknowledgment strategy**
- **Context:** Door-close sound must finish before system sleeps. OS provides a callback with an acknowledgment mechanism (up to 30s window).
- **Options:**
  1. Play sound, acknowledge immediately (risk: sound cut off)
  2. Play sound, acknowledge after playback completes (risk: delayed sleep if audio fails)
  3. Play sound, acknowledge after playback OR 3s timeout (whichever first)
- **Decision:** Option 3 — play + acknowledge on completion OR 3s safety timeout
- **Rationale:** Guarantees the system never waits more than 3s even if audio fails. Sounds are <2s so they'll finish within the window. Safety timeout prevents user-visible sleep delay.
- **Consequences:** Need a timer alongside the audio completion callback. Small complexity increase but eliminates the risk of blocking sleep.

### Component 3: Door sound assets

**Purpose:** Provide bundled door open and door close audio files.

**Responsibilities:**
- Bundle two audio files (door open, door close)
- Expose file references for the audio engine

**Boundaries:**
- Owns: sound file storage, file path resolution
- Does NOT own: playback logic

### Component 4: Lid toggle (UI extension)

**Purpose:** Add an independent on/off toggle for lid sounds in the menu bar popover.

**Responsibilities:**
- Display lid sound enabled/disabled state
- Toggle state independently from slap detection toggle
- Follow existing toggle visual pattern (icon + label)

**Boundaries:**
- Owns: toggle UI element, label text, icon selection
- Does NOT own: lid detection logic, sound playback
- Binds to: Lid State Observer's published enabled state

---

## Data architecture

### State model

| State | Type | Owner | Persistence |
|-------|------|-------|-------------|
| Lid sound enabled | Boolean | Lid State Observer | In-memory (no persistence — matches existing app pattern) |
| Current lid state | Enum (open/closed) | Lid State Observer | In-memory (runtime only) |
| Sleep acknowledgment pending | Boolean | Sleep-Aware Audio Coordinator | In-memory (transient) |
| Last lid event time | Timestamp | Lid State Observer | In-memory (cooldown tracking) |

### Data flow

```
OS Hardware State Change
        │
        ▼
┌─────────────────────┐
│  Lid State Observer  │──── lidSoundEnabled? ────── UI Toggle
│                      │         (gates)
│  Filters false       │
│  triggers             │
└─────────┬───────────┘
          │ LidEvent (.opened / .closed)
          ▼
┌─────────────────────────────┐
│  Sleep-Aware Audio          │
│  Coordinator                │
│                             │
│  .closed → play close sound │──→ Acknowledge sleep (after playback or 3s)
│  .opened → wait for HW     │──→ Play open sound (after ~500ms wake delay)
│           readiness         │
└─────────────┬───────────────┘
              │ play command
              ▼
┌─────────────────────┐
│  Existing Audio     │
│  Engine             │
│  (unchanged)        │
└─────────────────────┘
```

### Event sequence: Lid close

1. User closes lid
2. OS fires lid-specific hardware state notification → Lid State Observer
3. Observer checks `lidSoundEnabled` → if false, ignore
4. Observer fires callback: `.closed`
5. Coordinator receives `.closed` event
6. OS fires power-will-sleep callback → Coordinator
7. Coordinator plays door-close sound via audio engine
8. Coordinator starts 3s safety timeout
9. Audio completes (or timeout fires, whichever first)
10. Coordinator acknowledges sleep to OS
11. System sleeps

### Event sequence: Lid open

1. User opens lid
2. System wakes
3. OS fires power-did-wake callback → Coordinator
4. Coordinator waits ~500ms for audio hardware readiness
5. OS fires lid-specific hardware state notification (lid open) → Observer
6. Observer checks `lidSoundEnabled` → if false, ignore
7. Observer fires callback: `.opened`
8. Coordinator plays door-open sound via audio engine

---

## Integration patterns

### Integration with existing audio engine
- **Pattern:** Direct method call (same process)
- **Contract:** Coordinator calls existing `playSound` or a new `playSpecificSound(url:volume:)` method
- **Direction:** Coordinator → Audio Engine (one-way)
- **Error handling:** If playback fails, acknowledge sleep immediately (don't block)

### Integration with existing UI
- **Pattern:** Observable property binding (same as existing toggles)
- **Contract:** Lid State Observer exposes `@Published var lidSoundEnabled: Bool`
- **Direction:** Bidirectional (UI reads and writes state)

### Integration with OS power management
- **Pattern:** Callback registration (event-driven)
- **Contract:** Register for power callbacks; MUST acknowledge sleep events
- **Direction:** OS → Coordinator (push); Coordinator → OS (acknowledgment)
- **Critical rule:** Always acknowledge within 3 seconds. Never skip acknowledgment.

### Integration with OS lid state
- **Pattern:** Interest notification registration (event-driven)
- **Contract:** Register for hardware state changes on root power domain
- **Direction:** OS → Observer (push)
- **Filtering:** Re-read actual lid boolean on every notification (notifications fire for any property change on the domain, not just lid)

---

## Security architecture

Not applicable. This feature:
- Reads lid state from OS (no special privileges required)
- Plays audio files bundled with the app
- Has no network access
- Stores no user data
- Has no authentication/authorization requirements

---

## Performance targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| Lid open → sound start | <1 second | PRD acceptance criteria (US-001) |
| Lid close → sound start | <100ms | Must start quickly to finish before sleep |
| Sleep acknowledgment | <3 seconds | Safety timeout; never block user's lid-close experience |
| Wake audio delay | ~500ms | Audio hardware reinitialization time |
| Door sound duration | <2 seconds | Must complete within sleep acknowledgment window |
| Memory overhead | <5 MB | Two short audio files + observer state |
| CPU overhead (idle) | ~0% | Event-driven, no polling |

---

## Deployment topology

**Local desktop application.** No servers, no cloud, no containers.

- Audio files bundled inside `.app` bundle under `Resources/Sounds/`
- Lid observer runs in-process alongside existing slap detector
- No additional entitlements required beyond existing app capabilities

---

## Quality attributes

| Attribute | Strategy |
|-----------|----------|
| **Reliability** | Safety timeout on sleep acknowledgment; graceful degradation if lid detection unavailable (desktop Macs) |
| **Resilience** | If audio fails on lid close, acknowledge sleep immediately; if detection registration fails, disable feature silently |
| **Testability** | Lid State Observer testable with mock notifications; Coordinator testable with mock audio engine and mock sleep callbacks |
| **Maintainability** | Separate component from slap detection; clean interfaces between observer, coordinator, and audio engine |

---

## Risks and mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Sound cut off on lid close | High | Medium | 3s safety timeout + short sounds (<2s) |
| False triggers on display timeout | Medium | Medium | Use lid-specific hardware state, not sleep/wake proxy |
| Audio hardware not ready on wake | Low | Medium | 500ms delay before playing open sound |
| Desktop Mac (no lid hardware) | Low | Certain | Check for lid hardware on startup; disable feature silently |
| Notification fires for non-lid property changes | Medium | High | Always re-read actual lid boolean inside callback |

---

## Gate 3 validation checklist

| Category | Requirement | Status |
|----------|-------------|--------|
| **Architecture** | All PRD features mapped to components | Done (4 components cover all 6 features) |
| | Component boundaries clear | Done (observer, coordinator, assets, UI) |
| | Single responsibilities | Done |
| | Stable interfaces | Done (callback, method call, property binding) |
| **Data Design** | Ownership explicit | Done (state table) |
| | Models support PRD | Done |
| | Flows documented | Done (two event sequences) |
| **Quality Attributes** | Performance targets set | Done (6 metrics) |
| | Reliability defined | Done |
| **Integration** | Patterns selected | Done (4 integration points) |
| | Errors considered | Done (fail-safe acknowledgment) |
| **Technology Agnostic** | Zero product names | Done |
| | Capabilities abstract | Done |
| | Can swap tech without redesign | Done (observer pattern is generic) |

**Gate Result:** PASS — proceed to API Design
