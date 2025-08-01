# Phase 1: Environment Setup

## Step 1: Create the Domain Controller VM
1. Open VMware Workstation.
2. Click "Create a New Virtual Machine".
3. Choose "Typical" configuration and click Next.
4. Select the Windows Server 2025 ISO and click Next.
5. Choose "Windows Server 2025" as the Guest OS and version "Windows Server 2025".
6. Name the VM (e.g., "DC1") and choose a location.
7. Set the maximum disk size to 80 GB and choose "Store virtual disk as a single file".
8. Click "Customize Hardware":
   - Set Memory: 4096 MB
   - Set Processors: 2
   - Network Adapter: NAT (or Host-Only if you prefer)
   - Remove unnecessary hardware (like printer, sound card)
9. Click Finish.
## Step 2: Install Windows Server 2025 on the VM
1. Start the VM.
2. Follow the installation prompts:
   - Language, etc. -> Next.
   - Install now.
   - Choose "Windows Server 2025 Standard Evaluation (Desktop Experience)".
   - Accept the license, then Custom install.
   - Select the disk and click Next.
3. After installation, set the Administrator password.
## Step 3: Configure Static IP and Install AD DS
1. Log in as Administrator.
2. Open Server Manager.
3. Click "Add roles and features".
4. Before proceeding, set a static IP:
   - Open "Network and Sharing Center" -> Change adapter settings.
   - Right-click the network adapter -> Properties -> IPv4.
   - Set static IP (e.g., 192.168.10.10), subnet mask (255.255.255.0), gateway (your router, e.g., 192.168.10.1), and DNS (same as IP, 192.168.10.10).
5. Back to Server Manager -> Add Roles -> Select "Active Directory Domain Services".
   - Add required features? Click Add Features.
   - Click Next until the installation begins.
6. After installation, click the notification flag and "Promote this server to a domain controller".
7. In the Deployment Configuration:
   - Select "Add a new forest".
   - Root domain name: lab.local
8. Set DSRM password (make it strong and note it down).
9. Proceed with defaults until the prerequisites check, then click Install.
## Step 4: Create Client VMs
1. Create 2-3 new VMs for Windows 10/11:
   - Similar steps as above, but:
     - OS: Windows 10/11 Pro
     - Disk: 40 GB
     - RAM: 2048 MB
     - vCPU: 1
2. Install Windows 10/11 on each.
3. After installation, set the computer names (e.g., CLIENT1, CLIENT2).
4. Configure their network to be on the same subnet as the DC (NAT or Host-Only) and set DNS to the DC's IP (192.168.10.10).
## Step 5: Join Clients to the Domain
1. On each client VM:
   - Go to Settings -> System -> About -> "Rename this PC (advanced)".
   - Click "Change" under Computer Name tab.
   - Select "Domain" and enter "lab.local".
   - When prompted, enter domain admin credentials (e.g., LAB\Administrator).
   - Restart when prompted.
2. Create test users on the DC:
   - On DC: Open "Active Directory Users and Computers".
   - Expand lab.local -> right-click on "Users" container -> New -> User.
   - Create at least two users (e.g., user1, user2) and set passwords (meet complexity).
# Phase 2: Organizational Unit Structure
1. On DC, open "Active Directory Users and Computers".
2. Create top-level OUs:
   - Corporate
   - Branch Office
   - Service Accounts
3. Under Corporate, create:
   - Users
   - Computers
   - Servers
4. Under Branch Office, create:
   - Users
   - Computers
5. Move existing domain computers (the client VMs) from the default "Computers" container to:
   - Corporate/Computers (for one or two)
   - Branch Office/Computers (for one)
6. Move the test users from the default "Users" container to:
   - Corporate/Users (for user1)
   - Branch Office/Users (for user2)
7. Create security groups (e.g., in the Users container or a dedicated Groups OU):
   - Corporate_Admins
   - Branch_Admins
   - Service_Account_Group
8. Delegate control for OUs:
   - Right-click an OU (e.g., Corporate) -> Delegate Control.
   - Add the security group (e.g., Corporate_Admins) and assign appropriate permissions.
# Phase 3: Security Baseline Implementation
We'll create two GPOs: one for the domain (affecting all) and one for specific OUs.
## Step 1: Password Policy GPO (applies to the whole domain)
1. Open "Group Policy Management" (GPMC).
2. Right-click "Group Policy Objects" -> New.
   - Name: "DOMAIN_Password_Policy"
3. Right-click the new GPO -> Edit.
4. Navigate to: Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Account Policies -> Password Policy.
5. Configure:
   - Enforce password history: 24 passwords remembered
   - Maximum password age: 90 days
   - Minimum password age: 1 day
   - Minimum password length: 12 characters
   - Password must meet complexity requirements: Enabled
6. Under Account Lockout Policy:
   - Account lockout threshold: 5 invalid attempts
   - Account lockout duration: 30 minutes
   - Reset account lockout counter after: 30 minutes
