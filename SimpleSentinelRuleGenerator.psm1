function SimpleSentinelRuleGenerator ($rulename, [switch]$help) {$mitrePath = Join-Path $PSScriptRoot "..\AllKQLtoHTML\cache\enterprise-attack.json"

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
# Select content.
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)"); $selection = $null; $lines = @(); $wrappedLines = @(); $position = 0; $pageSize = 30; $inputBuffer = ""

function scripthelp ($section) {$pattern = "(?ims)^## ($([regex]::Escape($section)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}

# Display Table of Contents.
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"

if ($sections.Count -gt 7) {$half = [Math]::Ceiling($sections.Count / 2)
for ($i = 0; $i -lt $half; $i++) {$leftIndex = $i; $rightIndex = $i + $half; $leftNumber  = "{0,2}." -f ($leftIndex + 1); $leftLabel   = " $($sections[$leftIndex].Groups[1].Value)"; $leftOutput  = [string]::Empty

if ($rightIndex -lt $sections.Count) {$rightNumber = "{0,2}." -f ($rightIndex + 1); $rightLabel  = " $($sections[$rightIndex].Groups[1].Value)"; Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel -n; $pad = 40 - ($leftNumber.Length + $leftLabel.Length)
if ($pad -gt 0) {Write-Host (" " * $pad) -n}; Write-Host -f cyan $rightNumber -n; Write-Host -f white $rightLabel}
else {Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel}}}

else {for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host -f cyan ("{0,2}. " -f ($i + 1)) -n; Write-Host -f white "$($sections[$i].Groups[1].Value)"}}

# Display Header.
line yellow 100
if ($lines.Count -gt 0) {Write-Host  -f yellow $lines[0]}
else {Write-Host "Choose a section to view." -f darkgray}
line yellow 100

# Display content.
$end = [Math]::Min($position + $pageSize, $wrappedLines.Count)
for ($i = $position; $i -lt $end; $i++) {Write-Host -f white $wrappedLines[$i]}

# Pad display section with blank lines.
for ($j = 0; $j -lt ($pageSize - ($end - $position)); $j++) {Write-Host ""}

# Display menu options.
line yellow 100; Write-Host -f white "[↑/↓]  [PgUp/PgDn]  [Home/End]  |  [#] Select section  |  [Q] Quit  " -n; if ($inputBuffer.length -gt 0) {Write-Host -f cyan "section: $inputBuffer" -n}; $key = [System.Console]::ReadKey($true)

# Define interaction.
switch ($key.Key) {'UpArrow' {if ($position -gt 0) { $position-- }; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) { $position++ }; $inputBuffer = ""}
'PageUp' {$position -= 30; if ($position -lt 0) {$position = 0}; $inputBuffer = ""}
'PageDown' {$position += 30; $maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); if ($position -gt $maxStart) {$position = $maxStart}; $inputBuffer = ""}
'Home' {$position = 0; $inputBuffer = ""}
'End' {$maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); $position = $maxStart; $inputBuffer = ""}

'Enter' {if ($inputBuffer -eq "") {"`n"; return}
elseif ($inputBuffer -match '^\d+$') {$index = [int]$inputBuffer
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index; $pattern = "(?ims)^## ($([regex]::Escape($sections[$selection-1].Groups[1].Value)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $block = $match.Groups[1].Value.TrimEnd(); $lines = $block -split "`r?`n", 2
if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}}
$inputBuffer = ""}

default {$char = $key.KeyChar
if ($char -match '^[Qq]$') {"`n"; return}
elseif ($char -match '^\d$') {$inputBuffer += $char}
else {$inputBuffer = ""}}}}}

# External call to help.
if ($help) {help; return}

if (-not $rulename) {Write-Host -f cyan "`nUsage: CreateSentinelRule 'Sentinel Rule Name' <-help>`n"; return;}

# ---------------- DEFINE VARIABLES ---------------------------------------------------------------
$state = @{FileName=""; Name=""; Description=""; KQL=""; Type=""; Severity=""; Tactics=@(); Techniques=@(); SubTechniques=@(); CustomDetails=@{}; Entities=@(); EntityDraft=""; UsedEntityPairs = @()}

