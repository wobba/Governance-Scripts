# This script uses an ADAL app with certificate and app only permissions for authentication
# Feel free to change how you get an auth token, as there are many ways
$certStore = "Cert:\CurrentUser\My"
$tenantid = (Get-Content .\tenantid.txt).Trim()
$appid = (Get-Content .\appid.txt).Trim()
$thumb = (Get-Content .\cert-thumb.txt).Trim()
Connect-AzureAD -TenantId $tenantid -ApplicationId $appid -CertificateThumbprint $thumb

# Get ADAL access token against Graph
$loginUri = 'https://login.microsoftonline.com'
$resource = 'https://graph.microsoft.com'
$certificate = Get-Item "$certStore\$thumb"
$authority = "$loginUri/$tenantid"
$context = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
$cac = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($appId, $certificate)
$tokenResult = $context.AcquireTokenAsync($resource, $cac).GetAwaiter().GetResult()
$token = $tokenResult.AccessToken

#Connect-MicrosoftTeams -ApplicationId $appid -TenantId $tenantid -CertificateThumbprint $thumb

function Archive-Team($groupId) {
    $uri = "https://graph.microsoft.com/v1.0/teams/$groupId/archive"
    $headers = @{"Authorization" = "Bearer " + $token}
    $body = @"
    {
        "shouldSetSpoSiteReadOnlyForMembers": "true"
    }
"@
    Invoke-RestMethod -Method POST -ContentType "application/json" -Headers $headers -Body $body -Uri $uri -UseBasicParsing

}
function Archive-Group($groupId) {
    Try {
        $OrgName = (Get-OrganizationConfig).Name
    }
    Catch {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $ExchangeOnlineCredential -Authentication Basic -AllowRedirection -ErrorAction Stop
        $null = Import-PSSession $Session -CommandName Get-UnifiedGroup, Get-UnifiedGroupLinks, Add-UnifiedGroupLinks, Remove-UnifiedGroupLinks, Get-OrganizationConfig, Set-UnifiedGroup
    }

    $CheckGroup = Read-Host -Prompt "Enter alias of group to archive"
    $AGroup = (Get-UnifiedGroup $CheckGroup -ErrorAction SilentlyContinue)
    If ($AGroup) {
        Write-Host "Archiving" $AGroup.DisplayName -ForegroundColor Yellow
    }
    Else {
        Write-Host $CheckGroup "group not found - terminating"
        Return
    }
    # Get lists of current owners and members
    $CurrentOwners = (Get-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Owners | Select Name)
    $CurrentMembers = (Get-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Members | Select Name)
    # Add a new owner - this is the address of the account that will continue to access the group
    $AdminAccount = "Compliance Administrator"
    Add-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Members -Links $AdminAccount
    Add-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Owners -Links $AdminAccount
    # Remove the other members and owners
    ForEach ($O in $CurrentOwners) { 
        Remove-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Owners -Links $O.Name 
        -Confirm:$False
    }
    ForEach ($M in $CurrentMembers) { 
        Remove-UnifiedGroupLinks -Identity $AGroup.Alias -LinkType Members -Links $M.Name 
        -Confirm:$False
    }

    # Create SMTP Address for the archived group
    $OldSmtpAddress = $AGroup.PrimarySmtpAddress -Split "@"
    $NewSmtpAddress = $OldSmtpAddress[0] + "_archived" + "@" + $OldSmtpAddress[1]
    $AddressRemove = "smtp:" + $AGroup.PrimarySmtpAddress
    # Update Group properties
    Set-UnifiedGroup -Identity $AGroup.Alias -AccessType Private -RequireSenderAuthenticationEnabled $True -HiddenFromAddressListsEnabled $True -CustomAttribute1 "Archived" -CustomAttribute2 (Get-Date -Format s) -PrimarySmtpAddress $NewSmtpAddress 
    Set-UnifiedGroup -Identity $AGroup.Alias -EmailAddresses @{remove = $AddressRemove}

    Write-Host $AGroup.DisplayName "is now archived and" $AdminAccount "is the new group owner"    
}


Archive-Team -groupId "9c918e02-8ef4-4366-9be2-fb51c653cc0c"

