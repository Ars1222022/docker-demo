<#
.SYNOPSIS
    Docker CI/CD Setup Script - Pushes Docker container to GitHub with CI/CD pipeline
.DESCRIPTION
    This script takes your existing Docker container and pushes it to GitHub with a complete CI/CD pipeline.
    It checks your environment, creates GitHub Actions workflow, and helps with GitHub authentication.
    The CI/CD pipeline will automatically build, test, and push your Docker image to Docker Hub.
    All explanations are displayed in the terminal - perfect for beginners!
.NOTES
    Author: DevOps Demo
    Version: 2.0
    Filename: Setup-Docker-CICD.ps1
    Requirements: PowerShell 5.1+, Git, Docker, Internet connection
    Prerequisites: Docker Desktop running, Setup-Docker-Demo.ps1 already run
.EXAMPLE
    .\Setup-Docker-CICD.ps1
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
    Write-Host "     DOCKER CI/CD SETUP - Push to GitHub with Pipeline" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""
    Write-Info "This script takes your Docker container and sets up a complete CI/CD pipeline on GitHub."
    Write-Info "It will:"
    Write-Host ""
    Write-Info "  1. Check your environment (Git, Docker, files)"
    Write-Info "  2. Create a GitHub repository (or use existing)"
    Write-Info "  3. Create GitHub Actions workflow that builds and tests your container"
    Write-Info "  4. Push code to GitHub"
    Write-Info "  5. (Optional) Set up Docker Hub integration for automatic image pushing"
    Write-Host ""
    Write-Warning "This script requires an internet connection."
    Write-Warning "Make sure you have run Setup-Docker-Demo.ps1 first!"
    Write-Warning "Docker Desktop MUST be running."
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
    } else {
        Write-Success "PowerShell version $psVersion is installed."
    }

    # Check if running as administrator (recommended)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Running without administrator privileges."
        Write-Explanation "Some Git operations might require admin rights if you encounter issues."
    } else {
        Write-Success "Running with administrator privileges."
    }

    # Check current folder for Docker files
    Write-Info "Checking for Docker files in current folder..."
    $requiredFiles = @("Dockerfile", "index.html")
    $missingFiles = @()

    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Success "$file found"
        } else {
            Write-Warning "$file not found"
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        Write-Error "Missing required files: $($missingFiles -join ', ')"
        Write-Explanation "Please run Setup-Docker-Demo.ps1 first to create the required files."
        Read-Host "Press Enter to exit"
        exit
    }

    # Check internet connection
    Write-Info "Checking internet connection..."
    try {
        $ping = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction Stop
        if ($ping) {
            Write-Success "Internet connection OK."
        } else {
            Write-Error "Cannot reach github.com."
            Write-Explanation "You need internet access to connect to GitHub."
            exit
        }
    } catch {
        Write-Error "Could not check internet connection."
        Write-Explanation "Please check your network connection and try again."
        exit
    }
}

# ============================================
# 5. GIT CHECK
# ============================================

function Check-Git {
    Write-Step -Message "Checking Git installation" -StepNumber "2"

    Write-Info "Checking if Git is installed..."
    if (Test-CommandAvailable "git") {
        $gitVersion = git --version
        Write-Success "Git is installed: $gitVersion"
        Write-Explanation "Git is used for version control and to push code to GitHub."
    } else {
        Write-Error "Git is not installed."
        Write-Host ""
        Write-Explanation "Git is required to push code to GitHub."
        Write-Host ""
        Write-Info "Install Git from: https://git-scm.com/download/win"
        Write-Host ""
        Write-Info "After installation, restart PowerShell and run the script again."
        Read-Host "Press Enter to exit"
        exit
    }

    # Check Git configuration
    Write-Info "Checking Git configuration..."

    $gitUser = git config --global user.name 2>$null
    $gitEmail = git config --global user.email 2>$null

    if (-not $gitUser) {
        Write-Warning "Git user name is not configured."
        Write-Explanation "Git needs to know who you are to create commits."
        $gitUser = Read-Host "Enter your Git user name (or press Enter to skip)"
        if ($gitUser) {
            git config --global user.name $gitUser
            Write-Success "Git user name saved!"
        }
    } else {
        Write-Success "Git user name: $gitUser"
    }

    if (-not $gitEmail) {
        Write-Warning "Git email is not configured."
        $gitEmail = Read-Host "Enter your email (or press Enter to skip)"
        if ($gitEmail) {
            git config --global user.email $gitEmail
            Write-Success "Git email saved!"
        }
    } else {
        Write-Success "Git email: $gitEmail"
    }
}

