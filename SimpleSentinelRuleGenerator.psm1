function SimpleSentinelRuleGenerator ($rulename, [switch]$help) {# Create ARM JSON files for Sentinel rules offline.
$mitrePath = Join-Path $PSScriptRoot "..\AllKQLtoHTML\cache\enterprise-attack.json"

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
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object {$_.FullName -ieq $PSCommandPath} | Select-Object -ExpandProperty BaseName) Help Sections:`n"

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
switch ($key.Key) {'UpArrow' {if ($position -gt 0) {$position--}; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) {$position++}; $inputBuffer = ""}
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

# ---------------- LOAD & PARSE MITRE -------------------------------------------------------------
Write-Host -f Cyan "`nLoading MITRE ATT&CK Database...`n"
$mitreData = Get-Content $mitrePath -Raw | ConvertFrom-Json
$mitreObjects = $mitreData.objects; $techToTactic = @{}; $subToTech = @{}; $techLookup = @{}

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
$techToTactic[$id] = $tactics | ForEach-Object {Normalize-TacticName $_} | Select-Object -Unique}

# ---------------- SUBTECH → TECH -----------------------------------------------------------------
if ($obj.x_mitre_is_subtechnique -eq $true) {$subToTech[$id] = ($id -split '\.')[0]}}

# ---------------- DEFINE VARIABLES ---------------------------------------------------------------
$state = @{FileName="";
Name="";
Description="";
KQL="";
Type="";
Severity="";
Tactics=@();
Techniques=@();
SubTechniques=@();
CustomDetails=@{};
Entities=@();
EntityDraft="";
UsedEntityPairs = @();
QueryFrequency="PT1H";
QueryPeriod="PT1H";
LookbackDuration = "PT1H";
SuppressionEnabled = $false;
SuppressionDuration="PT1H";
StartTimeUtc = $null;
TriggerOperator = "GreaterThan"
TriggerThreshold = 0;
CreateIncident = $true;
GroupingEnabled = $false;
ReopenClosedIncident = $false;
MatchingMethod = "AllEntities";
GroupByEntities = @();
GroupByAlertDetails = @();
GroupByCustomDetails = @();
AggregationKind = "SingleAlert";}

$state.AlertDetailsOverride = @{};

# ---------------- CREATE SCREEN ------------------------------------------------------------------
function Render-UI ([hashtable]$state, [string[]]$Menu = @(), [string]$Prompt = "") {cls; $state.FileName = ($ruleName -replace '[^\w\s-]', '' -replace '\s+', '_') + ".json"; $state.Name = $ruleName

# ---------------- HEADER ----------------
Write-Host -f Yellow ("-" * 100); Write-Host "Simple Sentinel Rule Generator:" -f Yellow; Write-Host -f Yellow ("-" * 100)

# ---------------- FIELDS ----------------
$customDetailLine = ""
if ($state.CustomDetails.Count -gt 0) {$customDetailLine = ($state.CustomDetails.GetEnumerator() | ForEach-Object {"$($_.Key):$($_.Value)"}) -join "; "}

$alertOverrideLine = ""
if ($state.AlertDetailsOverride.Count -gt 0) {$alertOverrideLine = ($state.AlertDetailsOverride.GetEnumerator() | ForEach-Object {"$($_.Key):$($_.Value)"}) -join "; "}

$fields = @(@{Type="Value"; Name="FileName"; Value=$state.FileName}
@{Type="Header"; Name="---------------------------------------------------------------------------"}
@{Type="Value"; Name="Name"; Value=$state.Name}
@{Type="Value"; Name="Description"; Value=($state.Description -replace "`r`n"," ") -replace '^(.{50}).*','$1...'}
@{Type="Value"; Name="KQL"; Value=($state.KQL -replace "`r`n"," ") -replace '^(.{50}).*','$1...'}
@{Type="Header"; Name="---------------------------------------------------------------------------"}
@{Type="Value"; Name="Type"; Value=$state.Type}
@{Type="Value"; Name="Enabled"; Value=$state.Enabled}
@{Type="Value"; Name="Severity"; Value=$state.Severity}
@{Type="Header"; Name="------------------------------ MITRE ATT&CK -------------------------------"}
@{Type="Value"; Name="Tactics"; Value=($state.Tactics -join ", ")}
@{Type="Value"; Name="Techniques"; Value=($state.Techniques -join ", ")}
@{Type="Value"; Name="Sub-Techniques"; Value=($state.SubTechniques -join ", ")}
@{Type="Header"; Name="------------------------------ TIME SETTINGS ------------------------------"}
@{Type="Value"; Name="Query Frequency"; Value=$state.QueryFrequency}
@{Type="Value"; Name="Query Period"; Value=$state.QueryPeriod}
@{Type="Value"; Name="Lookback Duration"; Value=$state.LookbackDuration}
@{Type="Value"; Name="Suppression Enabled"; Value=$state.SuppressionEnabled}
@{Type="Value"; Name="Suppression Duration"; Value=$state.SuppressionDuration}
@{Type="Value"; Name="Start Time UTC"; Value=$state.StartTimeUtc}
@{Type="Header"; Name="------------------------------ INCIDENT SETTINGS --------------------------"}
@{Type="Value"; Name="Trigger Operator"; Value=$state.TriggerOperator}
@{Type="Value"; Name="Trigger Threshold"; Value=$state.TriggerThreshold}
@{Type="Value"; Name="Create Incident"; Value=$state.CreateIncident}
@{Type="Value"; Name="Grouping Enabled"; Value=$state.GroupingEnabled}
@{Type="Value"; Name="Reopen Closed Incident"; Value=$state.ReopenClosedIncident}
@{Type="Header"; Name="------------------------------ FIELD SETTINGS -----------------------------"}
@{Type="Value"; Name="Matching Method"; Value=$state.MatchingMethod}
@{Type="Value"; Name="Group by Entities"; Value=($state.GroupByEntities -join ", ")}
@{Type="Value"; Name="Group by Alert Details"; Value=($state.GroupByAlertDetails -join ", ")}
@{Type="Value"; Name="Group by Custom Details"; Value=($state.GroupByCustomDetails -join ", ")}
@{Type="Value"; Name="Aggregation Kind"; Value=$state.AggregationKind}
@{Type="Header"; Name="------------------------------ CORRELATION SETTINGS ------------------------"}
@{Type="Value"; Name="Alert Details Override"; Value=$alertOverrideLine}
@{Type="Value"; Name="Custom Details"; Value=$customDetailLine})

# ---------------- ENTITY LINE ----------------
$entityLine = @()
$entityLine = if ($state.EntityDraft) {$state.EntityDraft}
else {""}
$fields += @{Name="Sentinel Entities"; Value=$entityLine}
$labelWidth = 25
foreach ($f in $fields) {if ($f.Type -eq "Header") {Write-Host -f Yellow $f.Name; continue}
$label = ("{0}:" -f $f.Name).PadRight($labelWidth)
Write-Host -f Cyan -NoNewline $label; Write-Host -f White $f.Value}
Write-Host -f Yellow ("-" * 100)

# ---------------- MENU AREA (MAX 6) ----------------
if ($Menu.Count -gt 0) {$slice = $Menu | Select-Object -First 6
$i = 1
foreach ($m in $slice) {Write-Host "$i " -f Green -n; Write-Host $m -f White
$i++}
Write-Host ""; Write-Host $Prompt -f Yellow -n}}

# ---------------- CONVERT ENTITY MAPPING FOR FILE OUTPUT -----------------------------------------
function Convert-ToEntityMappings ($entities) {$entities | Group-Object Type | ForEach-Object {$type = $_.Name
[ordered]@{entityType = $script:EntityCatalog[$type].SentinelName
fieldMappings = @($_.Group | ForEach-Object {[ordered]@{identifier = $_.Identifier
columnName  = $_.Name}})}}}

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
function decriptionandquery {cls; Render-UI -State $state; $description = Read-MultiLine "Enter Description (END to finish):"; $state.Description = $description -replace "`r`n","\r\n"; cls; Render-UI -State $state; $query = Read-MultiLine "Enter KQL Query (END to finish):"; $state.KQL = $query -replace '\\','\\\\'  -replace '"','\"' -replace "`r`n","\r\n";}
decriptionandquery

# ---------------- RULE TYPE ----------------------------------------------------------------------
function ruletype {do{cls; Render-UI -State $state; Write-OptionLine 1 "Scheduled"
Write-OptionLine 2 "NRT"
Write-Question "Select rule Schedule type: "; $ruleType = Read-Host
$state.Type = if ($ruleType -eq "2") {"NRT"}
else {"Scheduled"}} until ($ruleType -match '^[1-2]$')}
ruletype

# ---------------- ENABLED STATUS------------------------------------------------------------------
function enabledstatus {do{cls; Render-UI -State $state; Write-Question "Enabled (Y/N)? "
$enabledPick = Read-Host} until ($enabledPick -match '^[yn]$')
$state.Enabled = if ($enabledPick -eq "y") {"true"}
else {"false"}}
enabledstatus

# ---------------- SEVERITY -----------------------------------------------------------------------
function severity {do{cls; Render-UI -State $state; Write-OptionLine 1 "Informational"
Write-OptionLine 2 "Low"
Write-OptionLine 3 "Medium"
Write-OptionLine 4 "High"
Write-Question "Select Severity: "
$sevPick = Read-Host} until ($sevPick -match '^[1-4]$')
$state.Severity = if ($sevPick -eq 1) {"Informational"}
elseif ($sevPick -eq 2) {"Low"}
elseif ($sevPick -eq 3) {"Medium"}
else {"High"}}
severity

# ---------------- MITRE INPUT --------------------------------------------------------------------
function mitre {$state.Tactics = @(); $state.Techniques = @(); $state.SubTechniques = @()
cls; Render-UI -State $state; Write-Host -f Yellow "Enter MITRE ATT&CK TTPs (" -n; Write-Host -f Green "TA####, Tactic names, T####[.###]" -n; Write-Host -f Yellow "):"; $mitreInput = Read-Host
$mitreList = $mitreInput -split "," | ForEach-Object {$_.Trim()} | Where-Object {$_}
foreach ($m in $mitreList) {$m = $m.Trim()
if ($m -match "^TA\d{4}$" -or $m -match "^[A-Za-z ]+$") {$state.Tactics += Normalize-Tactic $m; continue}
if ($m -match "^T\d{4}\.\d{3}$") {$state.SubTechniques += Normalize-TechId $m; continue}
if ($m -match "^T\d{4}$") {$state.Techniques += Normalize-TechId $m}}

$state.Tactics = $state.Tactics | Select-Object -Unique
$state.Techniques = $state.Techniques | Select-Object -Unique
$state.SubTechniques = $state.SubTechniques | Select-Object -Unique}
mitre

# ---------------- DERIVE TECH + TACTICS ----------------------------------------------------------
$derivedTech = @(); $derivedTac = @()
foreach ($st in $state.SubTechniques) {$st = Normalize-TechId $st; $tech = Normalize-TechId ($st -replace '\.\d{3}$',''); $derivedTech += $tech
if ($techToTactic[$tech]) {$derivedTac += $techToTactic[$tech]}}
foreach ($t in $state.Techniques) {$t = Normalize-TechId $t
if ($techToTactic[$t]) {$derivedTac += $techToTactic[$t]}}

$state.Techniques = @($state.Techniques + $derivedTech) | Select-Object -Unique
$state.Tactics    = @($state.Tactics + $derivedTac) | Select-Object -Unique
cls; Render-UI -State $state

# ---------------- CUSTOM DETAILS -----------------------------------------------------------------
function customdetails {$state.CustomDetails = @{}; do{cls; Render-UI -State $state
Write-Question "How many Custom Detail fields are required? "; $customDetailsCount = [int](Read-Host)} until ($customDetailsCount -match '^([0-9]|1\d|20)$')
for ($i = 1; $i -le $customDetailsCount; $i++) {cls; Render-UI -State $state; Write-Question "Custom Detail title: "; $name = Read-Host
Write-Question "Field Name: "; $column = Read-Host
if ($name -and $column) {$state.CustomDetails[$name] = $column; cls; Render-UI -State $state;}}}
customdetails

# ---------------- ENTITY MAPPINGS ----------------------------------------------------------------
function entitymappings {$script:EntityCatalog = @{Account = @{SentinelName = "Account"; MaxEntities = 8; Identifiers = @("Name","UPNSuffix","NTDomain","AadUserId","Sid","UserPrincipalName","DisplayName","Mail","ObjectId")}
Host = @{SentinelName = "Host"; MaxEntities = 8; Identifiers = @("HostName","DnsDomain","NTDomain","AzureID","OSFamily","OSVersion","NetBiosName","FQDN")}
IP = @{SentinelName = "IP"; MaxEntities = 1; Identifiers = @("Address")}
URL = @{SentinelName = "URL"; MaxEntities = 1; Identifiers = @("Url")}
File = @{SentinelName = "File"; MaxEntities = 3; Identifiers = @("Name","Directory","MD5","SHA1","SHA256")}
ProcessEntity = @{SentinelName = "Process"; MaxEntities = 6; Identifiers = @("ProcessId","CommandLine","ImageFile","AccountName","ParentProcessId","ProcessName","ImageFileHash")}
DNS = @{SentinelName = "DNS"; MaxEntities = 1; Identifiers = @("DomainName")}
Malware = @{SentinelName = "Malware"; MaxEntities = 2; Identifiers = @("Name","Category")}
RegistryKey = @{SentinelName = "RegistryKey"; MaxEntities = 1; Identifiers = @("Key")}
RegistryValue = @{SentinelName = "RegistryValue"; MaxEntities = 2; Identifiers = @("Name","Value")}
Mailbox = @{SentinelName = "Mailbox"; MaxEntities = 3; Identifiers = @("MailboxPrimaryAddress","DisplayName","UPN")}
MailMessage = @{SentinelName = "MailMessage"; MaxEntities = 5; Identifiers = @("MessageId","Subject","Sender","Recipient","DeliveryAction")}
SubmissionMail = @{SentinelName = "SubmissionMail"; MaxEntities = 4; Identifiers = @("SubmissionId","Sender","Recipient","Status")}
AzureResource = @{SentinelName = "AzureResource"; MaxEntities = 4; Identifiers = @("ResourceId","ResourceName","SubscriptionId","ResourceGroup")}
CloudApplication = @{SentinelName = "CloudApplication"; MaxEntities = 3; Identifiers = @("AppId","AppName","Publisher")}
FileHash = @{SentinelName = "FileHash"; MaxEntities = 3; Identifiers = @("MD5","SHA1","SHA256")}
SecurityGroup = @{SentinelName = "SecurityGroup"; MaxEntities = 4; Identifiers = @("GroupId","GroupName","Member","TenantId")}}

$state.EntityUsage = @{UsedPairs = @(); UsedPerType = @{}; Entities = @()}

function Get-EntityTypeRemaining ($type) {$max = $script:EntityCatalog[$type].MaxEntities; $used = if ($state.EntityUsage.UsedPerType[$type]) {$state.EntityUsage.UsedPerType[$type]} else {0}; return ($max - $used)}

function Get-AvailableIdentifiers ($type) {$ids = $script:EntityCatalog[$type].Identifiers; return $ids | Where-Object {"$type|$_" -notin $state.EntityUsage.UsedPairs}}

function Mark-IdentifierUsed ($type, $id) {$state.EntityUsage.UsedPairs += "$type|$id"
if (-not $state.EntityUsage.UsedPerType.ContainsKey($type)) {$state.EntityUsage.UsedPerType[$type] = 0}
$state.EntityUsage.UsedPerType[$type]++}

$entityTypes = @($script:EntityCatalog.Keys | Sort-Object)

cls; Render-UI -State $state
function Add-EntitiesLive ([hashtable]$state, [hashtable]$IdentifierMap, [string[]]$EntityTypes) {$state.Entities = @(); $draft = ""; Write-Question "How many Sentinel Entity mappings? "; $entityCount = Read-Host

# ---------------- ENTITY TYPE --------------------------------------------------------------------
$entityIndex = 1
while ($entityIndex -le [int]$entityCount) {Write-Host -f white "Select Entity Type:"
for ($e = 0; $e -lt $EntityTypes.Count; $e++) {Write-Host "$($e+1) $($EntityTypes[$e])"}
Write-Question "Entity Type: "; $etypeIndex = [int](Read-Host)
$etype = $EntityTypes[$etypeIndex - 1]; $idList = @(Get-AvailableIdentifiers $etype); $remaining = Get-EntityTypeRemaining $etype
if ($remaining -le 0) {Write-Host -f Yellow "Maximum mappings reached for $etype"; Read-Host; continue}

# Auto-handle single-identifier entities
if ($idList.Count -eq 1) {$identifier = $idList[0]; $pair = "$etype|$identifier";  $state.EntityUsage.UsedPairs += $pair; Write-Question "Field Name: "; $column = Read-Host
$entity = @{Type = $etype; SentinelType = $script:EntityCatalog[$etype].SentinelName; Identifier = $identifier; Name = $column}
$state.Entities += $entity
if ($draft.Length -eq 0) {$sentinelType = $script:EntityCatalog[$etype].SentinelName; $draft += "$sentinelType`:$identifier`:$column"}
else {$draft += "; $etype`:$identifier`:$column"}

$state.EntityDraft = $draft; Render-UI -State $state; $entityIndex++; continue}

Write-Question "How many field mappings for $($etype)`: "
$fieldCount = [int](Read-Host)

