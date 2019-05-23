$tenantid = (Get-Content .\tenantid.txt).Trim()
$appid = (Get-Content .\appid.txt).Trim()
$thumb = (Get-Content .\cert-thumb.txt).Trim()
$connection = Connect-AzureAD -TenantId $tenantid -ApplicationId $appid -CertificateThumbprint $thumb

# Group named Test2
$groupId = "9c918e02-8ef4-4366-9be2-fb51c653cc0c"

$settings = Get-AzureADObjectSetting -TargetObjectId $groupId -TargetType Groups
$template = $settings | ? TemplateId -eq '08d542b9-071f-4e16-94b0-74abb372e3d9'
$missingSettings = $null -eq $template
if ($missingSettings) {
    $template = Get-AzureADDirectorySettingTemplate -Id 08d542b9-071f-4e16-94b0-74abb372e3d9
    $setting = $template.CreateDirectorySetting()
}

#$settings["AllowToAddGuests"] = $true
$settings["AllowToAddGuests"] = $false

if ($missingSettings) {
    New-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $settings
}
else {
    Set-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $settings -Id $settings.Id
}