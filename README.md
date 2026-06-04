# Kantari Godot Demo

Kantari is a Godot demo project made with Fennara, a Godot-focused AI assistant and MCP workflow for agents that need real feedback from the engine while they work.

This repository is meant to show a real saved Godot project, not a web scene or a single runtime-only script. The project includes scene files, gameplay scripts, project settings, and the Fennara addon payload used during the demo workflow.

## What Is Included

- A Godot 4 project with `project.godot`
- Main playable scene: `scenes/toy_room_game.tscn`
- Gameplay scripts under `scripts/`
- Fennara Godot addon preview under `addons/fennara`
- A local Fennara agent guide in `AGENTS.md`

The demo focuses on a playful 3D toy-room style game scene with interactive objects, pickup behavior, a magical yarn ball, and scene/gameplay code generated and iterated inside Godot.

## Why This Demo Matters

Fennara is not built around a huge list of tiny editor commands.

The philosophy is:

```text
small toolset, deep Godot feedback
```

When an AI agent works through Fennara, the important part is not only that it can write files. The important part is that it can get feedback from Godot:

- GDScript diagnostics after script edits
- scene and node inspection
- changed node properties
- attached scripts and exported variables
- subresources and nested resources
- scene validation warnings
- runtime errors
- screenshots when visual feedback matters
- SemanticSearch for project understanding

That feedback loop helps the agent notice when it broke something, patch the right file, rerun, and continue.

## Fennara Links

- Website: https://www.fennara.io
- Godot MCP overview: https://www.fennara.io/godot-mcp
- Godot AI plugin overview: https://www.fennara.io/godot-ai-plugin
- Setup guide: https://www.fennara.io/docs/get-started
- MCP docs: https://www.fennara.io/docs/mcp
- Godot tools docs: https://www.fennara.io/docs/godot-plugin/tools
- Public Fennara MCP repo: https://github.com/fennaraOfficial/fennara-godot-mcp

## Opening The Project

1. Install Godot 4.6 or newer.
2. Clone this repository.
3. Open the folder in Godot.
4. Run the main scene:

```text
res://scenes/toy_room_game.tscn
```

The included Fennara addon payload is provided as a public demo snapshot. For normal Fennara setup, use the installer flow from the setup guide:

https://www.fennara.io/docs/get-started

## Repository Status

This is a demo repository for showing Fennara-built Godot work. It is not intended as a polished commercial game template.