for ($j = 1; $j -le $fieldCount; $j++) {cls; Render-UI -State $state; if ($j -gt 1 -and -not $identifier) {Write-Host -f red "Invalid selection."}; Write-Host -f white "Select $($etype) Identifier:"
$selectionMap = @{}; $optIndex = 1
for ($k = 0; $k -lt $idList.Count; $k++) {Write-Host "$optIndex $($idList[$k])"; $selectionMap[$optIndex] = $idList[$k]; $optIndex++}
Write-Question "Identifier: "; $idChoice = [int](Read-Host)

$identifier = $selectionMap[$idChoice]
if (-not $identifier) {$j--; continue}
$pair = "$etype|$identifier"
if ($state.EntityUsage.UsedPairs -contains $pair) {if ($state.EntityUsage.UsedPairs -contains $pair) {Write-Host -f red "That was already used."}; Read-Host; $j--; continue}

$state.EntityUsage.UsedPairs += $pair; Write-Question "Field Name: "; $column = Read-Host

# ---------------- BUILD ENTITY OBJECT ------------------------------------------------------------
$entity = @{Type = $etype; Identifier = $identifier; Name = $column}
$state.Entities += $entity

# ---------------- BUILD LIVE STRING --------------------------------------------------------------
if ($draft.Length -eq 0) {$draft = "$etype`:$identifier`:$column"}
else {$draft += "; $etype`:$identifier`:$column"}

# ---------------- UPDATE UI STATE ----------------------------------------------------------------
$state.EntityDraft = $draft; Render-UI -State $state}
$entityIndex++}
return $state.Entities}

