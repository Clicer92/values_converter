# frozen_string_literal: true

RSpec.describe ValuesConverter do
  describe '.convert_recipe' do
    let(:recipe_text) do
      <<~RECIPE
        Мука пшеничная - 500 г.
        Вода - 2 стакана
        Яйцо куриное - 3 шт.
        Соль - 0,5 ч. л.
      RECIPE
    end

    it "конвертирует ингредиенты в целевую единицу, учитывая плотность и игнорируя 'шт.'" do
      result = ValuesConverter.convert_recipe(recipe_text, target_unit: 'г.')

      expect(result).to include('Мука пшеничная - 500 г.')
      expect(result).to include('Вода - 500 г.')
      expect(result).to include('Яйцо куриное - 3 шт.')
      expect(result).to include('Соль - 3 г.')
    end
  end

  describe '.build_recipe' do
    it 'собирает текст рецепта из массива данных' do
      data = [
        { ingredient: 'Сахар', value: 100, unit: 'г.' },
        { ingredient: 'Молоко', value: 1.5, unit: 'стакана' }
      ]

      expected_output = "Сахар - 100 г.\nМолоко - 1,5 стакана"
      expect(ValuesConverter.build_recipe(data)).to eq(expected_output)
    end
  end
end
