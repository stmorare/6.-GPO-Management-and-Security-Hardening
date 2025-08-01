# Create OUs
New-ADOrganizationalUnit -Name "Corporate" -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Corporate,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Corporate,DC=lab,DC=local"

# Move computers
Get-ADComputer -Filter * | Where-Object Name -like "CLIENT*" | 
Move-ADObject -TargetPath "OU=Computers,OU=Corporate,DC=lab,DC=local"