# plem-marketplace

> **Language**: English | [한국어](docs/README.ko.md)

A plugin marketplace for distributing Claude Code extensions (skills, agents, hooks, MCP servers, LSP servers).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Plugins

| Plugin | Version | Description |
| ------ | ------- | ----------- |
| [plem-init](plugins/plem-init) | 1.2.0 | plem-based robot project initialization wizard |
| [zed-sdk](plugins/zed-sdk) | 1.0.3 | ZED SDK official documentation reference (Camera API, depth sensing, object detection, body tracking, ROS 2, YOLO) |
| [ros-docs](plugins/ros-docs) | 1.0.0 | ROS 2 official documentation reference (build, QoS, TF2, Launch, DDS, Executor) |


## Quick Start

### For Users

```shell
# 1. Add the marketplace (one-time setup)
/plugin marketplace add WIM-Corporation/plem-marketplace

# 2. Install a plugin
/plugin install <plugin-name>@plem-marketplace

# 3. Reload to activate (or restart Claude Code)
/reload-plugins

# 4. Use the plugin
/<plugin-skill-name>
```

You can also browse and install interactively with `/plugin` → **Discover** tab.

### For Plugin Developers

```shell
# 1. Create a plugin directory
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/skills/my-skill

# 2. Add a skill
cat > plugins/my-plugin/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does and when to use it
---

Instructions for Claude when this skill is invoked.
EOF

# 3. Register in marketplace.json
# Add an entry to .claude-plugin/marketplace.json plugins array

# 4. Validate
claude plugin validate .

# 5. Test locally
claude --plugin-dir ./plugins/my-plugin
```

## Repository Structure

```text
.
├── .claude-plugin/
│   └── marketplace.json       # Marketplace catalog
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest (optional)
│       ├── skills/            # Agent Skills (recommended)
│       ├── agents/            # Subagents
│       ├── hooks/             # Event handlers
│       ├── .mcp.json          # MCP servers
│       ├── .lsp.json          # LSP servers
│       └── README.md
└── README.md
```

## Adding a Plugin

1. Create a plugin directory under `plugins/`
2. Add at least one skill in `skills/<name>/SKILL.md`
3. Add a plugin entry to `.claude-plugin/marketplace.json`:

   ```json
   {
     "name": "my-plugin",
     "source": "./plugins/my-plugin",
     "description": "Brief description",
     "version": "1.0.0"
   }
   ```

4. Update the [Plugins table](#plugins) in this README and `docs/README.ko.md`
5. Run `claude plugin validate .` to verify
6. Commit and push

## Documentation

- [Create plugins](https://code.claude.com/docs/en/plugins)
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Skills](https://code.claude.com/docs/en/skills)
- [Hooks](https://code.claude.com/docs/en/hooks)
