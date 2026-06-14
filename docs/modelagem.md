# Modelagem das Expressões Regulares

Este documento detalha cada expressão regular utilizada no Reconhecedor de Lista de Afazeres, explicando a estrutura, os casos cobertos e as escolhas de modelagem.

---

## 1. Horários

### Expressão

```ruby
REGEX_HORARIO = /
  (?:
    (?:às?)\s+(2[0-3]|[01]?\d)\b(?::([0-5]\d)|\s+([0-5]\d)\b|\s+horas?\b)?
    |
    \b(2[0-3]|[01]?\d)(?::([0-5]\d)|\s+([0-5]\d)\b|\s+horas?\b)
  )
/xi
```

### Casos Cobertos

| Entrada | Resultado |
|---|---|
| `às 10:30` | `10:30` |
| `às 10 30` | `10:30` |
| `às 10 horas` | `10:00` |
| `às 10` | `10:00` |
| `10:30` | `10:30` |
| `10 30` | `10:30` |
| `1 hora` | `01:00` |
| `às 23 horas` | `23:00` |

### Justificativa

O padrão é dividido em duas alternâncias:

1. **Com prefixo "às/as"**: `(?:às?)\s+...` — captura horários precedidos da preposição, que é comum em linguagem natural ("às 10 horas").
2. **Sem prefixo**: `\b(2[0-3]|[01]?\d)...` — captura horários autônomos como "10:30".

**Ordem das alternâncias de horas**: `2[0-3]|[01]?\d` — o padrão `2[0-3]` (para horas 20–23) vem **antes** de `[01]?\d` porque o motor de regex testa alternâncias na ordem. Se `[01]?\d` fosse primeiro, o texto "23" seria capturado como "2" (apenas o dígito), deixando "3" sem sentido.

**Minutos**: três sub-alternâncias cobrem `:MM` (dois-pontos), ` MM` (espaço) e a ausência de minutos (implicitamente "00").

---

## 2. Datas

### Expressão

```ruby
REGEX_DATA = /
  \b
  (?:
    (\d{1,2})(?:\s+de)?\s+(janeiro|fevereiro|março|...)(?:\s+(?:de\s+)?(\d{4}))?
    |
    (\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?
    |
    (depois\s+de\s+amanh[aã]|amanh[aã]|hoje)
  )
  \b
/xi
```

### Casos Cobertos

| Entrada | Resultado (base: 21/03/2022) |
|---|---|
| `hoje` | `21/03/2022` |
| `amanhã` | `22/03/2022` |
| `depois de amanhã` | `23/03/2022` |
| `30/01` | `30/01/2022` |
| `20/04/2022` | `20/04/2022` |
| `28 de Fevereiro` | `28/02/2022` |
| `13 de agosto de 2021` | `13/08/2021` |
| `18 agosto` | `18/08/2022` |
| `18 de agosto 2023` | `18/08/2023` |

### Justificativa

Três alternâncias independentes:

1. **Por extenso**: `(\d{1,2})(?:\s+de)?\s+(mês)...` — o "de" é opcional com `(?:\s+de)?`, cobrindo "18 agosto" e "18 de agosto". O ano também é opcional.
2. **Numérica**: `(\d{1,2})\/(\d{1,2})...` — cobre dd/mm e dd/mm/aaaa.
3. **Relativa**: A ordem importa — `depois\s+de\s+amanh[aã]` vem antes de `amanh[aã]`, pois "depois de amanhã" contém "amanhã" como substring. Se "amanhã" viesse primeiro no regex, "depois de amanhã" seria reconhecido como se fosse apenas "amanhã".

**Classe de caracteres do ã**: `[aã]` ou `[a\u00e3]` — garante que tanto "amanha" (digitação sem acento) quanto "amanhã" sejam reconhecidos.

**Remoção prévia de URLs**: antes de aplicar o regex de datas, URLs são removidas para evitar que barras em paths como `https://site.com/30/01` sejam interpretadas como datas.

---

## 3. Tags

### Expressão

```ruby
REGEX_TAG = /#[a-z\u00e0-\u00ff0-9_-]+/i
```

### Casos Cobertos

| Entrada | Resultado |
|---|---|
| `#trabalho` | `["#trabalho"]` |
| `#casa #urgente` | `["#casa", "#urgente"]` |
| `#meu-projeto` | `["#meu-projeto"]` |

### Justificativa

- `#` — caractere literal que introduz a tag (igual a Twitter/X e Todoist).
- `[a-z\u00e0-\u00ff0-9_-]+` — permite letras ASCII, letras acentuadas do bloco Latin-1 Supplement (ã, ç, é etc.), dígitos, underline e hífen. O `+` exige ao menos um caractere após o `#`.
- `scan` é usado em vez de `match` para retornar **todas** as tags encontradas na linha.