7. Link this GPO to the domain (right-click lab.local -> Link an Existing GPO -> select "DOMAIN_Password_Policy").
Note: Password policies set in a GPO linked to an OU will only affect local accounts on computers in that OU, not domain accounts. Hence, domain password policy must be set at the domain level.
## Step 2: Security Baseline GPO
1. Create a new GPO named "CORP_Security_Baseline".
2. Edit the GPO and configure:
### Account Security Policies
- Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options
  - Interactive logon: Message text and title for users attempting to log on: Set a warning message.
  - Network security: Configure encryption types allowed for Kerberos: AES128, AES256 (disable DES, RC4).
  - User Account Control: Behavior of the elevation prompt for administrators: Prompt for consent.
### Audit Policy
- Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Audit Policy
  - Audit account logon events: Success, Failure
  - Audit account management: Success, Failure
  - Audit directory service access: Failure
  - Audit logon events: Success, Failure
  - Audit object access: Failure
  - Audit policy change: Success, Failure
  - Audit system events: Success, Failure
3. Link this GPO to the "Corporate" and "Branch Office" OUs.
# Phase 4: User Environment Management
Create a GPO named "CORP_User_Environment".
1. Edit the GPO (User Configuration):
   - Policies -> Administrative Templates: Control Panel/Personalization
     - Force a specific default lock screen and logon image: Enabled (set path to a network share, e.g., \\dc1\netlogon\wallpaper.jpg)
     - Prevent changing lock screen and logon image: Enabled
   - Policies -> Administrative Templates: Start Menu and Taskbar
     - Remove user's folder links from Start Menu: Enabled
     - Remove All Programs list from Start menu: Disabled
   - Policies -> Administrative Templates: System
     - Prevent access to registry editing tools: Enabled
     - Run only specified Windows applications: Enabled (then list allowed apps, e.g., notepad.exe, winword.exe, etc.)
2. Link this GPO to the "Corporate/Users" OU and "Branch Office/Users" OU.
# Phase 5: Computer Configuration Policies
Create a GPO named "CORP_Computer_Security".
1. Edit the GPO (Computer Configuration):
   - Policies -> Windows Settings -> Security Settings -> Windows Firewall with Advanced Security
     - Ensure Domain Profile is enabled and configure inbound/outbound rules as needed (e.g., block inbound by default, allow outbound).
   - Policies -> Administrative Templates: Windows Components/Windows Defender Antivirus
     - Turn on Windows Defender Antivirus: Enabled
   - Policies -> Administrative Templates: Windows Components/Windows Update
     - Configure Automatic Updates: Enabled (set to 4 - Auto download and schedule the install)
     - Specify intranet Microsoft update service location: Enabled (if using WSUS, set to http://your_wsus_server)
   - Policies -> Administrative Templates: System/Device Installation/Device Installation Restrictions
     - Prevent installation of removable devices: Enabled
2. Link this GPO to the "Corporate/Computers" and "Corporate/Servers" OUs.
# Phase 6: Software Deployment
We'll deploy an application (e.g., 7-Zip) via GPO.
1. On the DC, create a network share (e.g., \\dc1\software) and set permissions (e.g., Domain Computers: Read).
2. Download the 7-Zip MSI and place it in the share.
3. Create a new GPO named "CORP_Software_7Zip".
4. Edit the GPO: Computer Configuration -> Policies -> Software Settings -> Software installation.
   - Right-click -> New -> Package.
   - Browse to the network share and select the 7-Zip MSI.
   - Choose "Assigned".
5. Link this GPO to the "Corporate/Computers" OU.
# Phase 7: Windows Update Management
If you want to set up WSUS, that's a separate project. Alternatively, configure update policies:
1. Create a GPO named "CORP_Windows_Updates".
2. Edit the GPO (Computer Configuration):
   - Policies -> Administrative Templates: Windows Components/Windows Update
     - Configure Automatic Updates: Enabled (set to 4 - Auto download and schedule the install)
     - Specify active hours range: 8 AM to 5 PM
     - Automatic Updates detection frequency: 22 hours
     - Configure Automatic Updates: Scheduled install day: 0 (Every Sunday) and time: 3:00 AM
3. Link to the "Corporate/Computers" OU.
# Security Hardening Checklist
Go through the checklist and verify each item is configured. You can use the GPOs we created and also check local security settings on a client.
# Testing and Validation
1. On a client computer (in Corporate/Computers OU):
   - Run `gpupdate /force` in command prompt as admin.
   - Reboot.
   - Log in as a test user (from Corporate/Users).
   - Check applied policies:
     - `gpresult /r` to see applied GPOs.
     - Check password policy: try setting a short password (should fail).
     - Check software: 7-Zip should be installed.
     - Check wallpaper and restrictions (e.g., regedit should be blocked).

# Monitoring and Maintenance


## PowerShell Script for GPO Backup:
```powershell
# gpo-backup.ps1
Import-Module GroupPolicy
$backupPath = "C:\GPOBackup"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
New-Item -ItemType Directory -Path $backupPath -Force
Backup-Gpo -All -Path "$backupPath\$timestamp" -Comment "Daily Backup"
```
