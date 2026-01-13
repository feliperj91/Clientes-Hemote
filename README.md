# Clientes Hemote Plus - v11 🩸

**Ferramenta essencial para gerenciamento rápido e seguro de ambientes de clientes Hemote.**

O **Clientes Hemote Plus** é um utilitário desenvolvido em PowerShell (com interface Windows Forms e C# integrado) para facilitar a vida de quem precisa alternar constantemente entre configurações de diferentes clientes no sistema Hemote. Ele automatiza a troca de arquivos de configuração, valida duplicidades e oferece uma interface moderna e produtiva.

---

## 🚀 Funcionalidades

*   **⚡ Troca Rápida:** Alterne entre clientes em segundos. O sistema copia automaticamente `_data_access.ini`, `WebUpdate.ini` e logos para a pasta `C:\SACS`.
*   **🌙 Modo Escuro (Dark Mode):** Interface moderna que respeita seus olhos, com suporte nativo à barra de título escura do Windows 10 e 11.
*   **🛡️ Validação de Duplicidade:** Evite erros de configuração! O sistema alerta se você tentar usar um cliente que possui o mesmo `COD_HEM` ou URL de atualização de outro já cadastrado.
*   **📂 Atalhos Inteligentes:** Atualiza automaticamente os atalhos na sua área de trabalho/pasta de atalhos, renomeando-os com o nome do cliente ativo.
*   **👻 Tray Icon:** O programa roda discretamente na bandeja do sistema (perto do relógio) e pode iniciar minimizado.
*   **🚀 Inicialização Automática:** Opção para iniciar junto com o Windows.
*   **✏️ Edição Rápida:** Permite alterar o `COD_HEM` manualmente após a seleção.

---

## 📋 Pré-requisitos

*   **Sistema Operacional:** Windows 10 ou Windows 11.
*   **Estrutura de Pastas:**
    *   O sistema espera que exista uma pasta `C:\SACS`.
    *   Dentro dela, deve haver uma pasta com os clientes (ex: `C:\SACS\CLIENTES`) contendo subpastas para cada cliente.

---

## 🛠️ Como Usar (Passo a Passo)

1.  **Execução:**
    *   Abra o arquivo `Clientes Hemote.exe`.
    *   O ícone aparecerá na barra de tarefas e na bandeja do sistema.

2.  **Configuração Inicial (Primeira vez):**
    *   Vá no menu **Configurações > Clientes**.
    *   Selecione a pasta onde estão as pastas dos seus clientes (ex: `C:\SACS\CLIENTES`).
    *   O sistema irá carregar a lista automaticamente.

3.  **Trocando de Cliente:**
    *   Na tela inicial, clique na lista (ComboBox) e selecione o cliente desejado.
    *   Clique no botão azul **Confirmar**.
    *   ✅ **Pronto!** Os arquivos foram copiados, o status no rodapé foi atualizado e os atalhos foram renomeados.

4.  **Ajustes Visuais e Extras:**
    *   **Modo Escuro:** Vá em *Exibição > Modo Escuro*.
    *   **Opacidade:** Ajuste a transparência da janela em *Exibição > Opacidade*.
    *   **Sempre Visível:** Mantenha a janela sobre as outras em *Exibição > Sempre Visível*.

---

## ⚠️ Estrutura de Arquivos Esperada

Para que o sistema reconheça um cliente, a pasta dele deve conter:
*   `_data_access.ini`
*   `WebUpdate.ini`

---

## 📦 Compilação (Para Desenvolvedores)

Se você baixou o código fonte (`.ps1`), pode gerar o executável usando o **PS2EXE** ou similar. Certifique-se de usar os parâmetros:
*   `-noConsole` (Para não abrir a tela preta)
*   `-sta` (Single Threaded Apartment, necessário para Windows Forms)

---

## 👨‍💻 Créditos

Desenvolvido por **Felipe Almeida**.
*Última atualização: Janeiro de 2026*
