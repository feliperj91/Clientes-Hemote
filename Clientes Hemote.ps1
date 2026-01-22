Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Classe auxiliar para aplicar Dark Mode nativo do Windows na barra de título
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

# Classe para customizar cores do MenuStrip no modo escuro
$menuCode = @"
using System;
using System.Drawing;
using System.Windows.Forms;
public class DarkModeTable : ProfessionalColorTable {
    public override Color MenuBorder { get { return Color.FromArgb(30, 30, 30); } }
    public override Color MenuItemSelected { get { return Color.FromArgb(60, 60, 60); } }
    public override Color MenuItemBorder { get { return Color.FromArgb(60, 60, 60); } }
    public override Color MenuStripGradientBegin { get { return Color.FromArgb(30, 30, 30); } }
    public override Color MenuStripGradientEnd { get { return Color.FromArgb(30, 30, 30); } }
    public override Color MenuItemPressedGradientBegin { get { return Color.FromArgb(45, 45, 48); } }
    public override Color MenuItemPressedGradientEnd { get { return Color.FromArgb(45, 45, 48); } }
    public override Color ToolStripDropDownBackground { get { return Color.FromArgb(30, 30, 30); } }
    public override Color ImageMarginGradientBegin { get { return Color.FromArgb(30, 30, 30); } }
    public override Color ImageMarginGradientMiddle { get { return Color.FromArgb(30, 30, 30); } }
    public override Color ImageMarginGradientEnd { get { return Color.FromArgb(30, 30, 30); } }
    public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(60, 60, 60); } }
    public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(60, 60, 60); } }
}
"@
Add-Type -TypeDefinition $menuCode -ReferencedAssemblies System.Windows.Forms, System.Drawing

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
$global:clientCache = @{} # Cache de informações dos clientes (Path, CodHem, Url) para melhor performance

