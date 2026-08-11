# My Agent Setup

A modular local plugin and skill manager for AI coding agents (Antigravity / Gemini CLI / AGY).

Easily install, manage, and uninstall project-scoped plugins locally without cluttering your global configuration.

---

## 🚀 Quick Start

### 1. One-Line Interactive Install (via `curl`)

Run the interactive manager directly in any project folder:

```bash
curl -fsSL https://raw.githubusercontent.com/Showwaiyan/my-agent-setup/main/install-local-plugin.sh | bash
```

### 2. Direct Plugin Install

Install a specific plugin directly into your current project:

```bash
curl -fsSL https://raw.githubusercontent.com/Showwaiyan/my-agent-setup/main/install-local-plugin.sh | bash -s -- https://github.com/Egonex-AI/Understand-Anything.git
```

---

## 🖥️ Local Usage

If you clone or download `install-local-plugin.sh` into a project:

```bash
# Open interactive plugin menu
./install-local-plugin.sh

# Install specific plugin repository
./install-local-plugin.sh https://github.com/obra/superpowers.git

# List plugins installed in the current project
./install-local-plugin.sh --list

# Uninstall a plugin from the current project
./install-local-plugin.sh --uninstall Understand-Anything
```

---

## 📦 Pre-configured Plugin Catalog

The installer comes pre-configured with popular agent plugins and supports custom repositories:

| Plugin Name | Repository | Description |
| :--- | :--- | :--- |
| **Superpowers** | `https://github.com/obra/superpowers.git` | Brainstorming, execution planning, and systematic agent workflows |
| **Understand-Anything** | `https://github.com/Egonex-AI/Understand-Anything.git` | Codebase knowledge graph, interactive dashboard, and domain analysis |
| **visual-explainer** | `https://github.com/nicobailon/visual-explainer.git` | Interactive HTML diagrams, architecture visuals, and diff reviews in browser |
| **Custom Repository** | *Any Git URL* | Automatically discovers and symlinks any repository containing `SKILL.md` |

---

## ⚙️ How It Works

When run inside any project repository:

1. **Local Isolation**: Clones the plugin source repository into `.agents/plugins/<PluginName>`.
2. **Skill Discovery**: Automatically scans for all `SKILL.md` skill definitions—whether located in the root `skills/` directory or deeply nested subfolders.
3. **Workspace Symlinking**: Symlinks each discovered skill into `.agents/skills/<SkillName>` relative to the workspace root.
4. **Git Hygiene**: Keeps plugins local to the project. (Recommended: add `.agents/` to your target project's `.gitignore`).

---

## 📝 License

MIT
