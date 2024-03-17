# Define variables
$sourcePath = "/home/sten/scriptmaster-files"
$destinationPath = "C:\Users\stent\OneDrive - Saxion\Operating Systems\Scripts\scriptmaster-files"

$hostname = "192.168.168.10"
$username = "root"

# Function for colored output
function Write-ColoredOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    Write-Host $Message -ForegroundColor $Color
}

try {
    # Display information
    Write-ColoredOutput "Copying files from ${username}@${hostname}:${sourcePath} to $destinationPath" -Color Cyan

    # Perform SCP transfer
    scp -r "${username}@${hostname}:${sourcePath}" "$destinationPath"

    # Check if SCP transfer was successful
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput "File transfer complete." -Color Green
    } else {
        throw "SCP transfer failed with exit code: $LASTEXITCODE"
    }
} catch {
    Write-ColoredOutput "Error: $_" -Color Red
}
