# Clientes Hemote Plus - v11 🩸

**Ferramenta para gerenciamento e troca rápida de configurações de ambientes Hemote.**

O **Clientes Hemote Plus** automatiza a substituição de arquivos de configuração (`_data_access.ini` e `WebUpdate.ini`) e a atualização de atalhos, operando discretamente a partir da bandeja do sistema (System Tray).

---

## 🚀 Novidades da Versão

1.  **🔄 Atualização Manual de Lista:**
    *   Implementado botão de atualização (Refresh ↻) adjacente ao combo de seleção. Permite recarregar manualmente a lista de clientes após alterações no diretório raiz.
2.  **🛡️ Validação de Integridade:**
    *   Verificação prévia da existência dos arquivos críticos no diretório de origem. A troca de ambiente é bloqueada caso os arquivos estejam ausentes.
3.  **🎨 Interface Dark Mode:**
    *   Tema escuro aprimorado para conforto visual e integração com o estilo Windows 10/11.
4.  **🖱️ Controle via System Tray:**
    *   Minimização e restauração da interface através de duplo clique no ícone da bandeja.
5.  **✨ Gerenciamento de Atalhos:**
    *   Renomeação automática dos atalhos no diretório `Hemote Plus Update` para refletir o cliente ativo.
6.  **⚡ Inicialização Automática:**
    *   Opção nativa para iniciar a aplicação automaticamente junto com o Windows.

---

## 📋 Pré-requisitos

1.  **Sistema Operacional:** Windows 10 ou Windows 11.
2.  **Estrutura de Diretórios:**
    *   `C:\SACS`: Diretório raiz do sistema.
    *   `C:\SACS\CLIENTES`: Repositório das pastas de configuração de cada cliente.
    *   **Opcional:** `C:\SACS\atalhos\Hemote Plus Update`: Diretório alvo para renomeação dinâmica de atalhos.

---

## 🛠️ Guia de Utilização

### 1️⃣ Inicialização
1.  Execute o `Clientes Hemote.exe`.
2.  A aplicação iniciará minimizada na bandeja do sistema.
    *   ℹ **Nota:** O ícone pode estar oculto no menu de ícones ocultos (`^`) da barra de tarefas.

### 2️⃣ Configuração Inicial
Configure o diretório fonte dos clientes:
1.  Acesse o menu **Configurações > Clientes**.
2.  Selecione o diretório onde residem as subpastas dos clientes (Padrão: `C:\SACS\CLIENTES`).
3.  (Opcional) Ative **Iniciar com o Windows** no menu Configurações para execução automática.

### 3️⃣ Troca de Ambiente
1.  Restaure a janela com duplo clique no ícone da bandeja.
2.  Caso tenha adicionado pastas recentemente, utilize o botão **Atualizar (↻)**.
3.  Selecione o cliente desejado na lista suspensa.
4.  **Atalhos Rápidos:** O ícone de **Pasta Amarela** ao lado do botão Confirmar abre diretamente o diretório de atalhos (`C:\SACS\atalhos\Hemote Plus Update`) para verificação rápida.
5.  Clique em **Confirmar**.
    *   O sistema validará os arquivos e indicará sucesso ou falha.

### 4️⃣ Gestão de COD_HEM
O sistema oferece duas formas de manipular o parâmetro `COD_HEM` no arquivo `_data_access.ini`:
*   **Via Menu (Automação):** Se a opção **Configurações > Altera COD_HEM** estiver ativa, o sistema solicitará automaticamente o novo código logo após a confirmação da troca de cliente.
*   **Via Rodapé (Manual):** Clicar na etiqueta **"COD: XXX"** na barra de status inferior permite editar o código do cliente atual a qualquer momento, sem necessidade de trocar de ambiente.

### 5️⃣ Personalização e Exibição
No menu **Exibição**:
*   **Modo Escuro:** Alterna o tema da interface.
*   **Sempre Visível:** Mantém a janela sobreposta a outras aplicações (TopMost).
*   **Opacidade:** Ajusta a transparência da janela.
*   **Botão SACS:** Exibe/Oculta atalho rápido para o diretório raiz no rodapé.

### 6️⃣ Encerramento
Para encerrar a execução do processo:
1.  Clique com o **botão direito** no ícone da bandeja.
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

---

## ❓ Troubleshooting

**Ícone não visível**
> Verifique o menu de ícones ocultos (`^`) na barra de tarefas e arraste o ícone para a área visível para facilitar o acesso.

**Erro: Arquivos de configuração ausentes**
> O diretório selecionado para o cliente não contém os arquivos obrigatórios. Verifique a integridade da pasta em `C:\SACS\CLIENTES`.

**Conflito de Configuração**
> O sistema detectou duplicidade de parâmetros (`COD_HEM` ou `URL`) com outro cliente já mapeado.

---

## 👨‍💻 Créditos
Desenvolvido por **Felipe Almeida**.
*Versão 11 - Janeiro de 2026*
