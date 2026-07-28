#!/usr/bin/env bash
# 统一启动脚本：兼容 5 个 docker-compose 配置，并加载 .env + .env.local
# 兼容 macOS 自带 Bash 3.2
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# 展示顺序（菜单用）
STACK_ORDER="nginx prod full postgres full.postgres"

usage() {
  cat <<'EOF'
用法:
  ./dc.sh <command> [stack] [额外 docker compose 参数...]

命令:
  up [-d]       启动（默认 -d）
  down          停止并移除容器
  restart       重启
  ps            查看状态
  logs [-f]     查看日志（默认 -f）
  pull          拉取镜像
  config        校验并打印合并后的配置
  list          列出可用 stack
  help          显示帮助

Stack 别名:
  nginx | default              -> docker-compose.yml
  prod                         -> docker-compose.prod.yml
  full                         -> docker-compose.full.yml
  postgres | pg                -> docker-compose.postgres.yml
  full.postgres | full-pg      -> docker-compose.full.postgres.yml

示例:
  ./dc.sh up full.postgres
  ./dc.sh down prod
  ./dc.sh logs postgres
  ./dc.sh restart full-pg api
  ./dc.sh                        # 交互菜单
EOF
}

stack_desc() {
  case "$1" in
    nginx) echo "仅 Nginx（反代宿主机端口）" ;;
    prod) echo "Mongo + API + Vue/Nuxt（无 PHP）" ;;
    full) echo "Mongo + MySQL + PHP 全栈" ;;
    postgres) echo "Postgres + API + Vue/Nuxt（无 PHP）" ;;
    full.postgres) echo "Postgres + MySQL + PHP 全栈" ;;
    *) echo "" ;;
  esac
}

resolve_compose_file() {
  local stack="${1:-}"
  local file=""

  if [ -z "$stack" ]; then
    echo "错误: 请指定 stack" >&2
    list_stacks >&2
    exit 1
  fi

  case "$stack" in
    nginx|default) file="docker-compose.yml" ;;
    prod) file="docker-compose.prod.yml" ;;
    full) file="docker-compose.full.yml" ;;
    postgres|pg) file="docker-compose.postgres.yml" ;;
    full.postgres|full-pg|full_postgres) file="docker-compose.full.postgres.yml" ;;
    *)
      if [ -f "$stack" ]; then
        file="$stack"
      elif [ -f "docker-compose.${stack}.yml" ]; then
        file="docker-compose.${stack}.yml"
      elif [ -f "docker-compose.${stack}" ]; then
        file="docker-compose.${stack}"
      else
        echo "错误: 未知 stack「${stack}」" >&2
        list_stacks >&2
        exit 1
      fi
      ;;
  esac

  if [ ! -f "$file" ]; then
    echo "错误: compose 文件不存在: ${file}" >&2
    exit 1
  fi

  echo "$file"
}

is_known_stack() {
  case "$1" in
    nginx|default|prod|full|postgres|pg|full.postgres|full-pg|full_postgres) return 0 ;;
    *) return 1 ;;
  esac
}

list_stacks() {
  echo "可用 stack:"
  local key file
  for key in $STACK_ORDER; do
    file="$(resolve_compose_file "$key")"
    printf "  %-14s  %-36s  %s\n" "$key" "$file" "$(stack_desc "$key")"
  done
}

run_compose() {
  local file="$1"
  shift
  local env_args=()

  if [ -f .env ]; then
    env_args+=(--env-file .env)
  fi
  if [ -f .env.local ]; then
    env_args+=(--env-file .env.local)
  fi

  echo "==> docker compose ${env_args[*]} -f ${file} $*"
  docker compose "${env_args[@]}" -f "$file" "$@"
}

pick_stack_interactive() {
  echo
  echo "请选择要操作的 stack:"
  local i=1
  local key
  for key in $STACK_ORDER; do
    printf "  %d) %-14s  %s\n" "$i" "$key" "$(stack_desc "$key")"
    i=$((i + 1))
  done
  echo "  q) 退出"
  echo

  local choice
  local total
  total=$(echo "$STACK_ORDER" | wc -w | tr -d ' ')
  read -r -p "输入序号 [1]: " choice || true
  choice="${choice:-1}"

  if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
    exit 0
  fi
  case "$choice" in
    ''|*[!0-9]*)
      echo "无效选择: ${choice}" >&2
      exit 1
      ;;
  esac
  if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
    echo "无效选择: ${choice}" >&2
    exit 1
  fi

  set -- $STACK_ORDER
  eval "echo \${$choice}"
}

pick_command_interactive() {
  echo
  echo "请选择操作:"
  echo "  1) up        启动（后台）"
  echo "  2) down      停止"
  echo "  3) restart   重启"
  echo "  4) ps        状态"
  echo "  5) logs      日志"
  echo "  6) pull      拉取镜像"
  echo "  q) 退出"
  echo

  local choice
  read -r -p "输入序号 [1]: " choice || true
  choice="${choice:-1}"
  case "$choice" in
    1) echo up ;;
    2) echo down ;;
    3) echo restart ;;
    4) echo ps ;;
    5) echo logs ;;
    6) echo pull ;;
    q|Q) exit 0 ;;
    *)
      echo "无效选择: ${choice}" >&2
      exit 1
      ;;
  esac
}

main() {
  local cmd="${1:-}"
  local stack=""
  local file=""

  if [ "$#" -gt 0 ]; then
    shift
  fi

  if [ -z "$cmd" ]; then
    stack="$(pick_stack_interactive)"
    cmd="$(pick_command_interactive)"
  else
    case "$cmd" in
      help|-h|--help)
        usage
        exit 0
        ;;
      list|ls)
        list_stacks
        exit 0
        ;;
      up|down|restart|ps|logs|pull|config)
        stack="${1:-}"
        if [ -n "$stack" ]; then
          shift
        else
          stack="$(pick_stack_interactive)"
        fi
        ;;
      *)
        # 允许 ./dc.sh full.postgres up 这种写法
        if is_known_stack "$cmd" || [ -f "$cmd" ] || [ -f "docker-compose.${cmd}.yml" ]; then
          stack="$cmd"
          cmd="${1:-up}"
          if [ "$#" -gt 0 ]; then
            shift
          fi
        else
          echo "错误: 未知命令「${cmd}」" >&2
          usage >&2
          exit 1
        fi
        ;;
    esac
  fi

  file="$(resolve_compose_file "$stack")"

  case "$cmd" in
    up)
      if [ "$#" -eq 0 ]; then
        run_compose "$file" up -d
      else
        run_compose "$file" up "$@"
      fi
      ;;
    down)
      run_compose "$file" down "$@"
      ;;
    restart)
      run_compose "$file" restart "$@"
      ;;
    ps)
      run_compose "$file" ps "$@"
      ;;
    logs)
      if [ "$#" -eq 0 ]; then
        run_compose "$file" logs -f --tail=200
      else
        run_compose "$file" logs -f --tail=200 "$@"
      fi
      ;;
    pull)
      run_compose "$file" pull "$@"
      ;;
    config)
      run_compose "$file" config "$@"
      ;;
    *)
      echo "错误: 未知命令「${cmd}」" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