$entityMappings = Add-EntitiesLive $state $identifierMap $entityTypes}
entitymappings

# ---------------- DEFAULT SETTINGS --------------------------------------------------------------
function defaultsettings {if ($state.Type -eq "NRT") {return}; do{cls; Render-UI -State $state; Write-Host -f Yellow "`nChange DEFAULT Settings (Y/N)? " -n; $defaultspick = Read-Host
if ($defaultspick -eq "n") {return}} until ($defaultspick -match '^[yn]$')

# ---------------- QUERY FREQUENCY ----------------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "PT5M"; Write-OptionLine 2 "PT15M"; Write-OptionLine 3 "PT30M"; Write-OptionLine 4 "PT1H"; Write-OptionLine 5 "PT4H"; Write-OptionLine 6 "P1D"; Write-OptionLine 7 "P3D"; Write-OptionLine 8 "P7D"; Write-Question "Query Frequency: "; $queryFrequencyPick = Read-Host
$state.QueryFrequency = switch ($queryFrequencyPick) {"1" {"PT5M"}; "2" {"PT15M"}; "3" {"PT30M"}; "4" {"PT1H"}; "5" {"PT4H"}; "6" {"P1D"}; "7" {"P3D"}; "8" {"P7D"}; default {"PT1H"}}} until ($queryFrequencyPick -match '^[1-8]$')

