-- tray.applescript: the menu-bar runbook tray. It only draws; runbook-tray.py decides what is shown.
--
-- Compiled by build.sh with osacompile, which is part of macOS. The six properties below that sit between @ signs
-- are filled in by `runbook-tray.py stamp` at build time. Nothing here is outside code: AppleScript, Foundation, AppKit.
--
-- What it does: keeps one item in the menu bar; every few seconds asks the helper to run the status command and
-- write menu.json; draws that file as the menu; when an entry is chosen, asks the helper to do it.
-- What it never does: decide anything, read the config, or run a command of its own.
--
-- Before you edit: AppleScript does not tell upper case from lower, and a variable shares one set of names with
-- the AppKit methods called here. A variable named subMenu turned the call submenu() into subMenu() and broke it.
-- Words AppleScript or its standard additions already own cannot be variables either: kind, note, it, name.
-- The self-test with --with-applet draws every menu and reports the first such mistake by name.
--
-- Self-test (no helper is started, nothing is opened):
--   "<app>/Contents/MacOS/applet" --selftest <folder of menu.json files> <report file>
use AppleScript version "2.5"
use scripting additions
use framework "Foundation"
use framework "AppKit"

property pythonPath : "@@PYTHON@@"
property helperPath : "@@HELPER@@"
property configPath : "@@CONFIG@@"
property stateDir : "@@STATE@@"
property trayName : "@@NAME@@"
property everyText : "@@EVERY@@"

property statusItem : missing value
property trayMenu : missing value
property model : missing value
property ticker : missing value
property napToken : missing value
property helpers : missing value -- process id (text) -> {what it is, the task}
property renderStarted : 0
property renderAgain : false
property testing : false
property testReport : ""

-- ---------- starting and stopping ----------

on run
	if statusItem is not missing value then return
	try
		set argv to (current application's NSProcessInfo's processInfo()'s arguments()) as list
		set testDir to missing value
		set testOut to missing value
		repeat with i from 1 to (count of argv)
			if ((item i of argv) as text) is "--selftest" and (i + 2) ≤ (count of argv) then
				set testDir to (item (i + 1) of argv) as text
				set testOut to (item (i + 2) of argv) as text
			end if
		end repeat
		set helpers to current application's NSMutableDictionary's dictionary()
		if testDir is not missing value then
			set testing to true
			my makeItem()
			my runSelfTest(testDir, testOut)
			return
		end if
		current application's NSFileManager's defaultManager()'s createDirectoryAtPath:stateDir withIntermediateDirectories:true attributes:(missing value) |error|:(missing value)
		my makeItem()
		my logLine("started")
		my loadModel(stateDir & "/menu.json")
		my paintBar()
		my rebuildMenu()
		my kickRender()
		set secs to 60
		try
			set secs to everyText as integer
		end try
		if secs < 15 then set secs to 15
		set ticker to current application's NSTimer's scheduledTimerWithTimeInterval:secs target:me selector:"tick:" userInfo:(missing value) repeats:true
		ticker's setTolerance:(secs / 10)
		-- 16777215 is NSActivityUserInitiatedAllowingIdleSystemSleep: the timer keeps its time, the Mac may still sleep.
		set napToken to current application's NSProcessInfo's processInfo()'s beginActivityWithOptions:16777215 reason:"watching scheduled jobs"
		current application's NSWorkspace's sharedWorkspace()'s notificationCenter()'s addObserver:me selector:"didWake:" |name|:"NSWorkspaceDidWakeNotification" object:(missing value)
	on error msg number n
		my logLine("start failed: " & msg & " (" & n & ")")
	end try
end run

on makeItem()
	set statusItem to current application's NSStatusBar's systemStatusBar()'s statusItemWithLength:-1.0
	statusItem's setAutosaveName:trayName
	set trayMenu to current application's NSMenu's alloc()'s initWithTitle:trayName
	trayMenu's setAutoenablesItems:false
	trayMenu's setDelegate:me
	statusItem's setMenu:trayMenu
	my paintBar()
	my rebuildMenu()
end makeItem

on shutDown()
	try
		my logLine("stopped")
		if ticker is not missing value then ticker's invalidate()
		if napToken is not missing value then current application's NSProcessInfo's processInfo()'s endActivity:napToken
		current application's NSWorkspace's sharedWorkspace()'s notificationCenter()'s removeObserver:me
		current application's NSNotificationCenter's defaultCenter()'s removeObserver:me
		if statusItem is not missing value then current application's NSStatusBar's systemStatusBar()'s removeStatusItem:statusItem
	end try
	set statusItem to missing value
	set trayMenu to missing value
	set model to missing value
	set ticker to missing value
	set napToken to missing value
	set helpers to missing value
end shutDown

on quitTray:sender
	my shutDown()
	current application's NSApp's terminate:(missing value)
end quitTray:

on quit
	my shutDown()
	continue quit
end quit

-- ---------- the helper ----------

on kickRender()
	set nowSecs to (current application's NSDate's |date|()'s timeIntervalSince1970()) as real
	if renderStarted > 0 and (nowSecs - renderStarted) < 120 then
		set renderAgain to true
		return
	end if
	set renderStarted to nowSecs
	set renderAgain to false
	if not (my startHelper({"render"}, "render")) then set renderStarted to 0
end kickRender

on startHelper(extraArgs, what)
	set allArgs to {"-I", helperPath} & extraArgs & {"--config", configPath, "--state", stateDir}
	if testing then
		set saved to AppleScript's text item delimiters
		set AppleScript's text item delimiters to " "
		set testReport to testReport & "would run: " & (allArgs as text) & linefeed
		set AppleScript's text item delimiters to saved
		return false
	end if
	try
		set aTask to current application's NSTask's alloc()'s init()
		aTask's setLaunchPath:pythonPath
		aTask's setArguments:allArgs
		set nowhere to current application's NSFileHandle's fileHandleWithNullDevice()
		aTask's setStandardInput:nowhere
		aTask's setStandardOutput:nowhere
		aTask's setStandardError:nowhere
		current application's NSNotificationCenter's defaultCenter()'s addObserver:me selector:"helperDone:" |name|:"NSTaskDidTerminateNotification" object:aTask
		aTask's |launch|()
		helpers's setObject:{what, aTask} forKey:((aTask's processIdentifier()) as text)
		return true
	on error msg number n
		my logLine("could not start the helper (" & what & "): " & msg & " (" & n & ")")
		return false
	end try
