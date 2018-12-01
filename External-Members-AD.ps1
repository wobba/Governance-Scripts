Connect-AzureAD

$groupId = "9c918e02-8ef4-4366-9be2-fb51c653cc0c"

$template = Get-AzureADDirectorySettingTemplate -Id 08d542b9-071f-4e16-94b0-74abb372e3d9
$setting = $template.CreateDirectorySetting()   
$setting["AllowToAddGuests"] = $false

#New-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $setting
Set-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupId -DirectorySetting $setting