# Carrega lista de clientes do diretório e popula o cache local
function Load-Clientes {
    $comboBox.Items.Clear()
    $global:clientCache.Clear()

    if (Test-Path $global:clientesPath) {
        $statusLabelClient.Text = "Carregando clientes..."
        [System.Windows.Forms.Application]::DoEvents()

        # Salva seleção atual para restaurar após recarregar
        $selAtual = $comboBox.SelectedItem

        Get-ChildItem -Path $global:clientesPath -Directory | ForEach-Object {
            $clientePath = $_.FullName
            $nome = $_.Name
            $iniPath = Join-Path $clientePath "_data_access.ini"
            $webPath = Join-Path $clientePath "WebUpdate.ini"

            if ((Test-Path $iniPath) -and (Test-Path $webPath)) {
                $comboBox.Items.Add($nome) | Out-Null
                
                # Pré-carrega dados do cliente para o cache
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
        
        # Restaura seleção se ainda existir
        if ($selAtual -and $comboBox.Items.Contains($selAtual)) {
            $comboBox.SelectedItem = $selAtual
        }
        else {
            $comboBox.Text = ""
            $comboBox.SelectedIndex = -1
        }
        
        $statusLabelClient.Text = "Pronto."
    }
    
    $statusLabelClient.Text = "Pronto."
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

# --- Função auxiliar para atualizar o parâmetro COD_HEM no arquivo ini ---
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

# --- Diálogo moderno para alteração do COD_HEM ---
function Show-CodHemDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Alterar COD_HEM" # Texto para Narrador/Taskbar
    $dialog.Size = New-Object System.Drawing.Size(340, 160)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = 'None' # Remove borda do Windows para visual clean
    $dialog.KeyPreview = $true
    
    # Verifica Dark Mode (acessa a variável do script)
    $isDark = $false
    if ($menuModoEscuro -and $menuModoEscuro.Checked) { $isDark = $true }

    # Configuração de Cores (Paleta)
    if ($isDark) {
        $bgColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $fgColor = [System.Drawing.Color]::WhiteSmoke
        $inputBg = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $inputFg = [System.Drawing.Color]::White
        $borderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
        $btnCancelBg = $bgColor
        $btnCancelFg = [System.Drawing.Color]::Silver
    }
    else {
        $bgColor = [System.Drawing.Color]::White
        $fgColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
        $inputBg = [System.Drawing.Color]::WhiteSmoke
        $inputFg = [System.Drawing.Color]::Black
        $borderColor = [System.Drawing.Color]::LightGray
        $btnCancelBg = $bgColor
        $btnCancelFg = [System.Drawing.Color]::DimGray
    }

    $dialog.BackColor = $bgColor
    $dialog.ForeColor = $fgColor
    $dialog.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    # Desenha Borda Fina Customizada
    $dialog.Add_Paint({
            param($sender, $e)
            $pen = New-Object System.Drawing.Pen($borderColor, 1)
            $rect = $sender.ClientRectangle
            $rect.Width -= 1
            $rect.Height -= 1
            $e.Graphics.DrawRectangle($pen, $rect)
        })

    # Título
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "COD_HEM"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.AutoSize = $true
    $dialog.Controls.Add($lblTitle)
    
    # Subtítulo com instrução
    $lblMsg = New-Object System.Windows.Forms.Label
    $lblMsg.Text = "Digite o código de acesso:"
    $lblMsg.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lblMsg.ForeColor = if ($isDark) { [System.Drawing.Color]::Gray } else { [System.Drawing.Color]::Gray }
    $lblMsg.Location = New-Object System.Drawing.Point(22, 38)
    $lblMsg.AutoSize = $true
    $dialog.Controls.Add($lblMsg)

    # TextBox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(25, 60)
    $textBox.Size = New-Object System.Drawing.Size(290, 25)
    $textBox.BackColor = $inputBg
    $textBox.ForeColor = $inputFg
    $textBox.BorderStyle = 'FixedSingle'
    $dialog.Controls.Add($textBox)

    # Botão Confirmar
    $btnConfirmar = New-Object System.Windows.Forms.Button
    $btnConfirmar.Text = "Confirmar"
    $btnConfirmar.Size = New-Object System.Drawing.Size(90, 28)
    $btnConfirmar.Location = New-Object System.Drawing.Point(225, 110)
    $btnConfirmar.FlatStyle = 'Flat'
    $btnConfirmar.FlatAppearance.BorderSize = 0
    $btnConfirmar.BackColor = [System.Drawing.Color]::DodgerBlue
    $btnConfirmar.ForeColor = [System.Drawing.Color]::White
    $btnConfirmar.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnConfirmar.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.Controls.Add($btnConfirmar)

    # Botão Cancelar
    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = "Cancelar"
    $btnCancelar.Size = New-Object System.Drawing.Size(80, 28)
    $btnCancelar.Location = New-Object System.Drawing.Point(135, 110)
    $btnCancelar.FlatStyle = 'Flat'
    $btnCancelar.FlatAppearance.BorderSize = 0
    $btnCancelar.BackColor = $btnCancelBg
    $btnCancelar.ForeColor = $btnCancelFg
    $btnCancelar.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCancelar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($btnCancelar)

    $dialog.AcceptButton = $btnConfirmar
    $dialog.CancelButton = $btnCancelar

    # Força texto em Caixa Alta (UpperCase)
    $textBox.Add_TextChanged({
            $pos = $textBox.SelectionStart
            $textBox.Text = $textBox.Text.ToUpper()
            $textBox.SelectionStart = $pos
        })

    # Lógica para permitir arrastar a janela (Drag & Drop) pois borda foi removida
    $dragBlock = {
        if ($_.Button -eq 'Left') {
            $dialog.Tag = @{
                DragStart = [System.Windows.Forms.Cursor]::Position
                FormStart = $dialog.Location
            }
        }
    }
    $moveBlock = {
        if ($_.Button -eq 'Left' -and $dialog.Tag) {
            $diff = [System.Drawing.Point]::Subtract([System.Windows.Forms.Cursor]::Position, [System.Drawing.Size]$dialog.Tag.DragStart)
            $dialog.Location = [System.Drawing.Point]::Add($dialog.Tag.FormStart, $diff)
        }
    }

    $dialog.Add_MouseDown($dragBlock)
    $dialog.Add_MouseMove($moveBlock)
    $lblTitle.Add_MouseDown($dragBlock)
    $lblTitle.Add_MouseMove($moveBlock)

    $result = $dialog.ShowDialog($form)

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $valor = $textBox.Text.Trim()
        if (-not $valor) {
            # Feedback sonoro discreto em caso de input vazio
            [System.Console]::Beep(500, 200)
            return
        }
        Atualizar-CodHem $valor
    }
}
# --- Função para atualizar status visual no rodapé ---
function Update-Status {
    $textoEsq = " "
    
    $textoEsq = " "

    # Atualiza Cliente
    if ($menuClienteAtual.Checked) {
        $cliConfig = ""
        if (Test-Path $configFile) {
            try { $json = Get-Content $configFile | ConvertFrom-Json; $cliConfig = $json.Configuracoes.ClienteDefinido } catch {}
        }
        $val = if ($cliConfig) { $cliConfig } else { "---" }
        $textoEsq += "Cliente: $val"
    }
    
    $statusLabelClient.Text = $textoEsq

    # Atualiza CodHem
    $statusLabelCod.Visible = $menuCodHemAtual.Checked
    if ($menuCodHemAtual.Checked) {
        $valCod = Get-CodHemAtual
        if (-not $valCod) { $valCod = "---" }
        $statusLabelCod.Text = " COD: $valCod "
    }
}

# --- Função de Atualização de Atalhos ---
function Update-Shortcuts($pathAtalhos, $novoCliente) {
    if (Test-Path $pathAtalhos) {
        # Cria regex com todos os clientes conhecidos para garantir limpeza correta do nome antigo
        # Evita bugs como "App - Cliente - Cliente"
        $clientesConhecidos = @($comboBox.Items)
        if ($clientesConhecidos.Count -gt 0) {
            $patternClientes = $clientesConhecidos | ForEach-Object { [regex]::Escape($_) }
            $regexSuffix = " - (" + ($patternClientes -join '|') + ")$"
        }
        else {
            $regexSuffix = " - .*$" # Fallback genérico
        }

        Get-ChildItem -Path $pathAtalhos -Filter "*.lnk" | ForEach-Object {
            $atalho = $_
            $atalhoOriginal = $atalho.FullName
            
            # Remove sufixo de cliente anterior se houver
            $nomeBase = $atalho.BaseName -replace $regexSuffix, ""
            
            # Novo nome
            $novoNome = "$nomeBase - $novoCliente.lnk"
            $novoCaminho = Join-Path $pathAtalhos $novoNome

            # Renomeia se necessário
            if ($atalhoOriginal -ne $novoCaminho) {
                if (Test-Path $novoCaminho) {
                    # Evita duplicatas removendo o antigo que entraria em conflito
                    Remove-Item -Path $atalhoOriginal -Force
                }
                else {
                    Rename-Item -Path $atalhoOriginal -NewName $novoNome -Force
                }
            }
        }
    }
}



# Form principal
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Clientes Hemote Plus'
$form.Size = New-Object System.Drawing.Size(530, 210) # Comprimento aumentado para caber mensagens longas
$form.FormBorderStyle = 'FixedSingle' # Janela fixa, exibe ícone na barra de título
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

# StatusStrip (Barra de Rodapé Moderna e Interativa)
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
$statusLabelCod.BorderSides = 'None'
$statusLabelCod.IsLink = $true
$statusLabelCod.LinkBehavior = [System.Windows.Forms.LinkBehavior]::NeverUnderline
$statusLabelCod.LinkColor = [System.Drawing.Color]::DodgerBlue
$statusLabelCod.ActiveLinkColor = [System.Drawing.Color]::RoyalBlue
$statusLabelCod.ToolTipText = "Clique para alterar o COD_HEM"
$statusLabelCod.Add_Click({ Show-CodHemDialog; Update-Status })

# 3. Pasta SACS (Direita, Fixa)
$statusLabelDir = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabelDir.Text = " 📂 SACS "
$statusLabelDir.BorderSides = 'None'
$statusLabelDir.Margin = New-Object System.Windows.Forms.Padding(15, 0, 0, 0)
$statusLabelDir.IsLink = $true
$statusLabelDir.LinkBehavior = [System.Windows.Forms.LinkBehavior]::NeverUnderline
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



# --- Painel Início (Interface Principal Modernizada) ---
# --- Criar ícone de Refresh dinamicamente (ícone vetorial via desenho) ---
$refreshBmp = New-Object System.Drawing.Bitmap(30, 30)
$gRef = [System.Drawing.Graphics]::FromImage($refreshBmp)
$gRef.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$penRef = New-Object System.Drawing.Pen([System.Drawing.Color]::DimGray, 2.5)
$penRef.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$penRef.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor

# Desenha duas setas curvas formando um círculo
$gRef.DrawArc($penRef, 6, 6, 18, 18, 45, 170)  # Arco superior
$gRef.DrawArc($penRef, 6, 6, 18, 18, 225, 170) # Arco inferior
$gRef.Dispose()

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Image = $refreshBmp
$btnRefresh.Location = New-Object System.Drawing.Point(10, 13)
$btnRefresh.Size = New-Object System.Drawing.Size(30, 30)
$btnRefresh.FlatStyle = 'Flat'
$btnRefresh.FlatAppearance.BorderSize = 0
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnRefresh.TextAlign = 'MiddleCenter'

# Tooltip para clareza
$toolTipRefresh = New-Object System.Windows.Forms.ToolTip
$toolTipRefresh.SetToolTip($btnRefresh, "Atualizar lista de clientes")

$btnRefresh.Add_Click({ 
        Load-Clientes
        Update-Status 
    })
$painelInicio.Controls.Add($btnRefresh)

# ComboBox Modernizado (OwnerDraw)
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(45, 14) # Ajuste fino vertical
$comboBox.Size = New-Object System.Drawing.Size(295, 30)
$comboBox.DropDownStyle = 'DropDownList'
$comboBox.FlatStyle = 'Flat'
$comboBox.Font = New-Object System.Drawing.Font("Segoe UI", 11) # Fonte um pouco maior
$comboBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$comboBox.ItemHeight = 24 # Altura da linha maior para visual moderno

# Evento de desenho customizado para itens da lista
$comboBox.Add_DrawItem({
    param($sender, $e)
    if ($e.Index -lt 0) { return }

    $g = $e.Graphics
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    
    # Cores
    $isSelected = ($e.State -band [System.Windows.Forms.DrawItemState]::Selected)
    $bgColor = if ($isSelected) { [System.Drawing.Color]::FromArgb(230, 240, 255) } else { [System.Drawing.Color]::White } # Azul e Branco Clean
    $textColor = if ($isSelected) { [System.Drawing.Color]::FromArgb(0, 100, 200) } else { [System.Drawing.Color]::FromArgb(64, 64, 64) }

    # Ajuste para Dark Mode (se fundo do controle for escuro)
    if ($sender.BackColor.R -lt 100) {
        $bgColor = if ($isSelected) { [System.Drawing.Color]::FromArgb(70, 70, 70) } else { [System.Drawing.Color]::FromArgb(45, 45, 48) }
        $textColor = if ($isSelected) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::LightGray }
    }

    # Desenha Fundo
    $brushBg = New-Object System.Drawing.SolidBrush($bgColor)
    $g.FillRectangle($brushBg, $e.Bounds)

    # Desenha Texto Centralizado Verticalmente
    $brushText = New-Object System.Drawing.SolidBrush($textColor)
    $text = $sender.Items[$e.Index]
    
    # Centraliza texto verticalmente
    $yPos = $e.Bounds.Y + ($e.Bounds.Height - $e.Font.Height) / 2
    $g.DrawString($text, $e.Font, $brushText, ($e.Bounds.X + 5), $yPos)
    
    # Opcional: Desenha borda de foco customizada ou remove a padrão
    if ($isSelected) {
       # $penFocus = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 200, 250))
       # $g.DrawRectangle($penFocus, $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width - 1, $e.Bounds.Height - 1)
    }
})

