# Import the required modules
Import-Module ActiveDirectory

# Define a function to rerun the script when necessary
function RunScriptAgain {
    $response = Read-Host "Do you want to create another user? (Y/N)"
    if ($response -in 'Y','y') {
        Clear-Host
        & "$PSCommandPath"  # Run the script again
    } else {
        Write-Host "Exiting the script..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        exit
    }
}

# Function to add the user to selected groups
function AddUserToGroups {
    param (
        [string]$username,
        [array]$groupList,
        [object]$newUser
    )

    Write-Host "`nChoose the groups the user should be added to:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $groupList.Count; $i++) {
        Write-Host "$($i+1). $($groupList[$i])" -ForegroundColor Yellow
    }

    $selectedGroups = Read-Host "`nEnter the numbers of the groups to add the user to (separated by spaces or commas)"
    $selectedGroups = $selectedGroups -split ",|\s" | Where-Object { $_ -match '\d+' }

    # Check if all selected groups exist
    $validGroups = @()
    foreach ($index in $selectedGroups) {
        if ($index -ge 1 -and $index -le $groupList.Count) {
            $validGroups += $groupList[$index - 1]
        } else {
            Write-Host "Error: Group with number $index does not exist." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

    if ($validGroups.Count -eq 0) {
        Write-Host "No valid groups selected. Try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        AddUserToGroups -username $username -groupList $groupList -newUser $newUser
        return
    }

    # Add the user to the selected groups
    $addedGroups = @()
    foreach ($selectedGroup in $validGroups) {
        Add-ADGroupMember -Identity $selectedGroup -Members $newUser
        $addedGroups += $selectedGroup
    }

    # Display added groups
    Clear-Host
    if ($addedGroups) {
        Write-Host "User has been added to the following groups:`n" -ForegroundColor Cyan
        foreach ($group in $addedGroups) {
            Write-Host "- $group" -ForegroundColor Yellow
        }
    }

    return $addedGroups  # Return the added groups
    Start-Sleep -Seconds 2
}

# Default password
$defaultPassword = "DefaultPassword123!"

# Get user details
Clear-Host
$firstname = Read-Host "Enter the first name"
$lastname = Read-Host "Enter the last name"

# Add a short delay to prevent color glitches
Start-Sleep -Seconds 1

# Generate the username
$username = "$firstname.$lastname"

# Check if the username length exceeds the maximum limit
$maxUsernameLength = 20
if ($username.Length -gt $maxUsernameLength) {
    Write-Host "The combination of first name and last name results in a username that is too long." -ForegroundColor Red
    Write-Host "The script will fail here, as it exceeds the maximum username limit of Active Directory." -ForegroundColor Red
    Write-Host "Alternatively, you can create this user manually and then assign a different, shorter username." -ForegroundColor Red
    exit
}

# Create the user and store the output in a variable
$newUser = New-ADUser -Name $username -GivenName $firstname -Surname $lastname -AccountPassword (ConvertTo-SecureString -AsPlainText $defaultPassword -Force) -PassThru -Enabled $true

# Set the User Principal Name (UPN) equal to the username
Set-ADUser -Identity $username -UserPrincipalName "$username@orcsnest.local"

# Get the OU where the user should be stored via a GUI
$selectedOU = Get-ADOrganizationalUnit -Filter * | Out-GridView -Title "Select an OU for the user" -PassThru

if (-not $selectedOU) {
    Write-Host "The script has been aborted because no OU was selected to store the new user." -ForegroundColor Red
    exit
}

Write-Host "User will be stored in $selectedOU."

# Move the user to the selected OU
Move-ADObject -Identity $newUser.DistinguishedName -TargetPath $selectedOU.DistinguishedName

# Get the current groups and put them into a list
$groupList = Get-ADGroup -Filter *

# Add the user to the selected groups
$addedGroups = AddUserToGroups -username $username -groupList $groupList -newUser $newUser

# Display user and groups
Clear-Host
Start-Sleep -Seconds 1
if ($addedGroups) {
    Write-Host "User '$username' has been created with the following attributes:`n" -ForegroundColor Cyan
    Write-Host "First Name: $firstname" -ForegroundColor Yellow
    Write-Host "Last Name: $lastname" -ForegroundColor Yellow
    Write-Host "Username: $username" -ForegroundColor Yellow
    Write-Host "User Principal Name (UPN): $username@orcsnest.local" -ForegroundColor Yellow
    Write-Host "Location: $selectedOU`n" -ForegroundColor Yellow
    Write-Host "Groups:`n" -ForegroundColor Cyan
    foreach ($group in $addedGroups) {
        Write-Host "- $group" -ForegroundColor Yellow
    }
}

Write-Host "`nThe default password for this user is: $defaultPassword" -ForegroundColor Cyan

# Hide and clear the password from memory
$defaultPassword = $null
Write-Host ""
Write-Host ""
Write-Host "The script has completed." -ForegroundColor Green
# Run the function to decide whether the script should be rerun
RunScriptAgain
