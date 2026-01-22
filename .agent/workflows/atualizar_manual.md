---
description: Atualiza o manual PDF a partir do README.md
---

1. Certifique-se de que o arquivo README.md está atualizado com as últimas alterações.

// turbo
2. Gerar o arquivo PDF colorido usando npx markdown-pdf com estilos
```bash
npx -y markdown-pdf "README.md" -s "manual-style.css" -o "Manual.pdf"
```

3. Verifique se o arquivo Manual.pdf foi gerado corretamente no diretório atual.