$comboBox.Add_KeyPress({ $_.Handled = $true }) # Previne digitação
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

# --- Criar ícone de pasta dinamicamente (ícone vetorial via desenho) ---
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
$msgLabel.Location = New-Object System.Drawing.Point(10, 55) # Posição ajustada abaixo dos botões
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
$sobreLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$sobreLabel.Text = @"
Clientes Hemote Plus
Ferramenta de apoio com interface moderna e recursos personalizados.

Funcionalidades:
  • Troca rápida entre clientes com atalhos personalizados
  • Interface com Modo Escuro, controle de opacidade e sempre no topo
  • Acesso rápido ao SACS e pasta de atalhos
  • Configuração de impressoras para fichas e etiquetas
  • Validação de arquivos e verificação de duplicidade de URLs
  • Inicialização automática com o Windows
  • Ícone na bandeja do sistema para acesso discreto
  • Edição rápida do código COD_HEM

Desenvolvido por: Felipe Almeida
Versão: Janeiro/2026
"@
$painelSobre.Controls.Add($sobreLabel)

# --- Barra de Menus ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::White # Cor de fundo que harmoniza com o tema claro
$menuStrip.RenderMode = 'System' # Usa renderização nativa do sistema para integração visual

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
        $dialog.Description = 'Selecione a pasta CLIENTES'
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

