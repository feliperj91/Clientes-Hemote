Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Mutex para evitar múltiplas instâncias
$createdNew = $false
$refCreatedNew = [ref]$createdNew
$mutex = New-Object System.Threading.Mutex($true, "GerenciadorDeClientesMutex", $refCreatedNew)
if (-not $refCreatedNew.Value) {
    [System.Windows.Forms.MessageBox]::Show("O programa já está em execução.", "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    exit
}

$script:exiting = $false
$configFile = "C:\SACS\config.json"
$global:clientesPath = "C:\SACS\CLIENTES"

# Função para carregar clientes
function Load-Clientes {
    $comboBox.Items.Clear()
    if (Test-Path $global:clientesPath) {
        Get-ChildItem -Path $global:clientesPath -Directory | ForEach-Object {
            $clientePath = $_.FullName
            $iniExists = Test-Path (Join-Path $clientePath "_data_access.ini")
            $webExists = Test-Path (Join-Path $clientePath "WebUpdate.ini")
            if ($iniExists -and $webExists) {
                $comboBox.Items.Add($_.Name) | Out-Null
            }
        }
    }
}

# Função para obter COD_HEM atual
function Get-CodHemAtual {
    $iniPath = 'C:\SACS\_data_access.ini'
    if (-not (Test-Path $iniPath)) { return '' }
    try {
        $content = Get-Content -Path $iniPath -Raw
        $match = [regex]::Match($content, '(?im)^\s*N\s*=\[_cod_hem\]=\s*(.+)$')
        if ($match.Success) {
            return $match.Groups[1].Value.Trim()
        }
    }
    catch { return '' }
    return ''
}

# --- Função auxiliar para atualizar COD_HEM sem corromper o arquivo ---
function Atualizar-CodHem($valor) {
    $iniPath = "C:\SACS\_data_access.ini"
    if (Test-Path $iniPath) {
        $linhas = Get-Content $iniPath
        $alterado = $false
        for ($i = 0; $i -lt $linhas.Count; $i++) {
            if ($linhas[$i] -match '^\s*N\s*=\[_cod_hem\]=') {
                $linhas[$i] = "N =[_cod_hem]= $valor"
                $alterado = $true
            }
        }
        if (-not $alterado) {
            $linhas += "N =[_cod_hem]= $valor"
        }
        $linhas | Set-Content $iniPath -Encoding Default
    }
    else {
        "N =[_cod_hem]= $valor" | Set-Content $iniPath -Encoding Default
    }
}

# --- Função para alterar COD_HEM ---
function Show-CodHemDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Alterar COD_HEM"
    $dialog.Size = New-Object System.Drawing.Size(300, 150)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.KeyPreview = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Digite o COD_HEM que deseja acessar:"
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(260, 20)
    $dialog.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 35)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $dialog.Controls.Add($textBox)

    $btnConfirmar = New-Object System.Windows.Forms.Button
    $btnConfirmar.Text = "Confirmar"
    $btnConfirmar.Location = New-Object System.Drawing.Point(50, 70)
    $btnConfirmar.Size = New-Object System.Drawing.Size(80, 25)
    $btnConfirmar.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.Controls.Add($btnConfirmar)

    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = "Cancelar"
    $btnCancelar.Location = New-Object System.Drawing.Point(150, 70)
    $btnCancelar.Size = New-Object System.Drawing.Size(80, 25)
    $btnCancelar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($btnCancelar)

    # ENTER confirma, ESC cancela
    $dialog.AcceptButton = $btnConfirmar
    $dialog.CancelButton = $btnCancelar

    # Força maiúsculas
    $textBox.Add_TextChanged({
            $pos = $textBox.SelectionStart
            $textBox.Text = $textBox.Text.ToUpper()
            $textBox.SelectionStart = $pos
        })

    $dialog.TopMost = $true
    $dialog.StartPosition = "CenterParent"
    $result = $dialog.ShowDialog($form)

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $valor = $textBox.Text.Trim()
        if (-not $valor) {
            [System.Windows.Forms.MessageBox]::Show("Digite um valor para COD_HEM.", "Aviso",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        # Chama a função auxiliar para atualizar o COD_HEM
        Atualizar-CodHem $valor
    }
}
# Função para atualizar status no rodapé
function Update-Status {
    $texto = ""
    if ($menuLocalizacao.Checked) { $texto += "$global:clientesPath  " }
    if ($menuClienteAtual.Checked) {
        if (Test-Path $configFile) {
            $json = Get-Content $configFile | ConvertFrom-Json
            $clienteDefinido = $json.Configuracoes.ClienteDefinido
            if ($clienteDefinido) {
                if ($texto) { $texto += "   " }
                $texto += " $clienteDefinido  "
            }
        }
    }
    if ($menuCodHemAtual.Checked) {
        $codHem = Get-CodHemAtual
        if ($texto) { $texto += "   " }
        if ($codHem) { $texto += "$codHem" }
        else { $texto += "COD_HEM: (não definido)" }
    }
    $statusLabel.Text = $texto
}

