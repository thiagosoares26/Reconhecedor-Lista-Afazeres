require "date"
require_relative "src/reconhecedor"
require_relative "src/formatador"

Menu = <<~Menu
        Reconhecedor de Lista de Afazeres
        Digite um afazer para analisar.
        Comandos: 'sair', 'exit' ou 'quit' para encerrar.
Menu

puts Menu

loop do
  print "\n> Afazer: "
  entrada = gets&.chomp&.strip

  break if entrada.nil?

  case entrada.downcase
  when "sair", "exit", "quit"
    puts "\nFEchando!"
    break
  when ""
    puts "  (entrada vazia! Tente novamente ou digite um afazer válido)"
  else
    resultado = Reconhecedor.reconhecer(entrada)
    Formatador.exibir(resultado)
  end
end
