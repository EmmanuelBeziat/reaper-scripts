# reaper-scripts

ReaPack scripts for REAPER.

## Scripts

| Script | Description |
|--------|-------------|
| **Create time selection from current region** | Creates a time selection from the region at the current position (playhead when playing, edit cursor when stopped). With overlapping regions, uses the one with the closest start. |

---

# Helix Markers

Place Line 6 Helix cues as markers instead of editing MIDI by hand. Both scripts run only when launched (preparation step, not during playback).

| Script | Action |
|--------|--------|
| **Helix_Markers to MIDI** | Reads the markers of the **Helix** ruler lane, writes the events into the MIDI item of the **Helix Snapshots** track (created or extended to span the project), then deletes the markers |
| **Helix_MIDI to Markers** | Moves the CC32/PC/CC69 events of **Helix Snapshots** back to markers on the **Helix** lane (created if missing) |

## Marker syntax

| Marker | Events |
|--------|--------------------|
| `p-2-14` | CC32 = 2 (setlist), PC = 14 |
| `p-2-12C` | CC32 = 2, PC = 46 (Helix preset name, bank 01-32 + A-D) |
| `p-14` | PC = 14 only |
| `s-1` | CC69 = 1 (snapshot) |
| `p-2-12C-s-1` | CC69 exactly at the marker; CC32 + PC on one tick, 1/64 note before it |

Values are raw MIDI values (setlist and snapshot 0-7). Markers created from MIDI are colored: orange = preset, blue = snapshot, purple = preset + snapshot. Each cue written to MIDI is labelled on the item with a take marker of the same color (`2:04C S1`, `04C`, `S0`); MIDI to Markers removes these labels and keeps other take markers. Events are written on channel 1 and read on any channel: the track's MIDI hardware output sets the Helix channel. Other events of the item (e.g. CC1 expression ramps) are never touched. If one marker name is invalid, nothing is changed.

---

# Band Record

Set of ReaScripts for recording a band in REAPER.

## Scripts

| Step | Script                 | Action                          |
|------|------------------------|---------------------------------|
| 1    | **BR_Create Record Tracks** | Add Record group from template |
| 2    | **BR_Record Tracks** | Arm, mute monitor, start record |
| 3    | **BR_Remove Recorded Items** | Clear items on Record (optional) |
| 4    | **BR_Render Tracks** | Render stems to `<records root>/<project folder>/<date>` |
| 5    | **BR_Delete Record Tracks** | Delete Record track and subtracks (optional) |


## Process

The workflow follows four main steps:

### 1. Create the Records group — **BR_Create Record Tracks**

- Checks if a track named **Records** already exists (if so, does nothing).
- Loads the track template **Record Band** from `TrackTemplates/Record Band.RTrackTemplate` and inserts the tracks at the end of the track list.

**Requirement:** Save your band template as `Record Band.RTrackTemplate` in REAPER’s `TrackTemplates` folder (inside the Resource path).

---

### 2. Record — **BR_Record Tracks**

- Checks that all subtracks under **Records** are empty; if not, shows an error and stops.
- If tracks outside **Records** are armed, lists them and asks: disarm them, keep them, or cancel.
- Mutes the **Records** track and the **Track** track (so you don’t hear them while recording).
- Arms all subtracks of **Records** for recording.
- Starts recording at the current edit cursor position.

Run this when you’re ready to record a take.

---

### 3. Clear and re-record (optional) — **BR_Remove Recorded Items**

- Selects the **Records** track and all its children.
- Asks for confirmation, then deletes all media items on those tracks (keeps the tracks and routing).

Use this when you want to wipe a take and record again without removing the Records group.

---

### 4. Render stems — **BR_Render Tracks**

- Requires a saved project.
- Selects the **Records** track and all its children, unmutes them and disarms the subtracks.
- On first use, asks for the records root folder (default `~/Production/Records`) and stores it for this machine (`reaper-extstate.ini`, section `[BandRecord]`, key `records_root`; delete it to be asked again).
- Renders to `<records root>/<project folder name>/<YYYY-MM-DD HHhMMm>`.
- Applies the render preset **StemsExport** (from cfillion’s “Apply render preset”) to render selected tracks as stems. If that script/preset is missing, it falls back to: selected tracks (stems), pattern `$track`, MP3 with REAPER default settings.
- Sets the render output to the new folder and the render bounds to the time range of the recorded items (the time selection and the preset bounds are ignored), then runs the render.
- Mutes the **Records** track again when done, and reports whether all files were written.

**Optional:** Install [cfillion’s Apply render preset](https://github.com/ReaTeam/ReaScripts/blob/master/ReaScripts/cfillion/Apply%20render%20preset.lua) and create a preset named **StemsExport** (e.g. stems, `$track`, MP3 320) for consistent results.

---

### 5. Delete Records group (optional) — **BR_Delete Record Tracks**

- Finds the **Records** track and its subtracks.
- If any subtrack has media items, shows a warning that the content will be lost if not rendered and asks for confirmation (OK/Cancel).
- Deletes the Records track and all its subtracks from the project.

Use this when you want to remove the Records group entirely (e.g. at the end of a session).

