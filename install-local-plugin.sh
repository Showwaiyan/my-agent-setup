#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Modular Local Plugin Manager & Installer for AI Coding Agents
# Usage:
#   ./install-local-plugin.sh                       (Interactive Menu)
#   ./install-local-plugin.sh [GIT_URL] [HARNESS]  (Direct Install)
#   ./install-local-plugin.sh --list                (List Installed Plugins)
#   ./install-local-plugin.sh --uninstall [NAME]    (Uninstall Plugin)
#
# Curl-pipe usage:
#   curl -fsSL https://raw.githubusercontent.com/.../install-local-plugin.sh | bash
# ==============================================================================

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Registry of known plugins (Name | Repository URL | Description)
KNOWN_PLUGINS=(
    "Superpowers|https://github.com/obra/superpowers.git|Brainstorming, execution planning, and systematic agent workflows"
    "Understand-Anything|https://github.com/Egonex-AI/Understand-Anything.git|Codebase knowledge graph, interactive dashboard, and domain analysis"
    "visual-explainer|https://github.com/nicobailon/visual-explainer.git|Interactive HTML diagrams, architecture visuals, and diff reviews in browser"
)

# Helper function to read user input across standard terminal and curl-pipe environments
prompt_read() {
    local prompt_text="$1"
    local input_val=""

    if [ -t 0 ]; then
        read -r -p "${prompt_text}" input_val
    elif [ -e /dev/tty ]; then
        printf "%s" "${prompt_text}" >/dev/tty
        read -r input_val </dev/tty
    else
        echo "Error: Non-interactive environment and no arguments provided." >&2
        exit 1
    fi
    echo "${input_val}"
}

# ------------------------------------------------------------------------------
# Core Plugin Installer (AGY Harness)
# ------------------------------------------------------------------------------
install_plugin_agy() {
    local plugin_url="$1"
    local repo_name
    repo_name="$(basename "${plugin_url}")"
    local plugin_name="${repo_name%.git}"

    local plugin_dir="${PROJECT_ROOT}/.agents/plugins/${plugin_name}"
    local skills_dir="${PROJECT_ROOT}/.agents/skills"

    echo ""
    echo "=== Installing Local Plugin ==="
    echo "Project Root : ${PROJECT_ROOT}"
    echo "Plugin Name  : ${plugin_name}"
    echo "Plugin URL   : ${plugin_url}"
    echo "==============================="

    mkdir -p "${PROJECT_ROOT}/.agents/plugins"
    mkdir -p "${skills_dir}"

    if [ -d "${plugin_dir}" ]; then
        echo "[agy] Plugin directory already exists at ${plugin_dir}. Updating repository..."
        (cd "${plugin_dir}" && git pull --quiet) || true
    else
        echo "[agy] Cloning ${plugin_url} into ${plugin_dir}..."
        git clone --depth 1 "${plugin_url}" "${plugin_dir}"
    fi

    echo "[agy] Linking workspace skills into ${skills_dir}..."
    local found_skills=0
    while IFS= read -r skill_path; do
        [ -z "${skill_path}" ] && continue
        local skill_name
        skill_name="$(basename "${skill_path}")"
        local rel_path="../plugins/${plugin_name}/${skill_path#"${plugin_dir}/"}"
        local target_link="${skills_dir}/${skill_name}"

        rm -rf "${target_link}"
        ln -sf "${rel_path}" "${target_link}"
        echo "  -> Linked skill: ${skill_name}"
        found_skills=$((found_skills + 1))
    done < <(find "${plugin_dir}" -type f -name "SKILL.md" -exec dirname {} \;)

    if [ "${found_skills}" -eq 0 ]; then
        echo "  (No SKILL.md files found in ${plugin_dir})"
    fi

    echo ""
    echo "[agy] Successfully installed '${plugin_name}' locally (${found_skills} skills active)."
}

