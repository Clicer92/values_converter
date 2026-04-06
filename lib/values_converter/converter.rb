# frozen_string_literal: true

module ValuesConverter
  # TODO
  class Converter
    DENSITY_DICT = {
      'мука пшеничная' => 0.6,
      'вода' => 1.0,
      'молоко' => 1.03,
      'сахар' => 0.85,
      'соль' => 1.2,
      'разрыхлитель' => 0.9
    }.freeze

    UNITS = {
      volume:
      { 'стакан' => 250.0,
        'стакана' => 250.0,
        'ст. л.' => 15.0,
        'ч. л.' => 5.0,
        'чашка' => 240.0,
        'чашек' => 240.0,
        'fl oz' => 29.57 },
      mass: { 'г.' => 1.0, 'г' => 1.0, 'кг.' => 1000.0, 'oz' => 28.35 }
    }.freeze

    IGNORED_UNITS = ['шт.', 'щепотка'].freeze

    def self.convert(parsed_item, target_unit:)
      return parsed_item if IGNORED_UNITS.include?(parsed_item[:unit])

      base_value, current_type = to_base_unit(parsed_item[:value], parsed_item[:unit])
      target_type, target_factor = find_target_unit(target_unit)

      return parsed_item unless base_value && target_type

      converted_base = apply_density(base_value, current_type, target_type, parsed_item[:ingredient])

      { ingredient: parsed_item[:ingredient], value: (converted_base / target_factor).round(2), unit: target_unit }
    end

    private_class_method def self.apply_density(value, from_type, to_type, ingredient)
      return value if from_type == to_type

      density = DENSITY_DICT[ingredient.downcase] || 1.0

      if from_type == :volume && to_type == :mass
        value * density
      elsif from_type == :mass && to_type == :volume
        value / density
      else
        value
      end
    end

    def self.to_base_unit(value, unit)
      if (factor = UNITS[:volume][unit])
        [value * factor, :volume]
      elsif (factor = UNITS[:mass][unit])
        [value * factor, :mass]
      else
        [nil, nil]
      end
    end

    def self.find_target_unit(unit)
      if (factor = UNITS[:volume][unit])
        [:volume, factor]
      elsif (factor = UNITS[:mass][unit])
        [:mass, factor]
      else
        [nil, nil]
      end
    end
  end
end
