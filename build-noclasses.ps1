param([string]$Output = (Join-Path $PSScriptRoot 'TuinRPG_NoClasses.pk3'))

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'src'
if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Missing PK3 source directory: $source"
}

$resolvedOutput = [System.IO.Path]::GetFullPath($Output)
$parent = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($parent)) {
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
}

$tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$stage = Join-Path $tempRoot ("TuinRPG_NoClasses_" + [System.Guid]::NewGuid().ToString('N'))
$resolvedStage = [System.IO.Path]::GetFullPath($stage)
if (-not $resolvedStage.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to use a staging directory outside the system temp folder: $resolvedStage"
}

try {
    [System.IO.Directory]::CreateDirectory($resolvedStage) | Out-Null
    Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $resolvedStage -Recurse -Force

    # Preserve the original blue UI palette and all source text animations.

    # The regular edition includes ProjectSIDE's complete weapon/effect layer.
    # A compatibility edition must not replace even one player weapon, projectile,
    # puff, or canonical weapon sound, otherwise the external weapon mod loses
    # control of part of its arsenal (the chainsaw was the most visible example).
    $decoratePath = Join-Path $resolvedStage 'DECORATE'
    $classlessDecorate = @'
// Inert compile-time stubs only. None replaces, grants, or selects a weapon.
ACTOR PerkFist : Fist {}
ACTOR PerkPistol : Pistol {}
ACTOR Z86Chainsaw : Chainsaw {}
ACTOR PerkShotgun : Shotgun {}
ACTOR PerkSuperShotgun : SuperShotgun {}
ACTOR Z86Chaingun : Chaingun {}
ACTOR PerkRocketLauncher : RocketLauncher {}
ACTOR BloxPlasmaRifle : PlasmaRifle {}
ACTOR Z86BFG9000 : BFG9000 {}
ACTOR TuinMinigun : Weapon {}
ACTOR TuinMinigunRounds : Inventory {}
ACTOR TuinMinigunInitialized : Inventory {}
ACTOR XtremeSGPuff : BulletPuff {}
'@
    [System.IO.File]::WriteAllText($decoratePath, $classlessDecorate + "`r`n")
    $decoPath = Join-Path $resolvedStage 'DECO'
    if (Test-Path -LiteralPath $decoPath -PathType Container) {
        Remove-Item -LiteralPath $decoPath -Recurse -Force
    }
    $acsPath = Join-Path $resolvedStage 'ACS'
    if (Test-Path -LiteralPath $acsPath -PathType Container) {
        Remove-Item -LiteralPath $acsPath -Recurse -Force
    }
    $loadAcsPath = Join-Path $resolvedStage 'LOADACS'
    if (Test-Path -LiteralPath $loadAcsPath -PathType Leaf) {
        Remove-Item -LiteralPath $loadAcsPath -Force
    }
    @(
        'SNDINFO.PlayerWeps', 'SNDINFO.ProPuff', 'SNDINFO.WepDraws',
        'SNDINFO.DoomGuyQuad', 'SNDINFO.Engineer', 'SNDINFO.EngineerMine',
        'SNDINFO.HeavySupport', 'SNDINFO.QuickGrenade', 'SNDINFO.RogueWeapons',
        'SNDINFO.CaGoTer', 'DECALDEF'
    ) | ForEach-Object {
        $soundInfo = Join-Path $resolvedStage $_
        if (Test-Path -LiteralPath $soundInfo -PathType Leaf) {
            Remove-Item -LiteralPath $soundInfo -Force
        }
    }

    # Do not register the ProjectSIDE loadout/grenade handler. It normalizes the
    # starting fist and pistol and would therefore still alter external arsenals.
    $mapInfoPath = Join-Path $resolvedStage 'MAPINFO'
    $mapInfo = [System.IO.File]::ReadAllText($mapInfoPath)
    $mapInfo = $mapInfo.Replace('"PSCompatWeaponHandler", ', '')
    $mapInfo += "`r`nGameInfo { AddEventHandlers = `"TuinRunMenuRouter`" }`r`n"
    $mapInfo = $mapInfo.Replace('Statscreen_Single =', 'StatusBarClass = "TuinCombatHUD"' + "`r`n`tStatscreen_Single =")
    [System.IO.File]::WriteAllText($mapInfoPath, $mapInfo)

    # Publish only controls that exist in this edition. Old V/B/C/G defaults may
    # remain in a user's config, but no class/grenade handler consumes them.
    $keyConfPath = Join-Path $resolvedStage 'KEYCONF'
    $classlessKeys = @'
addkeysection "Tuin RPG" TuinRPG
addmenukey "Open Character Screen" "openmenu TuinRPGCharacter"
addmenukey "Open Weapon Arsenal" "openmenu TuinRPGArsenal"
addmenukey "Open Weapon Wheel" "openmenu TuinRPGWeaponWheel"
addmenukey "Inspect Current Weapon" "netevent tuin_inspect_weapon"
defaultbind I "netevent tuin_inspect_weapon"
addmenukey "Toggle Flashlight" "netevent tuin_toggle_flashlight"
addmenukey "Toggle Minimap" "netevent tuin_toggle_minimap"
addmenukey "Locator menu (cheat required)" "netevent tuin_locator_menu"
defaultbind O "netevent tuin_locator_menu"
defaultbind K "openmenu TuinRPGCharacter"
defaultbind L "openmenu TuinRPGArsenal"
defaultbind F "netevent tuin_toggle_flashlight"
defaultbind N "netevent tuin_toggle_minimap"
defaultbind Q "openmenu TuinRPGWeaponWheel"
'@
    [System.IO.File]::WriteAllText($keyConfPath, $classlessKeys + "`r`n")

    # Remove unreachable role menus and role-only testing/tuning entries from the
    # packaged menu definitions, so console-opened screens cannot expose leftovers.
    $menuDefPath = Join-Path $resolvedStage 'MENUDEF'
    $menuDef = [System.IO.File]::ReadAllText($menuDefPath)
    $menuDef = $menuDef.Replace('OptionMenu "TuinRPGOptions"', 'OptionMenu "TuinRPGAdvancedOptions"')
    $menuDef = $menuDef.Replace('Submenu "Tuin RPG Options", "TuinRPGOptions"', 'Submenu "Tuin RPG Options", "TuinRPGDifficulty"')
    $menuDef += @'

OptionMenu "TuinRPGOptions"
{
    Class "TuinRPGHubMenu"
}
OptionMenu "TuinRPGLocator"
{
    Class "TuinLocatorMenu"
}
OptionMenu "TuinRunStart" { Class "TuinRunMenu" }
OptionMenu "TuinRunScores" { Class "TuinRunScoresMenu" }
OptionMenu "TuinRPGDifficulty"
{
    Class "TuinDifficultySettings"
}
OptionMenu "TuinRPGDisplayOptions"
{
    Title "HUD AND MINIMAP"
    Option "Modern HUD", "tuin_modern_hud", "OnOff"
    Option "Animated combat bonuses", "tuin_combat_bonus_hud", "OnOff"
    Slider "HUD size", "tuin_hud_scale", 1.0, 3.0, 0.25, 2
    Option "Floating damage numbers", "tuin_damage_numbers", "OnOff"
    Submenu "Minimap settings", "TuinRPGMinimapOptions"
}
'@
    $menuDef = $menuDef.Replace('CLASS AND PERKS', 'GENERAL PERKS')
    $menuDef = $menuDef.Replace('CLASSES AND PERKS', 'UNIVERSAL PERKS')
    $menuDef = $menuDef.Replace('Submenu "GENERAL PERKS", "TuinRPGPerkHub"',
        'Submenu "GENERAL PERKS", "TuinRPGGeneralPerks"')
    $menuDef = $menuDef.Replace('Submenu "ARSENAL", "TuinRPGArsenal"',
        "Submenu `"ARSENAL`", `"TuinRPGArsenal`"`r`n`tSubmenu `"WEAPON PERKS`", `"TuinRPGWeaponPerks`"")
    $menuDef = $menuDef.Replace('Healer base healing/second', 'Support healing/second')
    $menuDef = $menuDef.Replace('Slider "Drop lifetime (seconds)", "tuin_weapon_drop_lifetime", 15, 600, 15',
        'StaticText "Weapon drops stay until collected or you leave the map"')
    $menuDef = [regex]::Replace($menuDef,
        '(?m)^\s*(Command "Testing: deploy Engineer turret"|Command "Testing: drop Riot Shotgun"|Command "Testing: drop Minigun"|Slider "Shotgun becomes Riot Shotgun).*\r?\n', '')
    foreach ($menuName in @('TuinRPGClassChoice', 'TuinRPGPerkHub', 'TuinRPGPerks',
        'TuinRPGClassTraining', 'TuinRPGClassCapstone')) {
        $pattern = '(?ms)^OptionMenu "' + [regex]::Escape($menuName) + '"\s*\r?\n\{.*?^\}\s*\r?\n?'
        $menuDef = [regex]::Replace($menuDef, $pattern, '')
    }
    # Render every tuning page with the same gated, TinyBaby card UI.
    $generatedSettings = ''
    $choiceNames = @{
        OnOff='OFF|ON'; TuinDifficultyModes='EASY|NORMAL|HARD|CRAZY'
        TuinLevelModes='PROGRESSIVE|RANDOM'; TuinHealthBarModes='LAST HIT|OVERHEAD|BOTH|OFF'
        TuinBossChestStyles='PIXEL|ANIMATED MODEL'
    }
    foreach ($settingsName in @('TuinRPGAdvancedOptions','TuinRPGAmmoOptions','TuinRPGFinaleBossOptions',
        'TuinRPGMinimapOptions','TuinRPGSignatureOptions','TuinRPGWeaponLootOptions','TuinRPGAffixOptions','TuinRPGDisplayOptions')) {
        $pattern = '(?ms)OptionMenu "' + $settingsName + '"\s*\{(.*?)^\}'
        $block = [regex]::Match($menuDef,$pattern)
        if (!$block.Success) { continue }
        $rows = ''
        foreach ($line in ($block.Groups[1].Value -split "`n")) {
            if ($line -match '^\s*Option "([^"]+)", "([^"]+)", "([^"]+)"') {
                $label=$Matches[1];$key=$Matches[2];$choices=$choiceNames[$Matches[3]]
                if (!$choices) {$choices='OFF|ON'}
                $max=($choices -split '\|').Count-1
                $rows += "Add(0,`"$label`",`"$key`",0,$max,1,`"$choices`");`n"
            } elseif ($line -match '^\s*Slider "([^"]+)", "([^"]+)", ([\d.]+), ([\d.]+), ([\d.]+)') {
                $rows += "Add(1,`"$($Matches[1])`",`"$($Matches[2])`",$($Matches[3]),$($Matches[4]),$($Matches[5]));`n"
            } elseif ($line -match '^\s*Submenu "([^"]+)", "([^"]+)"') {
                $rows += "Add(2,`"$($Matches[1])`",`"$($Matches[2])`");`n"
            } elseif ($line -match '^\s*Command "([^"]+)", "(netevent [^"]+)"') {
                $rows += "Add(3,`"$($Matches[1])`",`"$($Matches[2])`");`n"
            }
        }
        $rows += 'Add(5,"LOCK ADMIN SETTINGS");'
        $generatedSettings += "class $($settingsName)Modern : TuinModernSettings { override void Populate() { Heading=`"ADVANCED SETTINGS`"; $rows } }`n"
        $menuDef=[regex]::Replace($menuDef,$pattern,"OptionMenu `"$settingsName`" {`n Class `"$($settingsName)Modern`"`n}")
    }
    [System.IO.File]::WriteAllText((Join-Path $resolvedStage 'scripts/TuinGeneratedSettings.zs'),$generatedSettings)
    [System.IO.File]::AppendAllText((Join-Path $resolvedStage 'ZSCRIPT'),"`n#include `"scripts/TuinGeneratedSettings.zs`"`n")
    [System.IO.File]::WriteAllText($menuDefPath, $menuDef)

    $markerPath = Join-Path $resolvedStage 'scripts\TuinNoClassesBuildMarker.zs'
    [System.IO.File]::WriteAllText($markerPath,
        "// Injected only into TuinRPG_NoClasses.pk3.`r`nclass TuinNoClassesBuildMarker : Actor {}`r`n")
    $zscriptPath = Join-Path $resolvedStage 'ZSCRIPT'
    [System.IO.File]::AppendAllText($zscriptPath,
        "`r`n#include `"scripts/TuinNoClassesBuildMarker.zs`"`r`n")

    $notes = Join-Path $PSScriptRoot 'NO_CLASSES_README.txt'
    if (Test-Path -LiteralPath $notes -PathType Leaf) {
        Copy-Item -LiteralPath $notes -Destination (Join-Path $resolvedStage 'NO_CLASSES_README.txt') -Force
    }

    # Prune orphaned assets from the staged compatibility build, not shared source.
    # Keep every script/class (including dormant save-game types) and every sprite
    # family mentioned anywhere in retained definitions. The prefix search is
    # deliberately conservative and also catches full frame names/string lookups.
    $referenceFiles = @(Get-ChildItem -LiteralPath (Join-Path $resolvedStage 'scripts') -File -Recurse)
    $referenceFiles += @(Get-ChildItem -LiteralPath $resolvedStage -File | Where-Object {
        $_.Name -in @('TEXTURES','MODELDEF','VOXELDEF','DECORATE','ZSCRIPT','MAPINFO','MENUDEF') -or
        $_.Name -like 'SNDINFO*'
    })
    $assetReferences = ($referenceFiles | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
    $removedAssets = [Collections.Generic.List[string]]::new()
    foreach ($assetRoot in @('SPRITES','brightmaps','SOUNDS')) {
        $assetDirectory = Join-Path $resolvedStage $assetRoot
        foreach ($asset in Get-ChildItem -LiteralPath $assetDirectory -File -Recurse) {
            $token = $asset.BaseName
            if ($assetRoot -ne 'SOUNDS') {
                if ($token.Length -lt 6) { continue }
                $token = $token.Substring(0,4)
            }
            if ($assetReferences.IndexOf($token,[StringComparison]::OrdinalIgnoreCase) -ge 0) { continue }
            $assetPath = [IO.Path]::GetFullPath($asset.FullName)
            if (!$assetPath.StartsWith($resolvedStage + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to prune outside staging: $assetPath"
            }
            $removedAssets.Add($assetPath.Substring($resolvedStage.Length+1))
            Remove-Item -LiteralPath $assetPath -Force
        }
    }
    Write-Output "Excluded $($removedAssets.Count) unreferenced sprite/brightmap/sound assets (sources retained)."
    [IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'noclasses-pruned-assets.txt'),$removedAssets)

    if ([System.IO.File]::Exists($resolvedOutput)) {
        [System.IO.File]::Delete($resolvedOutput)
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $resolvedStage, $resolvedOutput, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    Write-Output "Built $resolvedOutput"
}
finally {
    if ([System.IO.Directory]::Exists($resolvedStage) -and
        $resolvedStage.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
