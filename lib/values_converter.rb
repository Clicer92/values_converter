# frozen_string_literal: true

require_relative 'values_converter/version'
require_relative 'values_converter/parser'
require_relative 'values_converter/converter'
require_relative 'values_converter/error'

# TODO
module ValuesConverter
  def self.convert_recipe(recipe_text, target_unit: 'г.')
    lines = recipe_text.strip.split("\n")
    converted_lines = lines.map do |line|
      next line unless line.include?(' - ')

      parsed_item = Parser.parse(line)
      next line unless parsed_item

      converted_item = Converter.convert(parsed_item, target_unit: target_unit)
      format_line(converted_item)
    rescue InvalidInputError => e
      puts "[ValuesConverter] Пропущена строка. #{e.message}"
    end
    converted_lines.join("\n")
  end

  def self.build_recipe(ingredients_data)
    ingredients_data.map { |item| format_line(item) }.join("\n")
  end

  def self.format_line(item)
    display_value = item[:value] == item[:value].to_i ? item[:value].to_i : item[:value]
    "#{item[:ingredient]} - #{display_value.to_s.tr('.', ',')} #{item[:unit]}"
  end
end
