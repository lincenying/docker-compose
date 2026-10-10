#!/usr/bin/env bash
# 按 stack 从华为云镜像源拉取 compose 所需镜像，并打成配置里使用的本地标签
# 兼容 macOS 自带 Bash 3.2
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MIRROR="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io"
STACK_ORDER="nginx mongo full.mongo postgres full.postgres"

usage() {
  cat <<'EOF'
用法:
  ./docker-images.sh <stack> [stack...]
  ./docker-images.sh all
  ./docker-images.sh list [stack...]

从华为云镜像源拉取对应 compose 文件中的镜像，再打成配置里使用的标签。
业务镜像 tag 读取 .env / .env.local；stack 别名与 dc.sh 一致。

Stack 别名:
  nginx | default              -> docker-compose.yml
  mongo | mg                   -> docker-compose.mongo.yml
  full.mongo | full-mg         -> docker-compose.full.mongo.yml
  postgres | pg                -> docker-compose.postgres.yml
  full.postgres | full-pg      -> docker-compose.full.postgres.yml
  all                          -> 以上全部（相同镜像只拉一次）

示例:
  ./docker-images.sh postgres
  ./docker-images.sh full-pg mongo
  ./docker-images.sh all
  ./docker-images.sh list full.mongo
EOF
}

canonical_stack() {
  case "$1" in
    nginx|default) echo nginx ;;
    mongo|mg) echo mongo ;;
    full.mongo|full-mg|full_mongo) echo full.mongo ;;
    postgres|pg) echo postgres ;;
    full.postgres|full-pg|full_postgres) echo full.postgres ;;
    *) echo "$1" ;;
  esac
}

stack_desc() {
  case "$(canonical_stack "$1")" in
    nginx) echo "仅 Nginx（反代宿主机端口）" ;;
    mongo) echo "Mongo + API + Vue/Nuxt（无 PHP）" ;;
    full.mongo) echo "Mongo + MySQL + PHP 全栈" ;;
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
    exit 1
  fi

  case "$stack" in
    nginx|default) file="docker-compose.yml" ;;
    mongo|mg) file="docker-compose.mongo.yml" ;;
    full.mongo|full-mg|full_mongo) file="docker-compose.full.mongo.yml" ;;
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
        echo "可用: ${STACK_ORDER} 或 all" >&2
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

compose_images() {
  local file="$1"

  if [ -f .env ] && [ -f .env.local ]; then
    docker compose --env-file .env --env-file .env.local -f "$file" config --images
  elif [ -f .env.local ]; then
    docker compose --env-file .env.local -f "$file" config --images
  elif [ -f .env ]; then
    docker compose --env-file .env -f "$file" config --images
  else
    docker compose -f "$file" config --images
  fi
}

# compose 里未写 tag 时，Docker 使用 latest
normalize_ref() {
  case "$1" in
    *:*) printf '%s\n' "$1" ;;
    *) printf '%s:latest\n' "$1" ;;
  esac
}

# 镜像源上的仓库:tag。浮动标签换成已验证可拉取的具体版本，再 tag 回 compose 使用的名字。
mirror_image() {
  case "$1" in
    crazymax/fail2ban:1) echo "crazymax/fail2ban:1.1.0" ;;
    mysql:8.0) echo "mysql:8.0.46" ;;
    postgres:18-alpine) echo "postgres:18.6-alpine3.24" ;;
    nginx:alpine) echo "nginx:1.31.6-alpine3.24" ;;
    nginx:latest) echo "nginx:1.31.6" ;;
    *) echo "$1" ;;
  esac
}

expand_targets() {
  local arg
  for arg in "$@"; do
    if [ "$arg" = "all" ]; then
      echo "$STACK_ORDER"
      return
    fi
  done

  local result=""
  for arg in "$@"; do
    resolve_compose_file "$arg" >/dev/null
    result="${result:+$result }$arg"
  done
  echo "$result"
}

print_stack() {
  local stack="$1"
  local file line img remote
  file="$(resolve_compose_file "$stack")"
  printf '%s  %s  %s\n' "$stack" "$file" "$(stack_desc "$stack")"

  local image_lines
  image_lines="$(compose_images "$file" | sort)" || exit 1
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    img="$(normalize_ref "$line")"
    remote="$(mirror_image "$img")"
    printf '  %-42s  %s/%s\n' "$img" "$MIRROR" "$remote"
  done <<EOF
$image_lines
EOF
}

collect_images() {
  local stack file line img acc="" image_lines
  for stack in "$@"; do
    file="$(resolve_compose_file "$stack")"
    image_lines="$(compose_images "$file")" || exit 1
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      img="$(normalize_ref "$line")"
      case " $acc " in
        *" $img "*) ;;
        *) acc="${acc:+$acc }$img" ;;
      esac
    done <<EOF
$image_lines
EOF
  done

  if [ -z "$acc" ]; then
    return
  fi
  # shellcheck disable=SC2086
  printf '%s\n' $acc | sort -u
}

pull_one() {
  local local_ref="$1"
  local remote mirror_ref
  remote="$(mirror_image "$local_ref")"
  mirror_ref="${MIRROR}/${remote}"

  echo "==> ${local_ref}"
  echo "    docker pull ${mirror_ref}"
  docker pull "$mirror_ref"
  docker tag "$mirror_ref" "$local_ref"
  docker rmi "$mirror_ref"
}

main() {
  local mode="pull"

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  case "$1" in
    help|-h|--help)
      usage
      exit 0
      ;;
    list|ls)
      mode="list"
      shift
      if [ "$#" -eq 0 ]; then
        set -- all
      fi
      ;;
  esac

  local targets
  targets="$(expand_targets "$@")"

  if [ "$mode" = "list" ]; then
    local stack
    for stack in $targets; do
      print_stack "$stack"
      echo
    done
    exit 0
  fi

  local images img count=0
  images="$(collect_images $targets)"
  if [ -z "$images" ]; then
    echo "错误: 没有解析到需要拉取的镜像" >&2
    exit 1
  fi

  while IFS= read -r img || [ -n "$img" ]; do
    [ -z "$img" ] && continue
    pull_one "$img"
    count=$((count + 1))
  done <<EOF
$images
EOF

  echo "完成，共处理 ${count} 个镜像"
}

main "$@"
