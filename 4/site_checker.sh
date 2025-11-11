#!/bin/bash

#Иницализация переменных по умолчанию
URL=""
ATTEMPTS=1
OUTPUT_FORMAT="text"
TIMEOUT=${CHECK_TIMEOUT:-5}

show_help() {
    cat << EOF

    Usage: $0 [--attempt=5][--output=(text|csv|html)] URL
    Options:
    -a, --attempt NUM    Number of attempts (default: 1)
    -o, --output FORMAT  Output format: text, html, csv (default: text)
    -h, --help          Show this help message

    Environment variables:
        CHECK_TIMEOUT       Timeout in seconds for each request (default: 5)

    Exit codes:
        0 - Site is available
        1 - Site is unavailable

EOF
}


for arg in "$@"; do
    case "$arg" in
        -a=*|--attempt=*)
            ATTEMPTS="${arg#*=}"
            if ! [[ "$ATTEMPTS" =~ ^[0-9]+$ ]] || [ "$ATTEMPTS" -lt 1 ]; then
                echo "Error: Invalid attempts number '$ATTEMPTS'" >&2
                exit 1;
            fi
            ;;
        -o=*|--output=*)
            OUTPUT_FORMAT="${arg#*=}"
            if ! [[ "$OUTPUT_FORMAT" =~ ^(text|csv|html)$ ]];then
                { echo "Error: Invalid output format"; exit 1; }
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ "$arg" =~ ^- ]]; then
                echo "Error: Unknown option: $arg"
                exit 1
            elif [[ -z "$URL" ]]; then
                URL="$arg"
            else
                echo "Error: Multiple URLs provided: '$URL' and '$arg'"
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$URL" ]]; then
    echo "Error: URL is required"
    show_help
    exit 1
fi

#Тело
check_url(){

    local url="$1"
    local timeout="$2"

    local tmp_file
    tmp_file=$(mktemp)

    local output
    output=$(curl -s -o /dev/null -w "%{http_code}\n%{time_total}" \
    --max-time "$timeout" "$url" \
    2>"$tmp_file")

    local exit_code=$?
    local error_msg=$(<"$tmp_file")

    # Удаляем временный файл
    rm -f "$tmp_file"

    local http_code=$(echo "$output" | head -n1)
    local time_total=$(echo "$output" | tail -n1)

    # Конвертируем время в миллисекунды
    local time_total_ms=$(echo "$time_total" | awk '{printf "%.0f", $1 * 1000}')

    if [ $exit_code -eq 0 ]; then
        echo "SUCCESS $http_code $time_total_ms"
    else
        echo "ERROR $exit_code $error_msg $time_total_ms"
    fi
}
success=false
time_total=0
last_error=""
last_exit=0
last_code=""
num_attempts=0
results=()
for ((i=1; i<=ATTEMPTS; i++)); do
    result=$(check_url "$URL" "$TIMEOUT")
    ((num_attempts++))
    if [[ $result == SUCCESS* ]]; then
        read -r status http_code response_time <<< "$result"
        results+=("$i;SUCCESS;$http_code;$response_time")
        time_total=$((time_total + response_time))
        success=true
        last_code=$http_code
        break
    else
        read -r status exit_code error_msg response_time <<< "$result"
        results+=("$i;ERROR;$exit_code;$response_time")
        last_error="$error_msg"
        last_exit="$exit_code"
        sleep 1  # задержка между попытками
    fi
done

#Вывод
case "$OUTPUT_FORMAT" in
    text)
        if [[ $result == SUCCESS* ]]; then
            read -r status http_code response_time <<< "$result"
            echo "✅ Сайт $URL доступен"
            echo "⏱️ Время ответа: ${response_time}ms"
            echo "📊 HTTP-статус: $http_code"
            echo "🔄 Количество попыток: $num_attempts"
            exit 0
        else
            read -r status exit_code error_msg <<< "$result"
            echo "❌ После $num_attempts попыток cайт $URL недоступен"
            echo "🔧 Ошибка: $last_error (код: $last_exit)"
            exit 1
        fi
        ;;
    html)
        {
        echo "<!DOCTYPE html>"
        echo "<html lang='ru'><head><meta charset='UTF-8'><title>Отчёт проверки сайта</title>"
        echo "<style>
                body { font-family: Arial, sans-serif; background: #f8f9fa; padding: 20px; }
                table { border-collapse: collapse; width: 80%; margin: 20px auto; background: white; box-shadow: 0 0 8px rgba(0,0,0,0.1); }
                th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
                th { background: #007bff; color: white; }
                tr:nth-child(even) { background: #f2f2f2; }
                .ok { color: green; font-weight: bold; }
                .fail { color: red; font-weight: bold; }
              </style></head><body>"
        echo "<h2>Результат проверки сайта: <a href='$URL'>$URL</a></h2>"
        echo "<table><tr><th>Попытка</th><th>Статус</th><th>Код / Ошибка</th><th>Время</th></tr>"

        for r in "${results[@]}"; do
            IFS=';' read -r attempt status code info <<< "$r"
            if [[ $status == SUCCESS ]]; then
                echo "<tr><td>$attempt</td><td class='ok'>Успех</td><td>$code</td><td>$response_time ms</td></tr>"
            else
                echo "<tr><td>$attempt</td><td class='fail'>Ошибка</td><td>$code</td><td>$response_time</td></tr>"
            fi
        done

        echo "</table>"
        if $success; then
            echo "<p><b style='color:green'>Сайт доступен</b>. HTTP: $last_code. Время: ${time_total} ms.</p>"
        else
            echo "<p><b style='color:red'>Сайт недоступен</b> после $ATTEMPTS попыток. Ошибка: $last_error</p>"
        fi
        echo "</body></html>"
        } > "check_result.html"

        echo "HTML-отчёт сохранён в файл: check_result.html"
        ;;
esac
