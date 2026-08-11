#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Modular Local Plugin Installer for AI Coding Agents
# Usage: ./install-local-plugin.sh [GIT_URL] [AGENT_HARNESS]
# Example: ./install-local-plugin.sh https://github.com/obra/superpowers.git agy
# ==============================================================================

PLUGIN_REPO_URL="${1:-https://github.com/obra/superpowers.git}"
AGENT_HARNESS="${2:-agy}"

# Determine root directory of the current git workspace
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "=== Installing Local Plugin ==="
echo "Project Root : ${PROJECT_ROOT}"
echo "Plugin URL   : ${PLUGIN_REPO_URL}"
echo "Agent Harness: ${AGENT_HARNESS}"
echo "==============================="

# Extract plugin name from git URL (e.g., superpowers.git -> superpowers)
REPO_NAME="$(basename "${PLUGIN_REPO_URL}")"
PLUGIN_NAME="${REPO_NAME%.git}"

# ------------------------------------------------------------------------------
# Installer Function for AGY (Google Antigravity / Gemini CLI)
# ------------------------------------------------------------------------------
install_agy_local() {
    local plugin_dir="${PROJECT_ROOT}/.agents/plugins/${PLUGIN_NAME}"
    local skills_dir="${PROJECT_ROOT}/.agents/skills"

    echo "[agy] Setting up local workspace plugin: ${PLUGIN_NAME}"

    mkdir -p "${PROJECT_ROOT}/.agents/plugins"
    mkdir -p "${skills_dir}"

    if [ -d "${plugin_dir}" ]; then
        echo "[agy] Plugin directory already exists at ${plugin_dir}. Updating repository..."
        (cd "${plugin_dir}" && git pull --quiet) || true
    else
        echo "[agy] Cloning ${PLUGIN_REPO_URL} into ${plugin_dir}..."
        git clone --depth 1 "${PLUGIN_REPO_URL}" "${plugin_dir}"
    fi

    # Symlink individual skills into .agents/skills/ for workspace-scoped discovery
    if [ -d "${plugin_dir}/skills" ]; then
        echo "[agy] Linking workspace skills into ${skills_dir}..."
        for skill_path in "${plugin_dir}/skills/"*; do
            if [ -d "${skill_path}" ]; then
                local skill_name
                skill_name="$(basename "${skill_path}")"
                local target_link="${skills_dir}/${skill_name}"

                rm -rf "${target_link}"
                ln -sf "../plugins/${PLUGIN_NAME}/skills/${skill_name}" "${target_link}"
                echo "  -> Linked skill: ${skill_name}"
            fi
        done
    fi

    echo "[agy] Successfully installed ${PLUGIN_NAME} locally to project!"
}

# ------------------------------------------------------------------------------
# Modular Dispatcher
# ------------------------------------------------------------------------------
case "${AGENT_HARNESS}" in
    agy|antigravity|gemini)
        install_agy_local
        ;;
    # Placeholder cases for adding future agent runners:
    # claude)
    #     install_claude_local
    #     ;;
    # cursor)
    #     install_cursor_local
    #     ;;
    *)
        echo "Error: Unsupported or unconfigured agent harness '${AGENT_HARNESS}'."
        echo "Supported harnesses: agy (antigravity / gemini)"
        exit 1
        ;;
esac

echo ""
echo "Done! '${PLUGIN_NAME}' is configured locally under .agents/"
