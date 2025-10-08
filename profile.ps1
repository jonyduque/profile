#----------------------------------------------------------------------
# Perfil do PowerShell
# Autor: Jony Duque (jonyduque@hotmail.com)
# Descrição: Configurações personalizadas e utilitários para o PowerShell.
#----------------------------------------------------------------------

#region 01. Estilos Visuais e Var. Globais
# --- Inicialização da Medição de Tempo ---
$script:ProfileLoadingTimes = [ordered]@{}
$script:OverallProfileStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# --- Estilos Visuais para o Console ---
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()

# As variáveis abaixo usam $PSStyle diretamente em sua definição e são colocadas no escopo do script.
$script:verde  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightGreen)"
$script:amarelo  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightYellow)"
$script:vermelho  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightRed)"
$script:ciano  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightCyan)"

$script:verdeN  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)"
$script:amareloN  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightYellow)$($PSStyle.Bold)"
$script:vermelhoN  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)"
$script:cianoN  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightCyan)$($PSStyle.Bold)"

$script:título    = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)"
$script:cmd    = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightYellow)$($PSStyle.Bold)"
$script:alias   = "$($PSStyle.Reset)$($PSStyle.Foreground.Yellow)"
$script:param  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightGreen)$($PSStyle.Italic)"

$script:mensagem  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightYellow)"
$script:destaque  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightCyan)$($PSStyle.Bold)"
$script:concluído  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightGreen)$($PSStyle.bold)"
$script:erro  = "$($PSStyle.Reset)$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)"

$script:negrito  = "$($PSStyle.Reset)$($PSStyle.Bold)"
$script:itálico  = "$($PSStyle.Reset)$($PSStyle.Italic)"
$script:reset  = $PSStyle.Reset

try { $script:tamanho = $Host.UI.RawUI.WindowSize.Width } catch { $script:tamanho = 80 }

