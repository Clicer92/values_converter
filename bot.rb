require 'net/http'
require 'json'
require 'dotenv/load'
require 'values_converter'

class VKRecipeBot
  attr_reader :token, :headers, :server, :running, :user_states, :densities, :units
  
  def initialize
    @token = ENV['VK_ACCESS_TOKEN']
    @headers = { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' }
    @server = nil
    @running = true
    @user_states = {}
    
    load_data_from_gem
    
    puts "Бот инициализирован с гемом values_converter"
    puts "Загружено продуктов: #{@densities.size}"
    puts "Загружено единиц объёма: #{@units[:volume].size}"
    puts "Загружено единиц массы: #{@units[:mass].size}"
  end
  
  
  def load_data_from_gem
    @densities = {}
    @units = { volume: {}, mass: {} }
    
    begin
      if defined?(ValuesConverter::Converter::DENSITY_DICT)
        @densities = ValuesConverter::Converter::DENSITY_DICT.dup
        puts "Загружены плотности из ValuesConverter::Converter::DENSITY_DICT"
      else
        @densities = {
          'мука пшеничная' => 0.6,
          'вода' => 1.0,
          'молоко' => 1.03,
          'сахар' => 0.85,
          'соль' => 1.2,
          'разрыхлитель' => 0.9
        }
      end
      
      if defined?(ValuesConverter::Converter::UNITS)
        units_data = ValuesConverter::Converter::UNITS
        @units[:volume] = units_data[:volume] if units_data[:volume]
        @units[:mass] = units_data[:mass] if units_data[:mass]
        puts "Загружены единицы из ValuesConverter::Converter::UNITS"
      else
        @units = {
          volume: { 'стакан' => 250.0, 'стакана' => 250.0, 'ст. л.' => 15.0, 'ч. л.' => 5.0, 'чашка' => 240.0, 'fl oz' => 29.57 },
          mass: { 'г' => 1.0, 'г.' => 1.0, 'кг' => 1000.0, 'oz' => 28.35 }
        }
      end
      
      @densities = @densities.transform_keys { |k| k.downcase }
      
      rescue => e
      puts "Ошибка загрузки данных из гема: #{e.message}"
      set_default_data
    end
  end
  
  def set_default_data
    @densities = {
      'мука пшеничная' => 0.6,
      'вода' => 1.0,
      'молоко' => 1.03,
      'сахар' => 0.85,
      'соль' => 1.2
    }
    @units = {
      volume: { 'стакан' => 250.0, 'ст. л.' => 15.0, 'ч. л.' => 5.0, 'чашка' => 240.0, 'мл' => 1.0, 'л' => 1000.0 },
      mass: { 'г' => 1.0, 'кг' => 1000.0 }
    }
  end
  
  def get_density(product)
    product_key = product.downcase
    @densities[product_key] || 1.0
  end
  
  def get_unit_factor(unit, type)
    unit_key = unit.downcase
    @units[type][unit_key] || (type == :mass ? 1.0 : 1.0)
  end
  
  
  def convert_with_gem(value, from_unit, product, to_unit)
    begin
      parsed_item = {
        value: value,
        unit: from_unit,
        ingredient: product
      }
      
      result = ValuesConverter::Converter.convert(parsed_item, to_unit)
      
      if result && result[:value]
        return "#{value} #{from_unit} #{product} = #{result[:value]} #{to_unit}"
      else
        return convert_with_density(value, from_unit, product, to_unit)
      end
      rescue => e
      puts "Ошибка гема: #{e.message}"
      return convert_with_density(value, from_unit, product, to_unit)
    end
  end
  
  
  def convert_with_density(value, from_unit, product, to_unit)
    density = get_density(product)
    
    if is_volume_unit?(from_unit) && is_mass_unit?(to_unit)
      ml_value = convert_to_ml(value, from_unit)
      result = ml_value * density
      return "#{value} #{from_unit} #{product} = #{result.round(1)} #{to_unit}"
      
    elsif is_mass_unit?(from_unit) && is_volume_unit?(to_unit)
     
      gram_value = convert_to_gram(value, from_unit)
      result = gram_value / density
      return "#{value} #{from_unit} #{product} = #{result.round(1)} #{to_unit}"
      
    else
    return "Ошибка: не могу конвертировать #{from_unit} в #{to_unit}"
    end
  end
  
  def is_volume_unit?(unit)
    @units[:volume].keys.any? { |u| u.downcase == unit.downcase } || ['мл', 'л'].include?(unit)
  end
  
  def is_mass_unit?(unit)
    @units[:mass].keys.any? { |u| u.downcase == unit.downcase } || ['г', 'кг'].include?(unit)
  end
  
  def convert_to_ml(value, unit)
    case unit.downcase
    when 'мл' then value
    when 'л' then value * 1000
    when 'стакан', 'стакана' then value * 250
    when 'ст. л.' then value * 15
    when 'ч. л.' then value * 5
    when 'чашка', 'чашек' then value * 240
    when 'fl oz' then value * 29.57
    else value
    end
  end
  
  def convert_to_gram(value, unit)
    case unit.downcase
    when 'г', 'г.' then value
    when 'кг', 'кг.' then value * 1000
    when 'oz' then value * 28.35
    else value
    end
  end
  
  
  def start
    return false unless get_long_poll_server
    puts "Бот запущен. "
    
    while @running
      begin
        updates = fetch_updates
        process_updates(updates) if updates
      rescue => e
        puts "Ошибка в основном цикле: #{e.message}"
        sleep 5
        get_long_poll_server
      end
    end
  end
  
  def stop
    @running = false
    puts "Бот остановлен"
  end
  
  def get_long_poll_server
    uri = URI("https://api.vk.com/method/messages.getLongPollServer")
    params = {
      access_token: @token,
      v: '5.199',
      need_pts: 1,
      lp_version: 3
    }
    uri.query = URI.encode_www_form(params)
    
    http = create_http(uri)
    response = http.get(uri.request_uri, @headers)
    data = JSON.parse(response.body)
    
    if data['response']
      @server = data['response']
      puts "Long Poll сервер получен"
      true
    else
      puts "Ошибка: #{data}"
      false
    end
  end
  
  def fetch_updates
    return nil unless @server
    
    poll_uri = URI("https://#{@server['server']}")
    poll_params = {
      act: 'a_check',
      key: @server['key'],
      ts: @server['ts'],
      wait: 25,
      mode: 2,
      version: 3
    }
    poll_uri.query = URI.encode_www_form(poll_params)
    
    poll_http = create_http(poll_uri)
    poll_response = poll_http.get(poll_uri.request_uri, @headers)
    poll_data = JSON.parse(poll_response.body)
    
    @server['ts'] = poll_data['ts'] if poll_data['ts']
    poll_data['updates']
  end
  
  def send_message(user_id, text)
    send_uri = URI("https://api.vk.com/method/messages.send")
    send_params = {
      access_token: @token,
      user_id: user_id,
      message: text,
      random_id: rand(10**10),
      v: '5.199'
    }
    send_uri.query = URI.encode_www_form(send_params)
    
    send_http = create_http(send_uri)
    send_http.get(send_uri.request_uri, @headers)
    puts "Ответ отправлен пользователю #{user_id}"
  end
  
  def create_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http
  end

  def process_updates(updates)
    updates.each do |update|
      if update[0] == 4 && update[2] == 1
        message = update[5]
        user_id = update[3]
        
        puts "Сообщение от #{user_id}: #{message}"
        answer = process_message(message, user_id)
        send_message(user_id, answer)
      end
    end
  end
  
  def process_message(message, user_id)
    state = get_user_state(user_id)
    cmd = message.strip
    
    case message
    when '/start' then
      set_user_state(user_id, 'idle', {})
      return start_message
    when '/help'then
      set_user_state(user_id, 'idle', {})
      return help_message
    when '/state'then
      return state_message(user_id)
    when '/reset'then
      set_user_state(user_id, 'idle', {})
      return reset_message
    when '/convert'then
      set_user_state(user_id, 'waiting_recipe', {})
      return msg_convert_recipe_prompt
    when '/products'then
      return products_list
    when '/units'then
      return units_list
    end
    
    case state[:step]
    when 'waiting_recipe'then set_user_state(user_id, 'idle', {})
      return convert_recipe(cmd)
    else
      if cmd =~ /\/convert\s+(\d+(?:\.\d+)?)\s+(\w+)\s+(\w+)\s+в\s+(\w+)/
        return convert_with_gem($1.to_f, $2, $3, $4)
      else
        return unknown_message
      end
    end
  end
  
  def convert(recipe_text)
    if UNITS[:mass].include?(from_unit) && UNITS[:mass].include?(to_unit)
      result = ValuesConverter::Mass.new(value, from_unit).to(to_unit)
      "#{value} #{from_unit} = #{result.round(2)} #{to_unit}"
    elsif UNITS[:volume].include?(from_unit) && UNITS[:volume].include?(to_unit)
      result = ValuesConverter::Volume.new(value, from_unit).to(to_unit)
      "#{value} #{from_unit} = #{result.round(2)} #{to_unit}"
    elsif UNITS[:temperature].include?(from_unit) && UNITS[:temperature].include?(to_unit)
      result = ValuesConverter::Temperature.new(value, from_unit).to(to_unit)
      "#{value} #{from_unit} = #{result.round(2)} #{to_unit}"
    else
     result =  "Ошибка: неподдерживаемые единицы"
    end
    return result
  end
  
  def get_user_state(user_id)
    @user_states[user_id] || { step: 'idle', data: {} }
  end
  
  def set_user_state(user_id, step, data = {})
    @user_states[user_id] = { step: step, data: data, updated_at: Time.now }
  end 
  def msg_help
    "Команды:\n/start - запуск\n/help - справка\n/products - список продуктов\n/units - список единиц\n/convert_recipe - ввод рецепта\n/state - текущее состояние\n/reset - сброс состояния\n\nПримеры:\n/convert 250 мл мука в г\n/convert 1 стакан молоко в г\n/convert 2 ст.л. сахар в г"
  end
  
  def msg_products
    "Доступные продукты:\nмука пшеничная (0.6)\nвода (1.0)\nмолоко (1.03)\nсахар (0.85)\nсоль (1.2)\nразрыхлитель (0.9)"
  end
  
  def msg_units
    "Единицы объёма:\nстакан, стакана, ст.л., ч.л., чашка, fl oz, мл, л\n\nЕдиницы массы:\nг, г., кг, кг., oz\n\nПример: /convert 1 стакан молоко в г"
  end
  
  def msg_state(step, data)
    "Состояние: #{step}\nДанные: #{data.empty? ? 'пусто' : data}"
  end
  
  def msg_reset
    "Состояние сброшено."
  end
  
  def msg_convert_recipe_prompt
    "Введите рецепт. Каждый ингредиент на новой строке.\nФормат: [число] [единица] [продукт] в [единица]\n\nПример:\n250 мл мука пшеничная в г\n200 мл молоко в г\n2 ст.л. сахар в г"
  end
  
  def msg_convert_success(value, from_unit, product, result, to_unit)
   "введите рецепт"
  end
  
  def msg_convert_error(from_unit, to_unit)
    "Ошибка: не могу конвертировать #{from_unit} в #{to_unit}"
  end
  
  def msg_unknown
    "Неизвестная команда. Напишите /help"
  end
  
  def msg_recipe_result(lines)
    lines.join("\n")
  end
  
  def msg_recipe_line_error(line)
    "Не распознано: #{line}"
  end
  
  def msg_product_not_found
    "Продукт не найден. Список: /products"
  end
  
  def msg_unit_not_found
    "Единица не найдена. Список: /units"
  end
    
  def get_density(product)
    product_key = product.downcase
    @densities[product_key] || 1.0
  end
  def msg_start
    "Что бы вы хотели конвертировать?"
  end
  
  def convert_to_ml(value, unit)
    case unit.downcase
    when 'мл' then value
    when 'л' then value * 1000
    when 'стакан', 'стакана' then value * 250
    when 'ст.л.' then value * 15
    when 'ч.л.' then value * 5
    when 'чашка' then value * 240
    when 'fl oz' then value * 29.57
    else value
    end
  end
  
  def convert_to_gram(value, unit)
    case unit.downcase
    when 'г', 'г.' then value
    when 'кг', 'кг.' then value * 1000
    when 'oz' then value * 28.35
    else value
    end
  end
  
  def convert_value(value, from_unit, product, to_unit)
    density = get_density(product)
    
    if is_volume_unit?(from_unit) && is_mass_unit?(to_unit)
      ml_value = convert_to_ml(value, from_unit)
      result = ml_value * density
      return result.round(1) 
    elsif is_mass_unit?(from_unit) && is_volume_unit?(to_unit)
      gram_value = convert_to_gram(value, from_unit)
      result = gram_value / density
      return  result.round(1) 
    else
      return  msg_convert_error(from_unit, to_unit) 
    end
  end
  
  def is_volume_unit?(unit)
    @units[:volume].keys.any? { |u| u.downcase == unit.downcase } || ['мл', 'л'].include?(unit)
  end
  
  def is_mass_unit?(unit)
    @units[:mass].keys.any? { |u| u.downcase == unit.downcase } || ['г', 'кг'].include?(unit)
  end

  
  def start
    return false unless get_long_poll_server
    puts "Бот запущен"
    
    while @running
      begin
        updates = fetch_updates
        process_updates(updates) if updates
      rescue => e
        puts "Ошибка: #{e.message}"
        sleep 5
        get_long_poll_server
      end
    end
  end
  
  def stop
    @running = false
    puts "Бот остановлен"
  end
  
  def get_long_poll_server
    uri = URI("https://api.vk.com/method/messages.getLongPollServer")
    params = { access_token: @token, v: '5.199', need_pts: 1, lp_version: 3 }
    uri.query = URI.encode_www_form(params)
    
    http = create_http(uri)
    response = http.get(uri.request_uri, @headers)
    data = JSON.parse(response.body)
    
    if data['response']
      @server = data['response']
      puts "Сервер получен"
      true
    else
      puts "Ошибка получения сервера"
      false
    end
  end
  
  def fetch_updates
    return unless @server
    
    poll_uri = URI("https://#{@server['server']}")
    poll_params = { act: 'a_check', key: @server['key'], ts: @server['ts'], wait: 25, mode: 2, version: 3 }
    poll_uri.query = URI.encode_www_form(poll_params)
    
    poll_http = create_http(poll_uri)
    poll_response = poll_http.get(poll_uri.request_uri, @headers)
    poll_data = JSON.parse(poll_response.body)
    
    @server['ts'] = poll_data['ts'] if poll_data['ts']
    poll_data['updates']
  end
  
  def send_message(user_id, text)
    send_uri = URI("https://api.vk.com/method/messages.send")
    send_params = {
      access_token: @token,
      user_id: user_id,
      message: text,
      random_id: rand(10**10),
      v: '5.199'
    }
    send_uri.query = URI.encode_www_form(send_params)
    
    send_http = create_http(send_uri)
    send_http.get(send_uri.request_uri, @headers)
  end
  
  def create_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http
  end

  
  def process_updates(updates)
    updates.each do |update|
      if update[0] == 4 && update[2] == 1
        message = update[5]
        user_id = update[3]
        puts "Сообщение: #{message}"
        answer = process_message(message, user_id)
        send_message(user_id, answer)
      end
    end
  end
  
  def process_message(message, user_id)
  cmd = message.strip
  
  if cmd.start_with?('/convert')
    parts = cmd.split(' ')
    if parts.length >= 6
      value = parts[1].to_f
      from_unit = parts[2]
      product = parts[3]
      to_unit = parts[5]
      return convert_value(value, from_unit, product, to_unit)
    else
      return "Неверный формат. Пример: /convert 250 мл мука в г"
    end
  end
  
  case cmd
  when '/start'
    return msg_start
  when '/help'
    return msg_help
  when '/products'
    return products_list
  when '/units'
    return units_list
  else
    return msg_unknown
  end
end
 
  
  def handle_start(user_id)
    set_user_state(user_id, 'idle', {})
    msg_start
  end
  
  def handle_help(user_id)
    set_user_state(user_id, 'idle', {})
    msg_help
  end
  
  def handle_state(user_id)
    state = get_user_state(user_id)
    msg_state(state[:step], state[:data])
  end
  
  def handle_reset(user_id)
    set_user_state(user_id, 'idle', {})
    msg_reset
  end
  
  def handle_products(user_id)
    set_user_state(user_id, 'idle', {})
    msg_products
  end
  
  def handle_units(user_id)
    set_user_state(user_id, 'idle', {})
    msg_units
  end
  
  def handle_convert(user_id)
    set_user_state(user_id, 'waiting_recipe', {})
    msg_convert_recipe_prompt
    convert
  end
  
  def handle_recipe_input(user_id, text)
    set_user_state(user_id, 'idle', {})
    lines = text.strip.split("\n")
    results = []
    
    lines.each do |line|
      if line =~ /(\d+(?:\.\d+)?)\s+(\w+)\s+(\w+)\s+в\s+(\w+)/
        value = $1.to_f
        from_unit = $2
        product = $3
        to_unit = $4
        
        conv = convert_value(value, from_unit, product, to_unit)
        
          results << msg_convert_success(value, from_unit, product, conv[:result], to_unit)
         
      end
    end
    
    msg_recipe_result(results)
  end
  
  def handle_convert(user_id, value, from_unit, product, to_unit)
    set_user_state(user_id, 'idle', {})
    conv = convert(value, from_unit, product, to_unit)
    
    if conv[:success]
      msg_convert_success(value, from_unit, product, conv[:result], to_unit)
    else
      conv[:error]
    end
  end
  
   if __FILE__ == $PROGRAM_NAME
  bot = VKRecipeBot.new
  
  trap('INT') do
    puts "\nОстановка бота..."
    bot.stop
    exit
  end
  
  bot.start
end 
end
