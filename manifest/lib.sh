#!/usr/bin/env bash
# Shared manifest parsing helpers — sourced by Dockerfiles and bare-metal scripts.

# manifest_field <section> <field> <file>
manifest_field() {
    local section="$1" field="$2" file="$3"
    awk -v s="[$section]" -v f="$field" \
        '$0==s{found=1;next} /^\[/{found=0} found && $0~"^"f"[[:space:]]*="{sub(/^[^=]*=[[:space:]]*/,""); print; exit}' \
        "$file"
}

# manifest_require <section> <field> <file>
# Like manifest_field but errors if value is empty or missing.
manifest_require() {
    local section="$1" field="$2" file="$3"
    local val
    val=$(manifest_field "$section" "$field" "$file")
    if [[ -z "$val" ]]; then
        echo "ERROR: [$section] $field not set in $file" >&2
        exit 1
    fi
    echo "$val"
}

# manifest_config <key> <file>
# Read a simple key=value from a flat config file. Errors if missing.
manifest_config() {
    local key="$1" file="$2"
    local val
    val=$(grep "^${key}=" "$file" | cut -d= -f2)
    if [[ -z "$val" ]]; then
        echo "ERROR: '$key' not set in $file" >&2
        exit 1
    fi
    echo "$val"
}

# manifest_sections <file>
manifest_sections() {
    awk '/^\[/{gsub(/[\[\]]/,""); print}' "$1"
}
