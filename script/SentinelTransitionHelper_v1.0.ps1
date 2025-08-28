# =============================================
# Defender Adoption Helper Script
#
# This PowerShell script assists with the adoption of Microsoft Defender and Sentinel by:
# - Checking retention settings for key Defender tables in Log Analytics
# - Analyzing analytics rules and Fusion engine status
# - Reviewing automation rules for best practices
#
# The script authenticates using an Entra App Registration and queries the Azure Management API.
#
# Author: [Mario Cuomo]
# Date: [12th August, 2025]
# =============================================


# Define your Entra App Registration and Sentinel details
$tenantId = "<your-tenant-ID>"
$clientId = "<your-client-ID>"
$clientSecret = "<your-secret-value>"
$subscriptionId = "<your-subscription-ID>"
$resourceGroupName = "<your-resource-group-name>"
$workspaceName = "<your-workspace-name>"

$resource = "https://management.azure.com/"
$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"


# Prepare the body for the token request
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}

# Request the token
$tokenResponse = Invoke-RestMethod -Method Post -Uri $authUrl -Body $body
$accessToken = $tokenResponse.access_token

Write-Host "DEFENDER ADOPTION HELPER" -ForegroundColor red -BackgroundColor White
Write-Host "This script assists with Defender and Sentinel adoption by checking table retention, analytics rules, and automation rules." -ForegroundColor Cyan
Write-Host ""


Write-Host "***********************"
Write-Host "DEFENDER DATA CONNECTOR"
Write-Host "***********************"
$defenderTables = @(
    "DeviceInfo",
    "DeviceNetworkInfo",
    "DeviceProcessEvents",
    "DeviceNetworkEvents",
    "DeviceFileEvents",
    "DeviceRegistryEvents",
    "DeviceLogonEvents",
    "DeviceImageLoadEvents",
    "DeviceEvents",
    "DeviceFileCertificateInfo",
    "EmailEvents",
    "EmailUrlInfo",
    "EmailAttachmentInfo",
    "EmailPostDeliveryEvents",
    "UrlClickEvents",
    "CloudAppEvents",
    "IdentityLogonEvents",
    "IdentityQueryEvents",
    "IdentityDirectoryEvents",
    "AlertInfo",
    "AlertEvidence"
)

$apiVersion = "2025-02-01"
foreach ($table in $defenderTables) {
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/tables/${table}?api-version=$apiVersion"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
        Authorization = "Bearer $accessToken"
        ContentType = "application/json"
    }
    $retentionPeriod = $($response.properties.totalRetentionInDays)

    if ($response.properties.totalRetentionInDays -lt 31){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " The table $table has a retention of $retentionPeriod days - no need to ingest this data in Sentinel" 
    }
    else{
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The table $table has a retention of $retentionPeriod days - need to be stored in Sentinel for more retention" 
    }
}

Write-Host ""



Write-Host "***********************"
Write-Host "ANALYTICS ANALYSIS"
Write-Host "***********************"

## FUSION ENGINE
$apiVersion = "2025-06-01"
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/alertRules/BuiltInFusion?api-version=$apiVersion"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
    ContentType = "application/json"
}
if ($response -eq $null){
    Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The Fusion engine is not enabled"
}
if ($response.properties.enabled){
    Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " Fusion rules will be automatically disabled after Microsoft Sentinel is onboarded in Defender"
}else{
    Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The Fusion engine is not enabled"
}


## ALERT VISIBILITY
$apiVersion = "2025-06-01"
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/alertRules?api-version=$apiVersion"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
    ContentType = "application/json"
}
foreach ($rule in $response.value) {
    if ($rule.properties.displayName -eq "Advanced Multistage Attack Detection"){
        continue
    }
    $ruleName = $($rule.properties.displayName)
    
    if (!$rule.properties.incidentConfiguration.createIncident){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " The rule $ruleName doesn't generate incidents. The alerts aren't visible in the Defender portal. They appear in SecurityAlerts table in Advanced Hunting"
    }else{
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The rule $ruleName is configured correctly"
    }
}






Write-Host ""
Write-Host "***********************"
Write-Host "AUTOMATION RULES ANALYSIS"
Write-Host "***********************"

$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/automationRules?api-version=$apiVersion"

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
    ContentType = "application/json"
}

# Iterate through automation rules
foreach ($rule in $response.value) {
    $ruleName = $rule.properties
    $triggeringLogic = $rule.properties.triggeringLogic
    $isEnabled = $triggeringLogic.isEnabled
    $triggersOn = $triggeringLogic.triggersOn
    $conditions = $triggeringLogic.conditions

    $incidentTitle = $false
    $incidentProvider = $false

    if ($isEnabled -and $triggersOn -eq "Incidents" -and $conditions) {
        foreach ($condition in $conditions) {
            if (
                $condition.conditionType -eq "Property" -and
                $condition.conditionProperties.propertyName -eq "IncidentTitle"
            ){$incidentTitle = $true}
            if (
                $condition.conditionType -eq "Property" -and
                $condition.conditionProperties.propertyName -eq "IncidentProviderName"
            ){$incidentProvider = $true}
            
            if($incidentTitle -and $incidentProvider){
                break
            }
        }
    }
    
    $ruleName = $($rule.properties.displayName)
    if($incidentTitle){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " Change the trigger condition in the automation rule $ruleName from `"Incident Title`" to `"Analytics Rule Name`""
    }
    if($incidentProvider){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " Change the trigger condition in the automation rule $ruleName from `"Incident Provider`" to `"Alert Product Name`""
    }
    if(!$incidentProvider -and !$incidentTitle){
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The automation rule $ruleName is configured correctly"

    }
}
