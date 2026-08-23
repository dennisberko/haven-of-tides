# Haven of Tides project instructions

- Use Godot 4.x and GDScript.
- Keep each change in the scope of the active phase in `docs/phases/`.
- Start with Phase 01 unless the user selects a different phase.
- Use the Godot MCP Runtime after each gameplay change.
- First, call `get_project_info` and validate the changed scripts.
- Then, run the project, read errors, take a screenshot, and simulate the input that the change needs.
- Stop the project after the test.
- Do not mark a phase as complete without runtime test evidence.
- Keep generated MCP files in `.mcp/`. Do not commit them.
- Git pushes to the configured `origin` remote (`git@github.com:dennisberko/haven-of-tides.git`) are always approved.
