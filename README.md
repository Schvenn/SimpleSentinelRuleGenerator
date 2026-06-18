# Simple Sentinel Rule Generator
A menu-driven PowerShell tool for building Microsoft Sentinel Analytics Rules offline and exporting them as valid ARM JSON templates for import into Azure Sentinel.

It is designed for rapid rule prototyping without needing to work directly inside a Sentinel workspace.

![Simple Sentinel Rule Generator](https://raw.githubusercontent.com/Schvenn/SimpleSentinelRuleGenerator/main/SimpleSentinelRuleGenerator.png)

---

## Features
- Interactive CLI-based rule builder
- Live UI preview during rule construction
- All basic rule settings:
    - Multi-line entry for Description
    - Multi-line entry for KQL
- MITRE ATT&CK integration (offline cached dataset):
    - Tactics (TA#### + human-readable names)
    - Techniques (T####)
    - Sub-techniques (T####.###)
    - Auto-derives:
        - Parent techniques from sub-techniques
        - Tactics from techniques
- All relevant time settings
- All relevant incident controls
- Incident grouping configuration settings:
     - Group-by field identification:
          - Entities
          - Alert Details
          - Custom Details
- Alert Details Override support (Sentinel alert display customization):
    - alertDisplayNameFormat
    - alertDescriptionFormat
    - alertSeverityColumnName
    - alertTacticsColumnName
    - alertTechniquesColumnName
    - alertDynamicProperties (Placeholder only)
- Custom field mapping support (`customDetails`)
- Entity mapping builder for default Sentinel entities and all associated child `Identifiers`:
    - **Account**:
        - AadUserId, DisplayName, Mail, Name, NTDomain, ObjectId, Sid, UPNSuffix, UserPrincipalName  
    - **AzureResource**:
        - AppName, AppId, Publisher  
    - **CloudApplication**:
        - AppId, AppName, Publisher  
    - **DNS**:
        - DomainName  
    - **File**:
        - Directory, FileHash, MD5, Name, SHA1, SHA256  
    - **FileHash**:
        - MD5, SHA1, SHA256  
    - **Host**:
        - AzureID, DnsDomain, FQDN, HostName, NetBiosName, NTDomain, OSFamily, OSVersion  
    - **IP**:
        - Address  
    - **MailMessage**:
        - DeliveryAction, MessageId, Recipient, Sender, Subject  
    - **Mailbox**:
        - DisplayName, MailboxPrimaryAddress, UPN  
    - **Malware**:
        - Category, Name  
    - **Process**:
        - AccountName, CommandLine, ImageFile, ImageFileHash, ParentProcessId, ProcessId, ProcessName  
    - **RegistryKey**:
        - Key  
    - **RegistryValue**:
        - Name, Value  
    - **SecurityGroup**:
        - GroupId, GroupName, Member, TenantId  
    - **SubmissionMail**:
        - Recipient, Sender, Status, SubmissionId  
    - **URL**:
        - Url  

- Exports valid Sentinel ARM template JSON
---
## Usage
```powershell
SimpleSentinelRuleGenerator 'My Sentinel Rule Name' -help
```
---
## Output
The module generates a full ARM template with a filename similar to:
```
My_Sentinel_Rule_Name.json
```
---
## Architecture Notes
- Uses local MITRE ATT&CK JSON cache, and is intended to be used in conjunction with AllKQLtoHTML
---
## Why this exists
This tool is designed for:
- Offline rule development
- Clean separation from production Sentinel environments
- Reusable detection engineering workflows
