## SESSION 12: Audio Implementation
**Model:** Gemini Flash 3  
**Duration:** 3-4 hours  
**Extended Thinking:** N/A  
**Dependencies:** Sessions 1-11 complete

### Purpose
Implement AudioManager and wire up all sound effects and music.

### Tasks

#### P4-301: AudioManager.gd Implementation
**Goal:** Create centralized audio system
- Implement `AudioManager.gd` autoload
- Properties:
  - `sfx_player_pool: Array[AudioStreamPlayer]` (4 players)
  - `music_player: AudioStreamPlayer`
  - `master_volume: float`
  - `music_volume: float`
  - `sfx_volume: float`
- Implement `play_sfx(sfx_name: String)`:
  - Load sound from `assets/audio/sfx/{sfx_name}.ogg`
  - Find available player from pool
  - Play sound
- Implement `play_music(track_name: String, loop: bool = true)`:
  - Load track from `assets/audio/music/{track_name}.ogg`
  - Stop current music
  - Play new track
- Implement volume controls:
  - `set_master_volume(db: float)`
  - `set_music_volume(db: float)`
  - `set_sfx_volume(db: float)`
- Load/save volume settings through SaveSystem

**Files:** `scripts/autoloads/AudioManager.gd`

---

#### P4-302: SFX Integration
**Goal:** Wire up sound effects to events
- Connect to RanchState signals in AudioManager._ready():
  - `egg_created` → play "egg_created.ogg"
  - `egg_hatched` → play "egg_hatched.ogg"
  - `order_completed` → play "order_completed.ogg"
  - `money_changed` (if positive) → play "money_gain.ogg"
  - `reputation_increased` → play "unlock.ogg"
  - `facility_built` → play "build.ogg"
- Add UI sound effects:
  - Button press → "ui_click.ogg"
  - Panel open → "ui_confirm.ogg"
  - Error notification → "ui_error.ogg"

**Files:** `scripts/autoloads/AudioManager.gd` (add signal connections)

---

#### P4-303: Music Implementation
**Goal:** Add background music
- Start music loop on Ranch scene load:
  - Play "ranch_theme.ogg" (looping)
- Fade in/out on scene transitions
- Stop music on main menu

**Files:** `scripts/autoloads/AudioManager.gd` (add methods)

---

#### P4-304: Settings UI for Audio
**Goal:** Add volume sliders to settings
- Create `SettingsPanel.tscn` (PanelContainer)
- Add sliders:
  - Master Volume
  - Music Volume
  - SFX Volume
- Connect sliders to AudioManager
- Add "Test" button to play sample sound
- Save settings on change

**Files:**
- `scenes/ranch/ui/panels/SettingsPanel.tscn`
- `scripts/ranch/ui/panels/SettingsPanel.gd`

---

**Session 12 Acceptance Criteria:**
- [x] Egg creation plays sound
- [x] Order completion plays money sound
- [x] Button clicks have audio feedback
- [x] Background music loops seamlessly
- [x] Volume sliders work and persist
- [x] Audio doesn't clip or overlap excessively
