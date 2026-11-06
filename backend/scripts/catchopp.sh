#!/usr/bin/env bash
# Runs the whole CatchOPP backend on one Linux machine (GitHub Codespaces, WSL, a VM…) the same way
# we run it on our PCs: MariaDB on localhost:3306 and every service from its jar, so all the
# "localhost" URLs in the services keep working. In a codespace it is also available as `catchopp`.
#
#   catchopp start            build what changed, then start everything that isn't running
#   catchopp status           which services are up (+ the URL for the app in a codespace)
#   catchopp logs <name>      follow one service's log, e.g. `catchopp logs project`
#   catchopp restart <name>   rebuild and restart one service after changing its code
#   catchopp stop             stop everything this script started
set -uo pipefail

BACKEND="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
RUN_DIR="${CATCHOPP_RUN_DIR:-$HOME/.catchopp}" # logs and pids, outside the repo
JAVA_OPTS="${CATCHOPP_JAVA_OPTS:--Xms32m -Xmx256m -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -Xss512k}"
mkdir -p "$RUN_DIR"

# name, folder, port. Started in this order: Eureka and the gateway first.
SERVICES=(
  "eureka eureka 8761"
  "gateway apigetway 8085"
  "user UserMicroService 8083"
  "project ProjectMicroService 8082"
  "payment paiementMS 8088"
  "competence MS_CompetenceAndReview 8084"
  "chat MSCommunication 8086"
  "support TechnicalSupportMS 8087"
  "skilltests SkillTestsMicroService 8089"
  "community CommunityMicroService 8090"
  "subscription SubscriptionMicroService 8091"
  "referral ReferralMicroService 8092"
)
AI="ai SkillExtractorAI 8093"

up() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

wait_port() { # port, seconds
  local waited
  for ((waited = 0; waited < $2; waited += 2)); do up "$1" && return 0; sleep 2; done
  return 1
}

running() { local pid; pid=$(cat "$RUN_DIR/$1.pid" 2>/dev/null) && kill -0 "$pid" 2>/dev/null; }

public_url() { echo "https://${CODESPACE_NAME}-8085.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"; }

# Links to chat attachments must use the codespace's public address.
if [[ -n ${CODESPACE_NAME:-} ]]; then export CHAT_PUBLIC_BASE_URL="$(public_url)"; fi

