# Optional parameter for FileName
param(
    [Parameter(Mandatory=$false)]
    [string]$FileName = $null
)
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
$tenantId = "<your-tenant-id>"
$clientId = "<your-client-id>"
$clientSecret = "<your-client-secret>"
$subscriptionId = "<your-subscription-id>"
$resourceGroupName = "<your-resource-group-name>"
$workspaceName = "<your-workspace-name>"
$resource = "https://management.azure.com/"
$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"

$totalControls = 0
$PassedControls = 0
$totalControlsTemp = 0
$passedControlsTemp = 0

if ($PSBoundParameters.ContainsKey('FileName')) {
    $WordApplication = New-Object -ComObject Word.Application
    $WordApplication.Visible = $false
    $Document = $WordApplication.Documents.Add()
    $Writer = $WordApplication.Selection
}

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


if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.Style = 'Heading 1'
    $Writer.TypeText("DEFENDER ADOPTION HELPER RESULTS")
    $Writer.TypeParagraph()
    $Writer.Style = 'Normal'
    $Writer.TypeText("This report describes your current situation to adopt Sentinel in Defender in terms of Table Retention, Analytics Rules and Automations Rules.")
    $Writer.TypeParagraph()
    $Writer.TypeText("Sentinel Environment in scope: ")
    $Writer.Font.Bold = $true
    $Writer.TypeText($workspaceName)
    $Writer.Font.Bold = $false
    $Writer.TypeParagraph()
    $Writer.TypeText("Report Generated on date: ")
    $Writer.Font.Bold = $true
    $date = Get-Date -Format "yyyy-MM-dd"
    $Writer.TypeText($date)
    $Writer.Font.Bold = $false
    $Writer.InsertBreak(7) 
}
Write-Host "DEFENDER ADOPTION HELPER" -ForegroundColor red -BackgroundColor White
Write-Host "This script assists with Defender and Sentinel adoption by checking table retention, analytics rules, and automation rules." -ForegroundColor Cyan
Write-Host ""


if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.TypeParagraph()
    $Writer.Style = 'Heading 2'
    $Writer.TypeText("DEFENDER DATA ANALYSIS")
    $Writer.TypeParagraph()
    $Writer.Style = 'Normal'
}
Write-Host "***********************"
Write-Host "DEFENDER DATA ANALYSIS"
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
    $totalControls++
    $totalControlsTemp++

    if ($response.properties.totalRetentionInDays -lt 31){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " The table $table has a retention of $retentionPeriod days - no need to ingest this data in Sentinel" 
            if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 255 
                $Writer.Font.Bold = $true
                $Writer.TypeText("[WARNING] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     
                $Writer.TypeText("The table ")
                $Writer.Font.Italic = $true
                $Writer.Font.Bold = $true
                $Writer.TypeText($table)
                $Writer.Font.Italic = $false
                $Writer.Font.Bold = $false
                $Writer.TypeText(" has a retention of $retentionPeriod days - no need to ingest this data in Sentinel")
                $Writer.TypeParagraph()
        }
    }
    else{
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The table $table has a retention of $retentionPeriod days - need to be stored in Sentinel for more retention" 
        $passedControlsTemp++
        $totalPassedControls++
            if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 5287936   # Green for OK
                $Writer.Font.Bold = $true
                $Writer.TypeText("[OK] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     # Black for normal text
                $Writer.TypeText(" The table ")
                $Writer.Font.Italic = $true
                $Writer.Font.Bold = $true
                $Writer.TypeText($table)
                $Writer.Font.Bold = $false
                $Writer.Font.Italic = $false
                $Writer.TypeText(" has a retention of $retentionPeriod days - need to be stored in Sentinel for more retention")
                $Writer.TypeParagraph()
        }
    }
}
# Show score for this section
$scorePercent = [math]::Round(($passedControlsTemp / $totalControlsTemp) * 100, 2)
Write-Host "Defender Data Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)" -ForegroundColor Cyan
if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.Font.Color = 0
    $Writer.Font.Bold = $true
    $Writer.TypeText("Defender Data Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)")
    $Writer.Font.Bold = $false
    $Writer.Font.Color = 0
    $Writer.TypeParagraph()
}
Write-Host ""



