# Clientes Hemote Plus - v11 🩸

**Ferramenta de produtividade para gerenciamento de ambientes Hemote.**

O **Clientes Hemote Plus** é um utilitário desenvolvido para agilizar a rotina de quem precisa alternar frequentemente entre configurações de diferentes clientes. Com foco em produtividade, ele automatiza a cópia de arquivos de configuração e gerencia atalhos, tudo através de uma interface discreta que reside na bandeja do sistema.

---

## 🚀 Novidades da Versão (Atualizado)

1.  **👁️ Monitoramento em Tempo Real:** 
    *   Não é mais necessário reiniciar o programa ao adicionar novos clientes! O sistema detecta automaticamente se você criar, renomear ou excluir pastas em `C:\SACS\CLIENTES` e atualiza a lista na hora.
2.  **🛡️ Validação de Integridade:** 
    *   Antes de trocar o cliente, o sistema verifica se os arquivos críticos (`_data_access.ini` e `WebUpdate.ini`) realmente existem na pasta de origem. Se estiverem faltando, ele avisa e impede a troca, prevenindo configurações quebradas.
3.  **🎨 Modo Escuro Aprimorado:** 
    *   Visual "Solid Dark" sem bordas brancas irritantes nos menus.
    *   Destaques em cinza escuro para maior conforto visual.
4.  **🖱️ Controle de Bandeja Inteligente:** 
    *   **Duplo clique** no ícone da bandeja para **Mostrar** a janela.
    *   **Duplo clique** novamente para **Minimizar** de volta para a bandeja.
    *   O programa fica totalmente oculto da barra de tarefas ("Stealth Mode").
5.  **🔄 Botão de Atualização Manual:**
    *   Caso precise forçar uma atualização, um botão "Refresh" (↻) foi adicionado ao lado da lista de clientes.

---

## 📋 Pré-requisitos do Sistema

Para o funcionamento correto, assegure-se de que sua máquina possui:
1.  **Sistema Operacional:** Windows 10 ou Windows 11.
2.  **Estrutura de Pastas Obrigatória:**
    *   `C:\SACS` (Raiz do sistema)
    *   `C:\SACS\CLIENTES` (Onde ficam as subpastas de cada cliente)
    *   **Opcional:** `C:\SACS\atalhos\Hemote Plus Update` (Para a funcionalidade automática de renomear atalhos).

---

## 🛠️ Passo a Passo: Como Utilizar

Siga este guia para configurar e operar o sistema corretamente.

### 1️⃣ Instalação e Primeira Execução
1.  Baixe e coloque o arquivo `Clientes Hemote.exe` em um local seguro (ex: `C:\SACS` ou sua Área de Trabalho).
2.  Execute o arquivo.
    *   ⚠ **Atenção:** O programa **NÃO** aparecerá na barra horizontal inferior do Windows. Procure pelo ícone de uma **Gota de Sangue 🩸** perto do relógio (Bandeja do Sistema).
3.  Dê um duplo clique no ícone da gota para abrir a janela principal.

### 2️⃣ Configurando a Pasta de Clientes
Antes de usar, você precisa dizer ao programa onde os dados dos clientes estão salvos:
1.  Na janela do programa, clique no menu superior **Configurações**.
2.  Clique em **Clientes**.
3.  Uma janela de seleção de pasta abrirá. Navegue e selecione a pasta que contém as subpastas dos clientes (Geralmente `C:\SACS\CLIENTES`).
4.  O sistema irá carregar a lista automaticamente.

### 3️⃣ Trocando de Cliente (Uso Diário)
1.  Abra o programa (duplo clique no ícone da bandeja ou use o botão ↻ se adicionou arquivos recentemente).
2.  Na lista (ComboBox), selecione o nome do cliente.
3.  Clique no botão azul **Confirmar**.
    *   O sistema verifica se os arquivos existem.
    *   Se houver duplicidade de `COD_HEM` ou `URL` com outro cliente, ele avisa.
    *   Se tudo estiver ok, ele copia os arquivos e renomeia o atalho em `Hemote Plus Update`.
    *   Uma mensagem verde confirmará o sucesso.
4.  Dê um duplo clique no ícone da bandeja para esconder a janela novamente.

### 4️⃣ Configurando Opções de Exibição
No menu **Exibição**, personalize sua experiência:
*   **Modo Escuro:** Alterna para o novo tema escuro refinado.
*   **Sempre Visível:** Mantém a janelinha flutuando acima de tudo.
*   **Opacidade:** Deixa a janela transparente ("Fantasma").
*   **Botão SACS:** Adiciona um atalho rápido no rodapé para abrir a pasta `C:\SACS`.

### 5️⃣ Como Fechar o Programa Definitivamente
Como o botão "X" apenas minimiza o programa para a bandeja (para não fechar por acidente):
1.  Clique com o **botão direito** no ícone da Gota de Sangue 🩸 perto do relógio.
2.  Selecione a opção **Sair**.

---

## ❓ Resolução de Problemas Comuns

**"Não encontro o ícone do programa!"**
> O Windows costuma esconder ícones pouco usados. Clique na setinha `^` na barra de tarefas (canto inferior direito) e arraste o ícone da gota para fora.

**"Erro: Arquivos de configuração ausentes"**
> Isso significa que a pasta do cliente que você selecionou está vazia ou faltando o `_data_access.ini` ou `WebUpdate.ini`. Verifique a pasta em `C:\SACS\CLIENTES`.

**"Erro: Conflito de data_access e WebUpdate"**
> O programa detectou que o cliente selecionado tem exatamente as mesmas configurações de outro cliente já existente. Ele mostrará qual arquivo está conflitando para você corrigir.

---

## 👨‍💻 Créditos
Desenvolvido por **Felipe Almeida**.
*Versão 11 - Janeiro de 2026*