# ---------------- CREATE SCREEN ------------------------------------------------------------------
function Render-UI ([hashtable]$State, [string[]]$Menu = @(), [string]$Prompt = "") {cls; $State.FileName = ($ruleName -replace '[^\w\s-]', '' -replace '\s+', '_') + ".json"; $State.Name = $ruleName

# ---------------- HEADER ----------------
Write-Host "Simple Sentinel Rule Generator:" -f Yellow; Write-Host -f Yellow ("-" * 100)

# ---------------- FIELDS ----------------
$customDetailLine = ""
if ($State.CustomDetails.Count -gt 0) {$customDetailLine = ($State.CustomDetails.GetEnumerator() | ForEach-Object {"$($_.Key):$($_.Value)"}) -join "; "}

$fields = @(@{Name="FileName"; Value=$State.FileName}
@{Name="Name"; Value=$State.Name}
@{Name="Description"; Value=($State.Description -replace "`r`n"," ") -replace '^(.{50}).*','$1...'}
@{Name="KQL"; Value=($State.KQL -replace "`r`n"," ") -replace '^(.{50}).*','$1...'}
@{Name="Type"; Value=$State.Type}
@{Name="Enabled"; Value=$State.Enabled}
@{Name="Severity"; Value=$State.Severity}
@{Name="Tactics"; Value=($State.Tactics -join ", ")}
@{Name="Techniques"; Value=($State.Techniques -join ", ")}
@{Name="Sub-Techniques"; Value=($State.SubTechniques -join ", ")}
@{Name="Custom Details"; Value=$customDetailLine})

# ---------------- ENTITY LINE ----------------
$entityLine = @()
$entityLine = if ($State.EntityDraft) {$State.EntityDraft}
else {""}
$fields += @{Name="Entities"; Value=$entityLine}
foreach ($f in $fields) {$label = "{0}:" -f $f.Name; $pad = 16 - $label.Length; if ($pad -lt 1) {$pad = 1}; Write-Host $label -f Cyan -n; Write-Host (" " * $pad) -n; Write-Host $f.Value -f White}
Write-Host -f Yellow ("-" * 100)

# ---------------- MENU AREA (MAX 6) ----------------
if ($Menu.Count -gt 0) {$slice = $Menu | Select-Object -First 6
$i = 1
foreach ($m in $slice) {Write-Host "$i " -f Green -n; Write-Host $m -f White
$i++}
Write-Host ""; Write-Host $Prompt -f Yellow -n}}

# ---------------- CONVERT ENTITY MAPPING FOR FILE OUTPUT -----------------------------------------
function Convert-ToEntityMappings($entities) {$result = @()
foreach ($group in ($entities | Group-Object Type)) {$mappings = @()
foreach ($e in $group.Group) {$mappings += @{identifier = $e.Identifier; columnName = $e.Name}}
$result += @{entityType = $group.Name; fieldMappings = $mappings}}
return $result}

# ---------------- READ VARIABLES -----------------------------------------------------------------
function Write-OptionLine ([int]$Index, [string]$Text) {Write-Host $Index -f Green -n; Write-Host " $Text" -f White}

function Write-Question ([string]$Text) {Write-Host $Text -f Yellow -n}

# ---------------- INPUT HELPERS ------------------------------------------------------------------
function Read-MultiLine($prompt) {Write-Host -f yellow "$prompt"
$lines = @()
while ($true) {$l = Read-Host
if ($l -eq "END") {break}
$lines += $l}
return ($lines -join "`r`n")}

# ---------------- GUID & NAME --------------------------------------------------------------------
$guid = [guid]::NewGuid().Guid; $ruleId = ($ruleName -replace '[^\w\s-]', '' -replace '\s+', '_') + ".json"

# ---------------- DESCRIPTION / QUERY ------------------------------------------------------------
function decriptionandquery {cls; Render-UI -State $state; $description = Read-MultiLine "Enter Description (END to finish):"; $state.Description = $description
cls; Render-UI -State $state; $query = Read-MultiLine "Enter KQL Query (END to finish):"; $state.KQL = $query
$description = $description ; $query = $query -replace '\\','\\\\'  -replace '"','\"' -replace "`r`n","\r\n"}
decriptionandquery

# ---------------- RULE TYPE ----------------------------------------------------------------------
function ruletype {cls; Render-UI -State $state; Write-OptionLine 1 "Scheduled"
Write-OptionLine 2 "NRT"
Write-Question "Select rule type: "; $ruleType = Read-Host
$state.Type = if ($ruleType -eq "2") {"NRT"}
else {"Scheduled"}}
ruletype