# ============================================
# 6. DOCKER CHECK
# ============================================

function Check-Docker {
    Write-Step -Message "Checking Docker installation" -StepNumber "3"

    Write-Info "Checking if Docker is installed and running..."

    # Check Docker version
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is installed: $dockerVersion"
        } else {
            throw "Docker not found"
        }
    } catch {
        Write-Error "Docker is not installed or not in PATH."
        Write-Explanation "Docker is required to build containers."
        Write-Info "Please run Setup-Docker-Demo.ps1 first to install Docker."
        Read-Host "Press Enter to exit"
        exit
    }

    # Check if Docker daemon is running
    Write-Info "Checking if Docker daemon is running..."
    try {
        docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker daemon is running."
        } else {
            Write-Error "Docker daemon is not running."
            Write-Explanation "Please start Docker Desktop and wait for the whale icon to turn green."
            Write-Explanation "Docker Desktop is usually located in the system tray."
            Write-Host ""
            $choice = Read-Host "Do you want to try starting Docker Desktop? (y/n)"
            if ($choice -eq 'y') {
                $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
                if (Test-Path $dockerPath) {
                    Start-Process $dockerPath
                    Write-Info "Starting Docker Desktop... Please wait 30 seconds."
                    Start-Sleep -Seconds 30

                    # Check again
                    docker info 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Docker daemon is now running."
                    } else {
                        Write-Error "Docker daemon still not running."
                        Write-Explanation "Please start Docker Desktop manually and try again."
                        Read-Host "Press Enter to exit"
                        exit
                    }
                } else {
                    Write-Error "Could not find Docker Desktop."
                    Write-Explanation "Please start Docker Desktop manually and try again."
                    Read-Host "Press Enter to exit"
                    exit
                }
            } else {
                Write-Error "Docker Desktop is required."
                Write-Explanation "Please start Docker Desktop and run this script again."
                Read-Host "Press Enter to exit"
                exit
            }
        }
    } catch {
        Write-Error "Could not check Docker daemon status."
        Write-Explanation "Please make sure Docker Desktop is running."
        Read-Host "Press Enter to exit"
        exit
    }
}

# ============================================
# 7. GITHUB CLI CHECK
# ============================================

function Check-GitHubCLI {
    Write-Step -Message "Checking GitHub CLI" -StepNumber "4"

    Write-Info "Checking if GitHub CLI (gh) is installed..."
    if (Test-CommandAvailable "gh") {
        $ghVersion = gh --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub CLI is installed: $ghVersion"
            Write-Explanation "GitHub CLI makes it easy to create repositories from the command line."
            return $true
        }
    }

    Write-Warning "GitHub CLI (gh) is not installed."
    Write-Explanation "Without gh, you must create the repository manually in your browser."
    Write-Host ""
    Write-Info "Install GitHub CLI from: https://cli.github.com/"
    Write-Info "Or create the repo manually on github.com."
    return $false
}

# ============================================
# 8. REPOSITORY CONFIGURATION
# ============================================

