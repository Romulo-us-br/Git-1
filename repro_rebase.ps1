$ErrorActionPreference = "Stop"

function Setup-Repo {
    param($DirName)
    $RepoPath = Join-Path $PWD $DirName
    if (Test-Path $RepoPath) { Remove-Item $RepoPath -Recurse -Force }
    New-Item -ItemType Directory -Path $RepoPath | Out-Null
    Set-Location $RepoPath
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
}

Write-Host "=== CENÁRIO 1: Sem conflito (Um lado muda, o outro mantém) ==="
Setup-Repo "teste_sem_conflito"

# 1. Base
"<h2>Texto Original</h2>" | Set-Content index.html
git add .
git commit -q -m "Base: Texto com H2"

# 2. Alteração no Master (em outra linha ou arquivo, ou nenhuma)
"Outro arquivo" | Set-Content outro.txt
git add .
git commit -q -m "Master: Outra mudança"

# 3. Alteração no Feature (Remove H2 na mesma linha base)
git checkout -q -b feature HEAD~1
"Texto Original" | Set-Content index.html
git commit -q -am "Feature: Remove H2"

# 4. Rebase
Write-Host "Tentando rebase feature em master..."
git rebase master
if ($?) {
    Write-Host "SUCESSO: Rebase automático completado." -ForegroundColor Green
    Get-Content index.html
} else {
    Write-Host "FALHA: Conflito detectado." -ForegroundColor Red
    git rebase --abort
}

Write-Host "`n=== CENÁRIO 2: Com conflito (Ambos mudam a mesma linha) ==="
Set-Location ..
Setup-Repo "teste_com_conflito"

# 1. Base
"<h2>Texto Original</h2>" | Set-Content index.html
git add .
git commit -q -m "Base: Texto com H2"

# 2. Alteração no Master (Muda texto DENTRO do H2)
"<h2>Texto MUDADO no Master</h2>" | Set-Content index.html
git commit -q -am "Master: Muda texto mantendo H2"

# 3. Alteração no Feature (Remove H2)
git checkout -q -b feature HEAD~1
"Texto Original" | Set-Content index.html
git commit -q -am "Feature: Remove H2"

# 4. Rebase
Write-Host "Tentando rebase feature em master..."
try {
    git rebase master 2>&1 | Out-Null
} catch {}

if ((git status | Select-String "interactive rebase in progress") -or (git status | Select-String "You have unmerged paths")) {
    Write-Host "SUCESSO: Conflito detectado como esperado!" -ForegroundColor Green
    git status
    git rebase --abort
} else {
    Write-Host "FALHA: Rebase foi automático (inesperado)." -ForegroundColor Red
}
