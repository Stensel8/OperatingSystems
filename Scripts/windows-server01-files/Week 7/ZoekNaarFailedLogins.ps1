########################################################################################
# © Sten Tijhuis - 550600
# ZoekNaarFailedLogins.ps1
########################################################################################

# Starttijd bepalen (1 week geleden)
$startTime = (Get-Date).AddDays(-7)

# Zoeken naar mislukte toegangspogingen in het auditlogbestand van de afgelopen week
Write-Host "Mislukte toegangspogingen in de afgelopen week:"

# PowerShell zoekt standaard in het Security logbestand
$failedAccessEvents = Get-WinEvent -LogName Security -FilterXPath "*[System[TimeCreated >= $startTime]] and EventData[Data[@Name='AccessMask'] and Data[@Name='AccessList'] and Data[@Name='ObjectServer'] and Data[@Name='ObjectType'] and Data[@Name='ObjectName'] and Data[@Name='HandleID'] and Data[@Name='ProcessID'] and Data[@Name='ProcessName'] and Data[@Name='SubjectDomainName'] and Data[@Name='SubjectLogonId'] and Data[@Name='SubjectUserName'] and Data[@Name='SubjectUserSid'] and Data[@Name='ObjectServer'] and Data[@Name='ObjectType'] and Data[@Name='ObjectName'] and Data[@Name='HandleID'] and Data[@Name='AccessMask'] and Data[@Name='AccessList']]]" | Select-Object -ExpandProperty TimeCreated, Message

# Doorloop de gebeurtenissen en haal de relevante informatie op
foreach ($Event in $failedAccessEvents) {
    Write-Host "Datum/Tijd: $($Event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss"))"
    Write-Host "Bericht:     $($Event.Message)"
    Write-Host "-------------------------------------------------------"
}
