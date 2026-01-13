# Clientes Hemote Plus - v11 🩸

**Ferramenta de produtividade para gerenciamento de ambientes Hemote.**

O **Clientes Hemote Plus** é um utilitário desenvolvido para agilizar a rotina de quem precisa alternar frequentemente entre configurações de diferentes clientes. Com foco em produtividade, ele automatiza a cópia de arquivos de configuração e gerencia atalhos, tudo através de uma interface discreta que reside na bandeja do sistema.

---

## 🚀 Funcionalidades Confirmadas

*   **⚡ Troca Rápida de Ambiente:** Altera automaticamente os arquivos `_data_access.ini`, `WebUpdate.ini` e logos na pasta raiz `C:\SACS`.
*   **🕵️‍♂️ Comportamento "Stealth" (Bandeja do Sistema):** O programa **não ocupa espaço na sua barra de tarefas**. Ele fica acessível exclusivamente pelo ícone na **Bandeja do Sistema** (ao lado do relógio do Windows), ideal para manter aberto o dia todo sem poluir sua área de trabalho.
*   **🌙 Modo Escuro Inteligente:** Interface adaptada com suporte a *Dark Mode* real (incluindo a barra de título) no Windows 10 e 11.
*   **🛡️ Auditoria de Duplicidade:** O sistema escaneia todos os clientes e impede que você selecione um ambiente que tenha o mesmo código (`COD_HEM`) ou URL de conexão de outro cliente já mapeado, evitando erros operacionais.
*   **🔗 Gestão Automática de Atalhos:** Ao trocar de cliente, o sistema busca atalhos na pasta `C:\SACS\atalhos\Hemote Plus Update` e os renomeia com o nome do cliente atual (ex: `Hemote - Unimed.lnk`), facilitando a identificação visual.
*   **📝 Edição de COD_HEM:** Permite alterar o código da unidade manualmente através de um diálogo dedicado, caso necessário.
*   **👻 Sempre em Segundo Plano:** Ao clicar no "X" para fechar, o programa apenas se esconde na bandeja, pronto para ser chamado novamente.

---

## 📋 Pré-requisitos do Sistema

Para o funcionamento correto, assegure-se de que sua máquina possui:
1.  **Sistema Operacional:** Windows 10 ou Windows 11.
2.  **Estrutura de Pastas Obrigatória:**
    *   `C:\SACS` (Raiz do sistema)
    *   `C:\SACS\CLIENTES` (Ou outra pasta contendo as subpastas de cada cliente)
    *   **Opcional:** `C:\SACS\atalhos\Hemote Plus Update` (Para a funcionalidade de renomear atalhos funcionar).

---

## 🛠️ Passo a Passo: Como Utilizar

Siga este guia para configurar e operar o sistema corretamente.

### 1️⃣ Instalação e Primeira Execução
1.  Baixe e coloque o arquivo `Clientes Hemote.exe` em um local seguro (ex: `C:\SACS` ou sua Área de Trabalho).
2.  Execute o arquivo.
    *   ⚠ **Atenção:** O programa **NÃO** aparecerá na barra horizontal inferior do Windows. Procure pelo ícone de uma **Gota de Sangue 🩸** perto do relógio (pode ser necessário clicar na setinha `^` para mostrar ícones ocultos).
3.  Dê um duplo clique no ícone da gota para abrir a janela principal.

### 2️⃣ Configurando a Pasta de Clientes
Antes de usar, você precisa dizer ao programa onde os dados dos clientes estão salvos:
1.  Na janela do programa, clique no menu superior **Configurações**.
2.  Clique em **Clientes**.
3.  Uma janela de seleção de pasta abrirá. Navegue e selecione a pasta que contém as subpastas dos clientes (Geralmente `C:\SACS\CLIENTES`).
4.  O sistema irá carregar a lista imediatamente.

### 3️⃣ Trocando de Cliente (Uso Diário)
1.  Abra o programa (duplo clique no ícone da bandeja).
2.  Na lista (ComboBox), selecione o nome do cliente desejado.
3.  Clique no botão azul **Confirmar**.
    *   O sistema copiará os arquivos.
    *   Os atalhos serão renomeados.
    *   Uma mensagem verde confirmará o sucesso no rodapé.
4.  Pode fechar a janela (ela voltará para a bandeja) e iniciar seu trabalho no sistema Hemote.

### 4️⃣ Configurando Opções Extras
No menu **Exibição**, você pode personalizar sua experiência:
*   **Modo Escuro:** Alterna as cores da interface, ideal para ambientes com pouca luz.
*   **Sempre Visível:** Mantém a janelinha do programa flutuando acima de qualquer outra janela aberta (útil durante manutenções).
*   **Opacidade:** Deixa a janela transparente (estilo "Fantasma") para ver o que está atrás.

### 5️⃣ Como Fechar o Programa Definitivamente
Como o botão "X" apenas minimiza o programa para a bandeja:
1.  Clique com o **botão direito** no ícone da Gota de Sangue 🩸 lá perto do relógio.
2.  Selecione a opção **Sair**.

---

## ❓ Resolução de Problemas Comuns

**"Não encontro o ícone do programa!"**
> O Windows costuma esconder ícones pouco usados. Clique na setinha `^` na barra de tarefas (canto inferior direito) e arraste o ícone da gota para fora, deixando-o sempre visível.

**"O Dark Mode não deixou a barra de título preta."**
> A barra de título escura requer Windows 10 (versão 2004 ou superior) ou Windows 11. Em versões antigas do Windows 10 ou anteriores, a barra permanecerá da cor padrão do sistema, mas o restante da interface ficará escuro.

**"Erro: Conflito de Duplicidade"**
> O programa detectou que o cliente que você tentou selecionar possui o mesmo `COD_HEM` ou `URL` de outro cliente na pasta. Verifique os arquivos `.ini` desses clientes para corrigir a duplicidade.

---

## 👨‍💻 Créditos
Desenvolvido por **Felipe Almeida**.
*Versão 11 - Janeiro de 2026*
