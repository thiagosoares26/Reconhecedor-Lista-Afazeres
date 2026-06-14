# Reconhecedor de Lista de Afazeres

Aplicação de linha de comando em **Ruby** que recebe uma linha de texto descrevendo um afazer e extrai, por meio de **expressões regulares**, os elementos relevantes: horários, datas, pessoas, ações, tags, URLs e e-mails.

## O Problema Resolvido

Aplicativos como Todoist e Remember The Milk permitem que o usuário escreva tarefas em linguagem natural — `"Agendar com José às 10:00 amanhã #trabalho"` — e parseiam automaticamente os dados estruturados. Este projeto implementa um reconhecedor desse tipo usando exclusivamente expressões regulares em Ruby, sem bibliotecas externas.

## Como Executar

```bash
# Execução interativa
ruby main.rb

```

Dentro do programa, digite `sair` para encerrar.

## Exemplo

**Entrada:**
```
Agendar com José reunião às 10:00 amanhã #trabalho
```

**Saída:**
```
──────────────────────────────────────────────────
Ação      : agendar
Dia       : 22/03/2022
Horário   : 10:00
Pessoa    : José
Tag       : #trabalho
──────────────────────────────────────────────────
```

## Estrutura do Projeto

```
reconhecedor/
├── main.rb                  # Ponto de entrada (loop interativo)
├── src/
│   ├── reconhecedor.rb      # Módulo com todas as expressões regulares e extratores
│   └── formatador.rb        # Módulo de exibição estruturada
└── docs/
    └── modelagem.md         # Documentação detalhada das expressões regulares
```

## Modelagem e Teoria

A documentação completa das expressões regulares, com justificativa de cada escolha e casos cobertos, está em [`docs/modelagem.md`](docs/modelagem.md).

Em síntese, as expressões utilizam:

- **Grupos de captura** `(...)` para isolar os valores extraídos
- **Alternâncias** `|` para cobrir múltiplos formatos do mesmo padrão
- **Quantificadores** `?`, `*`, `+` para elementos opcionais ou repetidos
- **Âncoras** `\b` para evitar correspondências parciais dentro de palavras
- **Flags** `x` (modo verboso) e `i` (case-insensitive) para legibilidade

## Principais Funções

| Função | Descrição |
|---|---|
| `Reconhecedor.reconhecer(linha)` | Executa todos os extratores e retorna um hash |
| `Reconhecedor.extrair_horario(texto)` | Retorna `"HH:MM"` ou `nil` |
| `Reconhecedor.extrair_data(texto, base)` | Retorna `"DD/MM/AAAA"` ou `nil` |
| `Reconhecedor.extrair_tags(texto)` | Retorna array de strings `["#tag"]` |
| `Reconhecedor.extrair_urls(texto)` | Retorna array de URLs |
| `Reconhecedor.extrair_emails(texto)` | Retorna array de e-mails |
| `Reconhecedor.extrair_acao(texto)` | Retorna o verbo/ação encontrado ou `nil` |
| `Reconhecedor.extrair_pessoas(texto)` | Retorna array de nomes próprios |
| `Formatador.exibir(resultado)` | Imprime o hash formatado no terminal |
