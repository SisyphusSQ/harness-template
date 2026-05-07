#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

extract_section_field() {
  local file="$1"
  local section="$2"
  local field="$3"

  if [[ ! -f "$file" ]]; then
    echo "missing file: $file" >&2
    return 1
  fi

  awk -v section="$section" -v field="$field" '
    $0 == section {
      in_section = 1
      next
    }

    /^## / && in_section {
      exit
    }

    in_section {
      pattern = "^[[:space:]]*-[[:space:]]*`?" field "`?:[[:space:]]*"
      if ($0 ~ pattern) {
        sub(pattern, "", $0)
        print
        exit
      }
    }
  ' "$file"
}

resolve_plan_implementation_section() {
  local file="$1"
  local candidate

  for candidate in \
    "## Architecture / Data Flow" \
    "## 0. 现有架构回顾与核心设计决策"; do
    if grep -Fqx "$candidate" "$file"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

subsection_has_meaningful_content() {
  local file="$1"
  local section="$2"
  local subsection="$3"

  if [[ ! -f "$file" ]]; then
    echo "missing file: $file" >&2
    return 1
  fi

  awk -v section="$section" -v subsection="$subsection" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }

    function is_placeholder(line) {
      return line ~ /<请替换为真实[^>]*>/ ||
        line ~ /<路径 \/ 类型>/ ||
        line ~ /<新增\/复用>/ ||
        line ~ /<任务名>/ ||
        line ~ /<todo-id>/ ||
        line ~ /\[待补充\]/ ||
        line ~ /\[请替换\]/
    }

    BEGIN {
      bullet_field = (subsection ~ /^-[[:space:]]*/)
    }

    $0 == section {
      in_section = 1
      next
    }

    /^## / && in_section {
      if (in_subsection) {
        exit
      }
      in_section = 0
    }

    in_section && !bullet_field && $0 == subsection {
      found = 1
      in_subsection = 1
      next
    }

    in_section && bullet_field {
      line = trim($0)
      if (!in_subsection && index(line, subsection) == 1) {
        found = 1
        in_subsection = 1

        rest = trim(substr(line, length(subsection) + 1))
        sub(/^[：:][[:space:]]*/, "", rest)
        if (rest != "" && !is_placeholder(rest)) {
          content = 1
        }
        next
      }
    }

    in_section && bullet_field && in_subsection && /^-[[:space:]]*`/ {
      exit
    }

    in_section && /^### / && in_subsection {
      exit
    }

    in_subsection {
      line = trim($0)

      if (line == "" || line ~ /^```/ || line ~ /^<!--/) {
        next
      }

      if (line ~ /^[-*][[:space:]]*$/ || line ~ /^[0-9]+\.[[:space:]]*$/) {
        next
      }

      if (line ~ /^\|[[:space:]]*模块\/类型[[:space:]]*\|[[:space:]]*新增\/复用/) {
        next
      }

      if (line ~ /^\|([[:space:]]*:?-+:?[[:space:]]*\|)+$/) {
        next
      }

      if (is_placeholder(line)) {
        next
      }

      content = 1
    }

    END {
      exit !(found && content)
    }
  ' "$file"
}

