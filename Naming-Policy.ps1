Connect-AzureAD
$group = Get-AzureADGroup -SearchString "O365-Admin"
# Fetch existing settings if set
$policySetting = Get-AzureADDirectorySetting | Where-Object {$_.DisplayName -eq "Group.Unified"}
if ($policySetting -eq $null) {
   # Retrieve the Group.Unified settings template (assuming you have not done this before)
   $template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}
   # Create the settings object from the template
   $settings = $template.CreateDirectorySetting()
   # Use this settings object to prevent others than specified group to create Groups
   $settings["EnableGroupCreation"] = $false
   $settings["GroupCreationAllowedGroupId"] = $group.ObjectId
   # (optional) Add a link to the Group usage guidelines
   $settings["UsageGuidelinesUrl"] = "https://<tenant>.sharepoint.com/SitePages/Guidelines.aspx"
   $policySetting = New-AzureADDirectorySetting -DirectorySetting $settings
}
else {
   $policySetting["EnableGroupCreation"] = $false
   $policySetting["GroupCreationAllowedGroupId"] = $group.ObjectId
   # (optional) Add a link to the Group usage guidelines
   $policySetting["UsageGuidelinesUrl"] = "https://<tenant>.sharepoint.com/SitePages/Guidelines.aspx"

   Set-AzureADDirectorySetting -Id $policySetting.Id -DirectorySetting $policySetting
}

$policySetting["PrefixSuffixNamingRequirement"] = "Grp_[Department]_[GroupName]"
Set-AzureADDirectorySetting -Id $policySetting.Id -DirectorySetting $policySetting
