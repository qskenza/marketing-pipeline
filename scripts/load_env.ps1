# Windows PowerShell - run from the repo root with:  . .\scripts\load_env.ps1
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
    }
}
Write-Host "Environment variables loaded from .env"