# ---------------- QUERY PERIOD -------------------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "PT5M"; Write-OptionLine 2 "PT15M"; Write-OptionLine 3 "PT30M"; Write-OptionLine 4 "PT1H"; Write-OptionLine 5 "PT4H"; Write-OptionLine 6 "P1D"; Write-OptionLine 7 "P3D"; Write-OptionLine 8 "P7D"; Write-Question "Query Period: "; $queryPeriodPick = Read-Host
$state.QueryPeriod = switch ($queryPeriodPick) {"1" {"PT5M"}; "2" {"PT15M"}; "3" {"PT30M"}; "4" {"PT1H"}; "5" {"PT4H"}; "6" {"P1D"}; "7" {"P3D"}; "8" {"P7D"}; default {"PT1H"}}} until ($queryPeriodPick -match '^[1-8]$')

if ([int]$queryFrequencyPick -gt [int]$queryPeriodPick) {Write-Host -f Red "`nInvalid configuration: Query Period cannot be shorter than Query Frequency.`nQuery Period has therefore been changed to $($state.QueryFrequency) in order to match Query Frequency."; $state.QueryPeriod = $state.QueryFrequency; Read-Host}

# ---------------- LOOKBACK DURATION --------------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "PT5M"; Write-OptionLine 2 "PT15M"; Write-OptionLine 3 "PT30M"; Write-OptionLine 4 "PT1H"; Write-OptionLine 5 "PT4H"; Write-OptionLine 6 "P1D"; Write-OptionLine 7 "P3D"; Write-OptionLine 8 "P7D"; Write-OptionLine 9 "P14D"; Write-OptionLine 10 "P30D"; Write-Question "Lookback Duration: "; $lookbackPick = Read-Host} until ($lookbackPick -match '^([1-9]|10)$')
$state.LookbackDuration = switch ($lookbackPick) {"1" {"PT5M"}; "2" {"PT15M"}; "3" {"PT30M"}; "4" {"PT1H"}; "5" {"PT4H"}; "6" {"P1D"}; "7" {"P3D"}; "8" {"P7D"}; "9" {"P14D"}; "10" {"P30D"}; default {"PT1H"}}

