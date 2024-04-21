# Define variables
$sourcePath = "C:\Users\stent\OneDrive - Saxion\Operating Systems\Scripts\scriptmaster-files\"
$destinationPath = "/home/sten/"

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
    Clear-Host
    Write-ColoredOutput "Copying files from $sourcePath to ${hostname}:$destinationPath" -Color Cyan

    # Perform SCP transfer
    scp -r "$sourcePath" "${username}@${hostname}:${destinationPath}"

    # Check if SCP transfer was successful
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput "File transfer complete." -Color Green
    } else {
        throw "SCP transfer failed with exit code: $LASTEXITCODE"
    }
} catch {
    Write-ColoredOutput "Error: $_" -Color Red
}
