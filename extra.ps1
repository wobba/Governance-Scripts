function Get-GetLastMail($groupId) {
    $query = "https://graph.microsoft.com/v1.0/groups/$groupId/conversations?`$top=1"
    $headers = @{"Authorization" = "Bearer " + $token}
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $query -Headers $headers -UseBasicParsing

    if ($result.value.count -gt 0 ) {
        lastDeliveredDateTime
    }
    return $result.value
}


function Get-LastTeamConversation($groupId) {
    $channelQuery = "https://graph.microsoft.com/beta/teams/$groupId/channels"
    $headers = @{"Authorization" = "Bearer " + $token}
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $channelQuery -Headers $headers -UseBasicParsing
    foreach ($channel in $result.value) {
        $channelId = $channel.id
        $messageQuery = "https://graph.microsoft.com/beta/teams/$groupId/channels/$channelId/messages?`$top=1"
        $messageResponse = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $query -Headers $headers -UseBasicParsing
        if ($messageResponse.value.count -gt 0) {
            $msgDate = Get-Date -Date $messageResponse.value[0].createdDateTime
            if ($msgDate -gt $lastMsgDate) {
                $lastMsgDate = $msgDate
            }
        }
    }
    return $lastMsgDate
}

#planner https://graph.microsoft.com/v1.0/planner/plans/Yb02z6a-mkyh6I_Kela00pYAD3bv/tasks
