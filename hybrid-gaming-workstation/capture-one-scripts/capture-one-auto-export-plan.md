# Capture One Tethered Auto-Export / Hotkey Plan

## Goal

While tethering in Capture One on macOS, automatically (and manually) export
photos that have not yet been exported, mark them with the keyword `exported`,
and use whatever Process/Export Recipes are currently enabled.

## Platform

- macOS
- Capture One 16.5.11.15 (AppleScript support confirmed)

## Constraints

- On Capture One 16.5.x the `CO_BatchDone` background handler (which returns
  exported file paths) is **not** available. It was added in 16.7.3.
- Therefore the keyword `exported` must be applied **before** the export is
  triggered, and the enabled recipe(s) must be configured to include keywords
  in exported metadata.
- AppleScript is the only supported scripting API on macOS. There is no
  equivalent on Windows.

## Two modes

### 1. Auto-export on capture (with 2-minute editing window)

When a new tethered image lands in Capture One, a background AppleScript handler
fires. The script waits 2 minutes, then checks whether the variant already has
the keyword `exported`. If it does not, the keyword is added and the image is
processed using the currently enabled recipes.

The 2-minute delay is implemented as a simple `delay 120` inside the
`CO_CaptureDone` handler. This means the handler is blocked for 2 minutes; if
you shoot faster than every 2 minutes, the delays stack. A future improvement is
an `on idle` queue that checks timestamps and exports anything older than 2
minutes.

### 2. Manual hotkey for all unexported photos

A foreground AppleScript scans all variants in the current collection, skips any
already tagged `exported`, adds the keyword, and triggers `process` for each.
This is bound to a keyboard shortcut via the Capture One Scripts menu and macOS
App Shortcuts.

## Files to create

```
~/Library/Scripts/Capture One Scripts/
├── Export Unexported.scpt              # foreground hotkey script
└── Background Scripts/
    └── Auto Export New Captures.scpt  # background capture handler
```

Source files should also be kept in this repo so changes can be tracked:

```
opencode-personal-assistant-projects/hybrid-gaming-workstation/capture-one-scripts/
├── Auto Export New Captures.applescript
├── Export Unexported.applescript
└── README.md
```

## Draft script — Auto Export New Captures

```applescript
(*
  Auto-export new tethered captures after a 2-minute editing window.
  Adds keyword "exported" and processes the image using currently enabled recipes.
  If the photo was already exported manually during the delay, it is skipped.
*)

on CO_CaptureDone(rawFilePath)
	delay 120
	
	tell application "Capture One"
		tell front document
			set targetVariants to {}
			repeat with v in variants
				try
					if POSIX path of (image file of parent image of v as alias) is rawFilePath then
						set end of targetVariants to v
					end if
				end try
			end repeat
			
			if (count of targetVariants) is 0 then
				display notification "Could not find variant for " & rawFilePath with title "Auto Export"
				return
			end if
			
			repeat with v in targetVariants
				set kwNames to {}
				repeat with kw in keywords of v
					set end of kwNames to name of kw
				end repeat
				
				if kwNames does not contain "exported" then
					tell v to make keyword with properties {name:"exported"}
					set batchID to process rawFilePath
					if batchID starts with "ERROR" then
						display notification batchID with title "Export Error"
					end if
				end if
			end repeat
		end tell
	end tell
end CO_CaptureDone
```

## Draft script — Export Unexported

```applescript
(*
  Export all variants in the current collection that are not tagged "exported".
  Uses the recipes currently enabled in Capture One.
*)

use AppleScript version "2.4"
use scripting additions

tell application "Capture One"
	tell front document
		set currentVariants to variants of current collection
		set unexportedVariants to {}
		
		repeat with v in currentVariants
			set kwNames to {}
			repeat with kw in keywords of v
				set end of kwNames to name of kw
			end repeat
			
			if kwNames does not contain "exported" then
				set end of unexportedVariants to v
			end if
		end repeat
		
		set exportCount to count of unexportedVariants
		
		if exportCount is 0 then
			display notification "No unexported photos found." with title "Export Unexported"
			return
		end if
		
		repeat with v in unexportedVariants
			tell v to make keyword with properties {name:"exported"}
			set rawPath to POSIX path of (image file of parent image of v as alias)
			set batchID to process rawPath
			if batchID starts with "ERROR" then
				display notification batchID with title "Export Error"
			end if
		end repeat
		
		display notification "Queued " & exportCount & " photo(s) for export." with title "Export Unexported"
	end tell
end tell
```

## Installation steps

1. Ensure Capture One shows the Scripts menu:
   - **Capture One → Preferences → Plugins / Scripts → Show Scripts menu**
2. Create scripts folder if it does not exist:
   ```bash
   mkdir -p "~/Library/Scripts/Capture One Scripts/Background Scripts"
   ```
3. Copy `Auto Export New Captures.scpt` into `Background Scripts/`.
4. Copy `Export Unexported.scpt` into `Capture One Scripts/`.
5. Restart Capture One so background scripts are loaded.
6. For the hotkey:
   - **System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts**
   - Add a shortcut for **Capture One** with menu title exactly `Export Unexported`.
   - If the shortcut does not appear in System Settings, add a dummy shortcut
     first, quit Capture One and System Settings, run the script installer once,
     then remove the dummy and add the real shortcut.

## Recipe metadata requirement

For the `exported` keyword to travel with the exported file, each enabled
Process/Export Recipe must be set to include keywords:

- Select the recipe
- In the **Metadata** tab, set **Keywords** to **Default** or **All keywords**
- Do **not** use **No keywords**

## Open questions before finalizing

1. Should the manual hotkey operate on the current selection or all variants in
   the current collection? (Plan assumes all in current collection.)
2. Should the keyword `exported` also be written to a Capture One keyword
   library, or is a plain keyword sufficient?
3. Is the 2-minute `delay` acceptable, or should we build the `on idle` queue
   version immediately to avoid stacking delays during rapid shooting?
4. Where should exported files go? The current enabled recipes control this; the
   script does not set output location.

## Next actions

1. Finalize answers to the open questions above.
2. Compile and install both `.scpt` files on the Mac.
3. Test auto-export with one tethered shot and verify the keyword and output.
4. Test manual hotkey after importing/capturing several shots.
5. Update this plan with any script fixes and commit the final scripts.

## References

- Emory Dunn CaptureOneScripts: `CO_CaptureDone` and `process` examples
  (https://github.com/emorydunn/CaptureOneScripts)
- Capture One AppleScript workflow guide
  (https://support.captureone.com/hc/en-us/articles/360002681418)
- Capture One 16.7.3 release notes: `CO_BatchDone` added later
  (https://support.captureone.com/hc/en-us/articles/33550967023389)