# Form principal
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Clientes Hemote Plus'
$form.Size = New-Object System.Drawing.Size(420, 200)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.StartPosition = 'Manual'
$form.ShowInTaskbar = $false

# Posiciona no canto inferior direito
$form.Add_Load({
        $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $x = $wa.X + $wa.Width - $form.Width
        $y = $wa.Y + $wa.Height - $form.Height
        $form.Location = New-Object System.Drawing.Point($x, $y)
    })

# StatusStrip (rodapé)
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusStrip.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusStrip)

# Painéis para Início e Sobre
$painelInicio = New-Object System.Windows.Forms.Panel
$painelInicio.Location = New-Object System.Drawing.Point(10, 30)
$painelInicio.Size = New-Object System.Drawing.Size(390, 120)
$form.Controls.Add($painelInicio)

$painelSobre = New-Object System.Windows.Forms.Panel
$painelSobre.Location = New-Object System.Drawing.Point(10, 30)
$painelSobre.Size = New-Object System.Drawing.Size(390, 120)
$painelSobre.Visible = $false
$form.Controls.Add($painelSobre)

# --- Painel Início ---
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10, 10)
$comboBox.Size = New-Object System.Drawing.Size(235, 25)
$comboBox.DropDownStyle = 'DropDownList'
$painelInicio.Controls.Add($comboBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Confirmar'
$button.Location = New-Object System.Drawing.Point(250, 10)
$button.Size = New-Object System.Drawing.Size(100, 25)
$painelInicio.Controls.Add($button)

$btnPasta = New-Object System.Windows.Forms.Button
$btnPasta.Location = New-Object System.Drawing.Point(355, 10)
$btnPasta.Size = New-Object System.Drawing.Size(30, 25)

# --- Criar ícone de pasta dinamicamente ---
$folderBmp = New-Object System.Drawing.Bitmap(16, 16)
$g = [System.Drawing.Graphics]::FromImage($folderBmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$brushPasta = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 240, 180, 60)) # Cor amarela/laranja
$penBorda = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 180, 130, 40), 1)

# Desenha aba e corpo da pasta
$g.FillRectangle($brushPasta, 1, 1, 6, 4)   # Aba
$g.DrawRectangle($penBorda, 1, 1, 6, 4)
$g.FillRectangle($brushPasta, 1, 4, 13, 9)  # Corpo
$g.DrawRectangle($penBorda, 1, 4, 13, 9)
$g.Dispose()

$btnPasta.Image = $folderBmp
$btnPasta.ImageAlign = 'MiddleCenter'
# ------------------------------------------