# ---------------- SUPPRESSION DURATION -------------------------------------------------------
do{cls; Render-UI -State $state; Write-Question "Enable Suppression (Y/N)? "; $enableSuppressionPick = Read-Host} until ($enableSuppressionPick -match '^[yn]$')

if ($enableSuppressionPick -eq "y") {$state.SuppressionEnabled = $true; do{cls; Render-UI -State $state; Write-OptionLine 1 "PT1H"; Write-OptionLine 2 "PT4H"; Write-OptionLine 3 "PT8H"; Write-OptionLine 4 "PT12H"; Write-OptionLine 5 "P1D"; Write-OptionLine 6 "P3D"; Write-OptionLine 7 "P7D"; Write-Question "Suppression Duration: "; $suppressionPick = Read-Host} until ($suppressionPick -match '^[1-7]$')
$state.SuppressionDuration = switch ($suppressionPick) {"1" {"PT1H"}; "2" {"PT4H"}; "3" {"PT8H"}; "4" {"P12H"}; "5" {"P1D"}; "6" {"P3D"}; "7" {"P7D"}; default {"PT1H"}}}
else {$state.SuppressionDuration = "PT1H"}

# ---------------- ALERT THRESHOLD ----------------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "GreaterThan 0 (Default)"; Write-OptionLine 2 "Custom Threshold"; Write-Question "Alert Threshold: "; $alertThreshold = Read-Host} until ($alertThreshold -match '^[1-2]$')

