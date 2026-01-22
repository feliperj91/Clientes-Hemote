# Menu de Impressoras - Clientes Hemote Plus

## Resumo das Alterações

Foi adicionado um novo menu **"Impressoras"** no menu de **Configurações**, localizado logo abaixo do menu "Clientes".

### Estrutura do Menu

```
Configurações
├── Clientes
├── Impressoras
│   ├── Gráfica
│   └── Etiqueta
├── Altera COD_HEM
├── Validar duplicidade de URL
└── Iniciar com o Windows
```

### Funcionalidades

#### 1. **Submenu Gráfica**
- Carrega automaticamente todas as impressoras instaladas no Windows
- Permite selecionar uma impressora para impressão de fichas
- A impressora selecionada é salva nos seguintes parâmetros do arquivo `C:\sacs\configuracao.ini`:
  - `[FICHA_DOADOR]`
  - `[FICHA_REDOME]`

#### 2. **Submenu Etiqueta**
- Carrega automaticamente todas as impressoras instaladas no Windows
- Permite selecionar uma impressora para impressão de etiquetas/códigos de barras
- A impressora selecionada é salva nos seguintes parâmetros do arquivo `C:\sacs\configuracao.ini`:
  - `[BARCODE_DOADOR]`
  - `[BARCODE_GERAL]`

### Comportamento

1. **Carregamento Dinâmico**: As impressoras são carregadas dinamicamente quando o usuário abre cada submenu
2. **Seleção Única**: Apenas uma impressora pode ser selecionada por vez em cada submenu
3. **Persistência**: A seleção é salva automaticamente no arquivo `configuracao.ini`
4. **Restauração**: Ao abrir o menu, a impressora atualmente configurada aparece marcada
5. **Criação Automática**: Se o arquivo `configuracao.ini` não existir, ele será criado automaticamente

### Exemplo de Configuração

Após selecionar as impressoras, o arquivo `C:\sacs\configuracao.ini` terá o seguinte formato:

```ini
[  IMPRESSORAS  ]
[INSTITUICAO]    = IEHE
[--]
[BARCODE_DOADOR] = Microsoft Print to PDF
[BARCODE_GERAL]  = Microsoft Print to PDF
[--]
[FICHA_DOADOR]   = Generic
[FICHA_REDOME]   = Generic
```

### Tooltips (Mensagens de Ajuda)

Ao passar o mouse sobre os menus, são exibidas as seguintes mensagens no rodapé:

- **Impressoras**: "Configurar impressoras para fichas e etiquetas"
- **Gráfica**: "Selecionar impressora para FICHA_DOADOR e FICHA_REDOME"
- **Etiqueta**: "Selecionar impressora para BARCODE_DOADOR e BARCODE_GERAL"

### Funções Adicionadas

1. **Load-Printers**: Carrega as impressoras instaladas no Windows e popula o menu
2. **Save-PrinterConfig**: Salva a impressora selecionada no arquivo `configuracao.ini`
3. **Load-CurrentPrinter**: Carrega a impressora atualmente configurada e marca no menu

### Compatibilidade

- ✅ Funciona com modo claro e escuro
- ✅ **Diálogo personalizado** - permite configurar ambas as impressoras em uma única janela
- ✅ Mantém o padrão visual do aplicativo
- ✅ Integrado com o sistema de tooltips existente
- ✅ Cria automaticamente o diretório e arquivo se não existirem

### Correções Aplicadas

**Versão 2.2 - 22/01/2026 - DARK MODE COMPLETO**
- ✅ **Dark Mode na barra de título** - title bar agora fica escura no modo escuro
- ✅ **Janela reduzida** - tamanho compacto 420x230 pixels
- ✅ **Interface limpa** - removidos labels informativos dos parâmetros
- ✅ **Implementado diálogo personalizado** - solução definitiva para o problema de fechamento do menu
- ✅ **Configuração simultânea** - permite selecionar Gráfica e Etiqueta na mesma janela
- ✅ Suporte completo ao modo escuro no diálogo
- ✅ Botões Salvar e Cancelar com visual moderno
- ✅ Carrega automaticamente as seleções atuais do arquivo configuracao.ini

### Notas Técnicas

- **Diálogo Personalizado**: Usa `System.Windows.Forms.Form` ao invés de submenus
- **Evento Click**: Menu Impressoras abre o diálogo ao clicar
- As expressões regulares usam `[regex]::Escape()` para escapar corretamente os colchetes
- A detecção do modo escuro é feita verificando `$menuModoEscuro.Checked`
- As cores são aplicadas dinamicamente ao abrir o diálogo
- **ComboBox**: Usa `DropDownList` para seleção das impressoras
- **Validação**: Apenas salva se houver impressora selecionada

