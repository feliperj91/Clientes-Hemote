# Clientes Hemote Plus - v11 🩸

**Ferramenta de apoio com interface moderna e recursos personalizados.**

O **Clientes Hemote Plus** automatiza a substituição de arquivos de configuração (`_data_access.ini` e `WebUpdate.ini`), atualização de atalhos e configuração de impressoras, operando discretamente a partir da Área de Notificação (System Tray).

---

## 🚀 Novidades da Versão

1.  **🔄 Atualização Manual de Lista:**
    *   Implementado botão de atualização (Refresh ↻) adjacente ao combo de seleção. Permite recarregar manualmente a lista de clientes após alterações no diretório raiz.
2.  **🛡️ Validação de Integridade:**
    *   Verificação prévia da existência dos arquivos críticos no diretório de origem. A troca de ambiente é bloqueada caso os arquivos estejam ausentes.
3.  **🎨 Interface Dark Mode:**
    *   Tema escuro aprimorado para conforto visual e integração com o estilo Windows 10/11.
4.  **🖱️ Controle via System Tray:**
    *   Minimização e restauração da interface através de duplo clique no ícone da Área de Notificação.
5.  **✨ Gerenciamento de Atalhos:**
    *   Renomeação automática dos atalhos no diretório `Hemote Plus Update` para refletir o cliente ativo.
6.  **⚡ Inicialização Automática:**
    *   Opção nativa para iniciar a aplicação automaticamente junto com o Windows.
7.  **🖨️ Configuração de Impressoras:**
    *   Diálogo moderno para configurar impressoras de fichas (gráfica) e etiquetas (códigos de barras).
    *   Suporte completo ao modo escuro, incluindo a barra de título.
    *   Salvamento automático em `C:\sacs\configuracao.ini`.

---

## 📋 Pré-requisitos

1.  **Sistema Operacional:** Windows 10 ou Windows 11.
2.  **Estrutura de Diretórios:**
    *   `C:\SACS`: Diretório raiz do sistema.
    *   `C:\SACS\CLIENTES`: Repositório das pastas de configuração de cada cliente.
    *   `C:\SACS\atalhos\Hemote Plus Update`: Diretório alvo para renomeação dinâmica de atalhos.
    *   `C:\sacs\configuracao.ini`: Arquivo de configuração de impressoras.

---

## 🛠️ Guia de Utilização

### 1. Inicialização
1.  Execute o `Clientes Hemote.exe`.
2.  A aplicação iniciará minimizada na Área de Notificação.
    *   ℹ **Nota:** O ícone pode estar oculto no menu de ícones ocultos (`^`) da barra de tarefas.

### 2. Configuração Inicial
Configure o diretório fonte dos clientes:
1.  Acesse o menu **Configurações > Clientes**.
2.  Selecione o diretório onde residem as subpastas dos clientes (Padrão: `C:\SACS\CLIENTES`).
3.  (Opcional) Ative **Iniciar com o Windows** no menu Configurações para execução automática.

### 3. Configuração de Impressoras
Configure as impressoras para fichas e etiquetas:
1.  Acesse o menu **Configurações > Impressoras**.
2.  Selecione a **Impressora Gráfica** (usada para fichas de doadores).
3.  Selecione a **Impressora Etiqueta** (usada para códigos de barras).
4.  Clique em **Salvar**.
    *   As configurações são salvas automaticamente em `C:\sacs\configuracao.ini`.
    *   Os parâmetros `[FICHA_DOADOR]`, `[FICHA_REDOME]`, `[BARCODE_DOADOR]` e `[BARCODE_GERAL]` são atualizados.

### 4. Troca de Ambiente
1.  Restaure a janela com duplo clique no ícone da Área de Notificação.
2.  Caso tenha adicionado pastas recentemente, utilize o botão **Atualizar (↻)**.
3.  Selecione o cliente desejado na lista suspensa.
4.  **Atalhos Rápidos:** O ícone de **Pasta Amarela** ao lado do botão Confirmar abre diretamente o diretório de atalhos (`C:\SACS\atalhos\Hemote Plus Update`) para verificação rápida.
5.  Clique em **Confirmar**.

### 5. Gestão de COD_HEM
O sistema oferece duas formas de manipular o parâmetro `COD_HEM` no arquivo `_data_access.ini`:
*   **Via Menu (Automação):** Se a opção **Configurações > Altera COD_HEM** estiver ativa, o sistema solicitará automaticamente o novo código logo após a confirmação da troca de cliente.
*   **Via Rodapé (Manual):** Clicar na etiqueta **"COD: XXX"** na barra de status inferior permite editar o código do cliente atual a qualquer momento, sem necessidade de trocar de ambiente.

### 6. Personalização e Exibição
No menu **Exibição**:
*   **Modo Escuro:** Alterna o tema da interface.
*   **Sempre Visível:** Mantém a janela sobreposta a outras aplicações.
*   **Opacidade:** Ajusta a transparência da janela.
*   **Botão SACS:** Exibe/Oculta atalho rápido para o diretório raiz no rodapé.

### 7. Encerramento
Para encerrar a execução do processo:
1.  Clique com o **botão direito** no ícone da Área de Notificação.
2.  Selecione **Sair**.

---

## ⚙️ Arquivos do Sistema

**config.json** (`C:\SACS\config.json`)
> Este arquivo armazena todas as preferências do usuário, incluindo:
> *   Caminho da pasta de clientes.
> *   Preferências de visualização (Tema, Opacidade, TopMost).
> *   Estados das opções de configuração (Altera COD_HEM, Iniciar com Windows).
>
> ⚠ **Importante:** Caso este arquivo seja excluído, o aplicativo perderá todas as personalizações e reverterá para as **configurações padrão de fábrica** na próxima execução.

**configuracao.ini** (`C:\sacs\configuracao.ini`)
> Este arquivo armazena as configurações de impressoras:
> *   `[FICHA_DOADOR]` e `[FICHA_REDOME]`: Impressora gráfica para fichas.
> *   `[BARCODE_DOADOR]` e `[BARCODE_GERAL]`: Impressora de etiquetas para códigos de barras.
>

---

## ❓ Solução de Problemas

**Ícone não visível**
> Verifique o menu de ícones ocultos (`^`) na barra de tarefas e arraste o ícone para a área visível para facilitar o acesso.

**Erro: Arquivos de configuração ausentes**
> O diretório selecionado para o cliente não contém os arquivos obrigatórios. Verifique a integridade da pasta em `C:\SACS\CLIENTES`.

**Conflito de Configuração**
> O sistema detectou duplicidade de parâmetros (`COD_HEM` ou `URL`) com outro cliente já mapeado.

**Impressoras não aparecem no diálogo**
> Verifique se há impressoras instaladas no Windows. Execute `Get-Printer` no PowerShell para listar as impressoras disponíveis.

**Diálogo de impressoras não abre**
> Certifique-se de que o sistema possui permissões para acessar as impressoras instaladas. Execute o aplicativo como administrador se necessário.

---

## 👨‍💻 Créditos
Desenvolvido por **Felipe Almeida**.
*Versão 11 - Janeiro de 2026*