if ($alertThreshold -eq "2") {do{cls; Render-UI -State $state; Write-Host -f White "Trigger Operator:"; Write-OptionLine 1 "GreaterThan"; Write-OptionLine 2 "LessThan"; Write-OptionLine 3 "Equal"; Write-OptionLine 4 "NotEqual"; Write-Question "Choice: "; $operatorPick = Read-Host} until ($operatorPick -match '^[1-4]$')
$state.TriggerOperator = switch ($operatorPick) {"1" {"GreaterThan"}; "2" {"LessThan"}; "3" {"Equal"}; "4" {"NotEqual"}; default {"GreaterThan"}}
Write-Question "Trigger Threshold: "; $state.TriggerThreshold = [int](Read-Host)}

# ---------------- FIRST RUN TIME -----------------------------------------------------------------
do{cls; Render-UI -State $state; Write-Question "Configure first run time (Y/N)? "; $firstRunPick = Read-Host} until ($firstRunPick -match '^[yn]$')

if ($firstRunPick -eq "y") {do{cls; Render-UI -State $state; Write-Question "Hour (0-23): "; $hour = [int](Read-Host)} until ($hour -match '^([0-9]|1\d|2[0-3])$')
do{cls; Render-UI -State $state; Write-Host -f White "Minute:"; Write-OptionLine 1 "00"; Write-OptionLine 2 "15"; Write-OptionLine 3 "30"; Write-OptionLine 4 "45"; Write-Question "Choice: "; $minutePick = Read-Host} until ($minutePick -match '^[1-4]$') 
$minute = switch ($minutePick) {"1" {0}; "2" {15}; "3" {30}; "4" {45}; default {0}}
$state.StartTimeUtc = "{0:00}:{1:00}:00Z" -f $hour,$minute}

# ---------------- INCIDENT CREATION --------------------------------------------------------------
do{cls; Render-UI -State $state; Write-Question "Create Incident (Y/N)? "; $incidentPick = Read-Host} until ($incidentPick -match '^[yn]$')
$state.CreateIncident = ($incidentPick -eq "y")

# ---------------- INCIDENT GROUPING --------------------------------------------------------------
do{cls; Render-UI -State $state; Write-Question "Enable Incident Grouping (Y/N)? "; $incidentGroupingPick = Read-Host} until ($incidentGroupingPick -match '^[yn]$')
$state.GroupingEnabled = ($incidentGroupingPick -eq "y")

