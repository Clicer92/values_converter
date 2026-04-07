# ValuesConverter

ValuesConverter - гем для конвертации всех ингридиентов рецепта с доступными единицами измерения в желаемую.

---

## Установка

Гем опубликован только на GitHub, поэтому используйте локальную сборку.

1. Склонируйте репозиторий и перейдите в корень.
2. Соберите гем:

```bash
gem build values_converter.gemspec
```

3. Установите:

```bash
gem install values_converter
```

---

## Использование

1. Подключаете гем

```ruby
require 'values_converter'
```
2. Создаете рецепт

```ruby
# Так
recipe =  'Мука пшеничная - 500 г.
          Вода - 2 стакана
          Яйцо куриное - 3 шт.
          Соль - 0,5 ч. л.'          
# Или так
recipe_hash = [
  { ingredient: 'Мука пшеничная', value: 500, unit: 'г.' },
  { ingredient: 'Вода', value: 2, unit: 'стакана' },
  { ingredient: 'Яйцо куриное', value: 3, unit: 'шт.' },
  { ingredient: 'Соль', value: 0.5, unit: 'ч. л.' }
]

recipe = ValuesConverter.build_recipe(recipe_hash)
```

3. Передаете методу 

```ruby
recipe_new = ValuesConverter.convert_recipe(recipe, 'г.')
```

4. Смотрите результат

```ruby
puts recipe_new
```

---

## Тесты

```bash
bundle exec rspec
```

---

## Лицензия

Гем предоставляется по [MIT License](https://opensource.org/licenses/MIT).