end startHelper

on helperDone:aNote
	try
		set aTask to aNote's object()
		current application's NSNotificationCenter's defaultCenter()'s removeObserver:me |name|:"NSTaskDidTerminateNotification" object:aTask
		set pidKey to (aTask's processIdentifier()) as text
		set what to "render"
		set pair to helpers's objectForKey:pidKey
		if pair is not missing value then
			set what to (pair's objectAtIndex:0) as text
			helpers's removeObjectForKey:pidKey
		end if
		if what is "render" then
			set renderStarted to 0
			my loadModel(stateDir & "/menu.json")
			my paintBar()
			if renderAgain then my kickRender()
		else
			my kickRender()
		end if
	on error msg number n
		my logLine("helperDone failed: " & msg & " (" & n & ")")
	end try
end helperDone:

on tick:aTimer
	try
		my paintBar()
		my kickRender()
	end try
end tick:

on renderSoon:aTimer
	try
		my kickRender()
	end try
end renderSoon:

on didWake:aNote
	try
		my kickRender()
	end try
end didWake:

-- ---------- reading what the helper wrote ----------

on loadModel(aPath)
	try
		set theData to current application's NSData's dataWithContentsOfFile:aPath
		if theData is missing value then return false
		set parsed to current application's NSJSONSerialization's JSONObjectWithData:theData options:0 |error|:(missing value)
		if parsed is missing value then return false
		if not ((parsed's isKindOfClass:(current application's NSDictionary)) as boolean) then return false
		set model to parsed
		return true
	on error
		return false
	end try
end loadModel

on textOf(aDict, aKey, fallback)
	set v to aDict's objectForKey:aKey
	if v is missing value then return fallback
	try
		return v as text
	on error
		return fallback
	end try
end textOf

on numberOf(aDict, aKey, fallback)
	set v to aDict's objectForKey:aKey
	if v is missing value then return fallback
	try
		return (v's doubleValue()) as real
	on error
		return fallback
	end try
end numberOf

on asText(v)
	if v is missing value then return ""
	try
		return v as text
	on error
		return ""
	end try
end asText

-- Seconds since the helper last finished a check, or -1 when it is fresh enough (or there is nothing yet).
on staleFor()
	if model is missing value or testing then return -1
	set epoch to my numberOf(model, "epoch", 0)
	set limit to my numberOf(model, "stale_after", 300)
	if epoch ≤ 0 then return -1
	set age to ((current application's NSDate's |date|()'s timeIntervalSince1970()) as real) - epoch
	if age > limit then return age
	return -1
end staleFor

on ageText(secs)
	if secs < 5400 then return ((secs div 60) as integer as text) & " min"
	return ((secs div 3600) as integer as text) & " h"
end ageText

-- ---------- drawing ----------

on tintColour(tint)
	if tint is "green" then return current application's NSColor's systemGreenColor()
	if tint is "amber" then return current application's NSColor's systemOrangeColor()
	if tint is "red" then return current application's NSColor's systemRedColor()
	if tint is "grey" then return current application's NSColor's systemGrayColor()
	return missing value
end tintColour

-- A system symbol in one colour, or as a template picture (which follows the menu bar's own colour) when tint is none.
on symbolImage(symName, tint, spoken)
	try
		set img to current application's NSImage's imageWithSystemSymbolName:symName accessibilityDescription:spoken
		if img is missing value then return missing value
		set colour to my tintColour(tint)
		if colour is missing value then
			img's setTemplate:true
			return img
		end if
		-- A filled mark has two layers: the sign inside is drawn white and the shape takes the colour.
		if symName ends with ".fill" then
			set cfg to current application's NSImageSymbolConfiguration's configurationWithPaletteColors:{current application's NSColor's whiteColor(), colour}
		else
			set cfg to current application's NSImageSymbolConfiguration's configurationWithPaletteColors:{colour}
		end if
		set tinted to img's imageWithSymbolConfiguration:cfg
		if tinted is missing value then return img
		return tinted
	on error
		return missing value
	end try
end symbolImage

-- The colour of a drawn meter. Blue is "no alarm"; amber and red are kept for state; grey ranks without judging.
on meterColour(tint)
	if tint is "amber" then return current application's NSColor's systemOrangeColor()
	if tint is "red" then return current application's NSColor's systemRedColor()
	if tint is "grey" then return current application's NSColor's systemGrayColor()
	if tint is "green" then return current application's NSColor's systemGreenColor()
	return current application's NSColor's systemBlueColor()
end meterColour

on capsule(x, y, w, h, r)
	return current application's NSBezierPath's bezierPathWithRoundedRect:(current application's NSMakeRect(x, y, w, h)) xRadius:r yRadius:r
end capsule

on blankImage()
	return current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(48, 12))
end blankImage

-- Is the menu dark? Colours that tell parts apart have one step for each ground.
on menuIsDark()
	try
		set best to current application's NSApp's effectiveAppearance()'s bestMatchFromAppearancesWithNames:{"NSAppearanceNameAqua", "NSAppearanceNameDarkAqua"}
		return (best as text) is "NSAppearanceNameDarkAqua"
	on error
		return false
	end try
end menuIsDark

-- A colour written as #rrggbb, or grey when it cannot be read.
on colourFromHex(hexText)
	try
		set digits to "0123456789abcdef"
		set parts to {}
		repeat with i from 0 to 2
			set pairText to text (2 + i * 2) thru (3 + i * 2) of hexText
			set hi to (offset of (character 1 of pairText) in digits) - 1
			set lo to (offset of (character 2 of pairText) in digits) - 1
			if hi < 0 or lo < 0 then error "not a colour"
			set end of parts to (hi * 16 + lo) / 255
		end repeat
		return current application's NSColor's colorWithSRGBRed:(item 1 of parts) green:(item 2 of parts) blue:(item 3 of parts) alpha:1.0
	on error
		return current application's NSColor's systemGrayColor()
	end try
end colourFromHex

on partColour(entry)
	if my menuIsDark() then return my colourFromHex(my textOf(entry, "dark", "#808080"))
	return my colourFromHex(my textOf(entry, "light", "#808080"))
end partColour

-- One whole split into its parts: a thin bar with round ends, a gap of the ground between parts, widths in
-- proportion, nothing drawn for a part too small to see.
on partsImage(arr, w, h)
	set img to missing value
	try
		if arr is missing value then return missing value
		set n to (arr's |count|()) as integer
		if n < 1 then return missing value
		set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(w, h + 4))
		img's lockFocus()
		(my capsule(0, 2, w, h, h / 2))'s addClip()
		-- the whole of memory, faintly, so that what the parts do not account for still shows as part of the bar
		((current application's NSColor's systemGrayColor())'s colorWithAlphaComponent:0.18)'s setFill()
		(current application's NSBezierPath's bezierPathWithRect:(current application's NSMakeRect(0, 2, w, h)))'s |fill|()
		set x to 0.0
		repeat with i from 0 to (n - 1)
			set part to (arr's objectAtIndex:i)
			set partW to w * (my numberOf(part, "value", 0))
			if partW ≥ 1.5 then
				(my partColour(part))'s setFill()
				((current application's NSBezierPath's bezierPathWithRect:(current application's NSMakeRect(x, 2, partW - 1.5, h)))'s |fill|())
			end if
			set x to x + partW
		end repeat
		img's unlockFocus()
		return img
	on error
		try
			if img is not missing value then img's unlockFocus()
		end try
		return missing value
	end try
end partsImage

-- The small square beside a part's name, in that part's colour.
on swatchImage(entry)
	set img to missing value
	try
		set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(12, 12))
		img's lockFocus()
		(my partColour(entry))'s setFill()
		(my capsule(1, 1, 10, 10, 3))'s |fill|()
		img's unlockFocus()
		return img
	on error
		try
			if img is not missing value then img's unlockFocus()
		end try
		return missing value
	end try
end swatchImage

-- A meter: a thin bar with round ends, its track a lighter step of the same colour, so the state reads along the whole bar.
on barImage(fraction, tint)
	set img to missing value
	try
		set barH to 6
		set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(48, 12))
		img's lockFocus()
		set colour to my meterColour(tint)
		(colour's colorWithAlphaComponent:0.25)'s setFill()
		(my capsule(0, 3, 48, barH, 3))'s |fill|()
		if fraction > 0 then
			set fillW to 48 * fraction
			if fillW < barH then set fillW to barH
			colour's setFill()
			(my capsule(0, 3, fillW, barH, 3))'s |fill|()
		end if
		img's unlockFocus()
		return img
	on error
		try
			if img is not missing value then img's unlockFocus()
		end try
		return missing value
	end try
end barImage

-- The last hour as one thin grey line, with the newest point marked in colour. The scale is the line's own range,
-- but never tighter than two points of the whole, so a flat hour looks flat.
on sparkImage(arr, tint)
	set img to missing value
	try
		if arr is missing value then return missing value
		set n to (arr's |count|()) as integer
		if n < 2 then return missing value
		set lowest to 2.0
		set highest to -1.0
		repeat with i from 0 to (n - 1)
			set v to ((arr's objectAtIndex:i)'s doubleValue()) as real
			if v < lowest then set lowest to v
			if v > highest then set highest to v
		end repeat
		if (highest - lowest) < 0.02 then
			set centre to (highest + lowest) / 2
			set lowest to centre - 0.01
			set highest to centre + 0.01
		end if
		set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(48, 14))
		img's lockFocus()
		set linePath to current application's NSBezierPath's bezierPath()
		linePath's setLineWidth:1.5
		linePath's setLineJoinStyle:1
		linePath's setLineCapStyle:1
		set px to 0
		set py to 0
		repeat with i from 0 to (n - 1)
			set v to ((arr's objectAtIndex:i)'s doubleValue()) as real
			set px to 2 + 42 * i / (n - 1)
			set py to 3 + 8 * (v - lowest) / (highest - lowest)
			if i is 0 then
				(linePath's moveToPoint:(current application's NSMakePoint(px, py)))
			else
				(linePath's lineToPoint:(current application's NSMakePoint(px, py)))
			end if
		end repeat
		(current application's NSColor's systemGrayColor())'s setStroke()
		linePath's stroke()
		(my meterColour(tint))'s setFill()
		(current application's NSBezierPath's bezierPathWithOvalInRect:(current application's NSMakeRect(px - 2.5, py - 2.5, 5, 5)))'s |fill|()
		img's unlockFocus()
		return img
	on error
		try
			if img is not missing value then img's unlockFocus()
		end try
		return missing value
	end try
end sparkImage

-- The menu bar's picture with a small upright gauge beside it. With no tint it is a template picture, which the
-- menu bar colours itself; the gauge's empty part is then the same ink, fainter.
on gaugeImage(symName, tint, fraction)
	set img to missing value
	try
		set glyph to my symbolImage(symName, tint, trayName)
		if glyph is missing value then return missing value
		set glyphSize to glyph's |size|()
		set gw to (width of glyphSize) as real
		set gh to (height of glyphSize) as real
		set h to 18.0
		if gh > h then set h to gh
		set barH to 14.0
		set y0 to (h - barH) / 2
		set img to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(gw + 8, h))
		img's lockFocus()
		glyph's drawInRect:(current application's NSMakeRect(0, (h - gh) / 2, gw, gh))
		set colour to my tintColour(tint)
		set isPlain to (colour is missing value)
		if isPlain then set colour to current application's NSColor's blackColor()
		(colour's colorWithAlphaComponent:0.3)'s setFill()
		(my capsule(gw + 3, y0, 5, barH, 2))'s |fill|()
		set fillH to barH * fraction
		if fillH < 3 then set fillH to 3
		if fillH > barH then set fillH to barH
		colour's setFill()
		(my capsule(gw + 3, y0, 5, fillH, 2))'s |fill|()
		img's unlockFocus()
		if isPlain then img's setTemplate:true
		return img
	on error
		try
			if img is not missing value then img's unlockFocus()
		end try
		return missing value
	end try
end gaugeImage

on paintBar()
	if statusItem is missing value then return
	set btn to statusItem's button()
	set symName to "checklist"
	set tint to "none"
	set shown to ""
	set gauge to -1
	set tip to trayName & ": waiting for the first check"
	if model is not missing value then
		set bar to model's objectForKey:"bar"
		if bar is not missing value then
			set symName to my textOf(bar, "symbol", "checklist")
			set tint to my textOf(bar, "tint", "none")
			set shown to my textOf(bar, "text", "")
			set tip to my textOf(bar, "tooltip", trayName)
			set gauge to my numberOf(bar, "gauge", -1)
		end if
		set age to my staleFor()
		if age > 0 then
			set tint to "none"
			set shown to "?"
			set gauge to -1
			set tip to trayName & ": not refreshed for " & my ageText(age)
		end if
	end if
	set img to missing value
	if gauge ≥ 0 then set img to my gaugeImage(symName, tint, gauge)
	if img is missing value then set img to my symbolImage(symName, tint, trayName)
	if img is missing value then
		btn's setImage:(missing value)
		if shown is "" then
			set shown to trayName
		else
			set shown to trayName & " " & shown
		end if
	else
		btn's setImage:img
	end if
	if shown is "" then
		btn's setImagePosition:1 -- the picture alone
	else
		btn's setImagePosition:2 -- the picture to the left of the count
	end if
	btn's setTitle:shown
	btn's setToolTip:tip
end paintBar

on rebuildMenu()
	if trayMenu is missing value then return
	trayMenu's removeAllItems()
	if model is missing value then
		my addInfo(trayMenu, "Waiting for the first check", "", "questionmark.circle", "grey", "?")
	else
		set age to my staleFor()
		if age > 0 then
			my addInfo(trayMenu, "Not refreshed for " & my ageText(age), "what follows is the last check that finished", "exclamationmark.triangle.fill", "amber", "!")
		end if
		my fillMenu(trayMenu, model's objectForKey:"items")
	end if
	-- These two are always here, whatever the helper wrote, so there is always a way to refresh and a way out.
	trayMenu's addItem:(current application's NSMenuItem's separatorItem())
	set refreshItem to current application's NSMenuItem's alloc()'s initWithTitle:"Refresh now" action:"menuAction:" keyEquivalent:""
	refreshItem's setTarget:me
	refreshItem's setRepresentedObject:"_refresh"
	my setPicture(refreshItem, "arrow.clockwise")
	trayMenu's addItem:refreshItem
	set quitItem to current application's NSMenuItem's alloc()'s initWithTitle:("Quit " & trayName) action:"quitTray:" keyEquivalent:""
	quitItem's setTarget:me
	my setPicture(quitItem, "power")
	trayMenu's addItem:quitItem
end rebuildMenu

-- Every kind of row the helper can ask for. A group becomes a submenu, filled the same way.
on fillMenu(aMenu, arr)
	if arr is missing value then return
	set n to (arr's |count|()) as integer
	repeat with i from 0 to (n - 1)
		set entry to (arr's objectAtIndex:i)
		set entryKind to my textOf(entry, "kind", "info")
		if entryKind is "separator" then
			(aMenu's addItem:(current application's NSMenuItem's separatorItem()))
		else if entryKind is "header" then
			my addHeader(aMenu, my textOf(entry, "title", ""))
		else if entryKind is "action" then
			my addAction(aMenu, entry)
		else if entryKind is "meter" then
			my addPicture(aMenu, entry, my barImage(my numberOf(entry, "value", 0), my textOf(entry, "tint", "blue")))
		else if entryKind is "spark" then
			my addPicture(aMenu, entry, my sparkImage(entry's objectForKey:"values", my textOf(entry, "tint", "blue")))
		else if entryKind is "parts" then
			my addPicture(aMenu, entry, my partsImage(entry's objectForKey:"parts", 220, 10))
		else if entryKind is "swatch" then
			my addPicture(aMenu, entry, my swatchImage(entry))
		else if entryKind is "group" then
			-- a folded group of rows carries the mark of its worst row; memory's parts carry their own small bar
			set groupPicture to missing value
			set groupSymbol to my textOf(entry, "symbol", "")
			if groupSymbol is not "" then set groupPicture to my symbolImage(groupSymbol, my textOf(entry, "tint", "none"), "")
			if groupPicture is missing value then set groupPicture to my partsImage(entry's objectForKey:"parts", 48, 6)
			if groupPicture is missing value then set groupPicture to my blankImage()
			set groupItem to my addPicture(aMenu, entry, groupPicture)
			set childMenu to (current application's NSMenu's alloc()'s initWithTitle:(my textOf(entry, "title", "")))
			(childMenu's setAutoenablesItems:false)
			my fillMenu(childMenu, entry's objectForKey:"items")
			(groupItem's setSubmenu:childMenu)
		else
			my addInfo(aMenu, my textOf(entry, "title", ""), my textOf(entry, "subtitle", ""), my textOf(entry, "symbol", ""), my textOf(entry, "tint", "none"), my textOf(entry, "mark", ""))
		end if
	end repeat
end fillMenu

on setSub(mi, shown, theSub)
	if theSub is "" then return
	if (mi's respondsToSelector:"setSubtitle:") as boolean then
		mi's setSubtitle:theSub
	else
		mi's setTitle:(shown & ": " & theSub)
	end if
	mi's setToolTip:theSub
end setSub

on addInfo(aMenu, theTitle, theSub, symName, tint, mark)
	set img to missing value
	if symName is not "" then set img to my symbolImage(symName, tint, "")
	set shown to theTitle
	if img is missing value and mark is not "" then set shown to mark & " " & theTitle
	set mi to current application's NSMenuItem's alloc()'s initWithTitle:shown action:(missing value) keyEquivalent:""
	my setSub(mi, shown, theSub)
	if img is not missing value then mi's setImage:img
	mi's setEnabled:true
	aMenu's addItem:mi
end addInfo

-- A row whose picture is drawn here: a meter, the line of the last hour, or a blank that keeps the words in line.
on addPicture(aMenu, entry, img)
	set shown to my textOf(entry, "title", "")
	set mi to current application's NSMenuItem's alloc()'s initWithTitle:shown action:(missing value) keyEquivalent:""
	my setSub(mi, shown, my textOf(entry, "subtitle", ""))
	if img is not missing value then mi's setImage:img
	mi's setEnabled:true
	aMenu's addItem:mi
	return mi
end addPicture

on addHeader(aMenu, theTitle)
	if (current application's NSMenuItem's respondsToSelector:"sectionHeaderWithTitle:") as boolean then
		aMenu's addItem:(current application's NSMenuItem's sectionHeaderWithTitle:theTitle)
	else
		set mi to current application's NSMenuItem's alloc()'s initWithTitle:theTitle action:(missing value) keyEquivalent:""
		mi's setEnabled:false
		aMenu's addItem:mi
	end if
end addHeader

-- A plain picture in the menu's own ink, so that the words of every row start in the same place.
on setPicture(mi, symName)
	if symName is "" then return
	set img to my symbolImage(symName, "none", "")
	if img is not missing value then mi's setImage:img
end setPicture

on addAction(aMenu, entry)
	set shown to my textOf(entry, "title", "")
	set mi to current application's NSMenuItem's alloc()'s initWithTitle:shown action:"menuAction:" keyEquivalent:""
	mi's setTarget:me
	mi's setRepresentedObject:(my textOf(entry, "id", ""))
	my setSub(mi, shown, my textOf(entry, "subtitle", ""))
	my setPicture(mi, my textOf(entry, "symbol", ""))
	set canChoose to true
	set v to entry's objectForKey:"enabled"
	if v is not missing value then
		try
			set canChoose to (v's boolValue()) as boolean
		end try
	end if
	mi's setEnabled:canChoose
	aMenu's addItem:mi
end addAction

-- ---------- what the menu calls ----------

on menuNeedsUpdate:aMenu
	try
		if not testing then my loadModel(stateDir & "/menu.json")
		my paintBar()
		my rebuildMenu()
		if not testing then my kickRender()
	on error msg number n
		my logLine("menu update failed: " & msg & " (" & n & ")")
	end try
end menuNeedsUpdate:

on menuAction:sender
	try
		set chosen to my asText(sender's representedObject())
		if chosen is "" then return
		if chosen is "_refresh" then
			my kickRender()
			return
		end if
		my logLine("entry chosen: " & chosen)
		if my startHelper({"act", chosen}, "act") then
			current application's NSTimer's scheduledTimerWithTimeInterval:1.0 target:me selector:"renderSoon:" userInfo:(missing value) repeats:false
		end if
	on error msg number n
		my logLine("menuAction failed: " & msg & " (" & n & ")")
	end try
end menuAction:

-- ---------- the log ----------

on logLine(what)
	if testing then
		set testReport to testReport & "log: " & what & linefeed
		return
	end if
	try
		set fmt to current application's NSDateFormatter's alloc()'s init()
		fmt's setDateFormat:"yyyy-MM-dd HH:mm:ss"
		set stamp to (fmt's stringFromDate:(current application's NSDate's |date|())) as text
		set entryText to current application's NSString's stringWithString:(stamp & "  " & what & linefeed)
		set logPath to stateDir & "/tray.log"
		set fh to current application's NSFileHandle's fileHandleForWritingAtPath:logPath
		if fh is missing value then
			entryText's writeToFile:logPath atomically:true encoding:4 |error|:(missing value)
		else
			fh's seekToEndOfFile()
			fh's writeData:(entryText's dataUsingEncoding:4)
			fh's closeFile()
		end if
	end try
end logLine

-- ---------- the self-test ----------

-- Draws every menu.json in a folder, in name order, reads back from AppKit what was drawn, sends each item's action the
-- way a click does, writes the report, and quits. The helper is never started and nothing is opened.
on runSelfTest(testDir, testOut)
	try
		set fm to current application's NSFileManager's defaultManager()
		set names to fm's contentsOfDirectoryAtPath:testDir |error|:(missing value)
		if names is missing value then error "cannot list " & testDir
		set names to names's sortedArrayUsingSelector:"compare:"
		repeat with i from 0 to (((names's |count|()) as integer) - 1)
			set nm to (names's objectAtIndex:i) as text
			if nm ends with ".json" then
				set model to missing value
				set loaded to my loadModel(testDir & "/" & nm)
				set testReport to testReport & "== " & nm & " loaded=" & (loaded as text) & linefeed
				my paintBar()
				my rebuildMenu()
				set testReport to testReport & my dumpAll()
				my saveSheet(testOut & "." & nm & ".png")
				my clickAll()
			end if
		end repeat
		set testReport to testReport & "selftest: done" & linefeed
	on error msg number n
		set testReport to testReport & "SELFTEST ERROR: " & msg & " (" & n & ")" & linefeed
	end try
	(current application's NSString's stringWithString:testReport)'s writeToFile:testOut atomically:true encoding:4 |error|:(missing value)
	current application's NSTimer's scheduledTimerWithTimeInterval:0.3 target:me selector:"endTest:" userInfo:(missing value) repeats:false
end runSelfTest

on endTest:aTimer
	my shutDown()
	current application's NSApp's terminate:(missing value)
end endTest:

on dumpAll()
	set dumpText to ""
	set btn to statusItem's button()
	set hasImage to ((btn's |image|()) is not missing value)
	set dumpText to dumpText & "bar: title=[" & my asText(btn's |title|()) & "] image=" & (hasImage as text) & " tip=[" & my asText(btn's toolTip()) & "]" & linefeed
	set n to (trayMenu's numberOfItems()) as integer
	repeat with i from 0 to (n - 1)
		set mi to (trayMenu's itemAtIndex:i)
		if (mi's isSeparatorItem()) as boolean then
			set dumpText to dumpText & "  ---" & linefeed
		else
			set subText to ""
			if (mi's respondsToSelector:"subtitle") as boolean then set subText to my asText(mi's |subtitle|())
			set hasPicture to ((mi's |image|()) is not missing value)
			set isWired to ((mi's |target|()) is not missing value)
			set isHead to false
			if (mi's respondsToSelector:"isSectionHeader") as boolean then set isHead to (mi's isSectionHeader()) as boolean
			set dumpText to dumpText & "  item: [" & my asText(mi's |title|()) & "] sub=[" & subText & "] picture=" & (hasPicture as text) & " enabled=" & ((mi's isEnabled()) as text) & " wired=" & (isWired as text) & " header=" & (isHead as text) & " id=[" & my asText(mi's representedObject()) & "]" & linefeed
			if (mi's hasSubmenu()) as boolean then
				set kids to mi's submenu()
				repeat with k from 0 to (((kids's numberOfItems()) as integer) - 1)
					set kid to (kids's itemAtIndex:k)
					set kidSub to ""
					if (kid's respondsToSelector:"subtitle") as boolean then set kidSub to my asText(kid's |subtitle|())
					set dumpText to dumpText & "    under it: [" & my asText(kid's |title|()) & "] sub=[" & kidSub & "] picture=" & (((kid's |image|()) is not missing value) as text) & linefeed
				end repeat
			end if
		end if
	end repeat
	return dumpText
end dumpAll

-- For a person to look at: the menu bar's picture and every row's picture with its words, once on a light ground and
-- once on a dark one. A template picture is drawn white on the dark ground, as the menu bar would draw it.
on saveSheet(pngPath)
	try
		set shots to {}
		set n to (trayMenu's numberOfItems()) as integer
		repeat with i from 0 to (n - 1)
			set mi to (trayMenu's itemAtIndex:i)
			if not ((mi's isSeparatorItem()) as boolean) then
				set end of shots to mi
				if (mi's hasSubmenu()) as boolean then
					set kids to mi's submenu()
					repeat with k from 0 to (((kids's numberOfItems()) as integer) - 1)
						set end of shots to (kids's itemAtIndex:k)
					end repeat
				end if
			end if
		end repeat
		set rowH to 30
		set halfW to 430
		set sheetH to 40 + rowH * (count of shots)
		set sheet to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(halfW * 2, sheetH))
		sheet's lockFocus()
		repeat with half from 0 to 1
			set x0 to half * halfW
			if half is 0 then
				(current application's NSColor's colorWithWhite:0.95 alpha:1.0)'s setFill()
				set ink to current application's NSColor's blackColor()
				set faint to current application's NSColor's colorWithWhite:0.4 alpha:1.0
			else
				(current application's NSColor's colorWithWhite:0.15 alpha:1.0)'s setFill()
				set ink to current application's NSColor's whiteColor()
				set faint to current application's NSColor's colorWithWhite:0.65 alpha:1.0
			end if
			(current application's NSBezierPath's bezierPathWithRect:(current application's NSMakeRect(x0, 0, halfW, sheetH)))'s |fill|()
			set titleLook to current application's NSDictionary's dictionaryWithObjects:{current application's NSFont's menuFontOfSize:13, ink} forKeys:{"NSFont", "NSColor"}
			set subLook to current application's NSDictionary's dictionaryWithObjects:{current application's NSFont's menuFontOfSize:10, faint} forKeys:{"NSFont", "NSColor"}
			set btn to statusItem's button()
			set barPicture to btn's |image|()
			if barPicture is not missing value then
				if half is 1 and ((barPicture's isTemplate()) as boolean) then set barPicture to my whitened(barPicture)
				set barSize to barPicture's |size|()
				barPicture's drawInRect:(current application's NSMakeRect(x0 + 12, sheetH - 30, (width of barSize) as real, (height of barSize) as real))
				(current application's NSString's stringWithString:(my asText(btn's |title|()) & "   (the menu bar)"))'s drawAtPoint:(current application's NSMakePoint(x0 + 50, sheetH - 28)) withAttributes:titleLook
			end if
			repeat with r from 1 to (count of shots)
				set mi to item r of shots
				set y to sheetH - 40 - rowH * r
				set pic to mi's |image|()
				set textX to x0 + 14
				if pic is not missing value then
					set picSize to pic's |size|()
					set pw to (width of picSize) as real
					set ph to (height of picSize) as real
					(pic's drawInRect:(current application's NSMakeRect(x0 + 14, y + (rowH - ph) / 2, pw, ph)))
					set textX to x0 + 14 + pw + 8
				end if
				set subText to ""
				if (mi's respondsToSelector:"subtitle") as boolean then set subText to my asText(mi's |subtitle|())
				if subText is "" then
					((current application's NSString's stringWithString:(my asText(mi's |title|())))'s drawAtPoint:(current application's NSMakePoint(textX, y + 7)) withAttributes:titleLook)
				else
					((current application's NSString's stringWithString:(my asText(mi's |title|())))'s drawAtPoint:(current application's NSMakePoint(textX, y + 13)) withAttributes:titleLook)
					((current application's NSString's stringWithString:subText)'s drawAtPoint:(current application's NSMakePoint(textX, y + 1)) withAttributes:subLook)
				end if
			end repeat
		end repeat
		sheet's unlockFocus()
		set bits to current application's NSBitmapImageRep's imageRepWithData:(sheet's TIFFRepresentation())
		set png to bits's representationUsingType:4 |properties|:(current application's NSDictionary's dictionary())
		png's writeToFile:pngPath atomically:true
		set testReport to testReport & "sheet: " & pngPath & linefeed
	on error msg number n
		set testReport to testReport & "SHEET ERROR: " & msg & " (" & n & ")" & linefeed
	end try
end saveSheet

on whitened(pic)
	set picSize to pic's |size|()
	set pw to (width of picSize) as real
	set ph to (height of picSize) as real
	set copyPic to current application's NSImage's alloc()'s initWithSize:(current application's NSMakeSize(pw, ph))
	copyPic's lockFocus()
	pic's drawInRect:(current application's NSMakeRect(0, 0, pw, ph))
	(current application's NSColor's whiteColor())'s setFill()
	current application's NSRectFillUsingOperation(current application's NSMakeRect(0, 0, pw, ph), 3) -- keep the shape, change the ink
	copyPic's unlockFocus()
	return copyPic
end whitened

on clickAll()
	set n to (trayMenu's numberOfItems()) as integer
	repeat with i from 0 to (n - 1)
		set mi to (trayMenu's itemAtIndex:i)
		set chosen to my asText(mi's representedObject())
		if chosen is not "" and ((mi's isEnabled()) as boolean) then
			set testReport to testReport & "click: " & chosen & linefeed
			(current application's NSApp's sendAction:"menuAction:" |to|:(mi's |target|()) |from|:mi)
		end if
	end repeat
end clickAll
