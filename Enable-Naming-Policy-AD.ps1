$tenantid = (Get-Content .\tenantid.txt).Trim()
$appid = (Get-Content .\appid.txt).Trim()
$thumb = (Get-Content .\cert-thumb.txt).Trim()
$connection = Connect-AzureAD -TenantId $tenantid -ApplicationId $appid -CertificateThumbprint $thumb

$group = Get-AzureADGroup -SearchString "O365-Admin"
# Fetch existing settings if set
$policySetting = Get-AzureADDirectorySetting | Where-Object {$_.DisplayName -eq "Group.Unified"}
if ($null -eq $policySetting) {
   # Retrieve the Group.Unified settings template (assuming you have not done this before)
   $template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}   
   # Create the settings object from the template
   $settings = $template.CreateDirectorySetting()
   $policySetting = New-AzureADDirectorySetting -DirectorySetting $settings
}


# (optional) Block group creation - only admins
#$policySetting["EnableGroupCreation"] = $false

# (optional) Allow a certain group to create
#$policySetting["GroupCreationAllowedGroupId"] = $group.ObjectId

# (optional) Add a link to the Group usage guidelines
#$policySetting["UsageGuidelinesUrl"] = "https://<tenant>.sharepoint.com/SitePages/Guidelines.aspx"

$policySetting["PrefixSuffixNamingRequirement"] = "Grp_[Department]_[GroupName]"
$policySetting["CustomBlockedWordsList"] = "poker"
Set-AzureADDirectorySetting -Id $policySetting.Id -DirectorySetting $policySetting
