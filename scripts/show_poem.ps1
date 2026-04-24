# show_poem.ps1 — Windows equivalent of show_poem.sh
# Picks a random public-domain poem and opens it in the default text editor.
# The poem is overlaid onto a random background from ../backgrounds/*.txt,
# which must contain a [POEM] marker on one line.
#
# Requires: Windows, PowerShell 5.1+.
# Fails silently on non-Windows platforms.

$ErrorActionPreference = 'Stop'

# Only run on Windows
if ($env:OS -ne 'Windows_NT') { exit 0 }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PoemsFile = Join-Path $ScriptDir '..\poems\poems.json'
$BackgroundsDir = Join-Path $ScriptDir '..\backgrounds'

if (-not (Test-Path $PoemsFile)) { exit 0 }
if (-not (Test-Path $BackgroundsDir)) { exit 0 }

# Drain stdin if piped (mirrors the bash script's behavior)
if (-not [Console]::IsInputRedirected) {
    # nothing to drain
} else {
    try { [void]([Console]::In.ReadToEnd()) } catch {}
}

$Poems = Get-Content -Raw $PoemsFile | ConvertFrom-Json
if ($Poems.Count -eq 0) { exit 0 }

$Index = Get-Random -Minimum 0 -Maximum $Poems.Count
$Title = $Poems[$Index].title
$Author = $Poems[$Index].author
$Text = $Poems[$Index].text

$Backgrounds = Get-ChildItem -Path $BackgroundsDir -Filter '*.txt'
if ($Backgrounds.Count -eq 0) { exit 0 }
$BgFile = $Backgrounds | Get-Random

$BgContent = Get-Content -Raw $BgFile.FullName
$Header = "$Title — $Author"
$PoemLines = $Text -split "`n"

$Marker = '[POEM]'
$ResultLines = @()

foreach ($BgLine in ($BgContent -split "`n")) {
    if ($BgLine -notlike "*$Marker*") {
        $ResultLines += $BgLine
        continue
    }

    $Idx = $BgLine.IndexOf($Marker)
    $Prefix = $BgLine.Substring(0, $Idx)
    $Suffix = $BgLine.Substring($Idx + $Marker.Length)

    # Build indent: replace visible characters with spaces, keep whitespace
    $Indent = -join ($Prefix.ToCharArray() | ForEach-Object {
        if ([char]::IsWhiteSpace($_) -or [char]::GetUnicodeCategory($_) -eq 'Format') {
            $_
        } else {
            ' '
        }
    })

    $ResultLines += "$Prefix$Header$Suffix"
    $ResultLines += ''
    foreach ($Line in $PoemLines) {
        if ($Line.Trim() -eq '') {
            $ResultLines += ''
        } else {
            $ResultLines += "$Indent$Line"
        }
    }
}

$TempFile = Join-Path $env:TEMP "poetry-in-code-$PID.txt"
$ResultLines -join "`r`n" | Out-File -FilePath $TempFile -Encoding utf8

# Open in default text editor
try {
    Start-Process $TempFile
} catch {
    # fail silently
}

exit 0