# ---------------- ENABLED STATUS------------------------------------------------------------------
function enabledstatus {cls; Render-UI -State $state; Write-OptionLine 1 "Enabled"
Write-OptionLine 2 "Disabled"
Write-Question "Select Enabled State: "
$enabledPick = Read-Host
$state.Enabled = if ($enabledPick -eq "1") {"true"}
else {"false"}}
enabledstatus

# ---------------- SEVERITY -----------------------------------------------------------------------
function severity {cls; Render-UI -State $state; Write-OptionLine 1 "Informational"
Write-OptionLine 2 "Low"
Write-OptionLine 3 "Medium"
Write-OptionLine 4 "High"
Write-Question "Severity: "
$sevPick = Read-Host
$state.Severity = if ($sevPick -eq 1) {"Informational"}
elseif ($sevPick -eq 2) {"Low"}
elseif ($sevPick -eq 3) {"Medium"}
else {"High"}}
severity

# ---------------- PARSE MITRE --------------------------------------------------------------------
$techToTactic = @{}; $subToTech = @{}; $techLookup = @{}

$mitreData = Get-Content $mitrePath -Raw | ConvertFrom-Json
$mitreObjects = $mitreData.objects

function Normalize-TechId($id) {return ($id.Trim() -replace "(?i)^t","T")}

function Normalize-TacticName($t) {return (($t -split '[-\s]+' | ForEach-Object {$_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()}) -join '')}

function Normalize-Tactic($t) {$t = $t.Trim()
if ($t -match "^TA\d{4}$") {return ($t -replace "(?i)ta","TA")}
return (($t -split '\s+' | ForEach-Object {$_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()}) -join '')}

foreach ($obj in $mitreObjects) {$ref = $obj.external_references | Where-Object {$_.source_name -eq "mitre-attack"} | Select-Object -First 1
if (-not $ref.external_id) {continue}
$id = Normalize-TechId $ref.external_id
if ($obj.type -eq "attack-pattern") {$techLookup[$id] = $obj.name}

# ---------------- TECH → TACTICS -----------------------------------------------------------------
if ($obj.type -eq "attack-pattern" -and -not $obj.x_mitre_is_subtechnique) {$tactics = @()
foreach ($phase in $obj.kill_chain_phases) {if ($phase.kill_chain_name -ne "mitre-attack") {continue}
if ($phase.phase_name) {$tactics += $phase.phase_name}}
$techToTactic[$id] = $tactics | ForEach-Object { Normalize-TacticName $_ } | Select-Object -Unique}

# ---------------- SUBTECH → TECH -----------------------------------------------------------------
if ($obj.x_mitre_is_subtechnique -eq $true) {$subToTech[$id] = ($id -split '\.')[0]}}

# ---------------- MITRE INPUT --------------------------------------------------------------------
function mitre {$State.Tactics = @(); $State.Techniques = @(); $State.SubTechniques = @()
cls; Render-UI -State $state; Write-Host -f white "(TA####, Tactic names, T####[.###])"; Write-Host -f Yellow "Enter MITRE ATT&CK input:"; $mitreInput = Read-Host
$mitreList = $mitreInput -split "," | ForEach-Object {$_.Trim()} | Where-Object {$_}
foreach ($m in $mitreList) {$m = $m.Trim()
if ($m -match "^TA\d{4}$" -or $m -match "^[A-Za-z ]+$") {$State.Tactics += Normalize-Tactic $m; continue}
if ($m -match "^T\d{4}\.\d{3}$") {$State.SubTechniques += Normalize-TechId $m; continue}
if ($m -match "^T\d{4}$") {$State.Techniques += Normalize-TechId $m}}

$State.Tactics = $State.Tactics | Select-Object -Unique
$State.Techniques = $State.Techniques | Select-Object -Unique
$State.SubTechniques = $State.SubTechniques | Select-Object -Unique}
mitre

# ---------------- DERIVE TECH + TACTICS ----------------------------------------------------------
$derivedTech = @(); $derivedTac = @()
foreach ($st in $State.SubTechniques) {$st = Normalize-TechId $st; $tech = Normalize-TechId ($st -replace '\.\d{3}$',''); $derivedTech += $tech
if ($techToTactic[$tech]) {$derivedTac += $techToTactic[$tech]}}
foreach ($t in $State.Techniques) {$t = Normalize-TechId $t
if ($techToTactic[$t]) {$derivedTac += $techToTactic[$t]}}

$State.Techniques = @($State.Techniques + $derivedTech) | Select-Object -Unique
$State.Tactics    = @($State.Tactics + $derivedTac) | Select-Object -Unique
cls; Render-UI -State $state