section_has_meaningful_content() {
  local file="$1"
  local section="$2"

  if [[ ! -f "$file" ]]; then
    echo "missing file: $file" >&2
    return 1
  fi

  awk -v section="$section" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }

    function is_placeholder(line) {
      return line ~ /<请替换为真实[^>]*>/ ||
        line ~ /<路径 \/ 类型>/ ||
        line ~ /<新增\/复用>/ ||
        line ~ /<任务名>/ ||
        line ~ /<todo-id>/ ||
        line ~ /\[待补充\]/ ||
        line ~ /\[请替换\]/
    }

    $0 == section {
      in_section = 1
      next
    }

    /^## / && in_section {
      exit
    }

    in_section {
      line = trim($0)

      if (line == "" || line ~ /^```/ || line ~ /^<!--/) {
        next
      }

      if (line == "至少锁定一个与当前关键调用链直接相关的真实接口 / 结构 / 命令 / 配置片段，不要保留占位 token。") {
        next
      }

      if (line == "至少锁定一个与当前关键调用链直接相关的真实接口 / 结构 / 命令 / 配置片段。复杂任务推荐放两段：一段锁定接口 / 结构，一段锁定规则 / 配置 / SQL / CLI。") {
        next
      }

      if (line ~ /^-[[:space:]]*`片段说明`:[[:space:]]*$/) {
        next
      }

      if (is_placeholder(line)) {
        next
      }

      content = 1
    }

    END {
      exit !content
    }
  ' "$file"
}

subsection_has_real_table_entry() {
  local file="$1"
  local section="$2"
  local subsection="$3"

  if [[ ! -f "$file" ]]; then
    echo "missing file: $file" >&2
    return 1
  fi

  awk -v section="$section" -v subsection="$subsection" '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }

    function is_placeholder(line) {
      return line ~ /<请替换为真实[^>]*>/ ||
        line ~ /<路径 \/ 类型>/ ||
        line ~ /<新增\/复用>/ ||
        line ~ /\[待补充\]/ ||
        line ~ /\[请替换\]/
    }

    $0 == section {
      in_section = 1
      next
    }

    /^## / && in_section {
      if (in_subsection) {
        exit
      }
      in_section = 0
    }

    in_section && $0 == subsection {
      in_subsection = 1
      next
    }

    in_section && /^### / && in_subsection {
      exit
    }

    in_subsection {
      line = trim($0)

      if (line ~ /^\|[[:space:]]*模块\/类型[[:space:]]*\|[[:space:]]*新增\/复用/ ||
          line ~ /^\|([[:space:]]*:?-+:?[[:space:]]*\|)+$/ ||
          line == "") {
        next
      }

      if (line ~ /^\|/ && !is_placeholder(line)) {
        found = 1
        exit
      }
    }

    END {
      exit !found
    }
  ' "$file"
}

collect_plan_implementation_skeleton_errors() {
  local file="$1"
  local implementation_section=""
  local has_error=0
  local subsection

  if ! implementation_section="$(resolve_plan_implementation_section "$file")"; then
    printf 'missing implementation section: expected %s or %s\n' \
      "## Architecture / Data Flow" \
      "## 0. 现有架构回顾与核心设计决策"
    has_error=1
  fi

  if [[ -n "$implementation_section" ]]; then
    for subsection in \
      "### 真实入口与触发" \
      "### 输入装配与边界校验" \
      "### 组件职责与代码落点" \
      "### 关键执行时序" \
      "### 停止 / 错误 / 恢复"; do
      if ! subsection_has_meaningful_content "$file" "$implementation_section" "$subsection"; then
        printf 'missing or placeholder-only subsection: %s / %s\n' "$implementation_section" "$subsection"
        has_error=1
      fi
    done

    for subsection in \
      '- `入口代码位置`' \
      '- `装配结果 / 核心对象`' \
      '- `步骤化时序`' \
      '- `关键分支 / 降级路径`'; do
      if ! subsection_has_meaningful_content "$file" "$implementation_section" "$subsection"; then
        printf 'missing or placeholder-only field: %s / %s\n' "$implementation_section" "$subsection"
        has_error=1
      fi
    done

    if ! subsection_has_real_table_entry "$file" "$implementation_section" "### 组件职责与代码落点"; then
      printf 'missing real module/path/type entry: %s / %s\n' "$implementation_section" "### 组件职责与代码落点"
      has_error=1
    fi
  fi

  if ! subsection_has_meaningful_content "$file" "## Concrete Steps" "### 实现步骤"; then
    printf 'missing or placeholder-only subsection: %s / %s\n' "## Concrete Steps" "### 实现步骤"
    has_error=1
  fi

  if ! section_has_meaningful_content "$file" "## Reference Snippets"; then
    printf 'missing or placeholder-only section: %s\n' "## Reference Snippets"
    has_error=1
  fi

  return "$has_error"
}