# --- Menu Impressoras ---
$menuImpressoras = New-Object System.Windows.Forms.ToolStripMenuItem
$menuImpressoras.Text = 'Impressoras'

# Função para mostrar diálogo de seleção de impressoras
function Show-PrinterDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Configurar Impressoras"
    $dialog.Size = New-Object System.Drawing.Size(420, 230)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    
    # Verifica Dark Mode
    $isDark = $false
    if ($menuModoEscuro -and $menuModoEscuro.Checked) { $isDark = $true }
    
    # Cores
    if ($isDark) {
        $bgColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $fgColor = [System.Drawing.Color]::WhiteSmoke
    }
    else {
        $bgColor = [System.Drawing.Color]::White
        $fgColor = [System.Drawing.Color]::Black
    }
    
    $dialog.BackColor = $bgColor
    $dialog.ForeColor = $fgColor
    
    # Label Gráfica
    $lblGrafica = New-Object System.Windows.Forms.Label
    $lblGrafica.Text = "Impressora Gráfica:"
    $lblGrafica.Location = New-Object System.Drawing.Point(20, 20)
    $lblGrafica.Size = New-Object System.Drawing.Size(370, 20)
    $lblGrafica.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $dialog.Controls.Add($lblGrafica)
    
    # ComboBox Gráfica
    $comboGrafica = New-Object System.Windows.Forms.ComboBox
    $comboGrafica.Location = New-Object System.Drawing.Point(20, 45)
    $comboGrafica.Size = New-Object System.Drawing.Size(370, 25)
    $comboGrafica.DropDownStyle = 'DropDownList'
    $comboGrafica.BackColor = if ($isDark) { [System.Drawing.Color]::FromArgb(60, 60, 60) } else { [System.Drawing.Color]::White }
    $comboGrafica.ForeColor = $fgColor
    $dialog.Controls.Add($comboGrafica)
    
    # Label Etiqueta
    $lblEtiqueta = New-Object System.Windows.Forms.Label
    $lblEtiqueta.Text = "Impressora Etiqueta:"
    $lblEtiqueta.Location = New-Object System.Drawing.Point(20, 85)
    $lblEtiqueta.Size = New-Object System.Drawing.Size(370, 20)
    $lblEtiqueta.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $dialog.Controls.Add($lblEtiqueta)
    
    # ComboBox Etiqueta
    $comboEtiqueta = New-Object System.Windows.Forms.ComboBox
    $comboEtiqueta.Location = New-Object System.Drawing.Point(20, 110)
    $comboEtiqueta.Size = New-Object System.Drawing.Size(370, 25)
    $comboEtiqueta.DropDownStyle = 'DropDownList'
    $comboEtiqueta.BackColor = if ($isDark) { [System.Drawing.Color]::FromArgb(60, 60, 60) } else { [System.Drawing.Color]::White }
    $comboEtiqueta.ForeColor = $fgColor
    $dialog.Controls.Add($comboEtiqueta)
    
    # Carrega impressoras
    $printers = Get-Printer | Select-Object -ExpandProperty Name
    foreach ($printer in $printers) {
        $comboGrafica.Items.Add($printer) | Out-Null
        $comboEtiqueta.Items.Add($printer) | Out-Null
    }
    
    # Carrega seleções atuais
    $configIniPath = 'C:\sacs\configuracao.ini'
    if (Test-Path $configIniPath) {
        $content = Get-Content $configIniPath -Raw
        
        if ($content -match '(?im)^\s*\[FICHA_DOADOR\]\s*=\s*(.+)$') {
            $printerName = $matches[1].Trim()
            $comboGrafica.SelectedItem = $printerName
        }
        
        if ($content -match '(?im)^\s*\[BARCODE_DOADOR\]\s*=\s*(.+)$') {
            $printerName = $matches[1].Trim()
            $comboEtiqueta.SelectedItem = $printerName
        }
    }
    
    # Botão Salvar
    $btnSalvar = New-Object System.Windows.Forms.Button
    $btnSalvar.Text = "Salvar"
    $btnSalvar.Size = New-Object System.Drawing.Size(90, 32)
    $btnSalvar.Location = New-Object System.Drawing.Point(300, 155)
    $btnSalvar.FlatStyle = 'Flat'
    $btnSalvar.FlatAppearance.BorderSize = 0
    $btnSalvar.BackColor = [System.Drawing.Color]::DodgerBlue
    $btnSalvar.ForeColor = [System.Drawing.Color]::White
    $btnSalvar.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnSalvar.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnSalvar.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.Controls.Add($btnSalvar)
    
    # Botão Cancelar
    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = "Cancelar"
    $btnCancelar.Size = New-Object System.Drawing.Size(90, 32)
    $btnCancelar.Location = New-Object System.Drawing.Point(200, 155)
    $btnCancelar.FlatStyle = 'Flat'
    $btnCancelar.FlatAppearance.BorderSize = 0
    $btnCancelar.BackColor = if ($isDark) { $bgColor } else { [System.Drawing.Color]::WhiteSmoke }
    $btnCancelar.ForeColor = if ($isDark) { [System.Drawing.Color]::Silver } else { [System.Drawing.Color]::DimGray }
    $btnCancelar.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btnCancelar.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCancelar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($btnCancelar)
    
    $dialog.AcceptButton = $btnSalvar
    $dialog.CancelButton = $btnCancelar
    
    # Aplica Dark Mode na barra de título quando a janela for criada
    $dialog.Add_HandleCreated({
            try { 
                [DarkModeHelper]::SetDarkMode($dialog.Handle, $isDark) 
            }
            catch {}
        })
    
    $result = $dialog.ShowDialog($form)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Salva Gráfica
        if ($comboGrafica.SelectedItem) {
            Save-PrinterToConfig $comboGrafica.SelectedItem 'Grafica'
        }
        
        # Salva Etiqueta
        if ($comboEtiqueta.SelectedItem) {
            Save-PrinterToConfig $comboEtiqueta.SelectedItem 'Etiqueta'
        }
    }
}