# ---------------- CUSTOM DETAILS -----------------------------------------------------------------
function customdetails {$State.CustomDetails = @{}; cls; Render-UI -State $state
Write-Question "How many custom details fields are required? "; $count = [int](Read-Host)
for ($i = 1; $i -le $count; $i++) {cls; Render-UI -State $state; Write-Question "Custom detail name: "; $name = Read-Host
Write-Question "Column name: "; $column = Read-Host
if ($name -and $column) {$State.CustomDetails[$name] = $column; cls; Render-UI -State $state;}}}
customdetails

# ---------------- ENTITY MAPPINGS ----------------------------------------------------------------
function entitymappings {$State.Entities = @(); $State.EntityDraft = "";
$entityTypes = @("Account","Host","IP","URL","File","Process")
$identifierMap = @{Account = @("Name","UPNSuffix","NTDomain","AadUserId","Sid")
Host = @("HostName","DnsDomain","NTDomain","AzureID")
IP = @("Address")
URL = @("Url")
File = @("Name","Directory","MD5","SHA1","SHA256")
Process = @("ProcessId","CommandLine","ImageFile")}

function Get-AvailableIdentifiers($State, $etype, $idList) {$used = $State.UsedEntityPairs; return $idList | Where-Object {"$etype|$_" -notin $used}}

cls; Render-UI -State $state
function Add-EntitiesLive ([hashtable]$State, [hashtable]$IdentifierMap, [string[]]$EntityTypes) {$State.Entities = @(); $draft = ""; Write-Question "How many entity mappings? "; $entityCount = Read-Host

# ---------------- ENTITY TYPE --------------------------------------------------------------------
$entityIndex = 1
while ($entityIndex -le [int]$entityCount) {Write-Host -f white "Select Entity Type:"
for ($e = 0; $e -lt $EntityTypes.Count; $e++) {Write-Host "$($e+1) $($EntityTypes[$e])"}
Write-Question "Choice: "; $etypeIndex = [int](Read-Host)
$etype = $EntityTypes[$etypeIndex - 1]; $idList = @(Get-AvailableIdentifiers $State $etype $IdentifierMap[$etype])

if ($idList.Count -eq 0) {Write-Host -f Yellow "No more identifiers available for $etype"; continue}

# Auto-handle single-identifier entities
if ($etype -in @("IP","URL")) {$identifier = $idList[0]; $pair = "$etype|$identifier";  $State.UsedEntityPairs += $pair; Write-Question "Column Name: "; $column = Read-Host
$entity = @{Type = $etype
Identifier = $identifier
Name = $column}

$State.Entities += $entity
if ($draft.Length -eq 0) {$draft = "$etype`:$identifier`:$column"}
else {$draft += "; $etype`:$identifier`:$column"}

$State.EntityDraft = $draft; Render-UI -State $State; $entityIndex++; continue}

Write-Question "How many field mappings for $($etype)`: "
$fieldCount = [int](Read-Host)

for ($j = 1; $j -le $fieldCount; $j++) {cls; Render-UI -State $state; if ($j -gt 1 -and -not $identifier) {Write-Host -f red "Invalid selection."}; Write-Host -f white "Select $($etype) Identifier:"
$selectionMap = @{}; $optIndex = 1
for ($k = 0; $k -lt $idList.Count; $k++) {Write-Host "$optIndex $($idList[$k])"; $selectionMap[$optIndex] = $idList[$k]; $optIndex++}
Write-Question "Choice: "; $idChoice = [int](Read-Host)

$identifier = $selectionMap[$idChoice]
if (-not $identifier) {$j--; continue}
$pair = "$etype|$identifier"
if ($State.UsedEntityPairs -contains $pair) {if ($State.UsedEntityPairs -contains $pair) {Write-Host -f red "That was already used."}; Read-Host; $j--; continue}

$State.UsedEntityPairs += $pair; Write-Question "Column Name: "; $column = Read-Host

# ---------------- BUILD ENTITY OBJECT ------------------------------------------------------------
$entity = @{Type = $etype; Identifier = $identifier; Name = $column}
$State.Entities += $entity

# ---------------- BUILD LIVE STRING --------------------------------------------------------------
if ($draft.Length -eq 0) {$draft = "$etype`:$identifier`:$column"}
else {$draft += "; $etype`:$identifier`:$column"}

# ---------------- UPDATE UI STATE ----------------------------------------------------------------
$State.EntityDraft = $draft; Render-UI -State $State}
$entityIndex++}
return $State.Entities}

$entityMappings = Add-EntitiesLive $state $identifierMap $entityTypes}
entitymappings

