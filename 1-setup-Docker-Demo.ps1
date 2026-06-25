<#
.SYNOPSIS
    Docker Demo Setup Script - Creates and runs a simple Docker container demo
.DESCRIPTION
    This script guides you step-by-step through setting up Docker and running your first container.
    It checks your environment, installs Docker if needed, creates files, and runs a web server.
    All explanations are displayed in the terminal - perfect for beginners!
.NOTES
    Author: DevOps Demo
    Version: 1.0
    Filename: Setup-Docker-Demo.ps1
    Requirements: PowerShell 5.1+, Internet connection, Windows 10/11
.EXAMPLE
    .\Setup-Docker-Demo.ps1
#>

# ============================================
# 1. CONFIGURATION
# ============================================

# Color definitions for terminal output
$script:colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Prompt = "Magenta"
    Explanation = "Gray"
    Menu = "DarkGray"
}

# ============================================
# 2. HELPER FUNCTIONS
# ============================================

function Write-Step {
    param(
        [string]$Message,
        [string]$StepNumber
    )
    Write-Host ""
    Write-Host ("-" * 70) -ForegroundColor $script:colors.Menu
    Write-Host "[$StepNumber] $Message" -ForegroundColor $script:colors.Header
    Write-Host ("-" * 70) -ForegroundColor $script:colors.Menu
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor $script:colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $script:colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $script:colors.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $script:colors.Info
}

function Write-Explanation {
    param([string]$Message)
    Write-Host ""
    Write-Host "EXPLANATION:" -ForegroundColor $script:colors.Prompt
    Write-Host "   $Message" -ForegroundColor $script:colors.Explanation
    Write-Host ""
}

function Write-Separator {
    Write-Host ("=" * 70) -ForegroundColor $script:colors.Menu
}

function Write-Menu {
    param(
        [string]$Title,
        [array]$Options
    )
    Write-Host ""
    Write-Host "MENU: $Title" -ForegroundColor $script:colors.Header
    Write-Host ("-" * 50) -ForegroundColor $script:colors.Menu
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "   [$($i+1)] $($Options[$i])" -ForegroundColor $script:colors.Info
    }
    Write-Host ("-" * 50) -ForegroundColor $script:colors.Menu
}

function Get-UserChoice {
    param(
        [string]$Prompt,
        [array]$ValidOptions
    )
    do {
        $choice = Read-Host $Prompt
        if ($choice -in $ValidOptions) {
            return $choice
        }
        Write-Warning "Invalid choice. Select: $($ValidOptions -join ', ')"
    } while ($true)
}

