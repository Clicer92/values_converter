require 'net/http'
require 'json'
require 'dotenv/load'

token = ENV['VK_ACCESS_TOKEN']
puts "Токен загружен"

headers = { 'User-Agent' => 'Mozilla/5.0' }

uri = URI("https://api.vk.com/method/messages.getLongPollServer")
params = {
  access_token: token,
  v: '5.199',
  need_pts: 1,
  lp_version: 3
}
uri.query = URI.encode_www_form(params)

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

response = http.get(uri.request_uri, headers)
data = JSON.parse(response.body)

if data['response']
  server = data['response']
  puts "Сервер получен! Бот запущен."
  
  loop do
    begin
      poll_uri = URI("https://#{server['server']}")
      poll_params = {
        act: 'a_check',
        key: server['key'],
        ts: server['ts'],
        wait: 25,
        mode: 2,
        version: 3
      }
      poll_uri.query = URI.encode_www_form(poll_params)
      
      poll_http = Net::HTTP.new(poll_uri.host, poll_uri.port)
      poll_http.use_ssl = true
      poll_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      poll_response = poll_http.get(poll_uri.request_uri, headers)
      poll_data = JSON.parse(poll_response.body)
      
      if poll_data['updates']
        poll_data['updates'].each do |update|
          if update[0] == 4 && update[2] == 1
            message = update[5]
            user_id = update[3]
            
            puts "Получено: #{message}"
            
            if message == '/start'
              answer = " Бот конвертации!\n\nКоманды:\n/help\n/convert 250 мл мука в г\n/convert 100 г мука в мл"
              
            elsif message == '/help'
              answer = "Команды:\n\n/start - запуск\n/help - помощь\n\nКонвертация объёма в массу:\n/convert 250 мл мука в г\n\nКонвертация массы в объём:\n/convert 100 г мука в мл"
              
            elsif message =~ /\/convert\s+(\d+(?:\.\d+)?)\s+(мл|г)\s+(\S+)\s+в\s+(г|мл)/
              value = $1.to_f
              from_unit = $2
              product = $3
              to_unit = $4
              
              # Плотности продуктов (г/мл)
              densities = {
                'мука' => 0.6,
                'муки' => 0.6,
                'сахар' => 0.85,
                'сахара' => 0.85,
                'молоко' => 1.03,
                'молока' => 1.03,
                'вода' => 1.0,
                'воды' => 1.0,
                'соль' => 1.2,
                'соли' => 1.2
              }
              
              density = densities[product] || 1.0
              
              if from_unit == 'мл' && to_unit == 'г'
                result = value * density
                answer = " #{value} мл #{product} = #{result.round(1)} г"
              elsif from_unit == 'г' && to_unit == 'мл'
                result = value / density
                answer = "#{value} г #{product} = #{result.round(1)} мл"
              else
                answer = " Не могу конвертировать #{from_unit} в #{to_unit}"
              end
              
            elsif message =~ /\/convert\s+(\d+(?:\.\d+)?)\s+(кг|г)\s+в\s+(г|кг)/
              value = $1.to_f
              from_unit = $2
              to_unit = $3
              
              if from_unit == 'кг' && to_unit == 'г'
                answer = " #{value} кг = #{value * 1000} г"
              elsif from_unit == 'г' && to_unit == 'кг'
                answer = " #{value} г = #{value / 1000} кг"
              else
                answer = "Не могу конвертировать"
              end
              
            else
              answer = "Неизвестная команда\n\nПример\n/convert 250 мл мука в г"
            end
            
            puts "Ответ: #{answer}"
            
            send_uri = URI("https://api.vk.com/method/messages.send")
            send_params = {
              access_token: token,
              user_id: user_id,
              message: answer,
              random_id: rand(10**10),
              v: '5.199'
            }
            send_uri.query = URI.encode_www_form(send_params)
            
            send_http = Net::HTTP.new(send_uri.host, send_uri.port)
            send_http.use_ssl = true
            send_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            send_http.get(send_uri.request_uri, headers)
          end
        end
      end
      
      server['ts'] = poll_data['ts'] if poll_data['ts']
    rescue => e
      puts "Ошибка: #{e.message}"
      sleep 5
    end
  end
end 