$aadAppId = "850b5f07-c2ad-4c75-9921-54e16e54e54b"        # partner's AAD app id
$aadAppRedirectUri = "http://localhost"                   # partner's AAD app redirect URI
$aadTenantId = "e92a969e-d2c0-4b61-b70d-5a6832856f6d"    # customer's tenant id
Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\AzureAD\2.0.2.140\Microsoft.IdentityModel.Clients.ActiveDirectory.dll" # Install-Module AzureAD to get this

# Get access token
$ctx = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$aadTenantId")
$redirectUri = New-Object -TypeName System.Uri -ArgumentList $aadAppRedirectUri
$platformParameters = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList ([Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)
$accessToken = $ctx.AcquireTokenAsync("https://api.businesscentral.dynamics.com", $aadAppId, $redirectUri, $platformParameters).GetAwaiter().GetResult().AccessToken
Write-Host -ForegroundColor Cyan 'Authentication complete - we have an access token for Business Central, and it is stored in the $accessToken variable.'

#deal with dates
$td = (Get-Date).Date
$Today = $td.Day.ToString()+$td.Month.ToString()+$td.Year.ToString()
$td = (Get-Date).Date.AddDays(-1).Date
$Yesterday = $td.Day.ToString()+$td.Month.ToString()+$td.Year.ToString()

#import telemtry Keith Babinec script
Import-Module C:\_source\AzurePowerShellUtilityFunctions\AzurePowerShellUtilityFunctions.psd1
 
$LogStart = 'Create ProdCopy' + $Today + ' sandbox.'
$AppInsightKey = 'bf7f93fd-72af-4ad1-982d-e738da3454a4'
Send-AppInsightsTraceTelemetry -InstrumentationKey $AppInsightKey -Message $LogStart -Severity Information 

# Delete ProdCopy environment from the previous day and create one for today
$newEnvironmentName = "ProdCopy"+$Yesterday
$response = Invoke-WebRequest `
    -Method Delete `
    -Uri    "https://api.businesscentral.dynamics.com/admin/v2.3/applications/businesscentral/environments/$newEnvironmentName" `
    -Headers @{Authorization=("Bearer $accessToken")}

$LogDeleteSandbox = 'Delete ProdCopy' + $Yesterday + ' sandbox.'
Send-AppInsightsTraceTelemetry -InstrumentationKey $AppInsightKey -Message $LogDeleteSandbox -Severity Information 

$environmentName = "Production"
$newEnvironmentName = "ProdCopy"+$Today
$response = Invoke-WebRequest `
    -Method Post `
    -Uri    "https://api.businesscentral.dynamics.com/admin/v2.3/applications/businesscentral/environments/$environmentName" `
    -Body   (@{
    EnvironmentName = $newEnvironmentName
    Type            = "Sandbox"
    } | ConvertTo-Json) `
    -Headers @{Authorization=("Bearer $accessToken")} `
    -ContentType "application/json"

$LogCreateNewSandbox = 'Create new ProdCopy' + $Today + ' sandbox.'
Send-AppInsightsTraceTelemetry -InstrumentationKey $AppInsightKey -Message $LogCreateNewSandbox -Severity Information 
