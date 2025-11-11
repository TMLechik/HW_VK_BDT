#!/bin/bash
# scripts/test_in_container.sh

echo "🧪 Запуск тестирования в Docker контейнере..."

# Собираем образ
docker build -t site_checker .

echo "🚀 Запускаем тестовую проверку сайта..."

# Запускаем контейнер с тестовым URL
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  site_checker "https://httpbin.org/status/200"

# Проверяем результат
if [ $? -eq 0 ]; then
    echo "✅ Тестирование прошло успешно!"
    echo "📄 Отчет должен быть в папке reports/"
else
    echo "❌ Тестирование завершилось с ошибкой"
    exit 1
fi