$btnPasta.Add_Click({
        $pathAtalhos = "C:\SACS\atalhos\Hemote Plus Update"
        if (Test-Path $pathAtalhos) {
            Invoke-Item $pathAtalhos
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Pasta não encontrada:`n$pathAtalhos", "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
$painelInicio.Controls.Add($btnPasta)

$msgLabel = New-Object System.Windows.Forms.Label
$msgLabel.Location = New-Object System.Drawing.Point(10, 45)
$msgLabel.Size = New-Object System.Drawing.Size(350, 40)
$msgLabel.ForeColor = [System.Drawing.Color]::DarkSlateBlue
$painelInicio.Controls.Add($msgLabel)

# --- Painel Sobre ---
$painelSobre = New-Object System.Windows.Forms.Panel
$painelSobre.Location = New-Object System.Drawing.Point(10, 30)
$painelSobre.Size = New-Object System.Drawing.Size(390, 120)
$painelSobre.Visible = $false
$painelSobre.AutoScroll = $true   # habilita rolagem automática
$form.Controls.Add($painelSobre)

$sobreLabel = New-Object System.Windows.Forms.Label
$sobreLabel.Location = New-Object System.Drawing.Point(0, 0)
$sobreLabel.AutoSize = $true      # deixa o label expandir conforme o texto
$sobreLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$sobreLabel.Text = @"
• Alteração rápida entre clientes;
• Atualização dos atalhos com nome do cliente;
• Permite alterar o COD_HEM a cada seleção de cliente;
• Controle a opacidade e mantenha a janela sempre visível;
• Permite inicialização automática junto com o Windows;
• Ícone na bandeja para abrir/fechar sem encerrar o programa;

Autor: Felipe Almeida
Atualizado em: Dezembro de 2025
"@
$painelSobre.Controls.Add($sobreLabel)

# --- Barra de Menus ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip

$menuInicio = New-Object System.Windows.Forms.ToolStripMenuItem
$menuInicio.Text = 'Início'
$menuInicio.Add_Click({
        $painelInicio.Visible = $true
        $painelSobre.Visible = $false
    }) | Out-Null

$menuConfig = New-Object System.Windows.Forms.ToolStripMenuItem
$menuConfig.Text = 'Configurações'

$menuExibicao = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExibicao.Text = 'Exibição'

$menuSobre = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSobre.Text = 'Sobre'
$menuSobre.Add_Click({
        $painelInicio.Visible = $false
        $painelSobre.Visible = $true
    }) | Out-Null

# Adiciona os menus na ordem correta
$menuStrip.Items.Add($menuInicio)   | Out-Null
$menuStrip.Items.Add($menuConfig)   | Out-Null
$menuStrip.Items.Add($menuExibicao) | Out-Null
$menuStrip.Items.Add($menuSobre)    | Out-Null

$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# --- Menu Configurações ---
$menuClientes = New-Object System.Windows.Forms.ToolStripMenuItem
$menuClientes.Text = 'Clientes'
$menuClientes.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Selecione a pasta CLIENTES"
        $dialog.SelectedPath = $global:clientesPath
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $global:clientesPath = $dialog.SelectedPath
            Save-Config
            Load-Clientes
            Update-Status
        }
    }) | Out-Null

$menuAlterarCodHem = New-Object System.Windows.Forms.ToolStripMenuItem
$menuAlterarCodHem.Text = 'Altera COD_HEM'
$menuAlterarCodHem.CheckOnClick = $true
$menuAlterarCodHem.Add_Click({ Save-Config }) | Out-Null

$menuIniciarWindows = New-Object System.Windows.Forms.ToolStripMenuItem
$menuIniciarWindows.Text = 'Iniciar com o Windows'
$menuIniciarWindows.CheckOnClick = $true
$menuIniciarWindows.Add_Click({
        Save-Config
        Set-Startup $menuIniciarWindows.Checked
    }) | Out-Null

$menuConfig.DropDownItems.Add($menuClientes)       | Out-Null
$menuConfig.DropDownItems.Add($menuAlterarCodHem)  | Out-Null
$menuConfig.DropDownItems.Add($menuIniciarWindows) | Out-Null

# --- Menu Exibição ---
$menuClienteAtual = New-Object System.Windows.Forms.ToolStripMenuItem
$menuClienteAtual.Text = 'Cliente atual'
$menuClienteAtual.CheckOnClick = $true
$menuClienteAtual.Add_Click({ Update-Status; Save-Config }) | Out-Null

$menuCodHemAtual = New-Object System.Windows.Forms.ToolStripMenuItem
$menuCodHemAtual.Text = 'COD_HEM atual'
$menuCodHemAtual.CheckOnClick = $true
$menuCodHemAtual.Add_Click({ Update-Status; Save-Config }) | Out-Null

$menuLocalizacao = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLocalizacao.Text = 'Caminho da pasta Clientes'
$menuLocalizacao.CheckOnClick = $true
$menuLocalizacao.Add_Click({ Update-Status; Save-Config }) | Out-Null

$menuSempreVisivel = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSempreVisivel.Text = 'Sempre Visível'
$menuSempreVisivel.CheckOnClick = $true
$menuSempreVisivel.Add_Click({ $form.TopMost = $menuSempreVisivel.Checked; Save-Config }) | Out-Null

$menuOpacidade = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpacidade.Text = 'Opacidade'
foreach ($valor in 20, 40, 60, 80, 100) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem
    $item.Text = "$valor%"
    $item.Tag = $valor
    $item.CheckOnClick = $true
    $item.Add_Click({
            foreach ($i in $menuOpacidade.DropDownItems) { $i.Checked = $false }
            $this.Checked = $true
            $form.Opacity = [double]($this.Tag) / 100
            Save-Config
        }) | Out-Null
    $menuOpacidade.DropDownItems.Add($item) | Out-Null
}
($menuOpacidade.DropDownItems | Where-Object { $_.Tag -eq 100 }).Checked = $true

$menuExibicao.DropDownItems.Add($menuClienteAtual)  | Out-Null
$menuExibicao.DropDownItems.Add($menuCodHemAtual)   | Out-Null
$menuExibicao.DropDownItems.Add($menuLocalizacao)   | Out-Null
$menuExibicao.DropDownItems.Add($menuSempreVisivel) | Out-Null
$menuExibicao.DropDownItems.Add($menuOpacidade)     | Out-Null
# Eventos de MouseHover para mostrar dicas no rodapé

# --- Timer para restaurar rodapé ---
$restoreStatusTimer = New-Object System.Windows.Forms.Timer
$restoreStatusTimer.Interval = 4000   # tempo em ms (4 segundos, ajuste se quiser)
$restoreStatusTimer.Add_Tick({
        $restoreStatusTimer.Stop()
        Update-Status
    })

# Eventos de MouseHover para mostrar dicas no rodapé

# Menus principais
$menuInicio.Add_MouseHover({ 
        $statusLabel.Text = "Voltar para a tela inicial de seleção de cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$btnPasta.Add_MouseHover({
        $statusLabel.Text = "Abrir pasta de atalhos (C:\SACS\atalhos\Hemote Plus Update)"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuConfig.Add_MouseHover({ 
        $statusLabel.Text = "Configurações gerais do programa"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuExibicao.Add_MouseHover({ 
        $statusLabel.Text = "Opções de exibição da janela e informações"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuSobre.Add_MouseHover({ 
        $statusLabel.Text = "Informações sobre o programa"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Configurações
$menuClientes.Add_MouseHover({ 
        $statusLabel.Text = "Define a pasta com os arquivos do cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuAlterarCodHem.Add_MouseHover({ 
        $statusLabel.Text = "Permitir alterar o COD_HEM após selecionar o cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuIniciarWindows.Add_MouseHover({ 
        $statusLabel.Text = "Habilitar ou desabilitar inicialização automática com o Windows"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Exibição
$menuClienteAtual.Add_MouseHover({ 
        $statusLabel.Text = "Mostrar o cliente atual no rodapé"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuCodHemAtual.Add_MouseHover({ 
        $statusLabel.Text = "Mostrar o COD_HEM atual no rodapé"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuLocalizacao.Add_MouseHover({ 
        $statusLabel.Text = "Mostrar o caminho da pasta de clientes no rodapé"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuSempreVisivel.Add_MouseHover({ 
        $statusLabel.Text = "Manter a janela sempre visível sobre outras aplicações"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuOpacidade.Add_MouseHover({ 
        $statusLabel.Text = "Ajustar a opacidade da janela"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# --- Funções auxiliares ---
function Save-Config {
    $opItem = ($menuOpacidade.DropDownItems | Where-Object { $_.Checked } | Select-Object -First 1)
    $opacidadeAtual = if ($opItem) { [int]$opItem.Tag } else { 100 }

    $configAtual = if (Test-Path $configFile) {
        Get-Content $configFile | ConvertFrom-Json
    }
    else {
        @{ Configuracoes = @{} }
    }

    $clienteDefinido = $configAtual.Configuracoes.ClienteDefinido

    $obj = @{
        ClientesPath  = $global:clientesPath
        Exibicao      = @{
            LocalizacaoClientes = $menuLocalizacao.Checked
            SempreVisivel       = $menuSempreVisivel.Checked
            Opacidade           = $opacidadeAtual
            ClienteAtual        = $menuClienteAtual.Checked
            CodHemAtual         = $menuCodHemAtual.Checked
        }
        Configuracoes = @{
            AlterarCodHem     = $menuAlterarCodHem.Checked
            IniciarComWindows = $menuIniciarWindows.Checked
            ClienteDefinido   = $clienteDefinido
        }
    }

    $obj | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
}

function Load-Config {
    if (Test-Path $configFile) {
        $json = Get-Content $configFile | ConvertFrom-Json
        if ($json.ClientesPath) { $global:clientesPath = $json.ClientesPath }

        $menuLocalizacao.Checked = $json.Exibicao.LocalizacaoClientes
        $menuSempreVisivel.Checked = $json.Exibicao.SempreVisivel
        $form.TopMost = $json.Exibicao.SempreVisivel

        foreach ($i in $menuOpacidade.DropDownItems) { $i.Checked = $false }
        $itemMatch = ($menuOpacidade.DropDownItems | Where-Object { $_.Tag -eq $json.Exibicao.Opacidade } | Select-Object -First 1)
        if ($itemMatch) {
            $itemMatch.Checked = $true
            $form.Opacity = [double]($itemMatch.Tag) / 100
        }

        $menuAlterarCodHem.Checked = $json.Configuracoes.AlterarCodHem
        $menuIniciarWindows.Checked = $json.Configuracoes.IniciarComWindows
        $menuClienteAtual.Checked = $json.Exibicao.ClienteAtual
        $menuCodHemAtual.Checked = $json.Exibicao.CodHemAtual

        Load-Clientes
        Set-Startup $menuIniciarWindows.Checked
    }
    else {
        $menuLocalizacao.Checked = $true
        $menuClienteAtual.Checked = $true
        $menuCodHemAtual.Checked = $true
    }
    Update-Status
}

# --- Função para criar/remover atalho de inicialização ---
function Set-Startup($enable) {
    $startupPath = [System.IO.Path]::Combine(
        $env:APPDATA,
        'Microsoft\Windows\Start Menu\Programs\Startup',
        'ClientesHemotePlus.lnk'
    )

    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName

    if ($enable) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($startupPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
        $shortcut.Save()
    }
    else {
        if (Test-Path $startupPath) {
            Remove-Item $startupPath -Force
        }
    }
}

# --- Ícone da bandeja ---
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true
$notifyIcon.Text = 'Clientes Hemote Plus'

$icoPath = 'C:\BASES HEMOTE\V8\sangue.ico'
if (Test-Path $icoPath) {
    try {
        $notifyIcon.Icon = New-Object System.Drawing.Icon($icoPath)
        $form.Icon = $notifyIcon.Icon
    }
    catch {
        # Se falhar ao carregar o ícone externo, usa o ícone embutido no .exe
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
        $form.Icon = $notifyIcon.Icon
    }
}
else {
    # Se o arquivo não existir, usa o ícone embutido no .exe
    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
    $form.Icon = $notifyIcon.Icon
}
function Show-Form {
    $form.Show()
    $form.WindowState = 'Normal'
    $form.ShowInTaskbar = $false
}


# --- Menu da bandeja ---
$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayAbrir = $trayMenu.Items.Add('Abrir')
$traySair = $trayMenu.Items.Add('Sair')
$trayAbrir.Add_Click({ Show-Form }) | Out-Null
$traySair.Add_Click({
        Save-Config
        $script:exiting = $true
        try { $mutex.ReleaseMutex() } catch {}
        try { $notifyIcon.Visible = $false; $notifyIcon.Dispose() } catch {}
        try { $form.Close() } catch {}
        [System.Windows.Forms.Application]::Exit()
        [System.Environment]::Exit(0)
    }) | Out-Null
$notifyIcon.ContextMenuStrip = $trayMenu
$notifyIcon.Add_DoubleClick({ Show-Form }) | Out-Null

# --- Eventos de minimizar e fechar ---
$form.Add_Resize({
        if ($form.WindowState -eq 'Minimized') {
            $form.Hide()
            $form.ShowInTaskbar = $false
        }
    }) | Out-Null

$form.Add_FormClosing({
        if (-not $script:exiting) {
            $_.Cancel = $true
            $form.Hide()
            $form.ShowInTaskbar = $false
        }
        else {
            $_.Cancel = $false
        }
    }) | Out-Null

# Carregar configuração inicial
Load-Config
Update-Status

# --- Botão Confirmar ---
$button.Add_Click({
        $cliente = $comboBox.SelectedItem
        if (-not $cliente) { 
            $msgLabel.Text = 'Selecione um cliente.' 
            $clearMsgTimer.Stop(); $clearMsgTimer.Start()
            return 
        }

        try {
            $origemCliente = Join-Path $global:clientesPath $cliente

            # Arquivos que vão para C:\SACS
            foreach ($arquivo in @("_data_access.ini", "logo.jpg", "logo2.jpg")) {
                $origem = Join-Path $origemCliente $arquivo
                if (Test-Path $origem) {
                    Copy-Item -Path $origem -Destination "C:\SACS\" -Force -ErrorAction Stop
                }
            }

            # Arquivo WebUpdate.ini vai para C:\SACS\BootStrap
            $origemWebUpdate = Join-Path $origemCliente "WebUpdate.ini"
            if (Test-Path $origemWebUpdate) {
                $destinoBootStrap = "C:\SACS\BootStrap"
                if (-not (Test-Path $destinoBootStrap)) {
                    New-Item -ItemType Directory -Path $destinoBootStrap | Out-Null
                }
                Copy-Item -Path $origemWebUpdate -Destination $destinoBootStrap -Force -ErrorAction Stop
            }
        }
        catch {
            $msgLabel.Text = "Erro ao copiar arquivos: $($_.Exception.Message)"
            $clearMsgTimer.Stop(); $clearMsgTimer.Start()
            return
        }
	
        # --- Validação de duplicidade ---
        $clientesDuplicados = @()

        # Pega valores do cliente selecionado
        $origemCliente = Join-Path $global:clientesPath $cliente
        $iniPath = Join-Path $origemCliente "_data_access.ini"
        $webUpdatePath = Join-Path $origemCliente "WebUpdate.ini"

        $codHemSelecionado = ""
        $urlSelecionado = ""

        if (Test-Path $iniPath) {
            $contentIni = Get-Content $iniPath -Raw
            $match = [regex]::Match($contentIni, '(?im)^\s*N\s*=\[_ws_url\]\s*=\s*(.+)$')
            if ($match.Success) { $codHemSelecionado = $match.Groups[1].Value.Trim() }
        }

        if (Test-Path $webUpdatePath) {
            $contentWeb = Get-Content $webUpdatePath -Raw
            $matchUrl = [regex]::Match($contentWeb, '(?im)^\s*URL\s*=\s*(.+)$')
            if ($matchUrl.Success) { $urlSelecionado = $matchUrl.Groups[1].Value.Trim() }
        }

        # Comparar com outros clientes
        Get-ChildItem -Path $global:clientesPath -Directory | ForEach-Object {
            if ($_.Name -ne $cliente) {
                $outroCliente = $_.Name
                $outroIni = Join-Path $_.FullName "_data_access.ini"
                $outroWeb = Join-Path $_.FullName "WebUpdate.ini"

                $codHemOutro = ""
                $urlOutro = ""

                if (Test-Path $outroIni) {
                    $cIni = Get-Content $outroIni -Raw
                    $mIni = [regex]::Match($cIni, '(?im)^\s*N\s*=\[_ws_url\]\s*=\s*(.+)$')
                    if ($mIni.Success) { $codHemOutro = $mIni.Groups[1].Value.Trim() }
                }

                if (Test-Path $outroWeb) {
                    $cWeb = Get-Content $outroWeb -Raw
                    $mWeb = [regex]::Match($cWeb, '(?im)^\s*URL\s*=\s*(.+)$')
                    if ($mWeb.Success) { $urlOutro = $mWeb.Groups[1].Value.Trim() }
                }

                if ($codHemSelecionado -ne "" -and $codHemSelecionado -eq $codHemOutro) {
                    $clientesDuplicados += "$outroCliente (duplicado em _data_access.ini)"
                }
                elseif ($urlSelecionado -ne "" -and $urlSelecionado -eq $urlOutro) {
                    $clientesDuplicados += "$outroCliente (duplicado em WebUpdate.ini)"
                }
            }
        }


        if ($clientesDuplicados.Count -gt 0) {
            $msgLabel.Text = "Duplicidade detectada: $cliente igual a " + ($clientesDuplicados -join ', ')
            return
        }

        # Se opção Alterar cod_hem marcada, abre diálogo COD_HEM
        if ($menuAlterarCodHem.Checked) {
            Show-CodHemDialog
        }

        # Atualiza config.json com cliente definido
        $config = if (Test-Path $configFile) {
            Get-Content $configFile | ConvertFrom-Json
        }
        else {
            @{ ClientesPath = $global:clientesPath; Exibicao = @{}; Configuracoes = @{} }
        }
        if (-not $config.Configuracoes) { $config.Configuracoes = @{} }
        $config.Configuracoes.ClienteDefinido = $cliente
        $config | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
	
        # --- Mapeamento e atualização dos atalhos ---
        $atalhosPath = "C:\SACS\atalhos\Hemote Plus Update"
        if (Test-Path $atalhosPath) {
            Get-ChildItem -Path $atalhosPath -Filter "*.lnk" | ForEach-Object {
                $atalho = $_
                $atalhoOriginal = $atalho.FullName
                $nomeBase = $atalho.BaseName

                # Remove cliente anterior, se houver (último sufixo após " - ")
                $partes = $nomeBase -split ' - '
                if ($partes.Count -gt 2) {
                    $nomeLimpo = ($partes[0..1] -join ' - ')
                }
                else {
                    $nomeLimpo = $nomeBase
                }

                # Novo nome com cliente atual
                $novoNome = "$nomeLimpo - $cliente.lnk"
                $novoCaminho = Join-Path $atalhosPath $novoNome

                # Renomeia se necessário
                if ($atalhoOriginal -ne $novoCaminho) {
                    Rename-Item -Path $atalhoOriginal -NewName $novoNome -Force
                }
            }
        }

        Update-Status
        $msgLabel.Text = "Cliente $cliente definido com sucesso!"
        $clearMsgTimer.Stop(); $clearMsgTimer.Start()
    }) | Out-Null

# --- Timer para limpar mensagens ---
$clearMsgTimer = New-Object System.Windows.Forms.Timer
$clearMsgTimer.Interval = 5000
$clearMsgTimer.Add_Tick({
        $msgLabel.Text = ""
        $clearMsgTimer.Stop()
    })

# --- Loop principal da aplicação ---
try {
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    try { $mutex.ReleaseMutex() } catch {}
}