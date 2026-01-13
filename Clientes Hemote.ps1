Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Classe auxiliar para manipular Title Bar (Dark Mode nativo do Windows)
$code = @"
using System;
using System.Runtime.InteropServices;
public class DarkModeHelper {
    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
    private const int DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;

    public static void SetDarkMode(IntPtr handle, bool enabled) {
        int useDarkMode = enabled ? 1 : 0;
        // Tenta primeiro o atributo moderno (Windows 11 e Windows 10 20H1+)
        int result = DwmSetWindowAttribute(handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref useDarkMode, 4);
        
        // Se falhar (retorno != 0), tenta o atributo legado (versões antigas do Windows 10)
        if (result != 0) {
            DwmSetWindowAttribute(handle, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, ref useDarkMode, 4);
        }
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp

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
$global:clientCache = @{} # Armazena info dos clientes para performance (Path, CodHem, Url)

# Função para carregar clientes e popular cache (Otimização)
function Load-Clientes {
    $comboBox.Items.Clear()
    $global:clientCache.Clear()

    if (Test-Path $global:clientesPath) {
        $statusLabelClient.Text = "Carregando clientes..."
        [System.Windows.Forms.Application]::DoEvents()

        Get-ChildItem -Path $global:clientesPath -Directory | ForEach-Object {
            $clientePath = $_.FullName
            $nome = $_.Name
            $iniPath = Join-Path $clientePath "_data_access.ini"
            $webPath = Join-Path $clientePath "WebUpdate.ini"

            if ((Test-Path $iniPath) -and (Test-Path $webPath)) {
                $comboBox.Items.Add($nome) | Out-Null
                
                # Pré-carregar dados para o cache
                $codHem = ""
                $url = ""
                
                try {
                    $cIni = Get-Content $iniPath -Raw -ErrorAction SilentlyContinue
                    if ($cIni -match '(?im)^\s*N\s*=\[_ws_url\]\s*=\s*(.+)$') { 
                        $codHem = $matches[1].Trim() 
                    }
                    
                    $cWeb = Get-Content $webPath -Raw -ErrorAction SilentlyContinue
                    if ($cWeb -match '(?im)^\s*URL\s*=\s*(.+)$') { 
                        $url = $matches[1].Trim() 
                    }
                }
                catch {}

                $global:clientCache[$nome] = @{
                    Path   = $clientePath
                    CodHem = $codHem
                    Url    = $url
                }
            }
        }
        $statusLabelClient.Text = "Pronto."
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
    $dialog.Size = New-Object System.Drawing.Size(320, 180) # Moderno
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.KeyPreview = $true
    $dialog.BackColor = [System.Drawing.Color]::White
    $dialog.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Digite o COD_HEM que deseja acessar:"
    $label.Location = New-Object System.Drawing.Point(15, 15)
    $label.AutoSize = $true
    $dialog.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(18, 45)
    $textBox.Size = New-Object System.Drawing.Size(260, 25)
    $dialog.Controls.Add($textBox)

    $btnConfirmar = New-Object System.Windows.Forms.Button
    $btnConfirmar.Text = "Confirmar"
    $btnConfirmar.Location = New-Object System.Drawing.Point(50, 90)
    $btnConfirmar.Size = New-Object System.Drawing.Size(90, 30)
    $btnConfirmar.FlatStyle = 'Flat'
    $btnConfirmar.FlatAppearance.BorderSize = 0
    $btnConfirmar.BackColor = [System.Drawing.Color]::DodgerBlue
    $btnConfirmar.ForeColor = [System.Drawing.Color]::White
    $btnConfirmar.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnConfirmar.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.Controls.Add($btnConfirmar)

    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = "Cancelar"
    $btnCancelar.Location = New-Object System.Drawing.Point(160, 90)
    $btnCancelar.Size = New-Object System.Drawing.Size(90, 30)
    $btnCancelar.FlatStyle = 'Flat'
    $btnCancelar.FlatAppearance.BorderSize = 1
    $btnCancelar.FlatAppearance.BorderColor = [System.Drawing.Color]::LightGray
    $btnCancelar.BackColor = [System.Drawing.Color]::White
    $btnCancelar.ForeColor = [System.Drawing.Color]::Black
    $btnCancelar.Cursor = [System.Windows.Forms.Cursors]::Hand
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
# Função para atualizar status no rodapé (Segmentado)
function Update-Status {
    $textoEsq = " "
    
    $textoEsq = " "

    # 2. Atualiza Cliente
    if ($menuClienteAtual.Checked) {
        $cliConfig = ""
        if (Test-Path $configFile) {
            try { $json = Get-Content $configFile | ConvertFrom-Json; $cliConfig = $json.Configuracoes.ClienteDefinido } catch {}
        }
        $val = if ($cliConfig) { $cliConfig } else { "---" }
        $textoEsq += "Cliente: $val"
    }
    
    $statusLabelClient.Text = $textoEsq

    # 3. Atualiza CodHem
    if ($menuCodHemAtual.Checked) {
        $valCod = Get-CodHemAtual
        if (-not $valCod) { $valCod = "---" }
        $statusLabelCod.Text = " COD: $valCod "
    }
    else {
        $statusLabelCod.Text = ""
    }
}

# Form principal
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Clientes Hemote Plus'
$form.Size = New-Object System.Drawing.Size(530, 210) # Expandido para caber mensagens longas
$form.FormBorderStyle = 'FixedSingle' # Permite exibir o ícone na barra de título
$form.MaximizeBox = $false
$form.StartPosition = 'Manual'
$form.ShowInTaskbar = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10) # Fonte Moderna
$form.BackColor = [System.Drawing.Color]::White # Fundo Clean


# Posiciona no canto inferior direito
$form.Add_Load({
        $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $x = $wa.X + $wa.Width - $form.Width
        $y = $wa.Y + $wa.Height - $form.Height
        $form.Location = New-Object System.Drawing.Point($x, $y)
        
        # Garante que o Dark Mode seja aplicado assim que a janela for criada
        $form.Add_HandleCreated({
                try { [DarkModeHelper]::SetDarkMode($form.Handle, $menuModoEscuro.Checked) } catch {}
            })

    })

# StatusStrip (rodapé Moderno e Interativo)
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::White
$statusStrip.SizingGrip = $false

# 1. Cliente (Esquerda, Spring)
$statusLabelClient = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabelClient.Spring = $true
$statusLabelClient.TextAlign = 'MiddleLeft'
$statusLabelClient.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$statusLabelClient.ForeColor = [System.Drawing.Color]::DarkSlateGray

# 2. COD_HEM (Direita, Interativo)
$statusLabelCod = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabelCod.BorderSides = 'Left'
$statusLabelCod.BorderStyle = 'Flat'
$statusLabelCod.IsLink = $true
$statusLabelCod.LinkColor = [System.Drawing.Color]::DodgerBlue
$statusLabelCod.ActiveLinkColor = [System.Drawing.Color]::Blue
$statusLabelCod.ToolTipText = "Clique para alterar o COD_HEM"
$statusLabelCod.Add_Click({ Show-CodHemDialog; Update-Status })

# 3. Pasta SACS (Direita, Fixa)
$statusLabelDir = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabelDir.Text = " SACS "
$statusLabelDir.BorderSides = 'Left'
$statusLabelDir.BorderStyle = 'Flat'
$statusLabelDir.IsLink = $true
$statusLabelDir.LinkColor = [System.Drawing.Color]::DimGray
$statusLabelDir.ToolTipText = "Abrir pasta C:\SACS"
$statusLabelDir.Add_Click({ if (Test-Path "C:\SACS") { Invoke-Item "C:\SACS" } })

$statusStrip.Items.Add($statusLabelClient) | Out-Null
$statusStrip.Items.Add($statusLabelCod) | Out-Null
$statusStrip.Items.Add($statusLabelDir) | Out-Null
$form.Controls.Add($statusStrip)

# Painéis para Início e Sobre
$painelInicio = New-Object System.Windows.Forms.Panel
$painelInicio.Location = New-Object System.Drawing.Point(10, 30)
$painelInicio.Size = New-Object System.Drawing.Size(500, 130)
$painelInicio.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($painelInicio)



# --- Painel Início (Modernizado) ---
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10, 15)
$comboBox.Size = New-Object System.Drawing.Size(330, 28) 
$comboBox.DropDownStyle = 'DropDownList'
$comboBox.FlatStyle = 'System' # Usa renderização nativa (corrige fundo azul)
$comboBox.Add_KeyPress({ $_.Handled = $true }) # Previne digitação no modo DropDown (Dark Mode Hack)
$painelInicio.Controls.Add($comboBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = 'Confirmar'
$button.Location = New-Object System.Drawing.Point(350, 13)
$button.Size = New-Object System.Drawing.Size(90, 30)
$button.FlatStyle = 'Flat'
$button.FlatAppearance.BorderSize = 0
$button.BackColor = [System.Drawing.Color]::DodgerBlue # Azul Pro
$button.ForeColor = [System.Drawing.Color]::White     # Texto Branco
$button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button.Cursor = [System.Windows.Forms.Cursors]::Hand
$painelInicio.Controls.Add($button)

$btnPasta = New-Object System.Windows.Forms.Button
$btnPasta.Location = New-Object System.Drawing.Point(450, 13)
$btnPasta.Size = New-Object System.Drawing.Size(32, 30)
$btnPasta.FlatStyle = 'Flat'
$btnPasta.FlatAppearance.BorderSize = 0
$btnPasta.BackColor = [System.Drawing.Color]::WhiteSmoke
$btnPasta.Cursor = [System.Windows.Forms.Cursors]::Hand

# --- Criar ícone de pasta dinamicamente (Melhorado) ---
$folderBmp = New-Object System.Drawing.Bitmap(20, 20) # Aumentado levemente para 20x20
$g = [System.Drawing.Graphics]::FromImage($folderBmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias # Suavização
$brushPasta = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 190, 0)) # Amarelo Ouro
$penBorda = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 200, 140, 0), 1.5)

