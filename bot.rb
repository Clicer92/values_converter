# frozen_string_literal: true

require 'vk-ruby'
require 'values_converter'
require 'dotenv/load'
require 'logger'
require 'json'

class VKRecipeBot
  UNITS = {
    mass: ValuesConverter::Mass::UNITS.keys,
    volume: ValuesConverter::Volume::UNITS.keys,
    temperature: ValuesConverter::Temperature::UNITS.keys
  }.freeze

  def initialize
    @app_id = ENV.fetch('VK_APP_ID')
    @access_token = ENV.fetch('VK_ACCESS_TOKEN')
    @logger = Logger.new($stdout)
    @api = VK::API.new(@access_token, version: '5.199')
    @active_users = {}
  end

  def start
    @logger.info('Бот запущен')
    longpoll_server = @api.messages.getLongPollServer(
      need_pts: 1,
      lp_version: 3
    )

    loop do
      response = VK::LongPoll::Client.fetch(
        server: longpoll_server['server'],
        key: longpoll_server['key'],
        ts: longpoll_server['ts'],
        wait: 25
      )

      response['updates']&.each do |update|
        handle_update(update) if update['type'] == 'message_new'
      end

      longpoll_server['ts'] = response['ts']
    rescue StandardError => e
      @logger.error("Ошибка: #{e.message}")
      longpoll_server = @api.messages.getLongPollServer(need_pts: 1, lp_version: 3)
      retry
    end
  end

  private

  def handle_update(update)
    message = update['object']['message']
    user_id = message['from_id']
    text = message['text'].strip

    return if text.empty?

    response = process_command(user_id, text)
    send_message(user_id, response)
  end

  def process_command(user_id, text)
    case text.downcase
    when '/start'
      start_command(user_id)
    when '/stop'
      stop_command(user_id)
    when '/help'
      help_message
    when '/get_rules'
      get_rules
    when '/units'
      units_list
    when /^\/convert\s+(\d+(?:\.\d+)?)\s+(\w+)\s+to\s+(\w+)$/i
      convert($1.to_f, $2.downcase, $3.downcase)
    else
      "Неизвестная команда. Напиши /help"
    end
  end

  def start_command(user_id)
    @active_users[user_id] = { active: true }
    "Бот активирован!\nНапиши /help для списка команд"
  end

  def stop_command(user_id)
    @active_users.delete(user_id)
    "Бот не активирован"
  end

  def help_message
    <<~HELP
     Команды:
      /start - запустить бота
      /stop - остановить бота
      /help - эта справка
      /get_rules - формат рецепта
      /units - список единиц
      /convert 100 g to kg - конвертация
    HELP
  end

  def get_rules
    "Формат: /convert [число] [единица] to [единица]\nПример: /convert 250 g to kg"
  end

  def units_list
    message = " Единицы измерения:\n"
    message += "Масса: #{UNITS[:mass].join(', ')}\n"
    message += "Объём: #{UNITS[:volume].join(', ')}\n"
    message += "Температура: #{UNITS[:temperature].join(', ')}"
    message
  end

  def convert(value, from_unit, to_unit)
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
      "Ошибка: неподдерживаемые единицы"
    end
  end

  def send_message(user_id, text)
    @api.message.send(
      user_id: user_id,
      message: text,
      random_id: rand(10**10),
      parse_mode: 'html'
    )
  rescue VK::Error => e
    @logger.error("Ошибка отправки: #{e.message}")
  end
end

# Запуск бота
if __FILE__ == $PROGRAM_NAME
  unless ENV['VK_APP_ID'] && ENV['VK_ACCESS_TOKEN']
    puts "Ошибка: нет переменных окружения"
    exit 1
  end

  bot = VKRecipeBot.new
  bot.start
end