# frozen_string_literal: true

module ValuesConverter
  # TODO
  class Parser
    # Регулярное выражение для формата "Ингредиент - Значение Единица"
    PATTERN = /\A(.+?)\b - ([\d,]+)\s(.+)\z/

    def self.parse(line)
      match = line.strip.match(PATTERN)

      unless match
        raise InvalidInputError,
              "Неверный формат входных данных: '#{line}'. Ожидается: 'Ингредиент - Значение Единица'"
      end

      {
        ingredient: match[1],
        value: change_value_format(match[2]),
        unit: match[3]
      }
    end

    def self.change_value_format(value)
      value.tr(',', '.').to_f
    end
  end
end