function Test-CommandAvailable {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ============================================
# 3. MAIN MENU
# ============================================

function Show-MainMenu {
    Clear-Host
    Write-Separator
    Write-Host "     DOCKER DEMO - Container Setup" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""
    Write-Info "This script guides you through setting up Docker and running your first container."
    Write-Info "Everything is created in this folder."
    Write-Host ""
    Write-Info "You will:"
    Write-Info "  1. Check your development environment"
    Write-Info "  2. Install Docker (if needed)"
    Write-Info "  3. Create a simple web application"
    Write-Info "  4. Build a Docker image"
    Write-Info "  5. Run a container with your web app"
    Write-Host ""
    Write-Warning "This script requires an internet connection."
    Write-Warning "Docker Desktop requires Windows 10/11 Pro, Enterprise, or Education."
    Write-Host ""
    
    $startChoice = Read-Host "Do you want to continue? (y/n)"
    if ($startChoice -ne 'y') {
        Write-Info "Exiting script."
        exit
    }
}

# ============================================
# 4. ENVIRONMENT CHECK
# ============================================

function Check-Environment {
    Write-Step -Message "Checking development environment" -StepNumber "1"
    
    # Check PowerShell version
    Write-Info "Checking PowerShell version..."
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -lt 5) {
        Write-Warning "PowerShell version $psVersion is old. Some features may be limited."
        Write-Explanation "This script works best with PowerShell 5.1 or later."
    } else {
        Write-Success "PowerShell version $psVersion is installed."
    }
    
    # Check if running as administrator (recommended)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Running without administrator privileges."
        Write-Explanation "Docker installation requires admin rights. If Docker is not installed, you will need to run as Administrator."
    } else {
        Write-Success "Running with administrator privileges."
    }
    
    # Check path - no special characters
    Write-Info "Checking current path..."
    $currentPath = Get-Location
    $pathString = $currentPath.Path
    
    $specialChars = [regex]::Matches($pathString, '[^a-zA-Z0-9\\\-_.: ]')
    if ($specialChars.Count -gt 0) {
        Write-Warning "Path contains special characters."
        Write-Explanation "This may cause issues with some tools. Current path: $pathString"
        $choice = Read-Host "Do you want to continue with this path? (y/n)"
        if ($choice -ne 'y') {
            Write-Error "Create a new folder without special characters and run the script again."
            exit
        }
    } else {
        Write-Success "Path contains only standard characters."
    }
    
    if ($pathString.Length -gt 100) {
        Write-Warning "Path is long ($($pathString.Length) characters)."
        Write-Explanation "Try using a shorter path if you encounter issues."
    }
    
    # Check internet connection
    Write-Info "Checking internet connection..."
    try {
        $ping = Test-Connection -ComputerName "hub.docker.com" -Count 1 -Quiet -ErrorAction Stop
        if ($ping) {
            Write-Success "Internet connection OK."
        } else {
            Write-Error "Cannot reach hub.docker.com."
            Write-Explanation "You need internet access to pull Docker images."
            exit
        }
    } catch {
        Write-Error "Could not check internet connection."
        Write-Explanation "Please check your network connection and try again."
        exit
    }
    
    # Check Windows version (Docker Desktop requires Windows 10/11)
    Write-Info "Checking Windows version..."
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $osVersion = $osInfo.Version
        $osName = $osInfo.Caption
        
        if ($osVersion -match '10\.0') {
            Write-Success "Windows 10/11 detected: $osName"
        } else {
            Write-Warning "Windows version may not be fully compatible with Docker Desktop."
            Write-Explanation "Docker Desktop requires Windows 10/11 Pro, Enterprise, or Education."
            Write-Explanation "Your OS: $osName"
        }
    } catch {
        Write-Warning "Could not determine Windows version."
    }
    
    # Check system resources (RAM, CPU)
    Write-Info "Checking system resources..."
    try {
        $ram = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
        $ramGB = [math]::Round($ram / 1GB, 2)
        
        if ($ramGB -ge 4) {
            Write-Success "RAM: $ramGB GB (sufficient for Docker)"
        } else {
            Write-Warning "RAM: $ramGB GB (Docker recommends at least 4 GB)"
            Write-Explanation "Docker may run slowly with less than 4 GB of RAM."
        }
    } catch {
        Write-Warning "Could not determine system RAM."
    }
    
    # Check for WSL2 (required for Docker Desktop on Windows)
    Write-Info "Checking for WSL2..."
    try {
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL2 is installed."
        } else {
            Write-Warning "WSL2 is not installed or not detected."
            Write-Explanation "Docker Desktop on Windows requires WSL2."
            Write-Explanation "You can install WSL2 with: wsl --install"
            Write-Explanation "Or download from: https://learn.microsoft.com/en-us/windows/wsl/install"
        }
    } catch {
        Write-Warning "Could not check WSL2 status."
    }
}

# ============================================
# 5. DOCKER CHECK AND INSTALLATION
# ============================================

function Check-Docker {
    Write-Step -Message "Checking Docker installation" -StepNumber "2"
    
    Write-Info "Checking if Docker is installed..."
    
    # Check Docker version
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is installed: $dockerVersion"
            Write-Explanation "Docker is ready to use on your system."
            return $true
        } else {
            throw "Docker not found"
        }
    } catch {
        Write-Warning "Docker is not installed or not in PATH."
        Write-Explanation "Docker is required to build and run containers."
        return $false
    }
}