Write-Host "***********************"
Write-Host "ANALYTICS ANALYSIS"
Write-Host "***********************"
$passedControlsTemp = 0
$totalControlsTemp = 0

if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.InsertBreak(7)
    $Writer.TypeParagraph()
    $Writer.Style = 'Heading 2'
    $Writer.TypeText("ANALYTICS ANALYSIS")
    $Writer.TypeParagraph()
    $Writer.Style = 'Normal'
}

## FUSION ENGINE
$apiVersion = "2025-06-01"
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/alertRules/BuiltInFusion?api-version=$apiVersion"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
    ContentType = "application/json"
}
$totalControls++
$totalControlsTemp++

if ($response -eq $null){
    Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The Fusion engine is not enabled"
    $passedControlsTemp++
    $totalPassedControls++
    if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 5287936
                $Writer.Font.Bold = $true
                $Writer.TypeText("[OK] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0
                $Writer.TypeText("The Fusion engine is not enabled")
                $Writer.TypeParagraph()
        }
}
if ($response.properties.enabled){
    Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " Fusion rules will be automatically disabled after Microsoft Sentinel is onboarded in Defender"
    if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 255 
                $Writer.Font.Bold = $true
                $Writer.TypeText("[WARNING] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     
                $Writer.TypeText("Fusion rules will be automatically disabled after Microsoft Sentinel is onboarded in Defender")
                $Writer.TypeParagraph()
    }
}else{
    Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The Fusion engine is not enabled"
    if ($PSBoundParameters.ContainsKey('FileName')) {
            $passedControlsTemp++
            $totalPassedControls++
            $Writer.Font.Color = 5287936
            $Writer.Font.Bold = $true
            $Writer.TypeText("[OK] ")
            $Writer.Font.Bold = $false
            $Writer.Font.Color = 0
            $Writer.TypeText("The Fusion engine is not enabled")
            $Writer.TypeParagraph()
    }
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
    $totalControls++
    $totalControlsTemp++
    
    $ruleName = $($rule.properties.displayName)
    
    if (!$rule.properties.incidentConfiguration.createIncident){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " The rule $ruleName doesn't generate incidents. The alerts aren't visible in the Defender portal. They appear in SecurityAlerts table in Advanced Hunting"
        if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 255 
                $Writer.Font.Bold = $true
                $Writer.TypeText("[WARNING] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     
                $Writer.TypeText("The rule ")
                $Writer.Font.Italic = $true
                $Writer.Font.Bold = $true
                $Writer.TypeText($ruleName)
                $Writer.Font.Bold = $false
                $Writer.Font.Italic = $false
                $Writer.TypeText("doesn't generate incidents. The alerts aren't visible in the Defender portal. They appear in SecurityAlerts table in Advanced Hunting")
                $Writer.TypeParagraph()
    }
    }else{
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The rule $ruleName is configured correctly"
        $passedControlsTemp++
        $totalPassedControls++
        if ($PSBoundParameters.ContainsKey('FileName')) {
            $Writer.Font.Color = 5287936
            $Writer.Font.Bold = $true
            $Writer.TypeText("[OK] ")
            $Writer.Font.Bold = $false
            $Writer.Font.Color = 0
            $Writer.TypeText("The rule ")
            $Writer.Font.Italic = $true
            $Writer.Font.Bold = $true
            $Writer.TypeText($ruleName)
            $Writer.Font.Italic = $false
            $Writer.Font.Bold = $false
            $Writer.TypeText(" is configured correctly")
            $Writer.TypeParagraph()
    }
    }
}
# Show score for this section
$scorePercent = [math]::Round(($passedControlsTemp / $totalControlsTemp) * 100, 2)
Write-Host "Analytics Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)" -ForegroundColor Cyan
if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.Font.Color = 0
    $Writer.Font.Bold = $true
    $Writer.TypeText("Analytics Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)")
    $Writer.Font.Bold = $false
    $Writer.Font.Color = 0
    $Writer.TypeParagraph()
}
Write-Host ""