function Configure-Repository {
    Write-Step -Message "Configure GitHub repository" -StepNumber "5"

    Write-Info "You need a GitHub repository for your CI/CD pipeline."
    Write-Explanation "The repository is where your code is stored and where GitHub Actions runs."
    Write-Host ""

    do {
        $repoName = Read-Host "Enter a name for your repository (e.g., docker-demo)"
        if ([string]::IsNullOrWhiteSpace($repoName)) {
            Write-Warning "Repository name cannot be empty."
            continue
        }
        $repoName = $repoName -replace '[^a-zA-Z0-9\-_.]', ''
        if ([string]::IsNullOrWhiteSpace($repoName)) {
            Write-Warning "Repository name contains invalid characters."
            continue
        }
        break
    } while ($true)

    Write-Success "Repository name: $repoName"
    Write-Explanation "This is the name that appears on GitHub under your account."
    Write-Host ""

    do {
        $branchName = Read-Host "Enter the main branch name (e.g., main or master)"
        if ([string]::IsNullOrWhiteSpace($branchName)) {
            Write-Warning "Branch name cannot be empty."
            continue
        }
        $branchName = $branchName -replace '[^a-zA-Z0-9\-_.]', ''
        if ([string]::IsNullOrWhiteSpace($branchName)) {
            Write-Warning "Branch name contains invalid characters."
            continue
        }
        break
    } while ($true)

    Write-Success "Main branch: $branchName"
    Write-Explanation "This is the branch that GitHub Actions monitors for changes."
    Write-Host ""

    return @{
        RepoName = $repoName
        BranchName = $branchName
    }
}

# ============================================
# 9. GITHUB AUTHENTICATION
# ============================================

function Login-GitHub {
    param([bool]$GhInstalled)

    Write-Step -Message "GitHub authentication" -StepNumber "6"

    Write-Info "To push code to GitHub, you need to authenticate."
    Write-Explanation "This allows the script to create the repository and push your code."
    Write-Host ""

    if ($GhInstalled) {
        Write-Menu -Title "Select authentication method" -Options @(
            "Login with GitHub CLI (recommended)",
            "Use Personal Access Token (PAT)",
            "Create repo manually in browser"
        )

        $authChoice = Get-UserChoice -Prompt "Select option (1-3)" -ValidOptions @("1", "2", "3")

        switch ($authChoice) {
            "1" {
                Write-Info "Logging in via GitHub CLI..."
                Write-Explanation "A browser will open for login. Follow the instructions there."
                Write-Host ""

                $ghUser = gh api user --jq '.login' 2>$null
                if ($ghUser) {
                    Write-Success "Already logged in as: $ghUser"
                    return @{Method = "CLI"; User = $ghUser}
                }

                gh auth login

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Login successful!"
                    $ghUser = gh api user --jq '.login' 2>$null
                    if ($ghUser) {
                        Write-Success "Logged in as: $ghUser"
                    }
                    return @{Method = "CLI"; User = $ghUser}
                } else {
                    Write-Error "Login failed."
                    Write-Explanation "Try manual login instead."
                    return @{Method = "Manual"}
                }
            }
            "2" {
                Write-Info "Using Personal Access Token (PAT)..."
                Write-Explanation "Create a PAT at: https://github.com/settings/tokens"
                Write-Explanation "Select 'repo' scope to be able to push code."
                Write-Host ""

                $pat = Read-Host "Enter your Personal Access Token"
                if ($pat) {
                    $env:GITHUB_TOKEN = $pat
                    Write-Success "PAT saved!"
                    return @{Method = "PAT"; Token = $pat}
                } else {
                    Write-Warning "No PAT provided. Using manual method."
                    return @{Method = "Manual"}
                }
            }
            "3" {
                return @{Method = "Manual"}
            }
        }
    } else {
        Write-Info "GitHub CLI is not installed. Using manual method."
        Write-Explanation "You will create the repository manually on GitHub.com."
        return @{Method = "Manual"}
    }

    return @{Method = "Manual"}
}

# ============================================
# 10. CREATE REPO MANUALLY
# ============================================