---

## 4. URLs

### Expressão

```ruby
REGEX_URL = %r{https?://[^\s/$.?#][^\s]*}i
```

### Casos Cobertos

| Entrada | Resultado |
|---|---|
| `https://sp.senac.br` | `["https://sp.senac.br"]` |
| `https://sp.senac.br/pag1#ancora?a=1&b=2` | URL completa |

### Justificativa

- `https?://` — cobre `http` e `https`.
- `[^\s/$.?#]` — o primeiro caractere do host não pode ser espaço nem os caracteres especiais, garantindo que o domínio seja válido.
- `[^\s]*` — captura tudo até o próximo espaço, preservando path, âncoras e query strings intactos.

---

## 5. E-mails

### Expressão

```ruby
REGEX_EMAIL = /\b[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}\b/i
```

### Casos Cobertos

| Entrada | Resultado |
|---|---|
| `jose@empresa.com.br` | `["jose@empresa.com.br"]` |
| `jose.da-silva@sp.senac.br` | `["jose.da-silva@sp.senac.br"]` |

### Justificativa

- `[a-z0-9._%+\-]+` — parte local: permite letras, dígitos e os símbolos permitidos pelo RFC 5321 (ponto, underscore, porcentagem, sinal de mais, hífen).
- `@` — separador obrigatório.
- `[a-z0-9.\-]+\.[a-z]{2,}` — domínio: subdomínios separados por ponto, seguidos de TLD com no mínimo 2 letras.
- `\b` nas bordas evita capturar e-mails dentro de palavras maiores.

---

## 6. Ações

### Expressão

```ruby
REGEX_ACAO = /\b(agendar|marcar|ligar|reunião|reunir|lembrar|enviar|...)\b/i
```

### Casos Cobertos

Verbos reconhecidos: `agendar`, `marcar`, `ligar`, `reunião`, `reunir`, `lembrar`, `enviar`, `mandar`, `comprar`, `pagar`, `revisar`, `estudar`, `entregar`, `fazer`, `criar`, `confirmar`, `cancelar`, `adiar`, `checar`, `verificar`.

### Justificativa

- Lista de alternâncias de verbos e substantivos de ação comuns em listas de tarefas.
- `\b` nas bordas garante que "agendaram" não seja confundido com "agendar".
- Flag `i` torna a busca insensível a maiúsculas, então "Agendar" e "AGENDAR" são reconhecidos.
- Apenas o **primeiro** verbo encontrado é retornado (um afazer tipicamente tem uma ação principal).

---

## 7. Pessoas

### Expressão

```ruby
REGEX_PESSOA = /\b(?:com|para)\s+([A-Z\u00c0-\u00dc][a-z\u00e0-\u00fc]+(?:\s+e\s+[A-Z\u00c0-\u00dc][a-z\u00e0-\u00fc]+)*)/
```

### Casos Cobertos

| Entrada | Resultado |
|---|---|
| `com José` | `["José"]` |
| `com Pedro e João` | `["Pedro", "João"]` |
| `para Maria` | `["Maria"]` |

### Justificativa

- `(?:com|para)` — conectores que introduzem pessoas em linguagem natural de tarefas.
- `[A-Z\u00c0-\u00dc]` — primeira letra maiúscula, incluindo letras acentuadas maiúsculas (Á, É, Ó etc.).
- `[a-z\u00e0-\u00fc]+` — restante do nome em minúsculas, incluindo letras acentuadas.
- `(?:\s+e\s+...)*` — captura múltiplas pessoas separadas por " e ".
- Após o `scan`, o grupo capturado é dividido em `split(/\s+e\s+/)` para separar os nomes individuais no array de saída.

---

## Considerações Gerais

### Por que não usar bibliotecas de data?

O enunciado proíbe gems ou bibliotecas que reconheçam datas. Todo o parsing é feito manualmente: o mês por extenso é convertido em número via `Array#index` sobre a lista `MESES`, e datas relativas são calculadas com aritmética sobre `Date.today`.

### Flags utilizadas

- `/i` — case-insensitive: "Agendar" e "agendar" são equivalentes.
- `/x` — modo verboso: permite espaços e comentários dentro da expressão (apenas nos padrões definidos com esse flag), tornando o regex mais legível.

### Prioridade das alternâncias

Em múltiplas alternâncias, o motor de regex Ruby (Oniguruma) testa cada alternativa da **esquerda para a direita** e retorna o primeiro sucesso. Isso exige atenção especial em dois casos:

1. **Horas**: `2[0-3]` antes de `[01]?\d`.
2. **Datas relativas**: `depois de amanhã` antes de `amanhã`.
