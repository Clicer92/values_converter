# frozen_string_literal: true

require_relative 'values_converter'

recipe =  'Мука пшеничная - 500 г.
          Вода - 2 стакана
          Яйцо куриное - 3 шт.
          Соль - 0,5 ч. л.'

recipe_new = ValuesConverter.convert_recipe(recipe, target_unit: 'г.')

puts recipe_new