# ---------------- REOPEN CLOSED INCIDENT ---------------------------------------------------------
if ($state.GroupingEnabled) {do{cls; Render-UI -State $state; Write-Question "Reopen closed incident (Y/N)? "; $reopenPick = Read-Host} until ($reopenPick -match '^[yn]$')
$state.ReopenClosedIncident = ($reopenPick -eq "y")}

# ---------------- MATCHING METHOD ----------------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "AllEntities"; Write-OptionLine 2 "Selected"; Write-Question "Matching Method: "; $matchingPick = Read-Host} until ($matchingPick -match '^[1-2]$')
$state.MatchingMethod = switch ($matchingPick) {"2" {"Selected"} default {"AllEntities"}}

# ---------------- GROUP BY ENTITIES --------------------------------------------------------------
$state.GroupByEntities = @()
if ($state.MatchingMethod -eq "Selected") {do{cls; Render-UI -State $state; Write-Question "How many Group By Entities fields (1-10)? "; $groupByEntitiescount = [int](Read-Host)} until ($groupByEntitiescount -match '^([0-9]|10)$')
for ($i = 1; $i -le $groupByEntitiescount; $i++) {cls; Render-UI -State $state; Write-Question "Sentinel Entity Field Name: "; $state.GroupByEntities += Read-Host}}

# ---------------- GROUP BY ALERT DETAILS ---------------------------------------------------------
$state.GroupByAlertDetails = @()
do{cls; Render-UI -State $state; Write-Question "How many Group By Alert Details fields (1-10)? "; $groupByAlertCount = [int](Read-Host)} until ($groupByAlertCount -match '^([0-9]|10)$')
for ($i = 1; $i -le $groupByAlertCount; $i++) {cls; Render-UI -State $state; Write-Question "Alert Detail Field Name: "; $state.GroupByAlertDetails += Read-Host}

# ---------------- GROUP BY CUSTOM DETAILS --------------------------------------------------------
$state.GroupByCustomDetails = @()
do{cls; Render-UI -State $state; Write-Question "How many Group By Custom Details fields (1-10)? "; $groupByCustomCount = [int](Read-Host)} until ($groupByCustomCount -match '^([0-9]|10)$')
for ($i = 1; $i -le $groupByCustomCount; $i++) {cls; Render-UI -State $state; Write-Question "Custom Detail Field Name: "; $state.GroupByCustomDetails += Read-Host}

if ($state.MatchingMethod -eq "Selected" -and $state.GroupByEntities.Count -eq 0 -and $state.GroupByAlertDetails.Count -eq 0 -and $state.GroupByCustomDetails.Count -eq 0) {Write-Host -f Red "`n'Matching Method: Selected' requires at least one grouping field, but none have been assigned.`nResetting to 'AllEntities'."; Read-Host; $state.MatchingMethod = "AllEntities";}

# ---------------- EVENT GROUPING SETTINGS --------------------------------------------------------
do{cls; Render-UI -State $state; Write-OptionLine 1 "SingleAlert"; Write-OptionLine 2 "AlertPerResult"; Write-Question "Event Grouping method: "; $eventGroupingPick = Read-Host} until ($eventGroupingPick -match '^[1-2]$')
$state.AggregationKind = switch ($eventGroupingPick) {"2" {"AlertPerResult"} default {"SingleAlert"}}

# ---------------- ALERT DETAILS OVERRIDE ---------------------------------------------------------
function AlertDetailsOverrideHeader {Write-Host -f Yellow "Sample Alert Details Override fields:`n"
Write-Host -f Cyan "Field Name: " -n; Write-Host -f White "alertDisplayNameFormat " -n; Write-Host -f Cyan "Value: " -n; Write-Host -f White "Suspicious Login from {{" -n; Write-Host -f Green "IPAddress" -n; Write-Host -f White "}}"
Write-Host -f Cyan "Field Name: " -n; Write-Host -f White "alertDescriptionFormat " -n; Write-Host -f Cyan "Value: " -n; Write-Host -f White "User {{" -n; Write-Host -f Green "Account" -n; Write-Host -f White "}} authenticated from {{" -n; Write-Host -f Green "IPAddress" -n; Write-Host -f White "}}"
Write-Host -f Cyan "Field Name: " -n; Write-Host -f White "alertSeverityColumnName " -n; Write-Host -f Cyan "Value: " -n; Write-Host -f White "Severity";
Write-Host -f Cyan "Field Name: " -n; Write-Host -f White "alertTacticsColumnName " -n; Write-Host -f Cyan "Value: " -n; Write-Host -f White "Tactics";
Write-Host -f Cyan "Field Name: " -n; Write-Host -f White "alertTechniquesColumnName " -n; Write-Host -f Cyan "Value: " -n; Write-Host -f White "Techniques`n";}

