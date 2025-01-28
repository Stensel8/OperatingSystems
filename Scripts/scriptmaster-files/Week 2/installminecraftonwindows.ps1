Add-Type -AssemblyName PresentationFramework

# Function to display a popup message with colored buttons
function Show-Popup {
    param(
        [string] $Message,
        [string] $Title = "Minecraft Installation",
        [string] $Buttons = "YesNo",
        [string] $Icon = "Question"
    )
    $buttonResult = [System.Windows.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
    $buttonResult
}

# Define mods folder path
$modsFolder = Join-Path $env:APPDATA ".minecraft\mods"

# Function to open the default web browser with the OptiFine download link
function Open-OptiFineDownloadLink {
    $optiFineDownloadUrl = "https://optifine.net/downloads"
    Write-Host "Opening OptiFine download link in the default web browser..." -ForegroundColor Cyan
    Start-Process $optiFineDownloadUrl
}

# Function to download OptiFine using BitsTransfer and move it to the Minecraft mods folder
function Install-OptiFine {
    # Open the OptiFine download link in the default web browser
    Open-OptiFineDownloadLink

    # Notify the user to manually download and install OptiFine
    Show-Popup "Please download OptiFine from the opened webpage and manually install it into the Minecraft mods folder at: $modsFolder and then doubleclick to execute it. Make sure to select OptiFine via the Minecraft Launcher after installation." "OptiFine Installation" "OK" "Information"
    $choiceMinecraft = Show-Popup "Head over to the Microsoft Store to download Minecraft?" "Minecraft Installation" "YesNo" "Question"

}

# Display the popup message to ask about installing Minecraft
$choiceMinecraft = Show-Popup "Do you want to install Minecraft? This will open the Microsoft Store, as scripted Minecraft installers are not supported by Microsoft."

# Check the user's choice regarding Minecraft installation
if ($choiceMinecraft -eq "Yes") {
    # Display the popup message to ask about installing OptiFine
    $choiceOptiFine = Show-Popup "Do you want to install the OptiFine plugin for Minecraft?"

    if ($choiceOptiFine -eq "Yes") {
        # Open the default web browser to download OptiFine
        Install-OptiFine
    } else {
        # Ask the user again if they want to go to the Microsoft Store
        $secondChoiceMinecraft = Show-Popup "Do you want to go to the Microsoft Store to download Minecraft?" "Minecraft Installation" "YesNo" "Question"
        if ($secondChoiceMinecraft -eq "Yes") {
            # Open Microsoft Store for Minecraft installation
            Start-Process ms-windows-store://pdp/?ProductId=9PGW18NPBZV5
        } else {
            Write-Host "User chooses not to go to the Microsoft Store. Exiting..." -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host "User chooses not to install Minecraft. Exiting..." -ForegroundColor Red
}