# Desenha aba e corpo da pasta (Coordenadas ajustadas)
$g.FillRectangle($brushPasta, 2, 3, 7, 4)   # Aba
$g.DrawRectangle($penBorda, 2, 3, 7, 4)
$g.FillRectangle($brushPasta, 2, 6, 16, 11)  # Corpo
$g.DrawRectangle($penBorda, 2, 6, 16, 11)
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
$msgLabel.Location = New-Object System.Drawing.Point(10, 55) # Levemente mais para baixo
$msgLabel.Size = New-Object System.Drawing.Size(480, 40)
$msgLabel.ForeColor = [System.Drawing.Color]::ForestGreen # Verde Sucesso
$msgLabel.TextAlign = 'MiddleCenter' # Centralizado
$msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$painelInicio.Controls.Add($msgLabel)

# --- Painel Sobre ---
$painelSobre = New-Object System.Windows.Forms.Panel
$painelSobre.Location = New-Object System.Drawing.Point(10, 30)
$painelSobre.Size = New-Object System.Drawing.Size(500, 130)
$painelSobre.Visible = $false
$painelSobre.AutoScroll = $true
$painelSobre.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($painelSobre)

$sobreLabel = New-Object System.Windows.Forms.Label
$sobreLabel.Location = New-Object System.Drawing.Point(0, 0)
$sobreLabel.AutoSize = $true
$sobreLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9) # Mantém 9 no texto longo para caber, ou 10 se preferir
$sobreLabel.Text = @"
Clientes Hemote Plus - v11