jar_of() { ls "$BACKEND/$1"/target/*.jar 2>/dev/null | grep -v '\.original$' | head -1; }

build() { # folder. Only rebuilds when the code changed since the last jar.
  local dir="$BACKEND/$1" jar
  jar="$(jar_of "$1")"
  if [[ -n "$jar" && -z "$(find "$dir/src/main" "$dir/pom.xml" -newer "$jar" -print -quit)" ]]; then return 0; fi
  echo "   building $1…"
  if ! (cd "$dir" && mvn -q -B -Dmaven.test.skip=true package) > "$RUN_DIR/build-$1.log" 2>&1; then
    echo " ✗ $1 doesn't build, see $RUN_DIR/build-$1.log"
    return 1
  fi
}

start_java() { # name, folder, port
  if up "$3"; then echo " ✓ $1 already running (:$3)"; return 0; fi
  build "$2" || return 1
  # From the service's folder, like `mvnw spring-boot:run` (chat attachments go to its uploads/).
  # setsid: keeps running after the codespace's start command ends.
  cd "$BACKEND/$2" || return 1
  setsid nohup java $JAVA_OPTS -jar "$(jar_of "$2")" > "$RUN_DIR/$1.log" 2>&1 < /dev/null &
  echo $! > "$RUN_DIR/$1.pid"
  cd - > /dev/null || true
  echo " → $1 starting (:$3)"
}

# Python 3.12 + the AI service's packages through uv (one binary): no apt, no system Python needed.
install_ai() { # folder
  local uv="$RUN_DIR/bin/uv"
  if [[ ! -x $uv ]]; then
    mkdir -p "$RUN_DIR/bin"
    curl -LsSf "https://github.com/astral-sh/uv/releases/latest/download/uv-$(uname -m)-unknown-linux-gnu.tar.gz" \
      | tar -xz -C "$RUN_DIR/bin" --strip-components=1 || return 1
  fi
  rm -rf "$1/.venv"
  "$uv" venv --python 3.12 "$1/.venv" && "$uv" pip install --python "$1/.venv/bin/python" -r "$1/requirements.txt"
}

start_ai() {
  local dir="$BACKEND/SkillExtractorAI" port=8093
  if up $port; then echo " ✓ ai already running (:$port)"; return 0; fi
  if [[ ! -f "$dir/.venv/.installed" || "$dir/requirements.txt" -nt "$dir/.venv/.installed" ]]; then
    echo "   installing the AI service (Python 3.12 + packages)…"
    if ! install_ai "$dir" > "$RUN_DIR/build-ai.log" 2>&1; then
      echo " ✗ ai can't be installed, see $RUN_DIR/build-ai.log (the rest works without it)"
      return 1
    fi
    touch "$dir/.venv/.installed"
  fi
  cd "$dir" || return 1
  setsid nohup .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port $port > "$RUN_DIR/ai.log" 2>&1 < /dev/null &
  echo $! > "$RUN_DIR/ai.pid"
  cd - > /dev/null || true
  echo " → ai starting (:$port), downloads its model the first time"
}

start_one() { # name, folder, port
  if [[ $1 == ai ]]; then start_ai; else start_java "$@"; fi
}

stop_one() { # name, port, folder
  local pid
  pid=$(cat "$RUN_DIR/$1.pid" 2>/dev/null) && kill "$pid" 2>/dev/null && echo " stopped $1"
  rm -f "$RUN_DIR/$1.pid"
  # No pid file, or a stale one (the codespace restarted): find the process by its jar folder or its port.
  if up "$2" && { pkill -f "/$3/target/" || pkill -f "uvicorn app.main:app .*--port $2"; } 2>/dev/null; then
    echo " stopped $1"
  fi
  for _ in {1..30}; do up "$2" || return 0; sleep 1; done
  return 1
}

find_service() { # name or folder → "name folder port"
  local entry
  for entry in "${SERVICES[@]}" "$AI"; do
    set -- $entry
    if [[ ${1,,} == "${target,,}" || ${2,,} == "${target,,}" ]]; then echo "$entry"; return 0; fi
  done
  echo "Unknown service '$target'. Names: $(for e in "${SERVICES[@]}" "$AI"; do printf '%s ' ${e%% *}; done)" >&2
  return 1
}

make_gateway_public() {
  [[ -n ${CODESPACE_NAME:-} ]] || return 0
  for _ in {1..6}; do
    if gh codespace ports visibility 8085:public -c "$CODESPACE_NAME" > /dev/null 2>&1; then
      echo "Port 8085 is public: the app can use $(public_url)"
      return 0
    fi
    sleep 5
  done
  echo "Make port 8085 public so the phone can reach it: PORTS tab → right-click 8085 → Port Visibility → Public"
}

cmd_status() {
  local entry state
  for entry in "${SERVICES[@]}" "$AI"; do
    set -- $entry
    if up "$3"; then state="✓ up"
    elif running "$1"; then state="… starting"
    else state="✗ down (catchopp logs $1)"; fi
    printf ' %-13s :%-5s %s\n' "$1" "$3" "$state"
  done
  if [[ -n ${CODESPACE_NAME:-} ]]; then
    echo
    echo "App: flutter run --dart-define=API_BASE_URL=$(public_url)"
  fi
}

cmd_start() {
  local entry
  echo "CatchOPP backend (logs in $RUN_DIR)"
  wait_port 3306 120 || { echo " ✗ MariaDB isn't answering on :3306"; exit 1; }
  set -- ${SERVICES[0]}
  start_java "$@" || exit 1
  wait_port 8761 180 || { echo " ✗ Eureka didn't start, see $RUN_DIR/eureka.log"; exit 1; }
  for entry in "${SERVICES[@]:1}"; do
    set -- $entry
    start_java "$@"
    sleep 3 # one JVM at a time gets through its startup: there are only 2 cores
  done
  start_ai
  echo "Waiting for the services to answer (a few minutes the first time)…"
  for ((waited = 0; waited < 420; waited += 5)); do
    local pending=0
    for entry in "${SERVICES[@]}"; do
      set -- $entry
      if ! up "$3" && running "$1"; then pending=1; fi
    done
    ((pending)) || break
    sleep 5
  done
  cmd_status
  make_gateway_public
}

target="${2:-}"
case "${1:-}" in
  start) cmd_start ;;
  status) cmd_status ;;
  stop)
    for entry in "${SERVICES[@]}" "$AI"; do set -- $entry; stop_one "$1" "$3" "$2"; done ;;
  logs)
    entry=$(find_service) || exit 1
    set -- $entry
    tail -n 200 -f "$RUN_DIR/$1.log" ;;
  restart)
    entry=$(find_service) || exit 1
    set -- $entry
    stop_one "$1" "$3" "$2" || { echo " ✗ $1 is still running on :$3 and won't stop"; exit 1; }
    start_one "$@" || exit 1
    if wait_port "$3" 240; then echo " ✓ $1 is up"; else echo " ✗ $1 didn't start, see: catchopp logs $1"; exit 1; fi ;;
  *)
    sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac
