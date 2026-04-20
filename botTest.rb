
require_relative 'bot' 

class BotTester
  def initialize
    @passed = 0
    @failed = 0
  end

  def test(description, expected, actual)
    if expected == actual
      puts " #{description}"
      @passed += 1
    else
      puts " #{description}"
      puts "Ожидалось: #{expected.inspect}"
      puts " Получено:  #{actual.inspect}"
      @failed += 1
    end
  end

  def test_includes(description, expected_substring, actual)
    if actual.to_s.include?(expected_substring.to_s)
      puts " #{description}"
      @passed += 1
    else
      puts " #{description}"
      puts " Ожидалось наличие: #{expected_substring.inspect}"
      puts " В строке: #{actual.inspect}"
      @failed += 1
    end
  end

  def summary

    puts "Результаты: #{@passed} пройдено, #{@failed} провалено"
    @failed.zero? ? " Все тесты пройдены!" : " Есть ошибки"
  end
end


puts "Загрузка бота..."
begin
  bot = VKRecipeBot.new
  puts " Бот загружен"
rescue => e
  puts "Ошибка загрузки бота: #{e.message}"
  exit
end

tester = BotTester.new
puts "Тестирование команд"

puts "\n Тест 1: Команда /start"
response = bot.send(:start_command, 123)
tester.test_includes('/start возвращает приветствие', 'активирован', response)

puts "\n Тест 2: Команда /stop"
response = bot.send(:stop_command, 123)
tester.test_includes('/stop возвращает сообщение о деактивации', 'деактивирован', response)

puts "\n Тест 3: Команда /help"
response = bot.send(:help_message)
tester.test_includes('/help содержит список команд', '/convert', response)
tester.test_includes('/help содержит /start', '/start', response)

puts "\n Тест 4: Команда /units"
response = bot.send(:units_list)
tester.test_includes('/units содержит единицы массы', 'g', response)
tester.test_includes('/units содержит единицы объёма', 'ml', response)
tester.test_includes('/units содержит единицы температуры', 'c', response)

puts "\n Тест 5: Команда /get_rules"
response = bot.send(:get_rules)
tester.test_includes('/get_rules содержит формат', 'формат', response.downcase)

puts "\n" + "=" * 50
puts "Тестирование конвертации"
puts "=" * 50

puts "\nТест 6: Конвертация массы"
response = bot.send(:convert, 1000, 'g', 'kg')
tester.test_includes('1000 g → kg', '1.0 kg', response)

puts "\n Тест 7: Конвертация объёма"
response = bot.send(:convert, 500, 'ml', 'l')
tester.test_includes('500 ml → l', '0.5 l', response)

puts "\nТест 8: Конвертация температуры"
response = bot.send(:convert, 0, 'c', 'f')
tester.test_includes('0°C → °F', '32.0 f', response)

puts "\n Тест 9: Неверные единицы измерения"
response = bot.send(:convert, 100, 'g', 'invalid')
tester.test_includes('Ошибка при неверной единице', 'Ошибка', response)

puts "\n Тест 10: Смешивание типов единиц"
response = bot.send(:convert, 100, 'g', 'ml')
tester.test_includes('Ошибка при смешивании массы и объёма', 'Ошибка', response)

puts "\n Тест 11: Определение единиц массы"
tester.test('g → массa', :mass, bot.send(:detect_unit_type, 'g'))
tester.test('kg → масса', :mass, bot.send(:detect_unit_type, 'kg'))
tester.test('lb → масса', :mass, bot.send(:detect_unit_type, 'lb'))

puts "\n Тест 12: Определение единиц объёма"
tester.test('ml → объём', :volume, bot.send(:detect_unit_type, 'ml'))
tester.test('l → объём', :volume, bot.send(:detect_unit_type, 'l'))
tester.test('cup → объём', :volume, bot.send(:detect_unit_type, 'cup'))

puts "\n Тест 13: Определение единиц температуры"
tester.test('c → температура', :temperature, bot.send(:detect_unit_type, 'c'))
tester.test('f →емпература', :temperature, bot.send(:detect_unit_type, 'f'))
tester.test('k → температура', :temperature, bot.send(:detect_unit_type, 'k'))

puts "\n Тест 14: Неизвестная единица"
tester.test('unknown → nil', nil, bot.send(:detect_unit_type, 'unknown'))

puts "\n Тест 15: Начало создания рецепта"
response = bot.send(:add_recipe, 123, 'Борщ')
tester.test_includes('add_recipe возвращает сообщение', 'Начинаю создание', response)

puts "\n Тест 16: Добавление ингредиента"
bot.send(:add_recipe, 123, 'Борщ')
response = bot.send(:add_ingredient, 123, 'Добавить 500 g свекла')
tester.test_includes('Добавление корректного ингредиента', 'Добавлен', response)

puts "\nТест 17: Неверный формат ингредиента"
response = bot.send(:add_ingredient, 123, 'неправильный формат')
tester.test('Неверный формат возвращает false', false, response)

puts "\n"
puts tester.summary 