function Get-ManualRepoUrl {
    param([string]$RepoName)

    Write-Step -Message "Create repository manually" -StepNumber "7"

    Write-Info "Create a new repository on GitHub.com:"
    Write-Host ""
    Write-Host "1. Go to: https://github.com/new" -ForegroundColor Cyan
    Write-Host "2. Name it: $RepoName" -ForegroundColor Cyan
    Write-Host "3. Select 'Public' or 'Private'" -ForegroundColor Cyan
    Write-Host "4. Click 'Create repository'" -ForegroundColor Cyan
    Write-Host ""
    Write-Explanation "After creating the repo, copy the HTTPS URL."
    Write-Explanation "It looks like: https://github.com/yourusername/docker-demo.git"
    Write-Host ""

    do {
        $repoUrl = Read-Host "Enter the repo URL (or press Enter to exit)"
        if ([string]::IsNullOrWhiteSpace($repoUrl)) {
            Write-Error "No URL provided. Exiting."
            exit
        }
        if ($repoUrl -match '^https://github\.com/.+/.+\.git$') {
            break
        } else {
            Write-Warning "URL format should be: https://github.com/username/reponame.git"
        }
    } while ($true)

    Write-Success "Repo URL: $repoUrl"
    return $repoUrl
}

# ============================================
# 11. CREATE DOCKER CI/CD WORKFLOW
# ============================================