function Install-Docker {
    Write-Step -Message "Installing Docker" -StepNumber "3"
    
    Write-Info "Docker is required for this demo."
    Write-Explanation "Docker Desktop is the recommended way to run Docker on Windows."
    Write-Host ""
    
    Write-Menu -Title "Select installation method" -Options @(
        "Download and install Docker Desktop automatically",
        "Open Docker download page in browser (manual install)",
        "Skip Docker installation (I will install it myself)"
    )
    
    $installChoice = Get-UserChoice -Prompt "Select option (1-3)" -ValidOptions @("1", "2", "3")
    
    switch ($installChoice) {
        "1" {
            Write-Info "Attempting automatic Docker Desktop installation..."
            Write-Explanation "This requires administrator privileges and will download ~500 MB."
            Write-Host ""
            
            # Check if running as admin
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            if (-not $isAdmin) {
                Write-Error "Administrator privileges required for automatic installation."
                Write-Explanation "Please restart PowerShell as Administrator and run this script again."
                Write-Info "Or select option 2 to install manually."
                return $false
            }
            
            $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
            
            Write-Info "Downloading Docker Desktop installer..."
            Write-Explanation "This may take a few minutes depending on your internet speed."
            
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
                Write-Success "Docker Desktop installer downloaded."
            } catch {
                Write-Error "Failed to download Docker Desktop installer."
                Write-Explanation "Please install Docker manually from: https://www.docker.com/products/docker-desktop/"
                return $false
            }
            
            Write-Info "Running Docker Desktop installer..."
            Write-Explanation "The installer will run in the background. Please follow any on-screen prompts."
            Write-Explanation "IMPORTANT: Make sure 'Use WSL 2 instead of Hyper-V' is checked during installation."
            Write-Host ""
            
            Start-Process -FilePath $installerPath -ArgumentList "install" -Wait
            
            Write-Success "Docker Desktop installation completed."
            Write-Explanation "Docker Desktop may need to be restarted. Please wait a moment."
            
            # Wait a moment for Docker to initialize
            Write-Info "Waiting for Docker to initialize (30 seconds)..."
            Start-Sleep -Seconds 30
            
            # Check if Docker is now available
            try {
                $dockerVersion = docker --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Docker is now installed: $dockerVersion"
                    return $true
                } else {
                    Write-Warning "Docker installation completed but Docker is not responding."
                    Write-Explanation "Please restart your computer and try running this script again."
                    Write-Explanation "After restart, Docker Desktop should start automatically."
                    return $false
                }
            } catch {
                Write-Warning "Docker installation completed but could not verify."
                Write-Explanation "Please restart your computer and try running this script again."
                return $false
            }
        }
        "2" {
            Write-Info "Opening Docker download page in your browser..."
            Write-Explanation "Download and install Docker Desktop from:"
            Write-Host ""
            Write-Host "   https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
            Write-Host ""
            Write-Explanation "After installation:"
            Write-Explanation "  1. Start Docker Desktop"
            Write-Explanation "  2. Make sure 'Use WSL 2 instead of Hyper-V' is checked"
            Write-Explanation "  3. Wait for Docker to start (whale icon in system tray should be green)"
            Write-Explanation "  4. Restart this script"
            Write-Host ""
            
            Start-Process "https://www.docker.com/products/docker-desktop/"
            Read-Host "Press Enter after you have installed Docker"
            
            # Verify Docker is now installed
            try {
                $dockerVersion = docker --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Docker is now installed: $dockerVersion"
                    return $true
                } else {
                    Write-Warning "Docker still not found."
                    Write-Explanation "Please make sure Docker Desktop is running."
                    Write-Explanation "Look for the whale icon in your system tray."
                    return $false
                }
            } catch {
                Write-Warning "Docker not found after installation."
                return $false
            }
        }
        "3" {
            Write-Info "Skipping Docker installation."
            Write-Explanation "You must install Docker manually before continuing."
            Write-Explanation "Download from: https://www.docker.com/products/docker-desktop/"
            return $false
        }
    }
}

# ============================================
# 6. VERIFY DOCKER IS WORKING
# ============================================

