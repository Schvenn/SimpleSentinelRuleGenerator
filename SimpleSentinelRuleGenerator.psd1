@{RootModule = 'simplesentinelrulegenerator.psm1'
ModuleVersion = '2.1'
GUID = 'ccd81dc6-8e13-4bec-b69c-03866abfa0de'
Author = 'Craig Plath'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '© Craig Plath. All rights reserved.'
Description = 'A menu driven tool that facilitates the creation of Microsoft Sentinel rule ARM JSON files.'
PowerShellVersion = '5.1'
FunctionsToExport = @('simplesentinelrulegenerator')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @('ssrg', 'createrule')
FileList = @('simplesentinelrulegenerator.psm1')

PrivateData = @{PSData = @{Tags = @('allkqltohtml', 'arm', 'json', 'kql', 'sentinel', 'powershell')
LicenseUri = 'https://github.com/Schvenn/simplesentinelrulegenerator/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/simplesentinelrulegenerator'
ReleaseNotes = 'Initial release.'}}}