• Troca Rápida: Alterne entre clientes com atualização automática de atalhos.
• Segurança: Validação automática de duplicidade de conexões.
• Produtividade: Edição rápida de COD_HEM e acesso à pasta SACS pelo rodapé.
• Controle: Opacidade, janela 'Sempre Visível' e inicialização com Windows.
• Performance: Sistema de cache para validação instantânea.

Desenvolvido por: Felipe Almeida
Última Atualização: Janeiro de 2026
"@
$painelSobre.Controls.Add($sobreLabel)

# --- Barra de Menus ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::White # Harmonização do tema
$menuStrip.RenderMode = 'System' # Tenta usar renderização nativa/flat se possível

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

$menuValidarDuplicidade = New-Object System.Windows.Forms.ToolStripMenuItem
$menuValidarDuplicidade.Text = 'Validar duplicidade de URL'
$menuValidarDuplicidade.CheckOnClick = $true
$menuValidarDuplicidade.Add_Click({ Save-Config }) | Out-Null

$menuConfig.DropDownItems.Add($menuClientes)       | Out-Null
$menuConfig.DropDownItems.Add($menuAlterarCodHem)  | Out-Null
$menuConfig.DropDownItems.Add($menuValidarDuplicidade) | Out-Null
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

$menuBotaoSacs = New-Object System.Windows.Forms.ToolStripMenuItem
$menuBotaoSacs.Text = 'Atalho Pasta SACS'
$menuBotaoSacs.CheckOnClick = $true
$menuBotaoSacs.Add_Click({ 
        $statusLabelDir.Visible = $menuBotaoSacs.Checked
        Save-Config 
    }) | Out-Null
    
