$pwd = "spc19"
$certStore ="Cert:\CurrentUser\My"
$currentDate = Get-Date
$endDate = $currentDate.AddYears(10) # 10 years is nice and long
$thumb = (New-SelfSignedCertificate -DnsName "madcow.dog" -CertStoreLocation $certStore -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $endDate).Thumbprint
$thumb > cert-thumb.txt # Save to file
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
#Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath .\madcow.pfx -Password $pwd
Export-PfxCertificate -cert "$certStore\$thumb" -FilePath .\madcow.pfx -Password $pwd
$path = (Get-Item -Path ".\").FullName
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("$path\madcow.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

# Connect to Azure AD as an admin account
Connect-AzureAD
 
# Create Azure Active Directory Application (ADAL App)
$application = New-AzureADApplication -DisplayName "AzureADPosh" -IdentifierUris "https://madcow.dog/AzureADPosh"
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier "AzureADPosh" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -StartDate $currentDate -EndDate $endDate.AddDays(-1)
 
# Create the Service Principal and connect it to the Application
$sp = New-AzureADServicePrincipal -AppId $application.AppId 
 
$azureDirectoryWriteRoleId = ( Get-AzureADDirectoryRoleTemplate |Where-Object DisplayName -eq "Directory Writers").ObjectId
try {
    Enable-AzureADDirectoryRole -RoleTemplateId $azureDirectoryWriteRoleId 
}
catch { }

# Give the application read/write permissions to AAD
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole |Where-Object DisplayName -eq "Directory Writers" ).Objectid -RefObjectId $sp.ObjectId
 
# Test to login using the app
$tenant = Get-AzureADTenantDetail
$tenant.ObjectId > tenantid.txt
$appId = $application.AppId
$appId > appid.txt
Connect-AzureAD -TenantId $tenant.ObjectId -ApplicationId  $Application.AppId -CertificateThumbprint $thumb

[Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens["AccessToken"]