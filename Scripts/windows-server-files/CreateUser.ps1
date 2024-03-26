# Importeer de benodigde modules
Import-Module ActiveDirectory

# Definieer een functie om het script opnieuw uit te voeren wanneer dit nodig is.
function RunScriptAgain {
    $response = Read-Host "Wil je nog een gebruiker aanmaken? (Y/J/Ja om door te gaan)"
    if ($response -in 'Y','y','J','j','Ja','ja') {
        Clear-Host
        & "$PSCommandPath"  # Voer het script opnieuw uit
    } else {
        Write-Host "Het script wordt afgesloten..." -ForegroundColor Cyan
        Start-Sleep -seconds 2
        exit
    }
}

# Functie om de gebruiker aan geselecteerde groepen toe te voegen
function AddUserToGroups {
    param (
        [string]$username,
        [array]$groupList,
        [object]$newUser
    )

    Write-Host "`nKies de groepen waarvan de gebruiker lid moet worden:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $groupList.Count; $i++) {
        Write-Host "$($i+1). $($groupList[$i])" -ForegroundColor Yellow
    }

    $selectedGroups = Read-Host "`nVoer de nummers in van de groepen waarvan de gebruiker lid moet worden (gescheiden door spaties of komma's)"
    $selectedGroups = $selectedGroups -split ",|\s" | Where-Object { $_ -match '\d+' }

    # Controleer of alle geselecteerde groepen bestaan
    $validGroups = @()
    foreach ($index in $selectedGroups) {
        if ($index -ge 1 -and $index -le $groupList.Count) {
            $validGroups += $groupList[$index - 1]
        } else {
            Write-Host "Fout: De groep met nummer $index bestaat niet." -ForegroundColor Red
            Start-Sleep -seconds 2
        }
    }

    if ($validGroups.Count -eq 0) {
        Write-Host "Geen geldige groepen geselecteerd. Probeer opnieuw." -ForegroundColor Red
        Start-Sleep -seconds 2
        AddUserToGroups -username $username -groupList $groupList -newUser $newUser
        return
    }

    # Voeg de gebruiker toe aan de geselecteerde groepen
    $addedGroups = @()
    foreach ($selectedGroup in $validGroups) {
        Add-ADGroupMember -Identity $selectedGroup -Members $newUser
        $addedGroups += $selectedGroup
    }

    # Weergave van toegevoegde groepen
    Clear-Host
    if ($addedGroups) {
        Write-Host "Gebruiker is toegevoegd aan de volgende groepen:`n" -ForegroundColor Cyan
        foreach ($group in $addedGroups) {
            Write-Host "- $group" -ForegroundColor Yellow
        }
    }

    return $addedGroups  # Retourneer de toegevoegde groepen
    Start-Sleep -Seconds 2
}


# Standaardwachtwoord
$defaultPassword = "DefaultPassword123!"

# Vraag gebruikersgegevens op
Clear-Host
$firstname = Read-Host "Voer de voornaam in"
$lastname = Read-Host "Voer de achternaam in"

# Voeg een korte vertraging toe om kleur glitches te voorkomen
Start-Sleep -Seconds 1

# Genereer de gebruikersnaam
$username = "$firstname.$lastname"

# Controleer of de lengte van de gebruikersnaam de maximale limiet overschrijdt
$maxUsernameLength = 20
if ($username.Length -gt $maxUsernameLength) {
    Write-Host "De combinatie van voornaam en achternaam resulteert in een gebruikersnaam die te lang is." -ForegroundColor Red
    Write-Host "Het script zal hierop falen, omdat de maximale gebruikersnaamlimiet van Active Directory wordt overschreden." -ForegroundColor Red
    Write-Host "Als alternatief kunt u deze gebruiker handmatig aanmaken en vervolgens een andere, kortere gebruikersnaam toewijzen." -ForegroundColor Red
    exit
}

# Maak de gebruiker aan en sla de uitvoer op in een variabele
$newUser = New-ADUser -Name $username -GivenName $firstname -Surname $lastname -AccountPassword (ConvertTo-SecureString -AsPlainText $defaultPassword -Force) -PassThru -Enabled $true

# Set de User Principal Name (UPN) gelijk aan de gebruikersnaam
Set-ADUser -Identity $username -UserPrincipalName "$username@orcsnest.local"

# Vraag de OU waar de gebruiker moet worden opgeslagen via een GUI
$selectedOU = Get-ADOrganizationalUnit -Filter * | Out-GridView -Title "Selecteer een OU voor de gebruiker" -PassThru

if (-not $selectedOU) {
    Write-Host "Het script is afgebroken omdat geen OU is geselecteerd om de nieuwe gebruiker in op te slaan." -ForegroundColor Red
    exit
}

Write-Host "Gebruiker zal worden opgeslagen in $selectedOU."

# Verplaats de gebruiker naar de geselecteerde OU
Move-ADObject -Identity $newUser.DistinguishedName -TargetPath $selectedOU.DistinguishedName

# Voeg de gebruiker toe aan de geselecteerde groepen
$addedGroups = AddUserToGroups -username $username -groupList $groupList -newUser $newUser

# Weergave van de gebruiker en de groepen
Clear-Host
Start-Sleep -seconds 1
if ($addedGroups) {
    Write-Host "Gebruiker '$username' is aangemaakt met de volgende attributen:`n" -ForegroundColor Cyan
    Write-Host "Voornaam: $firstname" -ForegroundColor Yellow
    Write-Host "Achternaam: $lastname" -ForegroundColor Yellow
    Write-Host "Gebruikersnaam: $username" -ForegroundColor Yellow
    Write-Host "User Principal Name (UPN): $username@orcsnest.local" -ForegroundColor Yellow
    Write-Host "Locatie: $selectedOU`n" -ForegroundColor Yellow
    Write-Host "Groepen:`n" -ForegroundColor Cyan
    foreach ($group in $addedGroups) {
        Write-Host "- $group" -ForegroundColor Yellow
    }
}

Write-Host "`nHet standaardwachtwoord voor deze gebruiker is: $defaultPassword" -ForegroundColor Cyan

# Maak het wachtwoord onzichtbaar en verwijder het uit het geheugen
$defaultPassword = $null
Write-Host ""
Write-Host ""
Write-Host "Het script is gereed." -ForegroundColor Green
# Voer de functie uit om te beslissen of het script opnieuw moet worden uitgevoerd
RunScriptAgain
