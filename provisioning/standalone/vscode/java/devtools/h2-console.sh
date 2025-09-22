#!/usr/bin/env bash
set -euo pipefail

H2_VERSION="${H2_VERSION:-2.3.232}"
M2="${HOME}/.m2/repository"
JAR_DIR="${M2}/com/h2database/h2/${H2_VERSION}"
JAR="${JAR_DIR}/h2-${H2_VERSION}.jar"

PORT="${H2_PORT:-8082}"
PID_FILE="${HOME}/.h2-console.pid"
LOG_FILE="${HOME}/.h2-console.log"

ensure_jar() {
  if [ ! -f "${JAR}" ]; then
    mvn -q dependency:get -Dartifact="com.h2database:h2:${H2_VERSION}" -Dtransitive=false >/dev/null
  fi
}

pid_running() {
  # true se il PID nel file esiste ed è un processo Java H2
  [ -f "${PID_FILE}" ] || return 1
  local pid; pid="$(cat "${PID_FILE}")" || return 1
  [ -d "/proc/${pid}" ] || return 1
  # controllo grossolano che sia il nostro jar
  tr -d '\0' <"/proc/${pid}/cmdline" 2>/dev/null | grep -q "h2-${H2_VERSION}.jar" || return 1
  return 0
}

start() {
  ensure_jar

  if pid_running; then
    echo "H2 Console already running on port ${PORT}"
    echo "/proxy/${PORT}/"
    exit 0
  fi

  # se la porta è occupata, H2 potrebbe crashare: controlla prima
  if ss -lnt 2>/dev/null | awk '{print $4}' | grep -q ":${PORT}$"; then
    echo "ERROR: port ${PORT} is already in use."
    ss -lnt | (echo "Listening ports:"; cat -) | sed 's/^/  /'
    exit 1
  fi

  # avvia e stacca davvero il processo, logga su file
  nohup java -jar "${JAR}" \
    -web -webPort "${PORT}" -webAllowOthers \
    >> "${LOG_FILE}" 2>&1 &

  echo $! > "${PID_FILE}"
  sleep 1

  if pid_running; then
    echo "H2 Console started on port ${PORT}"
    echo "/proxy/${PORT}/"
    exit 0
  else
    echo "ERROR: H2 did not stay up. Log tail:"
    tail -n 50 "${LOG_FILE}" || true
    # pulizia
    rm -f "${PID_FILE}" || true
    exit 1
  fi
}

stop() {
  if ! pid_running; then
    echo "H2 Console not running on port ${PORT}"
    exit 0
  fi
  kill "$(cat "${PID_FILE}")" 2>/dev/null || true
  sleep 0.5
  if pid_running; then
    kill -9 "$(cat "${PID_FILE}")" 2>/dev/null || true
  fi
  rm -f "${PID_FILE}" || true
  echo "H2 Console stopped on port ${PORT}"
}

status() {
  if pid_running; then
    echo "H2 Console is RUNNING on port ${PORT}"
    echo "/proxy/${PORT}/"
  else
    echo "H2 Console is STOPPED"
    # Piccolo aiuto: se il log esiste e ha errori recenti, mostra le ultime righe
    if [ -f "${LOG_FILE}" ]; then
      echo "--- recent log ---"
      tail -n 10 "${LOG_FILE}" || true
    fi
  fi
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  *) echo "Usage: $0 {start|stop|status}"; exit 1 ;;
esac