# ---------------- TEMPLATE -----------------------------------------------------------------------
function template {@"
{"`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
"contentVersion": "1.0.0.0",

"resources": [{"type": "Microsoft.SecurityInsights/alertRules",
"apiVersion": "2023-11-01-preview",

"name": "$guid",
"location": "global",
"kind": "$($state.Type)",

"properties": {"displayName": "$($state.Name)",
"description": "$($state.Description)",

"enabled": $($state.Enabled),
"severity": "$($state.Severity)",

"query": "$($state.KQL)",

"queryFrequency": "PT1H",
"queryPeriod": "PT1H",
"triggerOperator": "GreaterThan",
"triggerThreshold": 0,
"suppressionDuration": "PT5H",
"suppressionEnabled": false,

"tactics": $(($state.Tactics | ConvertTo-Json -Compress)),
"techniques": $(($state.Techniques | ConvertTo-Json -Compress)),
"subTechniques": $(($state.SubTechniques | ConvertTo-Json -Compress)),

"incidentConfiguration": {"createIncident": true,
"groupingConfiguration": {"enabled": false,
"reopenClosedIncident": false,
"lookbackDuration": "PT5H",
"matchingMethod": "AllEntities",
"groupByEntities": [],
"groupByAlertDetails": [],
"groupByCustomDetails": []}},

"eventGroupingSettings": {"aggregationKind": "SingleAlert"},
"alertDetailsOverride": {"alertDynamicProperties": []},

"customDetails": $(if ($State.CustomDetails.Count -gt 0) {$State.CustomDetails | ConvertTo-Json -Compress}
else {"{}"}),
"entityMappings": $(if ($state.Entities.Count -gt 0) {Convert-ToEntityMappings $state.Entities | ConvertTo-Json -Depth 10 -Compress}
else {"[]"}),

"id": "/Microsoft.SecurityInsights/alertRules/$guid",
"kind": "$($state.Type)",
"RuleId": "$($state.FileName -replace '\.json$','')"}}]}
"@}
$template = template

# ---------------- WRITE FILE ---------------------------------------------------------------------
$outPath = Join-Path (Get-Location) $ruleId; $template | Out-File $outPath -Encoding utf8; Write-Host -f cyan "Rule created: " -n; Write-Host -f white "$outPath`n"}
sal -name createrule -value simplesentinelrulegenerator
sal -name ssrg -value simplesentinelrulegenerator

Export-ModuleMember -Function SimpleSentinelRuleGenerator
Export-ModuleMember -Alias createrule, ssrg

<#
## SimpleSentinelRuleGenerator
This module allows users to create offline Microsoft Sentinel rules, using a standard JSON template for quick import into a Sentinel environment.

It is meant to be a companion module for AllKQLtoHTML and as such, uses the MITRE cache file from that module, rather than downloading a second copy, which is over 35MB.

		Usage: SimpleSentinelRuleGenerator 'Sentinel Rule Name' <-help>

The function is entirely menu driven and allows the user to create a basic rule with the following settings:

• Name:		Created at run time by the parameter passed to the function.
• Filename:	Also created at run time.
• Description:	Free-form entry.
• KQL:		Free-form entry.
• Type:		Scheduled/NRT
• Enabled:	true/false
• Severity:	Accepts Informational through High.

MITRE ATT&CK:
• Tactics:	  Accepts English names and TA#### formats, using the MITRE cache for auto-population.
• Techniques:	  Accepts T#### values, but will also auto-generate these from sub-techniques.
• Sub-Techniques: Accepts T####.### 

Field Mappings:
• Custom Details: Allows users to define the number and values of these fields.
• Entities:	  Accepts mapping fields to the 6 standard entities and all of their child identifiers.

Yes, there are plenty of other settings, such as groupings and suppression, but those are not included. This tool isn't designed to be a replacement for Sentinel. That would make no sense. Instead, this is a tool for quick and easy creation and tranfer of basic rule logic and settings between environments.

I created it because I often have ideas for new KQL queries, but do not want to use my employer's environment and in doing so, become beholden to their corporate intellectual property rights. This tool therefore, allows me to create these queries outside of that environment and maintain private control over the content.
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>