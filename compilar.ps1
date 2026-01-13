
Write-Host "Compilando Clientes Hemote..." -ForegroundColor Cyan

# Caminhos (usando o local do script como base)
$source = "$PSScriptRoot\Clientes Hemote.ps1"
$target = "$PSScriptRoot\Clientes Hemote.exe"
$icon = "$PSScriptRoot\sangue.ico"

# GUID Fixo para manter a identidade do processo no Windows
# IMPORTANTE: Não mude este ID nas próximas vezes, ou o Windows resetará as notificações.
$guid = "9F86D081-824F-45CF-8212-3292DD087F86"

# Verifica se o módulo PS2EXE está disponível
if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    Write-Warning "O comando 'Invoke-PS2EXE' não foi encontrado."
    Write-Host "Certifique-se de ter o módulo instalado (Install-Module ps2exe)."
    Read-Host "Pressione ENTER para sair"
    exit
}

try {
    Invoke-PS2EXE -InputFile $source `
        -OutputFile $target `
        -IconFile $icon `
        -Version "11.0.0.0" `
        -Product "Clientes Hemote Plus" `
        -Title "Clientes Hemote Plus" `
        -Description "Gerenciador de Clientes Hemote" `
        -Company "Felipe Almeida" `
        -NoConsole `
        -STA
                  
    Write-Host "`nSUCESSO! Novo executável gerado em:" -ForegroundColor Green
    Write-Host $target -ForegroundColor White
}
catch {
    Write-Error "Ocorreu um erro durante a compilação:"
    Write-Error $_
}

Write-Host "`n"
Read-Host "Pressione ENTER para sair"
