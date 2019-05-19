$adalUrlIdentifier = "https://madcow.dog/AzureADPosh"
$dummyReplyUrl = "https://www.puzzlepart.com"
$pwd = "spc19"
$certStore = "Cert:\CurrentUser\My"
$currentDate = Get-Date
$endDate = $currentDate.AddYears(10) # 10 years is nice and long
$thumb = (New-SelfSignedCertificate -DnsName "madcow.dog" -CertStoreLocation $certStore -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $endDate).Thumbprint
$thumb > cert-thumb.txt # Save to file
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "$certStore\$thumb" -FilePath .\madcow.pfx -Password $pwd
$path = (Get-Item -Path ".\").FullName
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("$path\madcow.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

# Connect to Azure AD as an admin account
Connect-AzureAD

# Store tenantid
$tenant = Get-AzureADTenantDetail
$tenant.ObjectId > tenantid.txt

# Add Reports.Read.All access
$svcPrincipal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Graph" }
$appRole = $svcPrincipal.AppRoles | ? { $_.Value -eq "Reports.Read.All" }
$appPermission = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "$($appRole.Id)", "Role"
$reqGraph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqGraph.ResourceAppId = $svcPrincipal.AppId
$reqGraph.ResourceAccess = $appPermission

# Create Azure Active Directory Application (ADAL App)
$application = New-AzureADApplication -DisplayName "AzureADPosh" -IdentifierUris $adalUrlIdentifier -ReplyUrls $dummyReplyUrl -RequiredResourceAccess $reqGraph
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier "AzureADPosh" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -StartDate $currentDate -EndDate $endDate.AddDays(-1)

# https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent
$consentUri = "https://login.microsoftonline.com/$($tenant.ObjectId)/adminconsent?client_id=$($application.AppId)&state=12345&redirect_uri=$dummyReplyUrl"
$consentUri | clip
Write-Host "Consent URL is copied to your clipboard - paste it into a browser, and ignore the redirect" -ForegroundColor Green
Write-Host $consentUri -ForegroundColor Blue
Read-Host -Prompt "Press ENTER when consented"

$sp = Get-AzureADServicePrincipal | ? AppId -eq $application.AppId
if (-not $sp) {
    # Create the Service Principal and connect it to the Application
    $sp = New-AzureADServicePrincipal -AppId $application.AppId 
}
 
$azureDirectoryWriteRoleId = ( Get-AzureADDirectoryRoleTemplate | Where-Object DisplayName -eq "Directory Writers").ObjectId
try {
    Enable-AzureADDirectoryRole -RoleTemplateId $azureDirectoryWriteRoleId 
}
catch { }

# Give the application read/write permissions to AAD
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | Where-Object DisplayName -eq "Directory Writers" ).Objectid -RefObjectId $sp.ObjectId

$appId = $application.AppId
$appId > appid.txt

Start-Sleep 10 # give it some seconds before connecting
Connect-AzureAD -TenantId $tenant.ObjectId -ApplicationId  $Application.AppId -CertificateThumbprint $thumb

[Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens["AccessToken"]