function Verify-Docker {
    Write-Step -Message "Verifying Docker is working" -StepNumber "4"
    
    Write-Info "Testing Docker with hello-world container..."
    Write-Explanation "This will pull the hello-world image and run a test container."
    Write-Explanation "If this works, Docker is correctly installed and configured."
    Write-Host ""
    
    # Check if Docker daemon is running
    try {
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Docker daemon is not running."
            Write-Explanation "Please start Docker Desktop and wait for the whale icon to turn green."
            Write-Explanation "Docker Desktop is usually located in the system tray (bottom-right corner)."
            Write-Host ""
            
            $choice = Read-Host "Do you want to try starting Docker Desktop? (y/n)"
            if ($choice -eq 'y') {
                $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
                if (Test-Path $dockerPath) {
                    Start-Process $dockerPath
                    Write-Info "Starting Docker Desktop... Please wait 30 seconds."
                    Start-Sleep -Seconds 30
                } else {
                    Write-Warning "Could not find Docker Desktop at: $dockerPath"
                }
            }
        }
    } catch {
        Write-Warning "Could not check Docker daemon status."
    }
    
    # Run hello-world test
    try {
        docker run hello-world
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is working correctly!"
            Write-Explanation "Docker can pull images and run containers."
            return $true
        } else {
            Write-Error "Docker test failed."
            Write-Explanation "Possible issues:"
            Write-Explanation "  1. Docker Desktop is not running"
            Write-Explanation "  2. Docker Desktop needs to be restarted"
            Write-Explanation "  3. WSL2 is not installed or configured"
            Write-Explanation "  4. Internet connection is blocked"
            Write-Host ""
            Write-Info "Try restarting Docker Desktop and your computer."
            return $false
        }
    } catch {
        Write-Error "Docker test failed with error."
        return $false
    }
}

# ============================================
# 7. CREATE FILES
# ============================================

function Create-Files {
    Write-Step -Message "Creating application files" -StepNumber "5"
    
    Write-Info "Creating the following files:"
    Write-Host "   Dockerfile - Instructions for building the container" -ForegroundColor Gray
    Write-Host "   index.html - A simple web page" -ForegroundColor Gray
    Write-Host ""
    Write-Explanation "The Dockerfile defines how to build your container. The HTML file is your web application."
    Write-Host ""
    
    # Create Dockerfile
    $dockerfileContent = @'
# Use nginx web server as base image
FROM nginx:alpine

# Copy our HTML file to the web server
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 (web server port)
EXPOSE 80
'@
    $dockerfileContent | Out-File -FilePath ".\Dockerfile" -Encoding utf8
    Write-Success "Dockerfile created"
    
    # Create index.html
    $htmlContent = @'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f0f4f8;
            text-align: center;
        }
        h1 {
            color: #0366d6;
        }
        .badge {
            background: #28a745;
            color: white;
            padding: 10px 20px;
            border-radius: 5px;
            display: inline-block;
            margin: 20px 0;
        }
        .container-info {
            background: #e6e6e6;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Hello from Docker!</h1>
    <div class="badge">Container is Running</div>
    <div class="container-info">
        <p>This web page is served from a Docker container.</p>
        <p><small>Web server: nginx (alpine)</small></p>
    </div>
    <p>Built with Docker Desktop!</p>
</body>
</html>
'@
    $htmlContent | Out-File -FilePath ".\index.html" -Encoding utf8
    Write-Success "index.html created"
    
    Write-Explanation "You now have a Dockerfile and a web page."
    Write-Explanation "The Dockerfile uses the official nginx image and copies your HTML file into it."
    Write-Host ""
}

# ============================================
# 8. BUILD AND RUN DOCKER CONTAINER
# ============================================

function Build-And-Run {
    Write-Step -Message "Building and running Docker container" -StepNumber "6"
    
    Write-Info "Building Docker image..."
    Write-Explanation "`docker build` creates a Docker image from your Dockerfile."
    Write-Explanation "The -t flag gives the image a name (tag)."
    Write-Host ""
    
    # Build the image
    docker build -t min-webbserver .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Docker image built successfully!"
    } else {
        Write-Error "Docker build failed."
        Write-Explanation "Please check the error messages above."
        return $false
    }
    
    Write-Info "Listing available Docker images..."
    docker images
    Write-Host ""
    
    Write-Info "Running Docker container..."
    Write-Explanation "`docker run` starts a container from your image."
    Write-Explanation "The -d flag runs it in the background (detached mode)."
    Write-Explanation "The -p flag maps port 8080 on your computer to port 80 in the container."
    Write-Explanation "The --name flag gives the container a name."
    Write-Host ""
    
    # Remove any existing container with the same name
    docker rm -f min-server 2>$null
    
    # Run the container
    docker run -d -p 8080:80 --name min-server min-webbserver
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Container is running!"
        Write-Explanation "Your web server is now running in a Docker container."
        Write-Host ""
        
        # Show container status
        Write-Info "Container status:"
        docker ps --filter "name=min-server"
        Write-Host ""
        
        return $true
    } else {
        Write-Error "Failed to run container."
        Write-Explanation "Please check the error messages above."
        return $false
    }
}