Write-Host ""
Write-Host "***********************"
Write-Host "AUTOMATION RULES ANALYSIS"
Write-Host "***********************"
$passedControlsTemp = 0
$totalControlsTemp = 0
if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.InsertBreak(7) 
    $Writer.TypeParagraph()
    $Writer.Style = 'Heading 2'
    $Writer.TypeText("AUTOMATION RULES ANALYSIS")
    $Writer.TypeParagraph()
    $Writer.Style = 'Normal'
}

$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/automationRules?api-version=$apiVersion"

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Bearer $accessToken"
    ContentType = "application/json"
}

# Iterate through automation rules
foreach ($rule in $response.value) {
    $totalControls++
    $totalControlsTemp++
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
            if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 255 
                $Writer.Font.Bold = $true
                $Writer.TypeText("[WARNING] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     
                $Writer.TypeText("Change the trigger condition in the automation rule ")
                $Writer.Font.Italic = $true
                $Writer.Font.Bold = $true
                $Writer.TypeText($ruleName)
                $Writer.Font.Bold = $false
                $Writer.Font.Italic = $false
                $Writer.TypeText(" from ")
                $Writer.Font.Italic = $true
                $Writer.TypeText("Incident Title")
                $Writer.Font.Italic = $false
                $Writer.TypeText(" to ")
                $Writer.Font.Italic = $true
                $Writer.TypeText("Analytics Rule Name")
                $Writer.Font.Italic = $false
                $Writer.TypeParagraph()
    }
    }
    if($incidentProvider){
        Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline; Write-Host " Change the trigger condition in the automation rule $ruleName from `"Incident Provider`" to `"Alert Product Name`""
        if ($PSBoundParameters.ContainsKey('FileName')) {
                $Writer.Font.Color = 255 
                $Writer.Font.Bold = $true
                $Writer.TypeText("[WARNING] ")
                $Writer.Font.Bold = $false
                $Writer.Font.Color = 0     
                $Writer.TypeText("Change the trigger condition in the automation rule ")
                $Writer.Font.Italic = $true
                $Writer.Font.Bold = $true
                $Writer.TypeText($ruleName)
                $Writer.Font.Italic = $false
                $Writer.Font.Bold = $false
                $Writer.TypeText(" to ")
                $Writer.Font.Italic = $true
                $Writer.TypeText("Alert Product Name")
                $Writer.Font.Italic = $false
                $Writer.TypeParagraph()
    }
    }
    if(!$incidentProvider -and !$incidentTitle){
        Write-Host "[OK]" -ForegroundColor Green -NoNewline; Write-Host " The automation rule $ruleName is configured correctly"
        $passedControlsTemp++
        $totalPassedControls++
        if ($PSBoundParameters.ContainsKey('FileName')) {
            $Writer.Font.Color = 5287936
            $Writer.Font.Bold = $true
            $Writer.TypeText("[OK] ")
            $Writer.Font.Bold = $false
            $Writer.Font.Color = 0
            $Writer.TypeText("The automation rule ")
            $Writer.Font.Italic = $true
            $Writer.Font.Bold = $true
            $Writer.TypeText($ruleName)
            $Writer.Font.Italic = $false
            $Writer.Font.Bold = $false
            $Writer.TypeText(" is configured correctly")
            $Writer.TypeParagraph()
    }
    }
}
# Show score for this section
$scorePercent = [math]::Round(($passedControlsTemp / $totalControlsTemp) * 100, 2)
Write-Host "Automation Rule Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)" -ForegroundColor Cyan
if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.Font.Color = 0
    $Writer.Font.Bold = $true
    $Writer.TypeText("Automation Rule Analysis Score: $passedControlsTemp/$totalControlsTemp ($scorePercent%)")
    $Writer.Font.Bold = $false
    $Writer.Font.Color = 0
    $Writer.TypeParagraph()
}
Write-Host ""


