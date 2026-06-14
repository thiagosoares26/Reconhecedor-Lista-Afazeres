require "date"

module Reconhecedor

  #Meses
  MesesRegex = %w[
    janeiro fevereiro marco março abril maio junho
    julho agosto setembro outubro novembro dezembro
  ].join("|")

  # Horários
  RegexHorario = /
    (?:
      (?:às?)\s+(2[0-3]|[01]?\d)\b(?::([0-5]\d)|\s+([0-5]\d)\b|\s+horas?\b)?
      |
      \b(2[0-3]|[01]?\d)(?::([0-5]\d)|\s+([0-5]\d)\b|\s+horas?\b)
    )
  /xi

  # Datas
  RegexData = /
    \b
    (?:
      (?<diaExt>\d{1,2})(?:\s+de)?\s+(?<mesExt>#{MesesRegex})(?:\s+(?:de\s+)?(?<anoExt>\d{4}))?
      |
      (?<dia>\d{1,2})\/(?<mes>\d{1,2})(?:\/(?<ano>\d{2,4}))?
      |
      (?<relativo>depois\s+de\s+amanh[a\u00e3]|amanh[a\u00e3]|hoje)
    )
    \b
  /xi

  RegexTag    = /#[a-z\u00e0-\u00ff0-9_-]+/i
  RegexURL    = %r{https?://[^\s/$.?#][^\s]*}i
  RegexEmail  = /\b[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}\b/i
  RegexAcao   = /\b(agendar|marcar|ligar|reuni[a\u00e3]o|reunir|lembrar|enviar|mandar|comprar|pagar|revisar|estudar|entregar|fazer|criar|confirmar|cancelar|adiar|checar|verificar)\b/i
  RegexPessoa = /\b(?:com|para)\s+(?:o|a)?\s*((?:[A-Z\u00c0-\u00dc][a-z\u00e0-\u00fc]+(?:\s+|$))+)/u

  def self.extrair_horario(texto)
    m = texto.match(RegexHorario)
    return nil unless m

    horas   = (m[1] || m[4]).to_i
    minutos = (m[2] || m[3] || m[5] || m[6] || "00").to_i
    format("%02d:%02d", horas, minutos)
  end

  def self.extrair_data(texto, dataBase = Date.today)
    textoLimpo = texto.gsub(RegexURL, "")
    m = textoLimpo.match(RegexData)
    return nil unless m

    if m[:relativo]
      palavra = m[:relativo].downcase
      delta =
        if palavra.include?("depois")
          2
        elsif palavra.include?("amanh")
          1
        else
          0
        end
      return (dataBase + delta).strftime("%d/%m/%Y")
    end

    if m[:dia]
      dia = m[:dia].to_i
      mes = m[:mes].to_i
      ano = m[:ano] ? normalizarAno(m[:ano].to_i) : dataBase.year
      return format("%02d/%02d/%04d", dia, mes, ano)
    end

    if m[:diaExt]
      mes_texto = m[:mesExt].downcase.gsub("\u00e3", "a").gsub("\u00e7", "c")
      idx = Meses.index { |mn| mn.casecmp(mes_texto).zero? }
      return nil unless idx

      dia = m[:diaExt].to_i
      mes = idx + 1
      ano = m[:anoExt] ? normalizarAno(m[:anoExt].to_i) : dataBase.year

      return format("%02d/%02d/%04d", dia, mes, ano)
    end

    nil
  end

  def self.extrair_tags(texto)
    texto.scan(RegexTag).uniq
  end

  def self.extrair_urls(texto)
    texto.scan(RegexURL).uniq
  end

  def self.extrair_emails(texto)
    texto.scan(RegexEmail).uniq
  end

  def self.extrair_acao(texto)
    m = texto.match(RegexAcao)
    m ? m[1].downcase : nil
  end

  def self.extrair_pessoas(texto)
    texto.scan(RegexPessoa).flatten
         .flat_map { |g| g.split(/\s+e\s+/i) }
         .map(&:strip).uniq
  end

  def self.reconhecer(linha, dataBase = Date.today)
    {
      horario: extrair_horario(linha),
      data:    extrair_data(linha, dataBase),
      tags:    extrair_tags(linha),
      urls:    extrair_urls(linha),
      emails:  extrair_emails(linha),
      acao:    extrair_acao(linha),
      pessoas: extrair_pessoas(linha)
    }
  end

  def self.normalizarAno(ano)
    return ano if ano >= 100
    ano + (ano >= 50 ? 1900 : 2000)
  end
  private_class_method :normalizarAno
end