# ============================================
# 9. TEST AND OPEN WEB PAGE
# ============================================

function Test-And-Open {
    Write-Step -Message "Testing the web application" -StepNumber "7"
    
    Write-Info "Testing the web server..."
    Write-Explanation "We will test if the web server is responding correctly."
    Write-Host ""
    
    # Test the web server using curl
    try {
        $response = curl -s -o nul -w "%{http_code}" http://localhost:8080 2>$null
        if ($response -eq "200") {
            Write-Success "Web server is responding with HTTP 200 OK!"
        } else {
            Write-Warning "Web server responded with status: $response"
        }
    } catch {
        Write-Warning "Could not test web server with curl."
    }
    
    Write-Host ""
    Write-Info "Opening web page in your browser..."
    Write-Explanation "The web page is available at: http://localhost:8080"
    Write-Host ""
    
    # Ask if user wants to open browser
    $openChoice = Read-Host "Do you want to open the web page in your browser? (y/n)"
    if ($openChoice -eq 'y') {
        try {
            Start-Process "http://localhost:8080"
            Write-Success "Web page opened in your browser!"
        } catch {
            Write-Warning "Could not open browser automatically."
            Write-Info "Please open: http://localhost:8080"
        }
    } else {
        Write-Info "You can open the web page later at: http://localhost:8080"
    }
    Write-Host ""
}

# ============================================
# 10. DOCKER MANAGEMENT GUIDE
# ============================================