# Função auxiliar para salvar impressora no arquivo
function Save-PrinterToConfig {
    param($printerName, $tipo)
    
    $configIniPath = 'C:\sacs\configuracao.ini'
    
    # Cria o diretório se não existir
    $configDir = Split-Path $configIniPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Lê o conteúdo atual do arquivo ou cria um novo
    $linhas = @()
    if (Test-Path $configIniPath) {
        $linhas = Get-Content $configIniPath
    }
    
    # Define os parâmetros baseado no tipo
    if ($tipo -eq 'Grafica') {
        $parametros = @('[FICHA_DOADOR]', '[FICHA_REDOME]')
    }
    else {
        $parametros = @('[BARCODE_DOADOR]', '[BARCODE_GERAL]')
    }
    
    # Atualiza ou adiciona os parâmetros
    foreach ($param in $parametros) {
        $encontrado = $false
        $paramEscaped = [regex]::Escape($param)
        for ($i = 0; $i -lt $linhas.Count; $i++) {
            if ($linhas[$i] -match "^\s*$paramEscaped\s*=") {
                $linhas[$i] = "$param= $printerName"
                $encontrado = $true
            }
        }
        
        if (-not $encontrado) {
            $linhas += "$param= $printerName"
        }
    }
    
    # Salva o arquivo
    $linhas | Set-Content $configIniPath -Encoding Default
}

