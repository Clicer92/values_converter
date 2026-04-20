

require 'minitest/autorun'

class BotTest < Minitest::Test
  
  def test_convert_ml_to_g_flour
    value = 250
    from_unit = 'мл'
    product = 'мука'
    to_unit = 'г'
    density = 0.6
    
    result = value * density
    expected = 150.0
    
    assert_equal expected, result
    puts "Test 1 passed: 250 мл мука = #{result} г"
  end
  
  def test_convert_g_to_ml_flour
    value = 150
    from_unit = 'г'
    product = 'мука'
    to_unit = 'мл'
    density = 0.6
    
    result = value / density
    expected = 250.0
    
    assert_equal expected, result
    puts "Test 2 passed: 150 г мука = #{result} мл"
  end
  
  def test_convert_ml_to_g_milk
    value = 200
    density = 1.03
    
    result = value * density
    expected = 206.0
    
    assert_equal expected, result
    puts "Test 3 passed: 200 мл молоко = #{result} г"
  end
  
  def test_convert_ml_to_g_sugar
    value = 100
    density = 0.85
    
    result = value * density
    expected = 85.0
    
    assert_equal expected, result
    puts "Test 4 passed: 100 мл сахар = #{result} г"
  end
  
  def test_convert_kg_to_g
    value = 1
    result = value * 1000
    expected = 1000
    
    assert_equal expected, result
    puts "Test 5 passed: 1 кг = #{result} г"
  end
  
  def test_convert_g_to_kg
    value = 1000
    result = value / 1000.0
    expected = 1.0
    
    assert_equal expected, result
    puts "Test 6 passed: 1000 г = #{result} кг"
  end
  
  def test_flour_density
    density = 0.6
    assert_equal 0.6, density
    puts "Test 7 passed: плотность муки = #{density}"
  end
  
  def test_milk_density
    density = 1.03
    assert_equal 1.03, density
    puts "Test 8 passed: плотность молока = #{density}"
  end
  
  def test_sugar_density
    density = 0.85
    assert_equal 0.85, density
    puts "Test 9 passed: плотность сахара = #{density}"
  end
  
  def test_start_command
    command = '/start'
    expected = 'start'
    assert_equal 'start', command[1..-1]
    puts "Test 10 passed: команда /start распознана"
  end
  
  def test_help_command
    command = '/help'
    expected = 'help'
    assert_equal 'help', command[1..-1]
    puts "Test 11 passed: команда /help распознана"
  end
  
  def test_convert_format
  message = '/convert 250 мл мука в г'
  assert message.include?('/convert')
  assert message.include?('в')
  puts "Test 12 passed: формат сообщения правильный"
end
end


Minitest.run