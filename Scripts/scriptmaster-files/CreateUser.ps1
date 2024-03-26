# Importeer de benodigde modules
Import-Module ActiveDirectory

# Standaardwachtwoord
$defaultPassword = "DefaultPassword123!"

# Vraag gebruikersgegevens op
Clear-Host
$username = Read-Host "Voer de gebruikersnaam in"
$firstname = Read-Host "Voer de voornaam in"
$lastname = Read-Host "Voer de achternaam in"

# Converteer het wachtwoord naar een SecureString
$securePassword = ConvertTo-SecureString -AsPlainText $defaultPassword -Force

# Maak de gebruiker aan
New-ADUser -Name $username -GivenName $firstname -Surname $lastname -AccountPassword $securePassword -PassThru

# Set de User Principal Name (UPN) gelijk aan de gebruikersnaam
Set-ADUser -Identity $username -UserPrincipalName "$username@orcsnest.local"

# Vraag de groepen waar de gebruiker lid van moet worden
Write-Host "`nKies de groepen waarvan de gebruiker lid moet worden:`n" -ForegroundColor Cyan
$groupList = Get-ADGroup -Filter * | Select-Object -ExpandProperty Name
for ($i = 0; $i -lt $groupList.Count; $i++) {
    Write-Host "$($i+1). $($groupList[$i])" -ForegroundColor Yellow
}
$selectedGroups = Read-Host "Voer de nummers in van de groepen waarvan de gebruiker lid moet worden (gescheiden door komma's)"

# Voeg de gebruiker toe aan de geselecteerde groepen
$addedGroups = @()
foreach ($index in $selectedGroups.Split(",")) {
    $groupIndex = [int]$index - 1
    $selectedGroup = $groupList[$groupIndex]
    Add-ADGroupMember -Identity $selectedGroup -Members $username
    $addedGroups += $selectedGroup
}

# Weergave van de gebruiker en de groepen
Clear-Host
Write-Host "Gebruiker '$username' is aangemaakt met de volgende attributen:`n" -ForegroundColor Cyan
Write-Host "Voornaam: $firstname" -ForegroundColor Yellow
Write-Host "Achternaam: $lastname" -ForegroundColor Yellow
Write-Host "Gebruikersnaam: $username" -ForegroundColor Yellow
Write-Host "User Principal Name (UPN): $username@orcsnest.local`n" -ForegroundColor Yellow
Write-Host "Groepen:" -ForegroundColor Cyan
foreach ($group in $addedGroups) {
    Write-Host "- $group" -ForegroundColor Yellow
}
Write-Host "`nHet standaardwachtwoord voor deze gebruiker is: $defaultPassword" -ForegroundColor Cyan

# Maak het wachtwoord onzichtbaar en verwijder het uit het geheugen
$securePassword.Dispose()
$defaultPassword = $null
