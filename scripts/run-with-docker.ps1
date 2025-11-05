param(
    [string]$Host = '127.0.0.1',
    [int]$Port = 8082,
    [string]$FolderPath,
    [string]$ComposeFile,
    [switch]$NoCompose,
    [int]$DockerTimeoutSeconds = 180,
    [string]$BrowserType = 'none'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Msg {
    param([string]$Message)
    Write-Host "[run-with-docker] $Message"
}

function Test-DockerReady {
    try {
        docker info *> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Start-DockerIfNeeded {
    if (Test-DockerReady) {
        Write-Msg 'Docker is already running.'
        return
    }

    $candidates = @(
        Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Docker\Docker\Docker Desktop.exe'),
        (Join-Path $env:LocalAppData 'Docker\Docker\Docker Desktop.exe')

    $dockerExe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $dockerExe) {
        throw 'Docker Desktop not found. Please install Docker Desktop and try again.'
    }

    Write-Msg "Starting Docker Desktop: $dockerExe"
    Start-Process -FilePath $dockerExe | Out-Null

    Write-Msg 'Waiting for Docker to become ready...'
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopWatch.Elapsed.TotalSeconds -lt $DockerTimeoutSeconds) {
        if (Test-DockerReady) {
            Write-Msg 'Docker is ready.'
            return
        }
        Start-Sleep -Seconds 1
    }

    throw "Docker failed to become ready within $DockerTimeoutSeconds seconds."
}

function Invoke-ComposeUp {
    param([string]$ComposePath)

    if ($NoCompose) {
        Write-Msg 'Skipping docker compose (NoCompose switch specified).'
        return
    }

    $resolved = $null
    if ($ComposePath) {
        $resolved = Resolve-Path -LiteralPath $ComposePath -ErrorAction SilentlyContinue
    } else {
        $root = Resolve-Path (Join-Path $PSScriptRoot '..')
        $try1 = Join-Path $root 'docker-compose.yml'
        $try2 = Join-Path $root 'docker-compose.yaml'
        if (Test-Path $try1) { $resolved = Resolve-Path $try1 }
        elseif (Test-Path $try2) { $resolved = Resolve-Path $try2 }
    }

    if (-not $resolved) {
        Write-Msg 'No docker-compose file found. Continuing without compose.'
        return
    }

    Write-Msg "Running: docker compose -f $resolved up -d"
    docker compose -f "$resolved" up -d
    if ($LASTEXITCODE -ne 0) {
        throw 'docker compose up failed.'
    }
}

function Start-WebApp {
    param(
        [string]$Host,
        [int]$Port,
        [string]$BrowserType,
        [string]$Folder
    )

    $folderToServe = if ($Folder) { Resolve-Path $Folder } else { Resolve-Path (Join-Path $PSScriptRoot '..') }
    Write-Msg "Serving folder: $folderToServe on http://$Host:$Port"

    $args = @('--host', $Host, '--port', $Port.ToString(), '--browserType', $BrowserType, $folderToServe)
    Write-Msg ('Command: npx -y @vscode/test-web ' + ($args -join ' '))
    npx -y @vscode/test-web @args
}

Start-DockerIfNeeded
Invoke-ComposeUp -ComposePath $ComposeFile
Start-WebApp -Host $Host -Port $Port -BrowserType $BrowserType -Folder $FolderPath