$sectionTimer.Stop()
$script:ProfileLoadingTimes['01. Estilos Visuais e Var. Globais'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 02. Funções Auxiliares (Hyperlink, TimeSpan)
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
function Format-TerminalHyperlink {
    param(
        [string]$Uri,
        [string]$LinkText = $Uri
    )
    $esc = "$([char]27)" # Caractere de Escape
    $bel = "$([char]7)"  # Caractere Bell
    return "${esc}]8;;${uri}${bel}${LinkText}${esc}]8;;${bel}"
}
function Format-TimeSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [timespan]$TimeSpan
    )
    if ($TimeSpan.TotalSeconds -ge 1) {
        return $TimeSpan.TotalSeconds.ToString("0.###s") # Mais precisão para segundos
    } elseif ($TimeSpan.TotalMilliseconds -gt 0) {
        return $TimeSpan.TotalMilliseconds.ToString("0ms")
    } else {
        return "0ms" # Caso seja exatamente 0
    }
}
$sectionTimer.Stop()
$script:ProfileLoadingTimes['02. Funções Auxiliares (Hyperlink, TimeSpan)'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 03. PSReadLine
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()

Import-Module -Name PSReadLine -ErrorAction SilentlyContinue

Set-PSReadLineKeyHandler -Key UpArrow    -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow  -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab        -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

Import-Module scoop-completion

$sectionTimer.Stop()
$script:ProfileLoadingTimes['03. PSReadLine'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 04. Terminal-Icons
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()

Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

$sectionTimer.Stop()
$script:ProfileLoadingTimes['04. Terminal-Icons'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 05. Config Sources OMP & Zoxide

# --- Configurações para Oh My Posh e Zoxide ---
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
$script:OhMyPoshThemeConfigPath = "C:/Program Files (x86)/oh-my-posh/themes/jony.omp.toml"
# $script:OhMyPoshConfigSourceFile = Join-Path -Path $HOME -ChildPath "Documents\PowerShell\Sources\oh-my-posh-prompt.ps1"
$script:OhMyPoshConfigSourceFile = (Get-ChildItem "C:\Users\jonyd\AppData\Local\oh-my-posh\" *.ps1)[1].fullname
$script:ZoxideSourceFile = Join-Path -Path $HOME -ChildPath "Documents\PowerShell\Sources\zoxide-init.ps1"
$script:UpdateSourceFrequencyDays = 7
$sectionTimer.Stop()
$script:ProfileLoadingTimes['05. Config Sources OMP & Zoxide'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 06. Update-ProfileSources
# --- Função Unificada para Atualizar Sources do Perfil ---
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
function Update-ProfileSources {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(ParameterSetName = 'OhMyPoshOnly')]
        [Alias('Omp')]
        [switch]$OhMyPosh,

        [Parameter(ParameterSetName = 'ZoxideOnly')]
        [Alias('Zox')]
        [switch]$Zoxide,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$Silent
    )

    $processOmp = $false
    $processZox = $false

    $ompLinkTextDisplay = "Source do Oh-My-Posh"
    $ompFileUri = "file:///$($script:OhMyPoshConfigSourceFile -replace '\\', '/')"
    $ompLink = Format-TerminalHyperlink -Uri $ompFileUri -LinkText $ompLinkTextDisplay

    $zoxLinkTextDisplay = "Source do Zoxide"
    $zoxFileUri = "file:///$($script:ZoxideSourceFile -replace '\\', '/')"
    $zoxLink = Format-TerminalHyperlink -Uri $zoxFileUri -LinkText $zoxLinkTextDisplay

    switch ($PSCmdlet.ParameterSetName) {
        'OhMyPoshOnly' { $processOmp = $true }
        'ZoxideOnly'   { $processZox = $true }
        default        { $processOmp = $true; $processZox = $true }
    }

    if (-not $Silent -and ($processOmp -or $processZox)) {
        Write-Host "`nIniciando verificação e atualização de sources do perfil..." -ForegroundColor Red
    }

    if ($processOmp) {
        if (-not $Silent) {
            $mode = if ($Force) {" (Modo Forçado)"} else {" (Verificando Data)"}
            Write-Host ("Processando Oh-My-Posh..." + $mode) -ForegroundColor Cyan
        }
        $needsActualUpdateOmp = $Force
        if (-not $Force) {
            $fileExists = Test-Path $script:OhMyPoshConfigSourceFile
            if (-not $fileExists) {
                if (-not $Silent) { Write-Host "$($ompLink) não encontrado. Será gerado." -ForegroundColor Yellow }
                $needsActualUpdateOmp = $true
            } else {
                $lastWriteTime = (Get-Item $script:OhMyPoshConfigSourceFile).LastWriteTime
                $thresholdDate = (Get-Date).AddDays(-$script:UpdateSourceFrequencyDays)
                if ($lastWriteTime -lt $thresholdDate) {
                    if (-not $Silent) { Write-Host "$($ompLink) tem mais de $($script:UpdateSourceFrequencyDays) dias. Será atualizado." -ForegroundColor Yellow }
                    $needsActualUpdateOmp = $true
                } else {
                    if (-not $Silent) { Write-Host "$($ompLink) está atualizado." }
                }
            }
        }
        if ($needsActualUpdateOmp) {
            if (-not $Silent) { Write-Host "Tentando gerar $ompLinkTextDisplay..." -ForegroundColor Yellow }
            try {
                $SourceDir = Split-Path -Path $script:OhMyPoshConfigSourceFile -Parent
                if (-not (Test-Path $SourceDir)) { New-Item -ItemType Directory -Path $SourceDir -Force -ErrorAction Stop | Out-Null }
                oh-my-posh init pwsh --config "$script:OhMyPoshThemeConfigPath" --print > "$script:OhMyPoshConfigSourceFile"
                if (-not $Silent) { Write-Host "$($ompLink) atualizado com sucesso." -ForegroundColor Green }
            } catch {
                if (-not $Silent) { Write-Error "Falha ao atualizar o $($ompLink).`nVerifique se Oh-My-Posh está instalado, no PATH, e o caminho do tema está correto.`n$($_.Exception.Message)" }
            }
        }
    }

    if ($processZox) {
        if (-not $Silent) {
            $mode = if ($Force) {" (Modo Forçado)"} else {" (Verificando Data)"}
            Write-Host ("Processando Zoxide..." + $mode) -ForegroundColor Cyan
        }
        $needsActualUpdateZox = $Force
        if (-not $Force) {
            $fileExists = Test-Path $script:ZoxideSourceFile
            if (-not $fileExists) {
                if (-not $Silent) { Write-Host "$($zoxLink) não encontrado. Será gerado." -ForegroundColor Yellow }
                $needsActualUpdateZox = $true
            } else {
                $lastWriteTime = (Get-Item $script:ZoxideSourceFile).LastWriteTime
                $thresholdDate = (Get-Date).AddDays(-$script:UpdateSourceFrequencyDays)
                if ($lastWriteTime -lt $thresholdDate) {
                    if (-not $Silent) { Write-Host "$($zoxLink) tem mais de $($script:UpdateSourceFrequencyDays) dias. Será atualizado." -ForegroundColor Yellow }
                    $needsActualUpdateZox = $true
                } else {
                    if (-not $Silent) { Write-Host "$($zoxLink) está atualizado." }
                }
            }
        }
        if ($needsActualUpdateZox) {
            if (-not $Silent) { Write-Host "Tentando gerar $zoxLinkTextDisplay..." -ForegroundColor Yellow }
            try {
                $SourceDir = Split-Path -Path $script:ZoxideSourceFile -Parent
                if (-not (Test-Path $SourceDir)) { New-Item -ItemType Directory -Path $SourceDir -Force -ErrorAction Stop | Out-Null }
                zoxide init powershell --cmd cd > "$script:ZoxideSourceFile"
                if (-not $Silent) { Write-Host "$($zoxLink) atualizado com sucesso." -ForegroundColor Green }
            } catch {
                if (-not $Silent) { Write-Error "Falha ao atualizar o $($zoxLink).`nVerifique se Zoxide está instalado e no PATH.`n$($_.Exception.Message)" }
            }
        }
    }

    if (-not $Silent -and ($processOmp -or $processZox)) {
        Write-Host "Verificação e atualização de sources do perfil concluída." -ForegroundColor Green
    }
}

# --- Verificação e Atualização Automática no Carregamento do Perfil ---
Update-ProfileSources -Silent
$sectionTimer.Stop()
$script:ProfileLoadingTimes['06. Update-ProfileSources'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 07. Carregamento Source - OMP
# --- Carregar os Sources Gerados ---
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
if (Test-Path $script:OhMyPoshConfigSourceFile) {
    #. $script:OhMyPoshConfigSourceFile
    & $script:OhMyPoshConfigSourceFile
} else {
    Write-Warning "Não foi possível encontrar o source do Oh My Posh:`n$($script:OhMyPoshConfigSourceFile)"
}

$sectionTimer.Stop()
$script:ProfileLoadingTimes['07. Carregamento Source - OMP'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 08. Carregamento Source - Zoxide
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
if (Test-Path $script:ZoxideSourceFile) {
    . $script:ZoxideSourceFile
} else {
    Write-Warning "Não foi possível encontrar o source do Zoxide:`n$($script:ZoxideSourceFile)"
}
#Set-Alias -Name cd -Value __zoxide_z -Option AllScope -Scope Global -Force

$sectionTimer.Stop()
$script:ProfileLoadingTimes['08. Carregamento Source - Zoxide'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 09. Env Vars
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()

$env:KOMOREBI_CONFIG_HOME = "C:\Users\jonyd\.config\komorebi"

$sectionTimer.Stop()
$script:ProfileLoadingTimes['09. Env Vars'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 10. Def. Funções Usuário (Ajuda, Tempo, etc.)
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()
# --- Funções de Utilidade e Navegação ---
function pwnl { pwsh -nologo }
function reload { & $PROFILE }
function Edit-Profile {
    param([string]$Editor = "code") # 'code' para VS Code, 'notepad' para Notepad, etc.
    try {
        & $Editor $PROFILE
        if (-not $?) { throw "Não foi possível abrir com $Editor." }
        Write-Host "$($script:mensagem)Editando perfil: $PROFILE com $Editor"
    } catch {
        Write-Warning "Falha ao abrir o perfil com '$Editor'. Verifique se o editor está no PATH. Tentando com notepad..."
        notepad $PROFILE
    }
}
function docs {
    $docPath = ""
    try { $docPath = [Environment]::GetFolderPath("MyDocuments") } catch {}
    if ([string]::IsNullOrWhiteSpace($docPath) -or (-not (Test-Path $docPath))) {
        $docPath = Join-Path -Path $HOME -ChildPath "Documents"
    }
    if (Test-Path $docPath) { Set-Location -Path $docPath } else { Write-Warning "Diretório de Documentos não encontrado: '$docPath'" }
}
function home { Set-Location -Path $HOME }
function desk {
    $deskPath = ""
    try { $deskPath = [Environment]::GetFolderPath("Desktop") } catch {}
    if ([string]::IsNullOrWhiteSpace($deskPath) -or (-not (Test-Path $deskPath))) {
        $deskPath = Join-Path -Path $HOME -ChildPath "Desktop"
    }
    if (Test-Path $deskPath) { Set-Location -Path $deskPath } else { Write-Warning "Diretório Desktop não encontrado: '$deskPath'" }
}
# --- Funções de Listagem ---
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }
# --- Funções Git ---
function lazygit {
    param([string]$Message = "Commit rápido") # Adicionado valor padrão
    git add -A
    git commit -m "$Message"
    git push
}
# --- Funções de Sistema e Rede ---
function Update-PWSH {
    try {
        Write-Host "`n$Verificando atualizações para o PowerShell Core..."
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"

        Write-Host "Versão atual: $($script:mensagem)$($currentVersion.ToString())$($script:reset)"
        Write-Host "Consultando GitHub API para versão mais recente..."
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl -UseBasicParsing -ErrorAction Stop
        $latestVersionStr = $latestReleaseInfo.tag_name.TrimStart('v')
        $latestVersion = [version]$latestVersionStr
        Write-Host "Versão mais recente encontrada: $($script:mensagem)$latestVersionStr$($script:reset)"

        if ($currentVersion -lt $latestVersion) {
            Write-Host "Nova versão do PowerShell disponível: $($script:mensagem)$latestVersionStr$($script:reset)"
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            if ((Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-Host "$($script:mensagem)Atualizando PowerShell via Winget...$($script:reset)"
                # Considerar rodar winget como admin se necessário para Microsoft.PowerShell
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -Command & {Write-Host 'Tentando atualizar PowerShell via Winget...'; winget upgrade Microsoft.PowerShell --accept-package-agreements --accept-source-agreements; Write-Host 'Pressione Enter para fechar esta janela.'; Read-Host}"
                Write-Host "$($script:mensagem)Processo de atualização iniciado em uma nova janela. PowerShell pode precisar ser reiniciado manualmente após a conclusão.$($script:reset)"
            } else {
                Write-Warning "Comando 'winget' não encontrado. Não é possível atualizar o PowerShell automaticamente."
                Write-Host "$($script:mensagem)Visite $($latestReleaseInfo.html_url) para baixar manualmente.$($script:reset)"
            }
        } else {
            Write-Host "$($script:concluído)O PowerShell ($($currentVersion.ToString())) está atualizado.$($script:reset)" -ForegroundColor Green
        }
    } catch {
        Write-Error "Falha ao atualizar o PowerShell. Erro: $($_.Exception.Message)"
    }
}
function Clear-Cache {
    Write-Host "`n$($script:mensagem)Limpando caches do sistema e usuário...$($script:reset)"
    $itemsToRemove = @(
        @{ Path = Join-Path -Path $env:SystemRoot -ChildPath "Prefetch\*"; Name = "Windows Prefetch"; Recurse = $false }
        @{ Path = Join-Path -Path $env:SystemRoot -ChildPath "Temp\*";      Name = "Windows Temp";     Recurse = $true  }
        @{ Path = Join-Path -Path $env:TEMP -ChildPath "*";                 Name = "User Temp";        Recurse = $true  }
        @{ Path = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\INetCache\*"; Name = "IE Cache"; Recurse = $true }
        @{ Path = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Temp\*";    Name = "User LocalAppData Temp"; Recurse = $true }
        # Adicionar outros caches aqui se desejar, e.g., navegador, winget, etc.
    )
    foreach ($item in $itemsToRemove) {
        # Verifica se o diretório pai do globbing existe
        $basePath = Split-Path -Path $item.Path
        if (Test-Path $basePath) {
                Write-Host "Limpando $($script:mensagem)$($item.Name)$($script:reset)..." -ForegroundColor Yellow
                try {
                    Remove-Item -Path $item.Path -Recurse:$item.Recurse -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Não foi possível limpar completamente '$($item.Name)'. Alguns arquivos podem estar em uso. Path: $($item.Path)"
                }
        } else {
                if (-not $Silent) {
                    Write-Warning "Caminho base para '$($item.Name)' não encontrado: $basePath"
                }
        }
    }

    Clear-DnsClientCache
    Write-Host "$($script:mensagem)Cache DNS limpo."

    Write-Host "$($script:concluído)Limpeza de caches concluída.$($script:reset)"
}
function health{

    Write-Host "👨‍⚕️ Saúde do Windows: $($script:mensagem)$((dism /online /cleanup-image /checkhealth)[6])"
    Write-Host "`n$($script:mensagem)Restaurar imagem do Windows?"
    Write-Host "$($script:verde)[S] Sim $($script:vermelho)[N] Não (padrão)$($script:reset)"

    $choice = Read-Host -Prompt "Opção"

    if ($choice.ToLower() -eq 's') {
        Write-Host "`n🖼️👨‍🎨🎨Restaurando imagem do Windows..."
        dism /online /cleanup-image /checkhealth
        Write-Host "`n$($script:concluído)✅ Pronto!"
        Read-Host | Out-Null
    }
}
function admin {
    param([string[]]$ArgumentListIn) # Renomeado para evitar conflito com $args implícito se não usado como param

    $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwshPath) { $pwshPath = (Get-Command powershell -ErrorAction SilentlyContinue).Source } # Fallback para Windows PowerShell se pwsh não encontrado
    if (-not $pwshPath) { Write-Error "Não foi possível encontrar o executável do PowerShell."; return }

    $startArgs = "-NoExit"
    if ($ArgumentListIn.Count -gt 0) {
        # Escapar aspas dentro dos argumentos para o comando aninhado
        $processedArgs = $ArgumentListIn | ForEach-Object { $_ -replace '"', '`"' }
        $startArgs += " -Command & { $($processedArgs -join ' ') }"
    }

    try {
        Start-Process -FilePath $pwshPath -ArgumentList $startArgs -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Error "Falha ao iniciar o processo como administrador: $($_.Exception.Message)"
    }
}
function winutil { Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression }

function WingetUpgrade{
    $upgrades = (winget upgrade).Split("\n") | Where-Object {$_.Trim().Length -gt 5}
    $indexInicial = $upgrades[0].IndexOf("ID")
    $tamanhoStr = $upgrades[0].IndexOf("Vers") - $indexInicial
    $upgrades = $upgrades | Select-Object -Skip 2 -SkipLast 1
    $ids = $upgrades | ForEach-Object { $_.Trim().Substring($indexInicial, $tamanhoStr) }
    Write-Host "`n$($script:mensagem)$($ids.Length) pacotes para atualizar...:$($script:cmd)"
    Write-Host $ids
    $opcaoSim = New-Object System.Management.Automation.Host.ChoiceDescription "&Sim", "Continua a operação."
    $opcaoNao = New-Object System.Management.Automation.Host.ChoiceDescription "&Não", "Interrompe a operação."
    $opcoes = [System.Management.Automation.Host.ChoiceDescription[]]($opcaoSim, $opcaoNao)
    $escolha = $Host.UI.PromptForChoice($Titulo, $Mensagem, $opcoes, 0)
    if ($escolha -eq 0) { # 0 corresponde a "Sim"
        Write-Host "`n$($script:mensagem)Iniciando atualizações via Winget...$($script:reset)"
        $ids | ForEach-Object {winget upgrade $_.Trim() --accept-source-agreements --disable-interactivity --include-unknown --force}
    }
}

# --- Funções de Clipboard ---
function copia {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory=$false)]
        [object[]]$InputObject,

        [Parameter(Position=0, Mandatory=$false)]
        [string]$Text
    )
    process {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            $InputObject | Out-String | Set-Clipboard
            Write-Host "$($script:concluído)Conteúdo do pipeline copiado para a área de transferência.$($script:reset)"
        } elseif ($PSBoundParameters.ContainsKey('Text')) {
            $Text | Set-Clipboard
            Write-Host "$($script:concluído)Texto fornecido copiado para a área de transferência.$($script:reset)"
        } elseif ($args.Count -gt 0) { # Fallback para comportamento de argumento simples
            $args -join [Environment]::NewLine | Set-Clipboard
            Write-Host "$($script:concluído)Argumentos concatenados copiados para a área de transferência.$($script:reset)"
        }
    }
}
# --- Função de Verificação de Atualizações ---
$script:UpdateCheckFilePath = Join-Path -Path $HOME -ChildPath "OneDrive\Documentos\PowerShell\atualizacao.ps1"
function UpdateCheck {
    if(-not (Test-Path $script:UpdateCheckFilePath)) {
        Write-Warning "`nO arquivo de verificação de atualizações não foi encontrado."
        return
    }
    . $script:UpdateCheckFilePath
}
# --- Metadados para Get-ProfileHelp ---
$script:ProfileFunctionsHelp = @(
    # Gerenciamento do Perfil
    [PSCustomObject]@{ Name = 'Update-ProfileSources'; Category = 'Gerenciamento do Perfil'; Alias='sources';
            Summary = "Atualiza OhMyPosh & Zoxide sources. $($script:param)(-Omp, -Zox, -Force, -Silent)" }
    [PSCustomObject]@{ Name = 'Reload';                Category = 'Gerenciamento do Perfil'; Alias='-';
            Summary = 'Recarrega o perfil do PowerShell atual.' }
    [PSCustomObject]@{ Name = 'Edit-Profile';          Category = 'Gerenciamento do Perfil'; Alias='profile';
            Summary = 'Abre este arquivo de perfil para edição (padrão: VS Code).' }
    [PSCustomObject]@{ Name = 'Get-ProfileHelp';       Category = 'Gerenciamento do Perfil'; Alias='ajuda';
            Summary = 'Mostra esta lista de funções e aliases do perfil.' }
    [PSCustomObject]@{ Name = 'Get-LoadingTime';       Category = 'Gerenciamento do Perfil'; Alias='tempos';
            Summary = 'Mostra os tempos de carregamento das seções do perfil.' }

    # Sistema e Utilitários
    [PSCustomObject]@{ Name = 'Update-PWSH';           Category = 'Sistema e Utilitários'; Alias='-';
            Summary = 'Verifica e inicia a atualização do PowerShell via Winget.' }
    [PSCustomObject]@{ Name = 'Clear-Cache';           Category = 'Sistema e Utilitários'; Alias='LimparCache';
            Summary = 'Limpa diversos caches do sistema e do usuário.' }
    [PSCustomObject]@{ Name = 'Admin';                 Category = 'Sistema e Utilitários'; Alias='su, adm';
            Summary = 'Abre PowerShell elevado ou executa comando como admin.' }
    [PSCustomObject]@{ Name = 'PWNL';                  Category = 'Sistema e Utilitários'; Alias='-';
            Summary = 'Inicia uma nova sessão do powershell.' }
    [PSCustomObject]@{ Name = 'Winutil';               Category = 'Sistema e Utilitários'; Alias='-';
            Summary = "$($script:vermelho)[CUIDADO]$($script:reset) Executa script de utilidades do Windows de christitus.com." }
    [PSCustomObject]@{ Name = 'Get-Definition';        Category = 'Sistema e Utilitários'; Alias='comando, explica';
            Summary = "$($script:param)(Parâmetro: <NomeDaFunção>)$($script:reset) Obtem o código de uma função." }
    [PSCustomObject]@{ Name = 'UpdateCheck';     Category = 'Sistema e Utilitários'; Alias='';
            Summary = "Inicia a verificação e atualização de atualizações de pacotes." }

    # Navegação
    [PSCustomObject]@{ Name = 'Docs';                  Category = 'Navegação'; Alias='-';
            Summary = 'Navega para o diretório Documentos.' }
    [PSCustomObject]@{ Name = 'Home';                  Category = 'Navegação'; Alias='jony';
            Summary = 'Navega para o diretório home do usuário.' }
    [PSCustomObject]@{ Name = 'Desk';                  Category = 'Navegação'; Alias='-';
            Summary = 'Navega para a Área de trabalho.' }

    # Listagem de Arquivos
    [PSCustomObject]@{ Name = 'la';                    Category = 'Listagem de Arquivos'; Alias='-';
            Summary = '(list all) Lista itens da pasta atual.' }
    [PSCustomObject]@{ Name = 'll';                    Category = 'Listagem de Arquivos'; Alias='-';
            Summary = '(list long) Lista itens da pasta atual, incluindo ocultos.' }

    # Git
    [PSCustomObject]@{ Name = 'LazyGit';                 Category = 'Git'; Alias='-';
            Summary = "$($script:param)(Parâmetro opcional: mensagem)$($script:reset) Inclui modificações, comita e pusha." }

    # Clipboard
    [PSCustomObject]@{ Name = 'Copia';                 Category = 'Clipboard'; Alias='-';
            Summary = "$($script:param)(Parâmetro opcional: texto)$($script:reset) Copia texto ou entrada do pipeline para a área de transferência." }
)
# --- Funções de Diagnóstico e Ajuda do Perfil ---
function Get-ProfileHelp {
    if (-not $script:ProfileFunctionsHelp -or $script:ProfileFunctionsHelp.Count -eq 0) {
        Write-Warning "Nenhuma informação de ajuda para funções do perfil foi definida em '$script:ProfileFunctionsHelp'."
        return
    }

    # Agrupa as funções pela propriedade 'Category' e ordena os grupos e itens dentro dos grupos.
    $groupedHelp = $script:ProfileFunctionsHelp | Sort-Object Category, Name | Group-Object -Property Category

    foreach ($group in $groupedHelp) {
        # Printa o nome da categoria como um título
        Write-Host "$($script:destaque)# $($group.Name.ToUpper())"

        # Itera sobre as funções dentro desta categoria
        foreach ($item in $group.Group) {

            # Constrói a parte do nome da função, incluindo o alias se existir
            $functionNamePart = "⇒ $($script:cmd)$($item.Name)$($script:reset)"
            if ($item.Alias -ne '-' -and $item.Alias) {
                $functionNamePart += " (=$($script:alias)$($item.Alias)$($script:reset))"
            }

            # Monta a linha de saída no formato "  Função: descrição." (com recuo)
            $outputLine = "  $($functionNamePart): $($item.Summary)"

            Write-Host $outputLine
        }
    }

    Write-Host "`nUse '$($script:cmd)Get-Definition/comando/explica $($script:param)<NomeDaFunção>$($script:reset)' para ver o código."
}
function Get-Definition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName
    )
    $function = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
    if ($function) {
        $function.Definition
    } else {
        Write-Warning "Função '$FunctionName' não encontrada."
    }
}
function Get-LoadingTime {
    if (-not $script:ProfileLoadingTimes -or $script:ProfileLoadingTimes.Count -eq 0) {
        Write-Warning "Dados de tempo de carregamento granular não disponíveis."
        return
    }

    $totalProfileMilliseconds = $script:OverallProfileStopwatch.Elapsed.TotalMilliseconds
    if ($totalProfileMilliseconds -eq 0) { $totalProfileMilliseconds = 1 } # Evitar divisão por zero se o tempo for muito rápido

    $dataForTable = foreach ($key in $script:ProfileLoadingTimes.Keys) {
        $elapsedMs = $script:ProfileLoadingTimes[$key]
        $percentage = ($elapsedMs / $totalProfileMilliseconds) * 100

        $color = [ConsoleColor]::Green
        if ($percentage -gt 40) { $color = [ConsoleColor]::Red }
        elseif ($percentage -gt 15) { $color = [ConsoleColor]::Yellow }

        [PSCustomObject]@{
            Section    = $key
            TimeMs     = $elapsedMs
            Percentage = $percentage
            Color      = $color
        }
    }

    $dataForTable | ForEach-Object {
        $sectionNameStr = ("{0,-45}" -f $_.Section)
        $timeStr = ("{0,7:N0}ms" -f $_.TimeMs).PadRight(10)
        $percStr = ("({0:N1}%)" -f $_.Percentage).PadLeft(8)
        Write-Host ($sectionNameStr + " : ") -NoNewline
        Write-Host ($timeStr + $percStr) -ForegroundColor $_.Color
    }

    $overallStopwatchFormatted = Format-TimeSpan -TimeSpan $script:OverallProfileStopwatch.Elapsed
    Write-Host "$($script:destaque)Tempo Total (Script Inteiro)  : $($overallStopwatchFormatted)$($script:reset)"
}
$sectionTimer.Stop()
$script:ProfileLoadingTimes['10. Def. Funções Usuário'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region 11. Aliases
$sectionTimer = [System.Diagnostics.Stopwatch]::StartNew()

# Aliases
Set-Alias -Name su          -Value admin            -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name adm         -Value admin            -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name jony        -Value home             -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name profile     -Value Edit-Profile     -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name ajuda       -Value Get-ProfileHelp  -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name tempos      -Value Get-LoadingTime  -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name explica     -Value Get-Definition   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name comando     -Value Get-Definition   -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name limpacache  -Value Clear-Cache      -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name sources     -Value Update-ProfileSources -Option AllScope -ErrorAction SilentlyContinue
# Adicione outros aliases aqui se desejar (ex: cls, .. etc.)

$sectionTimer.Stop()
$script:ProfileLoadingTimes['11. Aliases'] = $sectionTimer.ElapsedMilliseconds
#endregion
#region Finalização e Mensagens de Boas-vindas
$script:OverallProfileStopwatch.Stop() # Para o cronômetro geral

# Limpar tela no final do carregamento do perfil (opcional, descomente se desejar)
# Clear-Host

# Mensagem de boas-vindas / Status
Write-Host "`n$($script:título)Carregado em $($script:destaque)$(Format-TimeSpan $script:OverallProfileStopwatch.Elapsed)"
Write-Host "$($script:cmd)'ajuda'$($script:reset) para lista de comandos.$($script:reset)"
#endregion