function Create-DockerWorkflow {
    param(
        [string]$RepoName,
        [string]$BranchName
    )

    Write-Step -Message "Creating Docker CI/CD workflow" -StepNumber "8"

    Write-Info "Creating GitHub Actions workflow for Docker..."
    Write-Explanation "This workflow will automatically build and test your Docker container on every push."
    Write-Explanation "The workflow file will be saved as: .github/workflows/docker-ci.yml"
    Write-Host ""

    New-Item -Path ".\.github\workflows" -ItemType Directory -Force | Out-Null

    $workflowContent = @"
name: Docker CI/CD Pipeline

on:
  push:
    branches: [ $BranchName ]
  pull_request:
    branches: [ $BranchName ]

env:
  IMAGE_NAME: $RepoName

jobs:
  build-and-test:
    name: Build and Test Docker Container
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        run: |
          docker build -t `${{ env.IMAGE_NAME }} .
          echo "Docker image built successfully"

      - name: Run container
        run: |
          docker run -d -p 8080:80 --name test-server `${{ env.IMAGE_NAME }}
          echo "Container started on port 8080"

      - name: Test container
        run: |
          sleep 2
          curl -f http://localhost:8080 || exit 1
          echo "Web server is responding correctly"

      - name: Show container logs (if test fails)
        if: failure()
        run: docker logs test-server

      - name: Stop and remove test container
        if: always()
        run: |
          docker stop test-server
          docker rm test-server

  push-to-dockerhub:
    name: Push to Docker Hub
    runs-on: ubuntu-latest
    needs: build-and-test
    if: github.event_name == 'push' && github.ref == 'refs/heads/$BranchName'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: `${{ secrets.DOCKER_USERNAME }}
          password: `${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            `${{ secrets.DOCKER_USERNAME }}/`${{ env.IMAGE_NAME }}:latest
            `${{ secrets.DOCKER_USERNAME }}/`${{ env.IMAGE_NAME }}:`${{ github.sha }}
"@

    $workflowContent | Out-File -FilePath ".\.github\workflows\docker-ci.yml" -Encoding utf8
    Write-Success ".github/workflows/docker-ci.yml created"

    Write-Explanation "The workflow has two jobs:"
    Write-Explanation "  1. Build and Test - Builds your container and tests it"
    Write-Explanation "  2. Push to Docker Hub - Pushes your image to Docker Hub (only on main branch)"
    Write-Host ""
}

# ============================================
# 12. DOCKER HUB SETUP GUIDE
# ============================================

function Show-DockerHubGuide {
    Write-Step -Message "Docker Hub setup guide" -StepNumber "9"

    Write-Info "To push your Docker image to Docker Hub, you need to set up Docker Hub integration."
    Write-Explanation "This is optional but recommended for professional workflows."
    Write-Explanation "The workflow we created has a job that pushes to Docker Hub."
    Write-Host ""

    Write-Menu -Title "Docker Hub setup" -Options @(
        "I have a Docker Hub account - show me how to set it up",
        "I want to create a Docker Hub account",
        "Skip Docker Hub setup (I will set it up later)"
    )

    $dockerChoice = Get-UserChoice -Prompt "Select option (1-3)" -ValidOptions @("1", "2", "3")

    switch ($dockerChoice) {
        "1" {
            Write-Info "Docker Hub setup instructions:"
            Write-Host ""
            Write-Host "1. Go to: https://hub.docker.com/" -ForegroundColor Cyan
            Write-Host "2. Log in with your Docker Hub account" -ForegroundColor Cyan
            Write-Host "3. Go to Account Settings -> Security -> New Access Token" -ForegroundColor Cyan
            Write-Host "4. Create a token with 'Read, Write, Delete' permissions" -ForegroundColor Cyan
            Write-Host "5. Copy the token (it starts with 'dckr_pat_')" -ForegroundColor Cyan
            Write-Host "6. Go to your GitHub repository -> Settings -> Secrets and variables -> Actions" -ForegroundColor Cyan
            Write-Host "7. Add two secrets:" -ForegroundColor Cyan
            Write-Host "   - DOCKER_USERNAME = your Docker Hub username" -ForegroundColor Cyan
            Write-Host "   - DOCKER_PASSWORD = the token you just created" -ForegroundColor Cyan
            Write-Host ""
            Write-Explanation "After setting up these secrets, the GitHub Actions workflow will push your image to Docker Hub."
            Write-Info "You need to set up DOCKER_USERNAME and DOCKER_PASSWORD secrets in your GitHub repository."
            return $true
        }
        "2" {
            Write-Info "Creating a Docker Hub account:"
            Write-Host ""
            Write-Host "1. Go to: https://hub.docker.com/signup" -ForegroundColor Cyan
            Write-Host "2. Fill in your email, username, and password" -ForegroundColor Cyan
            Write-Host "3. Confirm your email" -ForegroundColor Cyan
            Write-Host "4. Return to this script and select option 1" -ForegroundColor Cyan
            Write-Host ""
            Start-Process "https://hub.docker.com/signup"
            Read-Host "Press Enter after you have created your Docker Hub account"
            return $false
        }
        "3" {
            Write-Info "Skipping Docker Hub setup."
            Write-Explanation "You can set up Docker Hub integration later by adding secrets to your GitHub repository."
            Write-Explanation "The workflow file is already configured to use DOCKER_USERNAME and DOCKER_PASSWORD secrets."
            return $false
        }
    }
}

# ============================================
# 13. GIT INITIALIZATION
# ============================================

function Initialize-Git {
    param([string]$BranchName)

    Write-Step -Message "Initializing Git" -StepNumber "10"

    Write-Info "Initializing Git in the current folder..."
    Write-Explanation "Git init creates a version control system that tracks all changes to your code."
    Write-Host ""

    if (Test-Path ".\.git") {
        Write-Warning ".git folder already exists. Removing it..."
        Remove-Item -Path ".\.git" -Recurse -Force -ErrorAction SilentlyContinue
    }

    git init
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Git initialized"
    } else {
        Write-Error "Git initialization failed"
        exit
    }

    Write-Info "Creating branch: $BranchName..."
    git checkout -b $BranchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        git branch -m $BranchName
    }
    Write-Success "Branch created: $BranchName"

    Write-Info "Adding files..."
    Write-Explanation "'git add .' adds all files in the folder to Git tracking."
    git add .
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Files added"
    }

    Write-Info "Creating initial commit..."
    Write-Explanation "'git commit' creates a snapshot of your files with a message."
    git commit -m "Initial commit: Docker CI/CD demo"
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Commit created"
    }
}

# ============================================
# 14. PUSH TO GITHUB
# ============================================

function Push-ToGitHub {
    param(
        [string]$RepoUrl,
        [string]$BranchName,
        [string]$AuthMethod
    )

    Write-Step -Message "Pushing to GitHub" -StepNumber "11"

    Write-Info "Adding remote repository..."
    Write-Explanation "'git remote add origin' links your local folder to the GitHub repo."

    git remote remove origin 2>$null
    git remote add origin $RepoUrl
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Remote added: $RepoUrl"
    } else {
        Write-Error "Failed to add remote."
        Write-Explanation "Check that the URL is correct and you have access."
        return $false
    }

    Write-Info "Pushing code to GitHub..."
    Write-Explanation "'git push' sends your code to GitHub. This triggers GitHub Actions."
    Write-Host ""

    # Redirect output and capture exit code properly
    $pushOutput = git push -u origin $BranchName 2>&1
    $pushSuccess = ($LASTEXITCODE -eq 0)

    if (-not $pushSuccess) {
        Write-Warning "Push failed with default credentials."

        if ($AuthMethod -eq "PAT" -and $env:GITHUB_TOKEN) {
            Write-Info "Retrying with Personal Access Token..."
            $repoUrlWithToken = $RepoUrl -replace '^https://', "https://$($env:GITHUB_TOKEN)@"
            git remote set-url origin $repoUrlWithToken
            $pushOutput = git push -u origin $BranchName 2>&1
            $pushSuccess = ($LASTEXITCODE -eq 0)

            if ($pushSuccess) {
                git remote set-url origin $RepoUrl
            }
        } else {
            Write-Info "You can try pushing manually: git push -u origin $BranchName"
            Write-Host ""
            Write-Info "If you get an authentication error:"
            Write-Host "   1. Use a Personal Access Token (PAT) instead of password" -ForegroundColor Gray
            Write-Host "   2. Create PAT at: https://github.com/settings/tokens" -ForegroundColor Gray
            Write-Host "   3. Select 'repo' as scope" -ForegroundColor Gray
        }
    }

    if ($pushSuccess) {
        Write-Success "Code pushed to GitHub!"
        Write-Explanation "GitHub Actions has now been automatically triggered on GitHub."
        Write-Explanation "Your Docker container will be built and tested automatically!"
        return $true
    } else {
        Write-Error "Could not push to GitHub."
        return $false
    }
}

# ============================================
# 15. SUMMARY
# ============================================

function Show-Summary {
    param(
        [string]$RepoUrl,
        [string]$BranchName,
        [bool]$DockerHubSetup,
        [bool]$PushSuccess
    )

    Write-Step -Message "Complete!" -StepNumber "12"

    Write-Separator
    Write-Host "     DOCKER CI/CD SETUP - COMPLETE!" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""

    Write-Info "What was created:"
    Write-Host "   .github/workflows/docker-ci.yml - CI/CD pipeline for Docker" -ForegroundColor Gray
    Write-Host ""

    Write-Info "Your CI/CD pipeline will:"
    Write-Host "   1. Build your Docker container" -ForegroundColor Gray
    Write-Host "   2. Run tests (check if web server responds)" -ForegroundColor Gray
    Write-Host "   3. Push to Docker Hub (if secrets are configured)" -ForegroundColor Gray
    Write-Host ""

    Write-Info "Next steps:"
    Write-Host "   1. Go to your repository on GitHub" -ForegroundColor Gray
    Write-Host "      Location: $RepoUrl" -ForegroundColor Cyan
    Write-Host "   2. Click the 'Actions' tab" -ForegroundColor Gray
    Write-Host "   3. See your pipeline running - it starts automatically!" -ForegroundColor Gray
    Write-Host "   4. Make a change to index.html and push again" -ForegroundColor Gray
    Write-Host "      -> This will trigger the pipeline again!" -ForegroundColor Gray
    Write-Host ""

    if ($DockerHubSetup) {
        Write-Info "Docker Hub integration:"
        Write-Host "   Your container will be pushed to Docker Hub automatically!" -ForegroundColor Gray
        Write-Host "   Check your Docker Hub account for the image." -ForegroundColor Gray
    } else {
        Write-Info "Docker Hub setup (optional):"
        Write-Host "   To push images to Docker Hub, add these secrets to your GitHub repository:" -ForegroundColor Gray
        Write-Host "   - DOCKER_USERNAME - Your Docker Hub username" -ForegroundColor Gray
        Write-Host "   - DOCKER_PASSWORD - Your Docker Hub access token" -ForegroundColor Gray
    }
    Write-Host ""

    Write-Info "Test the pipeline:"
    Write-Host "   echo '<h1>Updated!</h1>' >> index.html" -ForegroundColor Gray
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m 'Testing Docker CI/CD'" -ForegroundColor Gray
    Write-Host "   git push" -ForegroundColor Gray
    Write-Host ""

    Write-Info "Learning resources:"
    Write-Host "   GitHub Actions: https://docs.github.com/en/actions" -ForegroundColor Gray
    Write-Host "   Docker Hub: https://hub.docker.com/" -ForegroundColor Gray
    Write-Host "   Docker Documentation: https://docs.docker.com/" -ForegroundColor Gray
    Write-Host ""

    Write-Separator
    Write-Host "     CONGRATULATIONS! You have a Docker CI/CD pipeline!" -ForegroundColor Yellow
    Write-Separator
    Write-Host ""
}

# ============================================
# 16. MAIN PROGRAM
# ============================================

function Main {
    # Show main menu
    Show-MainMenu

    # Check environment
    Check-Environment

    # Check Git
    Check-Git

    # Check Docker
    Check-Docker

    # Check GitHub CLI
    $ghInstalled = Check-GitHubCLI

    # Configure repository
    $repoConfig = Configure-Repository
    $repoName = $repoConfig.RepoName
    $branchName = $repoConfig.BranchName

    # GitHub authentication
    $authResult = Login-GitHub -GhInstalled $ghInstalled
    $authMethod = $authResult.Method

    # Get repo URL
    if ($authMethod -eq "CLI" -and $authResult.User) {
        $ghUser = $authResult.User
        $repoUrl = "https://github.com/$ghUser/$repoName"
        Write-Success "Repository created automatically: $repoUrl"

        Write-Info "Creating repository on GitHub..."
        gh repo create $repoName --public --clone 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Repository created on GitHub"
        } else {
            Write-Warning "Repository may already exist. Continuing..."
        }
    } else {
        $repoUrl = Get-ManualRepoUrl -RepoName $repoName
    }

    # Create Docker CI/CD workflow
    Create-DockerWorkflow -RepoName $repoName -BranchName $branchName

    # Show Docker Hub setup guide
    $dockerHubSetup = Show-DockerHubGuide

    # Initialize Git
    Initialize-Git -BranchName $branchName

    # Push to GitHub
    $pushSuccess = Push-ToGitHub -RepoUrl $repoUrl -BranchName $branchName -AuthMethod $authMethod

    # Show summary
    Show-Summary -RepoUrl $repoUrl -BranchName $branchName -DockerHubSetup $dockerHubSetup -PushSuccess $pushSuccess

    if (-not $pushSuccess) {
        Write-Warning "The CI/CD pipeline was created but could not be pushed automatically."
        Write-Info "Try manually: git push -u origin $branchName"
    }

    Read-Host "`nPress Enter to exit"
}

# ============================================
# 17. START
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