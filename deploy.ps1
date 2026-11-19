# Build the Hugo site and publish public/ to the gh-pages branch.
# Usage: ./deploy.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$deployDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'blog-deploy'

# 1. Build fresh
if (Test-Path public) { Remove-Item public -Recurse -Force }
hugo --gc --minify
if ($LASTEXITCODE -ne 0) { throw 'hugo build failed' }
if (-not (Test-Path public/CNAME)) { throw 'public/CNAME missing - custom domain would break' }

# 2. Prepare gh-pages worktree
git worktree prune
git fetch origin
if (Test-Path $deployDir) { git worktree remove $deployDir --force }
$remoteExists = git ls-remote --heads origin gh-pages
if ($remoteExists) {
    git worktree add -B gh-pages $deployDir origin/gh-pages
} else {
    git worktree add --detach $deployDir
    Push-Location $deployDir
    git checkout --orphan gh-pages
    git rm -rf . | Out-Null
    Pop-Location
}

# 3. Replace contents with the build
Get-ChildItem $deployDir -Force | Where-Object Name -ne '.git' | Remove-Item -Recurse -Force
Copy-Item public\* $deployDir -Recurse -Force
New-Item (Join-Path $deployDir '.nojekyll') -ItemType File -Force | Out-Null

# 4. Commit and push
Push-Location $deployDir
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host 'No changes to deploy.'
} else {
    git commit -m "Deploy $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin gh-pages --force
}
Pop-Location

git worktree remove $deployDir --force
Write-Host 'Done.'
