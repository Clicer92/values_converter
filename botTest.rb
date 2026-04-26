require 'minitest/autorun'
require_relative 'bot'

class TestVKRecipeBot < Minitest::Test
  
  def setup
    @bot = VKRecipeBot.new
  end
  
  
  def test_convert_ml_to_g_flour
    result = @bot.convert_value(250, 'мл', 'мука', 'г')
    assert_equal "250 мл мука = 150.0 г", result
  end
  
  def test_convert_g_to_ml_flour
    result = @bot.convert_value(150, 'г', 'мука', 'мл')
    assert_equal "150 г мука = 250.0 мл", result
  end
  
  def test_convert_ml_to_g_milk
    result = @bot.convert_value(200, 'мл', 'молоко', 'г')
    assert_equal "200 мл молоко = 206.0 г", result
  end
  
  def test_convert_ml_to_g_sugar
    result = @bot.convert_value(100, 'мл', 'сахар', 'г')
    assert_equal "100 мл сахар = 85.0 г", result
  end
  
  def test_convert_g_to_ml_sugar
    result = @bot.convert_value(85, 'г', 'сахар', 'мл')
    assert_equal "85 г сахар = 100.0 мл", result
  end
  
  def test_convert_cup_to_g_flour
    result = @bot.convert_value(1, 'стакан', 'мука', 'г')
    assert_equal "1 стакан мука = 150.0 г", result
  end
  
  def test_convert_tsp_to_g_sugar
    result = @bot.convert_value(2, 'ч.л.', 'сахар', 'г')
    assert_equal "2 ч.л. сахар = 8.5 г", result
  end
  
  def test_convert_tbsp_to_g_sugar
    result = @bot.convert_value(1, 'ст.л.', 'сахар', 'г')
    expected = "1 ст.л. сахар = 12.8 г"
    assert_equal expected, result
  end
  
  def test_convert_kg_to_g
    result = @bot.convert_value(2, 'кг', '', 'г')
    assert_equal "2 кг = 2000 г", result
  end
  
  def test_convert_g_to_kg
    result = @bot.convert_value(500, 'г', '', 'кг')
    assert_equal "500 г = 0.5 кг", result
  end
  
  def test_convert_l_to_ml
    result = @bot.convert_value(1, 'л', '', 'мл')
    assert_equal "1 л = 1000 мл", result
  end
  
  def test_convert_ml_to_l
    result = @bot.convert_value(500, 'мл', '', 'л')
    assert_equal "500 мл = 0.5 л", result
  end
  
  def test_convert_cup_to_kg_flour
    result = @bot.convert_value(1, 'стакан', 'мука', 'кг')
    assert_equal "1 стакан мука = 0.15 кг", result
  end
  
  def test_convert_kg_to_cup_flour
    result = @bot.convert_value(0.15, 'кг', 'мука', 'стакан')
    assert_equal "0.15 кг мука = 1.0 стакан", result
  end
  
  
  def test_convert_invalid_unit
    result = @bot.convert_value(100, 'xxx', 'мука', 'г')
    assert_equal "Ошибка: не могу конвертировать xxx в г", result
  end
  
  def test_convert_invalid_product
    result = @bot.convert_value(250, 'мл', 'неизвестный', 'г')
    assert_equal "250 мл неизвестный = 250.0 г", result
  end
  
  
  def test_convert_single_ingredient_recipe
    recipe = "250 мл мука в г"
    result = @bot.convert_recipe(recipe)
    assert_includes result, "250 мл мука = 150.0 г"
  end
  
  def test_convert_multiple_ingredients_recipe
    recipe = "250 мл мука в г\n200 мл молоко в г"
    result = @bot.convert_recipe(recipe)
    assert_includes result, "250 мл мука = 150.0 г"
    assert_includes result, "200 мл молоко = 206.0 г"
  end
  
  
  def test_initial_user_state
    state = @bot.get_user_state(123456)
    assert_equal 'idle', state[:step]
    assert_empty state[:data]
  end
  
  def test_set_user_state
    @bot.set_user_state(123456, 'waiting_recipe', { product: 'мука' })
    state = @bot.get_user_state(123456)
    assert_equal 'waiting_recipe', state[:step]
    assert_equal 'мука', state[:data][:product]
  end
  
  def test_reset_user_state
    @bot.set_user_state(123456, 'waiting_recipe', {})
    @bot.set_user_state(123456, 'idle', {})
    state = @bot.get_user_state(123456)
    assert_equal 'idle', state[:step]
  end
  
  
  def test_start_command
    result = @bot.process_message('/start', 123456)
    assert_includes result, 'Что бы вы хотели конвертировать?'
  end
  
  def test_help_command
    result = @bot.process_message('/help', 123456)
    assert_includes result, 'Команды'
    assert_includes result, '/start'
    assert_includes result, '/help'
  end
  
  def test_products_command
    result = @bot.process_message('/products', 123456)
    assert_includes result, 'мука пшеничная'
    assert_includes result, 'молоко'
  end
  
  def test_units_command
    result = @bot.process_message('/units', 123456)
    assert_includes result, 'стакан'
    assert_includes result, 'г'
  end
  
  def test_state_command
    @bot.set_user_state(123456, 'idle', {})
    result = @bot.process_message('/state', 123456)
    assert_includes result, 'idle'
  end
  
  def test_reset_command
    @bot.set_user_state(123456, 'waiting_recipe', {})
    result = @bot.process_message('/reset', 123456)
    assert_includes result, 'Состояние сброшено'
    state = @bot.get_user_state(123456)
    assert_equal 'idle', state[:step]
  end
  
  def test_convert_recipe_command
    result = @bot.process_message('/convert_recipe', 123456)
    assert_includes result, 'Введите рецепт'
  end
  
  def test_unknown_command
    result = @bot.process_message('/unknown', 123456)
    assert_includes result, 'Неизвестная команда'
  end
  
  
  def test_flour_density
    density = @bot.get_density('мука')
    assert_equal 0.6, density
  end
  
  def test_milk_density
    density = @bot.get_density('молоко')
    assert_equal 1.03, density
  end
  
  def test_sugar_density
    density = @bot.get_density('сахар')
    assert_equal 0.85, density
  end
  
  def test_water_density
    density = @bot.get_density('вода')
    assert_equal 1.0, density
  end
  
  def test_salt_density
    density = @bot.get_density('соль')
    assert_equal 1.2, density
  end
  
  def test_unknown_product_density
    density = @bot.get_density('неизвестный')
    assert_equal 1.0, density
  end
end 