Write-Host ""
Write-Host "***********************"
Write-Host "FINAL SCORE"
Write-Host "***********************"
Write-Host "Total number of Controls : $totalControls"
Write-Host "Total number of Passed Controls : $totalPassedControls"
Write-Host "Total number of Not Passed Controls : $($totalControls - $totalPassedControls)"
$scorePercent = [math]::Round(($totalPassedControls / $totalControls) * 100, 2)
Write-Host "Final Score: $totalPassedControls/$totalControls ($scorePercent%)" -ForegroundColor Cyan

if ($PSBoundParameters.ContainsKey('FileName')) {
    $Writer.InsertBreak(7) 
    $Writer.TypeParagraph()
    $Writer.Style = 'Heading 2'
    $Writer.TypeText("FINAL SCORE")
    $Writer.TypeParagraph()
    $Writer.Style = 'Normal'
    $Writer.Font.Bold = $true
    $Writer.TypeText("Total number of Controls : ")
    $Writer.Font.Bold = $false
    $Writer.TypeText("$totalControls")
    $Writer.TypeParagraph()
    $Writer.Font.Bold = $true
    $Writer.TypeText("Total number of Passed Controls : ")
    $Writer.Font.Bold = $false
    $Writer.TypeText("$totalPassedControls")
    $Writer.TypeParagraph()
    $Writer.Font.Bold = $true
    $Writer.TypeText("Total number of Not Passed Controls : ")
    $Writer.Font.Bold = $false
    $Writer.TypeText("$($totalControls - $totalPassedControls)")
    $Writer.TypeParagraph()
    $Writer.Font.Bold = $true
    $Writer.TypeText("Final Score: ")
    $Writer.Font.Bold = $false
    $Writer.TypeText("$totalPassedControls/$totalControls ($scorePercent%)")
    $Writer.TypeParagraph()

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Add()
    $sheet = $workbook.Sheets.Item(1)

    # Sample data
    $sheet.Cells.Item(1,1).Value2 = "Controls"
    $sheet.Cells.Item(1,2).Value2 = "Values"
    $sheet.Cells.Item(2,1).Value2 = "Passed Controls"
    $sheet.Cells.Item(2,2).Value2 = $totalPassedControls
    $sheet.Cells.Item(3,1).Value2 = "Not Passed Controls"
    $sheet.Cells.Item(3,2).Value2 = $totalControls - $totalPassedControls

    $chart = $sheet.Shapes.AddChart2(251,5,$sheet.Cells.Item(5,1).Left, $sheet.Cells.Item(5,1).Top, 400, 300).Chart
    $chart.SetSourceData($sheet.Range("A1:B3"))
    $chart.ChartTitle.Text = "Final Score Distribution"
    $chart.ApplyDataLabels()
    foreach ($point in $chart.SeriesCollection(1).Points()) {
        $point.DataLabel.Font.Color = 0x000000
        $point.DataLabel.Font.Size = 14

    }

    $chart.ChartArea.Format.Line.Visible = 0 
    $chart.SeriesCollection(1).Points(1).Format.Fill.ForeColor.RGB = 0x0000FF00  # Green
    $chart.SeriesCollection(1).Points(2).Format.Fill.ForeColor.RGB = 0x000000FF  # Red

    $chart.ChartArea.Copy()

    # Paste chart into Word
    $Writer.TypeParagraph()
    $Writer.Paste()

}




##SAVE FILE
if ($PSBoundParameters.ContainsKey('FileName')) {
    Write-Host ""
    Write-Host "***********************"
    Write-Host "SAVING THE REPORT"
    Write-Host "***********************"
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptDir = Split-Path $scriptPath
    $finalName = $FileName
    if (-not $finalName.ToLower().EndsWith('.pdf')) {
        $finalName = "$finalName.pdf"
    }
    $savePath = Join-Path $scriptDir $finalName

    try {
        $wdFormatPDF = 17
        $Document.SaveAs2([string]$savePath, [ref]$wdFormatPDF)
        Write-Host "Report generated on " (Get-Date -Format "yyyy-MM-dd")
    }
    finally {
        $WordApplication.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Document) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WordApplication) | Out-Null

        exit
    }
}
