# This script uses an ADAL app with app only permissions for authentication
# Feel free to change how you get an auth token, as there are many ways
$appId = "<ADAL AppId with Group.ReadWrite.All>"
$appSecret = "<ADAL App Secret with Group.ReadWrite.All>"
$domain = "<tenant>.onmicrosoft.com"

$formFields = @{client_id = "$appId"; scope = "https://graph.microsoft.com/.default"; client_secret = "$appSecret"; grant_type = 'client_credentials'}
$url = "https://login.microsoftonline.com/$domain/oauth2/v2.0/token"

$result = Invoke-WebRequest -UseBasicParsing -Uri $url -Method Post -Body $formFields -ContentType "application/x-www-form-urlencoded"
$result = ConvertFrom-Json -InputObject $result.Content
$token = $result.access_token

function Set-GroupExternalAccess($groupId, $externalAccessAllowed) {    
    $query = "https://graph.microsoft.com/v1.0/groups/$groupId/settings"
    $headers = @{"Authorization" = "Bearer " + $token}
    $settings = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $query -Headers $headers -UseBasicParsing
    $body = @"
{
  "templateId": "08d542b9-071f-4e16-94b0-74abb372e3d9",
  "values": [
    {
      "name": "AllowToAddGuests",
      "value": "$externalAccessAllowed"
    }
  ]
}
"@

    $template = $settings.value |? templateId -eq '08d542b9-071f-4e16-94b0-74abb372e3d9'

    if (!$template) {
        $uri = "https://graph.microsoft.com/v1.0/groups/$groupId/settings"
        Invoke-RestMethod -Method POST -ContentType "application/json" -Headers $headers -Body $body -Uri $uri -UseBasicParsing
    }
    else {
        $settingsId = $template.id

        Write-Host "Settings ID: $settingsId"

        if ([bool]::Parse($template.values.value) -ne $externalAccessAllowed) {
            Write-Host "Setting AllowToAddGuests to $externalAccessAllowed."
            $uri = "https://graph.microsoft.com/v1.0/groups/$groupId/settings/$settingsId"
            Invoke-RestMethod -Method PATCH -ContentType "application/json" -Headers $headers -Body $body -Uri $uri
        }    
    }

    
}

Set-GroupExternalAccess -groupId "9c918e02-8ef4-4366-9be2-fb51c653cc0c" -externalAccessAllowed $false
