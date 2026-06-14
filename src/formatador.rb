require_relative "reconhecedor"

module Formatador
  Sep = "-" * 50

  Rotulos = {
    acao:    "Acao",
    data:    "Dia",
    horario: "Horario",
    pessoas: "Pessoa",
    tags:    "Tag",
    urls:    "URL",
    emails:  "Email"
  }.freeze

  def self.exibir(resultado)
    puts Sep
    vazio = true

    Rotulos.each do |chave, rotulo|
      valor = resultado[chave]
      if valor.is_a?(Array)
        valor.each do |item|
          puts "#{rotulo.ljust(10)}: #{item}"
          vazio = false
        end
      elsif valor
        puts "#{rotulo.ljust(10)}: #{valor}"
        vazio = false
      end
    end

    puts "(nenhum elemento reconhecido)" if vazio
    puts Sep
  end
end
