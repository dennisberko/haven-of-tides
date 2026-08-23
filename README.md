# Haven of Tides

A 2D pirate-haven action and life RPG made with Godot 4.

The current playable scope is [Phase 01: Walking](docs/phases/01-walking.md).

## Run the game

Requirements:

- Godot 4.x
- Node.js 20 or newer for the Godot MCP Runtime
- Codex with this project marked as trusted

Run from the project root:

```sh
godot --path .
```

Use WASD or the arrow keys to walk through the cove.

## Test with Codex and Godot MCP Runtime

The project-level MCP configuration is in `.codex/config.toml`. Restart Codex after the first checkout so it can load the `godot` MCP server.

In a new Codex task, ask:

> Use the Godot MCP Runtime to inspect this project, run it, take a screenshot, move the player, confirm that the position changed, read the game errors, and stop the project.

The MCP server is started with `npx -y godot-mcp-runtime`. It injects its runtime bridge only during a test and removes it when the game stops.

## Local validation

```sh
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
```
