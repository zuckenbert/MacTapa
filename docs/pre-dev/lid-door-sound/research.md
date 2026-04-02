# Gate 0: Research — Lid Open/Close Door Sound

**Research Mode:** Modification (extending existing MacTapa app with new trigger type)
**Date:** 2026-03-28

---

## 1. Codebase patterns (repo-research-analyst)

### Event Detection Pattern (Closure Callback)
- `SlapDetector.swift:18` — `onSlap: (Double) -> Void` closure
- `SlapDetector.swift:383-395` — `handleSlap(intensity:)` enforces cooldown, then calls `onSlap(intensity)`
- All detection paths (accelerometer, mic, keyboard) funnel through this single handler

### AppDelegate Wiring
- `AppDelegate.swift:14-19` — Creates `AudioEngine`, then `SlapDetector` with closure calling `audioEngine.playSound(intensity:)` on main queue
- This is the sole integration point between detection and audio

### Sound Playback
- `AudioEngine.swift:32-57` — `playSound(intensity:)` selects URL (random or specific from pack), creates `AVAudioPlayer`, sets volume as `base_volume * (0.3 + intensity * 0.7)`, plays
- Multiple sounds can overlap (players array)

### UI Toggle Pattern
- `MenuBarView.swift:23-29` (isActive toggle), `:95-103` (fastMode toggle)
- `.toggleStyle(.switch)` with HStack: SF Symbol icon + label text
- All bound via `@ObservedObject` to `SlapDetector`'s `@Published` properties

### @Published State
- `SlapDetector.swift:10-15` — `isActive`, `sensitivity`, `slapCount`, `detectionMode`, `cooldown`, `fastMode`
- MenuBarView binds directly via `@ObservedObject`

### Sound Pack Structure
- `Resources/Sounds/<PackName>/<sound>.mp3` — 3 packs: GemidaoClassic (7), FutebolBR (5), MemesBR (7)

### Key Finding: No Existing Power/Lid Code
- Zero references to NSWorkspace, sleep, wake, lid, power, or screen notifications anywhere in the codebase
- Lid detection is greenfield within an existing architecture

---

## 2. Best practices (best-practices-researcher)

### Recommended Approach: Dual-Layer Detection

**Layer 1 — IOKit `IOPMrootDomain` Interest Notification (True Lid Detection)**
- Register `kIOGeneralInterest` on `IOPMrootDomain` for `kIOPMMessageClamshellStateChange`
- Event-driven, fires BEFORE sleep initiates
- Bitfield: `kClamshellStateBit (1<<0)` = lid closed, `kClamshellSleepBit (1<<1)` = will sleep
- No special privileges required to read `AppleClamshellState`

**Layer 2 — `IORegisterForSystemPower` (Sleep Delay for Audio)**
- Provides 30-second acknowledgment window via `IOAllowPowerChange`
- On `kIOMessageSystemWillSleep`: start audio, then acknowledge after playback
- On `kIOMessageSystemHasPoweredOn`: system fully awake (play door open sound)

### Notification Ordering on Lid Close
1. `kIOPMMessageClamshellStateChange` — IOKit interest (FIRST, lid-specific)
2. `NSWorkspace.screensDidSleepNotification` — display off
3. `kIOMessageSystemWillSleep` — system will sleep (30s ack window)
4. `NSWorkspace.willSleepNotification` — Cocoa-level
5. System sleeps

### On Lid Open
1. System wakes
2. `kIOMessageSystemHasPoweredOn` — IOKit callback
3. `NSWorkspace.didWakeNotification` — Cocoa-level
4. `NSWorkspace.screensDidWakeNotification` — display on

### Anti-Patterns to Avoid
1. **Polling `ioreg` via Process/shell exec** — wasteful; use IOKit interest notifications
2. **Using `IOCancelPowerChange` for forced sleep** — NO effect on lid-close sleep
3. **Using `NotificationCenter.default`** — sleep/wake are on `NSWorkspace.shared.notificationCenter`
4. **Playing long audio in sleep callbacks** — max 30s window; keep sounds under 2-3s
5. **Forgetting `IOAllowPowerChange`** — causes 30s delay for every lid close
6. **Assuming `screensDidSleepNotification` = lid close** — also fires on display timeout, hot corners

### Open Source References
- `treydempsey/clamshell` — C implementation reading AppleClamshellState
- `iccir/Fermata` — macOS lid close sensor deactivation
- `mbenoukaiss/clapet` — Swift/SwiftUI clamshell manager

---

## 3. Framework documentation (framework-docs-researcher)

### NSWorkspace Notifications (AppKit, macOS 10.6+)
```swift
NSWorkspace.willSleepNotification      // System about to sleep
NSWorkspace.didWakeNotification        // System woke up
NSWorkspace.screensDidSleepNotification // Display went dark
NSWorkspace.screensDidWakeNotification  // Display powered on
```
Must use `NSWorkspace.shared.notificationCenter`, NOT `NotificationCenter.default`.

### IORegisterForSystemPower (IOKit.pwr_mgt)
```swift
// Returns root_port (0 on failure)
IORegisterForSystemPower(refcon, &portRef, callback, &notifier) -> io_connect_t
```
Message types: `kIOMessageSystemWillSleep`, `kIOMessageSystemHasPoweredOn`, `kIOMessageCanSystemSleep`, `kIOMessageSystemWillPowerOn`

### AppleClamshellState (IORegistry)
```swift
func isClamshellClosed() -> Bool {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
    guard service != IO_OBJECT_NULL else { return false }
    defer { IOObjectRelease(service) }
    if let prop = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0) {
        return (prop.takeRetainedValue() as? Bool) ?? false
    }
    return false
}
```
No special privileges required. Only exists on laptops.

### AVAudioPlayer + Sleep
- Players stop when system sleeps (hardware powers down)
- After wake, ~100-500ms delay before audio hardware reinitializes
- MacTapa creates short-lived players per event — no resume logic needed

### ProcessInfo.beginActivity (macOS 10.9+)
- `.idleSystemSleepDisabled` prevents idle sleep (NOT lid-close)
- Useful complement but does NOT prevent forced sleep

### Compatibility
All APIs compatible with macOS 14+ target. `kIOMainPortDefault` (not deprecated `kIOMasterPortDefault`) is correct and already used in the project.

---

## 4. Synthesis & Recommendations

### Architecture Decision
Add lid detection **directly inside SlapDetector** (not a new class) because:
1. Follows existing pattern of multiple detection modes in one class
2. AppDelegate wiring stays unchanged if we reuse `onSlap` or add parallel callback
3. `@Published` property for toggle fits existing ObservableObject pattern

### Sound Strategy Decision Needed
Two options for lid sounds:
- **Option A:** Reuse current sound pack (random sound from pack on lid events)
- **Option B:** Dedicated door sounds (new sound category, separate from packs)

**Recommendation:** Option B — door open/close sounds are semantically different from slap reactions. Need 2 new MP3 files.

### Implementation Layers
1. **IOKit `AppleClamshellState` observer** — true lid detection, event-driven
2. **`IORegisterForSystemPower`** — 30s window to play door-close sound before sleep
3. **NSWorkspace `didWakeNotification`** — trigger door-open sound on wake
4. **New `@Published var lidSoundEnabled: Bool`** on SlapDetector
5. **New toggle in MenuBarView** after fastMode section
6. **New sound files** in `Resources/Sounds/DoorSounds/`

### Risk: Audio Before Sleep
Playing a door-close sound when lid closes requires the 30s IOKit acknowledgment window. The sound must be short (<2s). This is the only technically risky part.