$fieldMap = @{1 = "alertDisplayNameFormat"; 2 = "alertDescriptionFormat"; 3 = "alertSeverityColumnName"; 4 = "alertTacticsColumnName"; 5 = "alertTechniquesColumnName"}; cls; Render-UI -State $state; AlertDetailsOverrideHeader
do {cls; Render-UI -State $state; Write-Question "How many Alert Details Override fields are required (0-5)? "; $count = [int](Read-Host)} until ($count -ge 0 -and $count -le 5)
$usedFields = @()
for ($i = 1; $i -le $count; $i++) {cls; Render-UI -State $state; AlertDetailsOverrideHeader; Write-Host -f Yellow "Available Fields:"
foreach ($key in $fieldMap.Keys | Sort-Object) {if ($fieldMap[$key] -notin $usedFields) {Write-OptionLine $key $fieldMap[$key]}}
do {Write-Question "Pick one of the available fields: "; $pick = [int](Read-Host); $name = $fieldMap[$pick]} until ($name -and $name -notin $usedFields)
$usedFields += $name; Write-Question "Value: "; $value = Read-Host
if ($value) {$state.AlertDetailsOverride[$name] = $value}}

cls; Render-UI -State $state}
defaultsettings

function Build-AlertDetailsOverride {$items = @()
foreach ($item in $state.AlertDetailsOverride.GetEnumerator()) {$value = $item.Value.Replace('"','\"'); $items += "`"$($item.Key)`": `"$value`""}
$items += '"alertDynamicProperties": []'
return "{$(($items -join ','))}"}

# ---------------- TEMPLATE -----------------------------------------------------------------------
function template {@"
{"`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
"contentVersion": "1.0.0.0",

"resources": [{"type": "Microsoft.SecurityInsights/alertRules",
"apiVersion": "2023-10-91-preview",

"name": "$guid",
"location": "global",
"kind": "$($state.Type)",

"properties": {"displayName": "$($state.Name)",
"description": "$($state.Description)",

"enabled": $($state.Enabled),
"severity": "$($state.Severity)",

"query": "$($state.KQL)",

"queryFrequency": "$($state.QueryFrequency)",
"queryPeriod": "$($state.QueryPeriod)",
"triggerOperator": "$($state.triggerOperator)",
"triggerThreshold": $($state.triggerThreshold),
"suppressionEnabled": $($state.suppressionEnabled.ToString().ToLower()),
"suppressionDuration": "$($state.SuppressionDuration)",
"startTimeUtc": "$($state.StartTimeUtc)",

"tactics": $(($state.Tactics | ConvertTo-Json -Compress)),
"techniques": $(($state.Techniques | ConvertTo-Json -Compress)),
"subTechniques": $(($state.SubTechniques | ConvertTo-Json -Compress)),

"incidentConfiguration": {"createIncident": $($state.CreateIncident.ToString().ToLower()),
"groupingConfiguration": {"enabled": $($state.GroupingEnabled.ToString().ToLower()),
"reopenClosedIncident": $($state.ReopenClosedIncident.ToString().ToLower()),
"lookbackDuration": "$($state.LookbackDuration)",
"matchingMethod": "$($state.MatchingMethod)",

"groupByEntities": $(if ($state.GroupByEntities.Count -gt 0) {$state.GroupByEntities | ConvertTo-Json -Compress} else {"[]"}),
"groupByAlertDetails": $(if ($state.GroupByAlertDetails.Count -gt 0) {$state.GroupByAlertDetails | ConvertTo-Json -Compress} else {"[]"}),
"groupByCustomDetails": $(if ($state.GroupByCustomDetails.Count -gt 0) {$state.GroupByCustomDetails | ConvertTo-Json -Compress} else {"[]"})}},

"eventGroupingSettings": {"aggregationKind": "$($state.AggregationKind)"},
"alertDetailsOverride": $(Build-AlertDetailsOverride),

"customDetails": $(if ($state.CustomDetails.Count -gt 0) {$state.CustomDetails | ConvertTo-Json -Compress}
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

Those are the minimum settings required for any rule, but the user is also given the opportunity to adapt several other default settings, at which point several new prompts will be presented.
The only significant setting that is not allowed to be configured with this script is: alertDynamicProperties within Alert Details Override. 

This tool isn't designed to be a replacement for Sentinel, but rather a fast way of creating offline rules for easy import or transfer of content between environments.

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
