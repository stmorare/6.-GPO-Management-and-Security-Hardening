# Install AD DS Role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest `
-DomainName "lab.local" `
-DomainMode "WinThreshold" `
-ForestMode "WinThreshold" `
-InstallDNS:$true `
-SafeModeAdministratorPassword (ConvertTo-SecureString "YourStrongPassword!" -AsPlainText -Force)