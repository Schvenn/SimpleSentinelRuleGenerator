# Simple Sentinel Rule Generator
A menu-driven PowerShell tool for building Microsoft Sentinel Analytics Rules offline and exporting them as valid ARM JSON templates for import into Azure Sentinel.

It is designed for rapid rule prototyping without needing to work directly inside a Sentinel workspace.

![Simple Sentinel Rule Generator](https://raw.githubusercontent.com/Schvenn/SimpleSentinelRuleGenerator/main/SimpleSentinelRuleGenerator.png)

---

## Features
- Interactive CLI-based rule builder
- MITRE ATT&CK integration (offline cached dataset)
- Supports:
  - Tactics (TA#### + human-readable names)
  - Techniques (T####)
  - Sub-techniques (T####.###)
- Auto-derives:
  - Parent techniques from sub-techniques
  - Tactics from techniques
- Custom field mapping support (`customDetails`)
- Entity mapping builder for Sentinel entities:
  - Account
  - Host
  - IP
  - URL
  - File
  - Process
- Live UI preview during rule construction
- Exports valid Sentinel ARM template JSON
---
## Usage
```powershell
SimpleSentinelRuleGenerator 'My Sentinel Rule Name' -help
```
---
## Output
The module generates a file similar to:
```
My_Sentinel_Rule_Name.json
```
Containing a full ARM template:
- Microsoft.SecurityInsights alert rule
- MITRE mappings (tactics, techniques, sub-techniques)
- Entity mappings
- Custom details
- KQL query
- Rule configuration metadata
---
## Supported Rule Configuration
### Core Fields
- Name
- Description
- KQL Query
- Rule Type (Scheduled / NRT)
- Enabled state
- Severity

### MITRE ATT&CK
- Tactics
- Techniques
- Sub-techniques
- Auto-resolution from MITRE dataset cache

### Custom Details
Example:
```json
"customDetails": {
  "AccountCreationTime": "AccountCreationTime",
  "AccountCreator": "AccountCreator"
}
```
### Entity Mappings
Supports structured mappings such as:

- Account → Name, SID, AadUserId, etc.
- Host → HostName, DNS, AzureID
- IP → Address
- URL → Url
- File → hashes, name, path
- Process → command line, image, PID
---
## Architecture Notes
- Uses local MITRE ATT&CK JSON cache, and is intended to be used in conjunction with AllKQLtoHTML
---
## Example Workflow
1. Enter rule name
2. Provide description (multi-line)
3. Enter KQL query (multi-line)
4. Choose rule type
5. Set severity
6. Select MITRE tactics / techniques / sub-techniques
7. Define custom details (optional)
8. Map entities
9. Export JSON file
## Why this exists
This tool is designed for:
- Offline rule development
- Rapid KQL experimentation
- Clean separation from production Sentinel environments
- Reusable detection engineering workflows