# ------------------------------------------------------------------------------
# List Installed Plugins
# ------------------------------------------------------------------------------
list_installed_plugins() {
    local plugins_dir="${PROJECT_ROOT}/.agents/plugins"
    local skills_dir="${PROJECT_ROOT}/.agents/skills"

    echo ""
    echo "=== Installed Local Plugins ==="
    if [ ! -d "${plugins_dir}" ] || [ -z "$(ls -A "${plugins_dir}" 2>/dev/null)" ]; then
        echo "No local plugins installed in '${PROJECT_ROOT}'."
        echo "==============================="
        return 0
    fi

    for plugin_path in "${plugins_dir}"/*; do
        [ -d "${plugin_path}" ] || continue
        local plugin_name
        plugin_name="$(basename "${plugin_path}")"

        local skill_count=0
        if [ -d "${skills_dir}" ]; then
            for symlink in "${skills_dir}"/*; do
                if [ -L "${symlink}" ]; then
                    local target
                    target="$(readlink "${symlink}")"
                    if [[ "${target}" == *"plugins/${plugin_name}/"* ]]; then
                        skill_count=$((skill_count + 1))
                    fi
                fi
            done
        fi
        echo "  - ${plugin_name} (${skill_count} skills active)"
    done
    echo "==============================="
}

# ------------------------------------------------------------------------------
# Uninstall Plugin
# ------------------------------------------------------------------------------
uninstall_plugin() {
    local plugin_name="$1"
    local plugin_dir="${PROJECT_ROOT}/.agents/plugins/${plugin_name}"
    local skills_dir="${PROJECT_ROOT}/.agents/skills"

    if [ ! -d "${plugin_dir}" ]; then
        echo "Error: Plugin '${plugin_name}' is not installed in this project."
        return 1
    fi

    echo ""
    echo "Removing local plugin '${plugin_name}'..."
    if [ -d "${skills_dir}" ]; then
        for symlink in "${skills_dir}"/*; do
            if [ -L "${symlink}" ]; then
                local target
                target="$(readlink "${symlink}")"
                if [[ "${target}" == *"plugins/${plugin_name}/"* ]]; then
                    rm -f "${symlink}"
                    echo "  -> Unlinked skill: $(basename "${symlink}")"
                fi
            fi
        done
    fi

    rm -rf "${plugin_dir}"
    echo "Successfully uninstalled '${plugin_name}' from project."
}

# ------------------------------------------------------------------------------
# Interactive Menu
# ------------------------------------------------------------------------------
interactive_menu() {
    while true; do
        echo ""
        echo "=========================================================="
        echo "        Local Plugin Manager for AI Coding Agents         "
        echo "=========================================================="
        echo "Project Root: ${PROJECT_ROOT}"
        echo ""
        echo "Select a plugin to install/update:"
        local idx=1
        for item in "${KNOWN_PLUGINS[@]}"; do
            IFS='|' read -r name url desc <<< "${item}"
            local status=""
            if [ -d "${PROJECT_ROOT}/.agents/plugins/${name}" ]; then
                status=" [INSTALLED]"
            fi
            echo "  ${idx}) ${name}${status}"
            echo "     ${desc}"
            idx=$((idx + 1))
        done
        echo "  ${idx}) Custom Git Repository..."
        local custom_idx="${idx}"

        echo ""
        echo "Management Options:"
        local list_idx=$((custom_idx + 1))
        local remove_idx=$((custom_idx + 2))
        echo "  ${list_idx}) List installed plugins"
        echo "  ${remove_idx}) Uninstall a plugin"
        echo "  0) Exit"
        echo "=========================================================="
        local choice
        choice="$(prompt_read "Enter choice [0-${remove_idx}]: ")"

        if [ "${choice}" = "0" ] || [ "${choice}" = "q" ]; then
            echo "Exiting."
            break
        elif [ "${choice}" -ge 1 ] && [ "${choice}" -lt "${custom_idx}" ] 2>/dev/null; then
            local selected="${KNOWN_PLUGINS[$((choice - 1))]}"
            IFS='|' read -r name url desc <<< "${selected}"
            install_plugin_agy "${url}"
        elif [ "${choice}" -eq "${custom_idx}" ] 2>/dev/null; then
            local custom_url
            custom_url="$(prompt_read "Enter Git repository URL: ")"
            if [ -n "${custom_url}" ]; then
                install_plugin_agy "${custom_url}"
            else
                echo "No URL provided."
            fi
        elif [ "${choice}" -eq "${list_idx}" ] 2>/dev/null; then
            list_installed_plugins
        elif [ "${choice}" -eq "${remove_idx}" ] 2>/dev/null; then
            local installed=()
            local pdir="${PROJECT_ROOT}/.agents/plugins"
            if [ -d "${pdir}" ]; then
                for p in "${pdir}"/*; do
                    [ -d "${p}" ] && installed+=("$(basename "${p}")")
                done
            fi
            if [ ${#installed[@]} -eq 0 ]; then
                echo "No plugins currently installed."
            else
                echo ""
                echo "Select plugin to uninstall:"
                for i in "${!installed[@]}"; do
                    echo "  $((i + 1))) ${installed[$i]}"
                done
                local pchoice
                pchoice="$(prompt_read "Select plugin [1-${#installed[@]}]: ")"
                if [ "${pchoice}" -ge 1 ] && [ "${pchoice}" -le "${#installed[@]}" ] 2>/dev/null; then
                    uninstall_plugin "${installed[$((pchoice - 1))]}"
                else
                    echo "Invalid selection."
                fi
            fi
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

# ------------------------------------------------------------------------------
# Main Dispatcher
# ------------------------------------------------------------------------------
ARG1="${1:-}"
ARG2="${2:-}"

chmod +x "$0" 2>/dev/null || true

case "${ARG1}" in
    "")
        interactive_menu
        ;;
    --list|-l)
        list_installed_plugins
        ;;
    --uninstall|-u)
        if [ -n "${ARG2}" ]; then
            uninstall_plugin "${ARG2}"
        else
            echo "Error: Please specify the plugin name to uninstall."
            echo "Usage: ./install-local-plugin.sh --uninstall <PLUGIN_NAME>"
            exit 1
        fi
        ;;
    http://*|https://*|git@*)
        install_plugin_agy "${ARG1}"
        ;;
    *)
        echo "Error: Unknown argument '${ARG1}'"
        echo "Usage:"
        echo "  ./install-local-plugin.sh                       (Interactive menu)"
        echo "  ./install-local-plugin.sh [GIT_URL]             (Direct install)"
        echo "  ./install-local-plugin.sh --list                (List installed plugins)"
        echo "  ./install-local-plugin.sh --uninstall [NAME]    (Uninstall plugin)"
        exit 1
        ;;
esac