# Adiciona evento de clique ao menu Impressoras
$menuImpressoras.Add_Click({
        Show-PrinterDialog
    })

$menuConfig.DropDownItems.Add($menuClientes)       | Out-Null
$menuConfig.DropDownItems.Add($menuImpressoras)    | Out-Null
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
        $statusLabelClient.Text = 'Alternar entre tema Claro e Escuro'
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
    $item.Text = $valor.ToString() + '%'
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
# --- Configuração de Eventos de Hover (Dicas de Ferramenta) ---

# Timer para restaurar o texto padrão do rodapé após alguns segundos
$restoreStatusTimer = New-Object System.Windows.Forms.Timer
$restoreStatusTimer.Interval = 4000
$restoreStatusTimer.Add_Tick({
        $restoreStatusTimer.Stop()
        Update-Status
    })

# --- Definição das mensagens de hover ---
$btnRefresh.Add_MouseHover({ 
        $statusLabelClient.Text = 'Atualizar lista de clientes'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuInicio.Add_MouseHover({ 
        $statusLabelClient.Text = 'Voltar para a tela inicial de seleção de cliente'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$btnPasta.Add_MouseHover({
        $statusLabelClient.Text = 'Abrir pasta de atalhos (C:\SACS\atalhos\Hemote Plus Update)'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuConfig.Add_MouseHover({ 
        $statusLabelClient.Text = 'Configurações gerais do programa'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuExibicao.Add_MouseHover({ 
        $statusLabelClient.Text = 'Opções de exibição da janela e informações'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuSobre.Add_MouseHover({ 
        $statusLabelClient.Text = 'Informações sobre o programa'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Configurações
$menuClientes.Add_MouseHover({ 
        $statusLabelClient.Text = 'Define a pasta com os arquivos do cliente'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuAlterarCodHem.Add_MouseHover({ 
        $statusLabelClient.Text = 'Permitir alterar o COD_HEM após selecionar o cliente'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuIniciarWindows.Add_MouseHover({ 
        $statusLabelClient.Text = 'Habilitar ou desabilitar inicialização automática com o Windows'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuValidarDuplicidade.Add_MouseHover({ 
        $statusLabelClient.Text = 'Verificar se existe duplicidade de data_access e webupdate.'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuImpressoras.Add_MouseHover({ 
        $statusLabelClient.Text = 'Configurar impressoras para fichas e etiquetas'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# Submenus de Exibição
$menuClienteAtual.Add_MouseHover({ 
        $statusLabelClient.Text = 'Mostrar o cliente atual no rodapé'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuCodHemAtual.Add_MouseHover({ 
        $statusLabelClient.Text = 'Mostrar o COD_HEM atual no rodapé'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

$menuBotaoSacs.Add_MouseHover({ 
        $statusLabelClient.Text = 'Mostrar/Ocultar o botão de atalho para C:\SACS'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })



$menuSempreVisivel.Add_MouseHover({ 
        $statusLabelClient.Text = 'Manter a janela sempre visível sobre outras aplicações'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })
$menuOpacidade.Add_MouseHover({ 
        $statusLabelClient.Text = 'Ajustar a opacidade da janela'
        $restoreStatusTimer.Stop(); $restoreStatusTimer.Start()
    })

# --- Função de Tema (Dark Mode) ---
function Apply-Theme {
    if ($menuModoEscuro.Checked) {
        $bg = [System.Drawing.Color]::FromArgb(30, 30, 30) # Unificado com Painéis
        $panelBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $fg = [System.Drawing.Color]::WhiteSmoke
        $inputBg = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $btnPastaBg = $panelBg # Fundo igual ao painel (sem caixa de cor)
        
        # Ativa Renderização Customizada (Remove Barra Branca)
        $menuStrip.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer(New-Object DarkModeTable)
    }
    else {
        $bg = [System.Drawing.Color]::White
        $panelBg = [System.Drawing.Color]::White
        $fg = [System.Drawing.Color]::Black
        $inputBg = [System.Drawing.Color]::White
        $btnPastaBg = $panelBg # Fundo igual ao painel (sem caixa de cor)
        
        # Restaura Renderização do Sistema (Padrão)
        $menuStrip.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System
        $menuStrip.Renderer = $null 
    }

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
    
    # Atualiza cores dos links do rodapé (Adaptação ao Tema Escuro/Claro)
    if ($menuModoEscuro.Checked) {
        $statusLabelCod.LinkColor = [System.Drawing.Color]::LightSkyBlue
        $statusLabelDir.LinkColor = [System.Drawing.Color]::Silver
    }
    else {
        $statusLabelCod.LinkColor = [System.Drawing.Color]::DodgerBlue
        $statusLabelDir.LinkColor = [System.Drawing.Color]::DimGray
    }
    
    # ComboBox
    if ($menuModoEscuro.Checked) {
        # Hack: Muda para DropDown (editável) para aceitar cores personalizadas, mas bloqueamos digitação no KeyPress
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
    
    $btnRefresh.BackColor = $btnPastaBg
    $btnRefresh.ForeColor = $fg
    $btnPasta.BackColor = $btnPastaBg
    $sobreLabel.ForeColor = $fg
    
    # Atualiza cor do texto dos menus recursivamente
    $updateColors = {
        param($items)
        foreach ($i in $items) {
            $i.ForeColor = $fg
            if ($i -is [System.Windows.Forms.ToolStripMenuItem]) {
                & $updateColors $i.DropDownItems
            }
        }
    }
    & $updateColors $menuStrip.Items
    
    # Invalida para redesenhar bordas se necessário
    $form.Refresh()
}

# --- Funções auxiliares de Persistência e Configuração ---
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
        
        # Carrega ValidarDuplicidade (padrão true se não existir no JSON para manter compatibilidade)
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
        # Valores padrão para nova instalação ou configuração ausente
        $menuClienteAtual.Checked = $true
        $menuCodHemAtual.Checked = $true
        $menuBotaoSacs.Checked = $true
        $statusLabelDir.Visible = $true
        $menuValidarDuplicidade.Checked = $true
    }
    Update-Status
}

# --- Função para gerenciar atalho de inicialização no Windows ---
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

# --- Gerenciamento do Ícone na Área de Notificação (Tray) ---

function Show-Form {
    $form.Show()
    $form.WindowState = 'Normal'
    $form.Activate()
    $form.ShowInTaskbar = $false
}

function Toggle-Form {
    if ($form.Visible -and $form.WindowState -ne 'Minimized') {
        $form.WindowState = 'Minimized' # O evento Resize ocultará a janela na barra de tarefas
    }
    else {
        Show-Form
    }
}

# --- Eventos de Janela para Minimizar ao Tray ---
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

# --- Evento Load (Configuração inicial de Ícones e Tray) ---
$form.Add_Load({
        # Tenta carregar ícone
        $icon = $null
        $iconPath = 'C:\BASES HEMOTE\V11\hemote.ico'
        if (Test-Path $iconPath) {
            $icon = New-Object System.Drawing.Icon($iconPath)
        }
        else {
            # Tentativa alternativa: extrair ícone do próprio executável
            try {
                $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
                $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
            }
            catch {
                # Último recurso: ícone genérico de aplicação do sistema
                $icon = [System.Drawing.SystemIcons]::Application
            }
        }
    
        # 1. Configura NotifyIcon (Ícone na Bandeja)
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = $icon
        $notifyIcon.Text = 'Clientes Hemote Plus'
        $notifyIcon.Visible = $true
    
        $trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
        
        $trayItemAbrir = New-Object System.Windows.Forms.ToolStripMenuItem 'Abrir'
        $trayItemAbrir.Add_Click({ Show-Form })
        [void]$trayMenu.Items.Add($trayItemAbrir)
        
        $trayItemSair = New-Object System.Windows.Forms.ToolStripMenuItem 'Sair'
        $trayItemSair.Add_Click({ $script:exiting = $true; $form.Close() })
        [void]$trayMenu.Items.Add($trayItemSair)
    
        $notifyIcon.ContextMenuStrip = $trayMenu
        $notifyIcon.Add_MouseDoubleClick({ Toggle-Form })

        # 2. Configura Ícone da Janela
        $form.Icon = $icon
    }) | Out-Null

# Carregar configuração inicial
Load-Config
Update-Status

# --- Evento Principal: Botão Confirmar ---
$button.Add_Click({
        $cliente = $comboBox.SelectedItem
        if (-not $cliente) { 
            $msgLabel.ForeColor = [System.Drawing.Color]::Red
            $msgLabel.Text = 'Selecione um cliente.' 
            $clearMsgTimer.Stop(); $clearMsgTimer.Start()
            return 
        }

        # 1. Validação de Duplicidade (Cache)
        if ($menuValidarDuplicidade.Checked) {
            $dadosAtual = $global:clientCache[$cliente]
            if ($dadosAtual) {
                $duplicados = @()
                $global:clientCache.GetEnumerator() | ForEach-Object {
                    if ($_.Key -ne $cliente) {
                        $dadosOutro = $_.Value
                        $conflitos = @()
                        
                        if ($dadosAtual.CodHem -ne '' -and $dadosAtual.CodHem -eq $dadosOutro.CodHem) {
                            $conflitos += 'data_access'
                        }
                        if ($dadosAtual.Url -ne '' -and $dadosAtual.Url -eq $dadosOutro.Url) {
                            $conflitos += 'WebUpdate'
                        }
                        
                        if ($conflitos.Count -gt 0) {
                            $duplicados += $_.Key + ' (' + ($conflitos -join ' e ') + ')'
                        }
                    }
                }

                if ($duplicados.Count -gt 0) {
                    $msgLabel.ForeColor = [System.Drawing.Color]::Firebrick
                    $msgLabel.Text = 'Conflito: ' + ($duplicados -join ', ')
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
                # Recurso de segurança caso o cache falhe
                $origemCliente = Join-Path $global:clientesPath $cliente
            }

            # Validação Rígida: Garante integridade verificando existência real dos arquivos
            # (Previne erros ao selecionar pastas que foram renomeadas ou excluídas externamente)
            $testeIni = Join-Path $origemCliente '_data_access.ini'
            $testeWeb = Join-Path $origemCliente 'WebUpdate.ini'
            
            if (-not (Test-Path $testeIni) -or -not (Test-Path $testeWeb)) {
                $msgLabel.ForeColor = [System.Drawing.Color]::Blue
                $msgLabel.Text = 'Erro: Arquivos de configuração ausentes na pasta!'
                $clearMsgTimer.Stop(); $clearMsgTimer.Start()
                 
                # Força recarregamento da lista para refletir o estado real do diretório
                Load-Clientes
                return
            }

            # Arquivos para C:\SACS
            foreach ($arquivo in @('_data_access.ini', 'logo.jpg', 'logo2.jpg')) {
                $origem = Join-Path $origemCliente $arquivo
                if (Test-Path $origem) {
                    Copy-Item -Path $origem -Destination 'C:\SACS\' -Force -ErrorAction Stop
                }
            }

            # Arquivo WebUpdate.ini
            $origemWeb = Join-Path $origemCliente 'WebUpdate.ini'
            if (Test-Path $origemWeb) {
                $destBoot = 'C:\SACS\BootStrap'
                if (-not (Test-Path $destBoot)) { New-Item -ItemType Directory -Path $destBoot | Out-Null }
                Copy-Item -Path $origemWeb -Destination $destBoot -Force -ErrorAction Stop
            }
        
        }
        catch {
            $msgLabel.Text = 'Erro na cópia: ' + $_.Exception.Message
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
        Update-Shortcuts 'C:\SACS\atalhos\Hemote Plus Update' $cliente

        Update-Status
        $msgLabel.ForeColor = [System.Drawing.Color]::ForestGreen
        $msgLabel.Text = 'Cliente ' + $cliente + ' definido com sucesso!'
        $clearMsgTimer.Stop(); $clearMsgTimer.Start()
    }) | Out-Null

# --- Timer para limpar mensagens de status automaticamente ---
$clearMsgTimer = New-Object System.Windows.Forms.Timer
$clearMsgTimer.Interval = 5000
$clearMsgTimer.Add_Tick({
        $msgLabel.Text = ''
        $clearMsgTimer.Stop()
    })

# --- Loop principal de execução da aplicação ---
try {
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    try { $mutex.ReleaseMutex() } catch {}
}