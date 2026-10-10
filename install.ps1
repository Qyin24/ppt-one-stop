<#
.SYNOPSIS
    安装 ppt-one-stop 及其依赖技能到 DSH / Agents 技能目录。

.EXAMPLE
    .\install.ps1
    从默认仓库地址克隆并安装。

.EXAMPLE
    .\install.ps1 -Repo https://github.com/Qyin24/ppt-one-stop.git
    从指定地址安装。

.EXAMPLE
    .\install.ps1 -LocalDir ..\ppt-one-stop-repo -DryRun
    从本地目录安装，只打印将要执行的动作（离线/测试用）。
#>
[CmdletBinding()]
param(
    [string] $Repo = 'https://github.com/Qyin24/ppt-one-stop.git',
    [string] $LocalDir,
    # 目标主目录。留空则用 $env:USERPROFILE。显式传入可把技能装到非默认位置。
    # 注意：$HOME / $Home 在 PowerShell 中是只读自动变量且大小写不敏感，
    # 不能靠给变量赋值来改目标——必须用这个 -TargetHome 参数。
    [string] $TargetHome,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$Skills = @('ppt-one-stop', 'ppt-content-generation', 'ppt-visual-design')

if (-not $TargetHome) { $TargetHome = $env:USERPROFILE }
if (-not $TargetHome) { throw '错误: 无法确定目标主目录，请用 -TargetHome 指定' }

$DshSkills    = Join-Path $TargetHome '.dsh/skills'
$AgentsSkills = Join-Path $TargetHome '.agents/skills'
$Roots        = @($DshSkills, $AgentsSkills)

function Write-Step($msg) { Write-Host $msg }

# ── 取得仓库 ────────────────────────────────────────────────────────────
$workDir = $null
try {
    if ($LocalDir) {
        if (-not (Test-Path (Join-Path $LocalDir 'skills'))) {
            throw "错误: $LocalDir 下没有 skills/ 目录"
        }
        $src = (Resolve-Path $LocalDir).Path
        Write-Step "使用本地仓库: $src"
    }
    else {
        Write-Step "克隆仓库: $Repo"
        if ($DryRun) {
            Write-Step "  [dry-run] git clone --depth 1 $Repo <临时目录>"
            $src = '<未克隆>'
        }
        else {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                throw '错误: 需要 git'
            }
            $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ppt-one-stop-" + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $workDir -Force | Out-Null
            & git clone --depth 1 $Repo (Join-Path $workDir 'repo') 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw '错误: 克隆失败，请检查仓库地址是否正确且可公开访问'
            }
            $src = Join-Path $workDir 'repo'
        }
    }

    # ── 安装 ────────────────────────────────────────────────────────────
    Write-Step ''
    Write-Step "安装技能到 $($Roots -join '  ')"
    $installed = @()
    $failed    = @()

    foreach ($skill in $Skills) {
        $srcSkill = Join-Path $src "skills/$skill"
        if (-not (Test-Path $srcSkill) -or -not (Test-Path (Join-Path $srcSkill 'SKILL.md'))) {
            Write-Step "  ✗ $skill — 仓库中缺少 SKILL.md，跳过"
            $failed += $skill
            continue
        }
        foreach ($root in $Roots) {
            $dest = Join-Path $root $skill
            if ($DryRun) {
                Write-Step "  [dry-run] 复制 $srcSkill\* -> $dest\"
            }
            else {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                # 覆盖同名文件，不删除目标目录中的其他内容
                Copy-Item -Path (Join-Path $srcSkill '*') -Destination $dest -Recurse -Force
            }
        }
        Write-Step "  ✓ $skill"
        $installed += $skill
    }

    # ── 校验 ────────────────────────────────────────────────────────────
    Write-Step ''
    Write-Step '校验'
    foreach ($skill in $installed) {
        foreach ($root in $Roots) {
            $file = Join-Path $root "$skill/SKILL.md"
            if ($DryRun) {
                Write-Step "  [dry-run] 校验 $file"
                continue
            }
            if (-not (Test-Path $file)) {
                Write-Step "  ✗ $file 不存在"
                $failed += $skill
                continue
            }
            $head = (Get-Content $file -TotalCount 20) -join "`n"

            if ($head -notmatch '(?m)^name:') {
                Write-Step "  ✗ $file 缺少 name 字段"
                $failed += $skill
                continue
            }
            if ($head -notmatch '(?m)^description:') {
                Write-Step "  ✗ $file 缺少 description 字段"
                $failed += $skill
                continue
            }
            $name = ([regex]::Match($head, '(?m)^name:\s*(.+)$')).Groups[1].Value.Trim().Trim('"', "'")
            if ($name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
                Write-Step "  ✗ $file 的 name 不是 kebab-case: $name"
                $failed += $skill
                continue
            }
        }
    }

    # ── 结果 ────────────────────────────────────────────────────────────
    Write-Step ''
    Write-Step '安装结果'
    foreach ($skill in $installed) {
        foreach ($root in $Roots) {
            Write-Step "  $skill -> $(Join-Path $root $skill)/"
        }
    }

    if ($failed.Count -gt 0) {
        Write-Step ''
        Write-Host "有问题的技能: $($failed -join ' ')" -ForegroundColor Red
        exit 1
    }

    Write-Step ''
    Write-Step '完成。修改即时生效，无需重启 DSH。'
    Write-Step '用法：直接对 DSH 说「帮我做个项目汇报 PPT」，它会一步步问你要需求。'
}
finally {
    if ($workDir -and (Test-Path $workDir)) {
        Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}