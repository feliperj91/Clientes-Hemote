# Clientes Hemote Plus - v11 🩸

**Ferramenta para gerenciamento e troca rápida de configurações de ambientes Hemote.**

O **Clientes Hemote Plus** automatiza a substituição de arquivos de configuração (`_data_access.ini` e `WebUpdate.ini`) e a atualização de atalhos, operando discretamente a partir da bandeja do sistema (System Tray).

---

## 🚀 Novidades da Versão

1.  **🔄 Atualização Manual de Lista:**
    *   Implementado botão de atualização (Refresh ↻) adjacente ao combo de seleção. Permite recarregar manualmente a lista de clientes após alterações no diretório raiz, garantindo confiabilidade.
2.  **🛡️ Validação de Integridade:**
    *   Verificação prévia da existência dos arquivos críticos (`_data_access.ini` e `WebUpdate.ini`) no diretório de origem. A troca de ambiente é bloqueada caso os arquivos estejam ausentes, prevenindo inconsistências no sistema.
3.  **🎨 Interface Dark Mode:**
    *   Tema escuro aprimorado para conforto visual e integração com o estilo Windows 10/11.
4.  **🖱️ Controle via System Tray:**
    *   Minimização e restauração da interface através de duplo clique no ícone da bandeja.
    *   A aplicação não ocupa espaço na barra de tarefas (Taskbar), mantendo o ambiente de trabalho limpo.
5.  **✨ Gerenciamento de Atalhos:**
    *   Renomeação automática dos atalhos no diretório `Hemote Plus Update` para refletir o cliente ativo, facilitando a identificação visual.

---

## 📋 Pré-requisitos

1.  **Sistema Operacional:** Windows 10 ou Windows 11.
2.  **Estrutura de Diretórios:**
    *   `C:\SACS`: Diretório raiz do sistema.
    *   `C:\SACS\CLIENTES`: Repositório das pastas de configuração de cada cliente.
    *   `C:\SACS\atalhos\Hemote Plus Update`: Diretório alvo para renomeação dinâmica de atalhos.

---

## 🛠️ Guia de Utilização

### 1️⃣ Inicialização
1.  Execute o `Clientes Hemote.exe`.
2.  A aplicação iniciará minimizada na bandeja do sistema (ícone Hemote).
    *   ℹ **Nota:** O ícone pode estar oculto no menu de ícones ocultos (`^`) da barra de tarefas.

### 2️⃣ Configuração Inicial
Configure o diretório fonte dos clientes:
1.  Acesse o menu **Configurações > Clientes**.
2.  Selecione o diretório onde residem as subpastas dos clientes (Padrão: `C:\SACS\CLIENTES`).

### 3️⃣ Troca de Ambiente
1.  Restaure a janela com duplo clique no ícone da bandeja.
2.  Caso tenha adicionado pastas recentemente, utilize o botão **Atualizar (↻)**.
3.  Selecione o cliente desejado na lista suspensa.
4.  Clique em **Confirmar**.
    *   O sistema validará os arquivos e indicará sucesso ou falha (ex: arquivos ausentes ou duplicidade de parâmetros).
5.  A janela pode ser minimizada novamente para a bandeja com duplo clique no ícone ou botão de fechar.

### 4️⃣ Personalização e Exibição
No menu **Exibição**:
*   **Modo Escuro:** Alterna o tema da interface.
*   **Sempre Visível:** Mantém a janela sobreposta a outras aplicações.
*   **Opacidade:** Ajusta a transparência da janela.
*   **Botão SACS:** Exibe/Oculta atalho rápido para o diretório raiz.

### 5️⃣ Encerramento
Para encerrar a execução do processo:
1.  Clique com o **botão direito** no ícone da bandeja.
2.  Selecione **Sair**.

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