function Show-DockerGuide {
    Write-Step -Message "Docker management guide" -StepNumber "8"
    
    Write-Info "Useful Docker commands:"
    Write-Host ""
    Write-Host "  docker ps                - Show running containers" -ForegroundColor Gray
    Write-Host "  docker ps -a             - Show all containers (including stopped)" -ForegroundColor Gray
    Write-Host "  docker stop min-server   - Stop the container" -ForegroundColor Gray
    Write-Host "  docker start min-server  - Start the container again" -ForegroundColor Gray
    Write-Host "  docker rm min-server     - Remove the container" -ForegroundColor Gray
    Write-Host "  docker images            - Show all Docker images" -ForegroundColor Gray
    Write-Host "  docker rmi min-webbserver - Remove the image" -ForegroundColor Gray
    Write-Host "  docker logs min-server   - View container logs" -ForegroundColor Gray
    Write-Host ""
    
    Write-Explanation "To stop the container, run: docker stop min-server"
    Write-Explanation "To remove the container, run: docker rm min-server"
    Write-Explanation "To remove the image, run: docker rmi min-webbserver"
    Write-Host ""
    
    Write-Info "Docker Desktop tips:"
    Write-Host "  1. Docker Desktop runs in the background (system tray)" -ForegroundColor Gray
    Write-Host "  2. Look for the whale icon in your system tray" -ForegroundColor Gray
    Write-Host "  3. Green whale = Docker is running" -ForegroundColor Gray
    Write-Host "  4. Orange whale = Docker is starting" -ForegroundColor Gray
    Write-Host "  5. Right-click the whale icon to access Docker Desktop menu" -ForegroundColor Gray
    Write-Host "  6. Docker Desktop MUST be running for containers to work" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# 11. TROUBLESHOOTING
# ============================================

function Show-Troubleshooting {
    param(
        [string]$Issue
    )
    
    Write-Step -Message "Troubleshooting" -StepNumber "9"
    
    Write-Info "Common Docker issues and solutions:"
    Write-Host ""
    
    Write-Host "Issue: Docker is not recognized as a command" -ForegroundColor Yellow
    Write-Host "  Solution: Docker is not in PATH. Restart PowerShell or your computer." -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Issue: Docker daemon is not running" -ForegroundColor Yellow
    Write-Host "  Solution: Start Docker Desktop. Look for the whale icon in system tray." -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Issue: Port 8080 is already in use" -ForegroundColor Yellow
    Write-Host "  Solution: Stop the program using port 8080 or change the port." -ForegroundColor Gray
    Write-Host "  Change port: docker run -d -p 8081:80 --name min-server min-webbserver" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Issue: WSL2 is not installed" -ForegroundColor Yellow
    Write-Host "  Solution: Install WSL2 with: wsl --install" -ForegroundColor Gray
    Write-Host "  Or download from: https://learn.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Issue: Docker Desktop needs to be restarted" -ForegroundColor Yellow
    Write-Host "  Solution: Right-click whale icon -> Restart Docker Desktop" -ForegroundColor Gray
    Write-Host ""
    
    if ($Issue) {
        Write-Host ""
        Write-Info "Specific issue detected: $Issue"
    }
}

# ============================================
# 12. SUMMARY
# ============================================

function Show-Summary {
    param(
        [bool]$DockerRunning
    )
    
    Write-Step -Message "Complete!" -StepNumber "10"
    
    Write-Separator
    Write-Host "     DOCKER DEMO - COMPLETE!" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""
    
    if ($DockerRunning) {
        Write-Info "Your Docker container is running!"
        Write-Host ""
        Write-Info "What was created:"
        Write-Host "   Dockerfile - Instructions for building the container" -ForegroundColor Gray
        Write-Host "   index.html - Your web application" -ForegroundColor Gray
        Write-Host "   Docker image: min-webbserver" -ForegroundColor Gray
        Write-Host "   Docker container: min-server (running)" -ForegroundColor Gray
        Write-Host ""
        Write-Info "Access your web application:"
        Write-Host "   URL: http://localhost:8080" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Warning "Docker container is not running."
        Write-Info "The files have been created but Docker setup failed."
    }
    
    Write-Info "Learning resources:"
    Write-Host "   Docker Documentation: https://docs.docker.com/" -ForegroundColor Gray
    Write-Host "   Docker Desktop: https://www.docker.com/products/docker-desktop/" -ForegroundColor Gray
    Write-Host "   WSL2 Installation: https://learn.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Gray
    Write-Host ""
    
    Write-Separator
    Write-Host "     CONGRATULATIONS! You have used Docker!" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""
}

# ============================================
# 13. MAIN PROGRAM
# ============================================

function Main {
    # Show main menu
    Show-MainMenu
    
    # Check environment
    Check-Environment
    
    # Check Docker
    $dockerInstalled = Check-Docker
    
    if (-not $dockerInstalled) {
        $dockerInstalled = Install-Docker
        if (-not $dockerInstalled) {
            Write-Error "Docker is required for this demo."
            Show-Troubleshooting
            Read-Host "Press Enter to exit"
            exit
        }
    }
    
    # Verify Docker is working
    $dockerWorking = Verify-Docker
    
    if (-not $dockerWorking) {
        Write-Error "Docker is installed but not working correctly."
        Show-Troubleshooting -Issue "Docker verification failed"
        Read-Host "Press Enter to exit"
        exit
    }
    
    # Create files
    Create-Files
    
    # Build and run container
    $buildSuccess = Build-And-Run
    
    if ($buildSuccess) {
        # Test and open web page
        Test-And-Open
        
        # Show Docker management guide
        Show-DockerGuide
        
        Show-Summary -DockerRunning $true
    } else {
        Show-Summary -DockerRunning $false
        Show-Troubleshooting -Issue "Docker build or run failed"
    }
    
    Read-Host "`nPress Enter to exit"
}

# ============================================
# 14. START
# ============================================

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "This script requires PowerShell 3.0 or later."
    exit
}

# Set TLS 1.2 for secure connections
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
} catch {
    # Ignore if cannot set
}

# Run main program
Main