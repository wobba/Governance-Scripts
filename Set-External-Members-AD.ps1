Connect-AzureAD

# Group named Test2
$groupId = "9c918e02-8ef4-4366-9be2-fb51c653cc0c"

$settings = Get-AzureADObjectSetting -TargetObjectId $groupId -TargetType Groups
$template = $settings | ? TemplateId -eq '08d542b9-071f-4e16-94b0-74abb372e3d9'
$missingSettings = $null -eq $template
if ($missingSettings) {
    $template = Get-AzureADDirectorySettingTemplate -Id 08d542b9-071f-4e16-94b0-74abb372e3d9
    $setting = $template.CreateDirectorySetting()
}

#$setting["AllowToAddGuests"] = $true
$setting["AllowToAddGuests"] = $false

if ($missingSettings) {
    New-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $setting
}
else {
    Set-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $setting -Id $settings.Id
}