$menuModoEscuro = New-Object System.Windows.Forms.ToolStripMenuItem
$menuModoEscuro.Text = 'Modo Escuro'
$menuModoEscuro.CheckOnClick = $true
$menuModoEscuro.Add_Click({ Apply-Theme; Save-Config }) | Out-Null
$menuModoEscuro.Add_MouseHover({ 
        $statusLabelClient.Text = "Alternar entre tema Claro e Escuro"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })



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
$menuExibicao.DropDownItems.Add($menuBotaoSacs)     | Out-Null
$menuExibicao.DropDownItems.Add($menuModoEscuro)    | Out-Null
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
# Menus principais
$menuInicio.Add_MouseHover({ 
        $statusLabelClient.Text = "Voltar para a tela inicial de seleção de cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$btnPasta.Add_MouseHover({
        $statusLabelClient.Text = "Abrir pasta de atalhos (C:\SACS\atalhos\Hemote Plus Update)"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuConfig.Add_MouseHover({ 
        $statusLabelClient.Text = "Configurações gerais do programa"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuExibicao.Add_MouseHover({ 
        $statusLabelClient.Text = "Opções de exibição da janela e informações"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuSobre.Add_MouseHover({ 
        $statusLabelClient.Text = "Informações sobre o programa"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Configurações
$menuClientes.Add_MouseHover({ 
        $statusLabelClient.Text = "Define a pasta com os arquivos do cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuAlterarCodHem.Add_MouseHover({ 
        $statusLabelClient.Text = "Permitir alterar o COD_HEM após selecionar o cliente"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuIniciarWindows.Add_MouseHover({ 
        $statusLabelClient.Text = "Habilitar ou desabilitar inicialização automática com o Windows"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuValidarDuplicidade.Add_MouseHover({ 
        $statusLabelClient.Text = "Verificar se existe duplicidade de data_access e webupdate."
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Exibição
$menuClienteAtual.Add_MouseHover({ 
        $statusLabelClient.Text = "Mostrar o cliente atual no rodapé"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuCodHemAtual.Add_MouseHover({ 
        $statusLabelClient.Text = "Mostrar o COD_HEM atual no rodapé"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

$menuBotaoSacs.Add_MouseHover({ 
        $statusLabelClient.Text = "Mostrar/Ocultar o botão de atalho para C:\SACS"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })



$menuSempreVisivel.Add_MouseHover({ 
        $statusLabelClient.Text = "Manter a janela sempre visível sobre outras aplicações"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuOpacidade.Add_MouseHover({ 
        $statusLabelClient.Text = "Ajustar a opacidade da janela"
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# --- Função de Tema (Dark Mode) ---
function Apply-Theme {
    if ($menuModoEscuro.Checked) {
        $bg = [System.Drawing.Color]::FromArgb(45, 45, 48) # VS Code Dark
        $panelBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $fg = [System.Drawing.Color]::WhiteSmoke
        $inputBg = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $btnPastaBg = [System.Drawing.Color]::FromArgb(80, 80, 80)
    }
    else {
        $bg = [System.Drawing.Color]::White
        $panelBg = [System.Drawing.Color]::White
        $fg = [System.Drawing.Color]::Black
        $inputBg = [System.Drawing.Color]::White
        $btnPastaBg = [System.Drawing.Color]::WhiteSmoke
    }

    # Aplica Dark Mode na Barra de Título (Windows 10/11)
    # Aplica Dark Mode na Barra de Título (Windows 10/11)
    try { [DarkModeHelper]::SetDarkMode($form.Handle, $menuModoEscuro.Checked) } catch {}

    $form.BackColor = $bg
    $form.ForeColor = $fg
    $painelInicio.BackColor = $panelBg
    $painelSobre.BackColor = $panelBg
    $menuStrip.BackColor = $panelBg
    $menuStrip.ForeColor = $fg
    $statusStrip.BackColor = $panelBg
    $statusStrip.ForeColor = $fg
    
    $statusLabelClient.ForeColor = if ($menuModoEscuro.Checked) { [System.Drawing.Color]::LightGray } else { [System.Drawing.Color]::DarkSlateGray }
    
    # ComboBox
    if ($menuModoEscuro.Checked) {
        # Hack: Muda para DropDown (editável) para aceitar cores, mas bloqueamos digitação no KeyPress
        $comboBox.DropDownStyle = 'DropDown' 
        $comboBox.FlatStyle = 'Flat'
        $comboBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $comboBox.ForeColor = [System.Drawing.Color]::WhiteSmoke
    }
    else {
        $comboBox.DropDownStyle = 'DropDownList'
        $comboBox.FlatStyle = 'Standard'
        $comboBox.BackColor = [System.Drawing.Color]::White
        $comboBox.ForeColor = [System.Drawing.Color]::Black
    }
    
    $btnPasta.BackColor = $btnPastaBg
    $sobreLabel.ForeColor = $fg
    
    # Invalida para redesenhar bordas se necessário
    $form.Refresh()
}

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

            SempreVisivel = $menuSempreVisivel.Checked
            Opacidade     = $opacidadeAtual
            ClienteAtual  = $menuClienteAtual.Checked
            CodHemAtual   = $menuCodHemAtual.Checked
            BotaoSacs     = $menuBotaoSacs.Checked
            ModoEscuro    = $menuModoEscuro.Checked
        }
        Configuracoes = @{
            AlterarCodHem      = $menuAlterarCodHem.Checked
            IniciarComWindows  = $menuIniciarWindows.Checked
            ValidarDuplicidade = $menuValidarDuplicidade.Checked
            ClienteDefinido    = $clienteDefinido
        }
    }

    $obj | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
}

function Load-Config {
    if (Test-Path $configFile) {
        $json = Get-Content $configFile | ConvertFrom-Json
        if ($json.ClientesPath) { $global:clientesPath = $json.ClientesPath }


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
        
        # Carrega ValidarDuplicidade (padrão true se não existir no JSON para manter comportamento anterior)
        if ($json.Configuracoes.PSObject.Properties.Match('ValidarDuplicidade').Count) {
            $menuValidarDuplicidade.Checked = $json.Configuracoes.ValidarDuplicidade
        }
        else {
            $menuValidarDuplicidade.Checked = $true
        }

        $menuClienteAtual.Checked = $json.Exibicao.ClienteAtual
        $menuCodHemAtual.Checked = $json.Exibicao.CodHemAtual
        
        if ($json.Exibicao.PSObject.Properties.Match('BotaoSacs').Count) {
            $menuBotaoSacs.Checked = $json.Exibicao.BotaoSacs
        }
        else {
            $menuBotaoSacs.Checked = $true # Padrão ativado para novos
        }
        if ($json.Exibicao.PSObject.Properties.Match('ModoEscuro').Count) {
            $menuModoEscuro.Checked = $json.Exibicao.ModoEscuro
        }
        $statusLabelDir.Visible = $menuBotaoSacs.Checked

        Load-Clientes
        Set-Startup $menuIniciarWindows.Checked
        Apply-Theme
    }
    else {
        # Defaults para nova instalação/configuração ausente
        $menuClienteAtual.Checked = $true
        $menuCodHemAtual.Checked = $true
        $menuBotaoSacs.Checked = $true
        $statusLabelDir.Visible = $true
        $menuValidarDuplicidade.Checked = $true
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

function Show-Form {
    $form.Show()
    $form.WindowState = 'Normal'
    $form.Activate()
}

# (Código do Tray movido para o Load)


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

# --- Evento Load (Carrega Ícones e Tray) ---
$form.Add_Load({
        # Tenta carregar ícone
        $icon = $null
        $iconPath = "C:\BASES HEMOTE\V11\hemote.ico"
        if (Test-Path $iconPath) {
            $icon = New-Object System.Drawing.Icon($iconPath)
        }
        else {
            # Fallback para extrair do próprio EXE
            try {
                $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
                $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
            }
            catch {
                # Último fallback (ícone genérico)
                $icon = [System.Drawing.SystemIcons]::Application
            }
        }
    
        # 1. Configura NotifyIcon (Tray)
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = $icon
        $notifyIcon.Text = "Clientes Hemote Plus"
        $notifyIcon.Visible = $true
    
        $trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
        
        $trayItemAbrir = New-Object System.Windows.Forms.ToolStripMenuItem "Abrir"
        $trayItemAbrir.Add_Click({ Show-Form })
        [void]$trayMenu.Items.Add($trayItemAbrir)
        
        $trayItemSair = New-Object System.Windows.Forms.ToolStripMenuItem "Sair"
        $trayItemSair.Add_Click({ $script:exiting = $true; $form.Close() })
        [void]$trayMenu.Items.Add($trayItemSair)
    
        $notifyIcon.ContextMenuStrip = $trayMenu
        $notifyIcon.Add_MouseDoubleClick({ Show-Form })

        # 2. Configura Ícone da Janela
        $form.Icon = $icon
    }) | Out-Null

# Carregar configuração inicial
Load-Config
Update-Status

# --- Botão Confirmar ---
# --- Botão Confirmar (Refatorado e Otimizado com Cache) ---
$button.Add_Click({
        $cliente = $comboBox.SelectedItem
        if (-not $cliente) { 
            $msgLabel.ForeColor = [System.Drawing.Color]::Red
            $msgLabel.Text = 'Selecione um cliente.' 
            $clearMsgTimer.Stop(); $clearMsgTimer.Start()
            return 
        }

        # 1. Validação de Duplicidade (Usando Cache - Ultra Rápido)
        if ($menuValidarDuplicidade.Checked) {
            $dadosAtual = $global:clientCache[$cliente]
            if ($dadosAtual) {
                $duplicados = @()
                $global:clientCache.GetEnumerator() | ForEach-Object {
                    if ($_.Key -ne $cliente) {
                        $dadosOutro = $_.Value
                        if ($dadosAtual.CodHem -ne "" -and $dadosAtual.CodHem -eq $dadosOutro.CodHem) {
                            $duplicados += "$($_.Key) (data_access)"
                        }
                        elseif ($dadosAtual.Url -ne "" -and $dadosAtual.Url -eq $dadosOutro.Url) {
                            $duplicados += "$($_.Key) (WebUpdate)"
                        }
                    }
                }

                if ($duplicados.Count -gt 0) {
                    $msgLabel.ForeColor = [System.Drawing.Color]::Firebrick
                    $msgLabel.Text = "Conflito: " + ($duplicados -join ', ')
                    return
                }
            }
        }

        # 2. Cópia de Arquivos
        try {
            if ($global:clientCache[$cliente]) {
                $origemCliente = $global:clientCache[$cliente].Path
            }
            else {
                # Fallback caso cache falhe por algum motivo raro
                $origemCliente = Join-Path $global:clientesPath $cliente
            }

            # Arquivos para C:\SACS
            foreach ($arquivo in @("_data_access.ini", "logo.jpg", "logo2.jpg")) {
                $origem = Join-Path $origemCliente $arquivo
                if (Test-Path $origem) {
                    Copy-Item -Path $origem -Destination "C:\SACS\" -Force -ErrorAction Stop
                }
            }

            # Arquivo WebUpdate.ini
            $origemWeb = Join-Path $origemCliente "WebUpdate.ini"
            if (Test-Path $origemWeb) {
                $destBoot = "C:\SACS\BootStrap"
                if (-not (Test-Path $destBoot)) { New-Item -ItemType Directory -Path $destBoot | Out-Null }
                Copy-Item -Path $origemWeb -Destination $destBoot -Force -ErrorAction Stop
            }
        
        }
        catch {
            $msgLabel.Text = "Erro na cópia: $($_.Exception.Message)"
            return
        }

        # 3. Alteração de COD_HEM (Opcional)
        if ($menuAlterarCodHem.Checked) {
            Show-CodHemDialog
        }

        # 4. Salvar Configuração Atual
        $config = if (Test-Path $configFile) { Get-Content $configFile | ConvertFrom-Json } else { @{ Configuracoes = @{} } }
        if (-not $config.Configuracoes) { $config.Configuracoes = @{} }
        $config.Configuracoes.ClienteDefinido = $cliente
        if (-not $config.Exibicao) { $config.Exibicao = @{ Opacidade = 100 } }
        if (-not $config.Configuracoes.ValidarDuplicidade) { $config.Configuracoes.ValidarDuplicidade = $menuValidarDuplicidade.Checked }

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
                    if (Test-Path $novoCaminho) {
                        # CONFLITO: O arquivo de destino já existe!
                        # Isso acontece quando há duplicatas (ex: "Arquivo.lnk" e "Arquivo - Old.lnk").
                        # Solução: Removemos este arquivo redundante para limpar a pasta e manter apenas um atualizado.
                        Remove-Item -Path $atalhoOriginal -Force
                    }
                    else {
                        Rename-Item -Path $atalhoOriginal -NewName $novoNome -Force
                    }
                }
            }
        }

        Update-Status
        $msgLabel.ForeColor = [System.Drawing.Color]::ForestGreen
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