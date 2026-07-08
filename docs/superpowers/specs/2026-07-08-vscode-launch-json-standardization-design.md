# VS Code `launch.json` Standardization — Design

## Problem

`devcontainer-sync` renders `.devcontainer/devcontainer.json` (extensions, settings, MCP) but has no way to standardize VS Code debug configurations (`launch.json`) across containers. Goal: add a `.vscode/launch.json` render pipeline, following the existing merge/render conventions in this repo, starting with Python (+ Django), then Rust. TypeScript and Terraform are explicitly out of scope for this pass (see Non-Goals).

## Constraints discovered during research

- The Dev Container spec's `customizations.vscode` only supports `settings` / `extensions` / `mcp` — no `launch` key. `launch.json` must be its own file at `<container_root>/.vscode/launch.json`, not embedded in `devcontainer.json`.
- This repo's merge model (`ansible.builtin.combine(..., list_merge='append_rp')`) is **append-only** for all list-typed fields (`vscode_extensions`, `mounts`, `install_steps`, etc.) — there is no override-by-name. A per-container config can only *add* list entries, never replace or remove one contributed by a plugin default. Any default we ship is therefore effectively permanent for every container using that plugin, re-asserted on every sync run (with backup) — a wrong assumption can't be locally patched and will keep reverting.
- `.vscode/launch.json` lives outside `.devcontainer/`, so it does **not** interact with `devcontainer_sync_managed_files` (which only governs collisions with the `files/<name>/` extra-file mechanism inside `.devcontainer/`). It follows the same backup tier as `.editorconfig`: per-file `backup:` on write, not the whole-directory `.devcontainer-bak-*` move.

## Design

### New merged field: `vscode_launch_configurations`

A list of dicts, defaulting to `[]`, merged with `list_merge='append_rp'` at the same three tiers as every other list field: `devcontainer_defaults` → plugin(s) → per-container `devcontainer_config`. Validated as a sequence of mappings, same pattern as the existing `is sequence` / `is not string` / element-type asserts for `vscode_extensions` and friends.

### Render pipeline

1. `Build vscode launch.json content` — `set_fact` builds `{'version': '0.2.0', 'configurations': devcontainer.vscode_launch_configurations}`, only when the merged list is non-empty (mirrors how `vscode_settings` is conditionally merged into `customizations.vscode`).
2. `Ensure .vscode directory exists` — same pattern as `Ensure .devcontainer directory exists`.
3. `Render .vscode/launch.json` — `ansible.builtin.copy` with `content: ... | to_nice_json(indent=4)`, `backup: "{{ devcontainer_sync_backup }}"`, gated on `devcontainer_sync_should_render` and a non-empty configurations list.

No new Jinja template file — matches how `devcontainer.json` itself is built inline via `set_fact`, not a `.j2` template.

### Per-language content (this pass)

| Plugin | Content | Rationale |
|---|---|---|
| `python` | `Python Debugger: Current File` (debugpy, launch, `${file}`, integratedTerminal) + `Python Debugger: Attach` (debugpy, attach, `localhost:5678`) | Matches VS Code's own auto-generated starter configs exactly (see debugpy docs). No project-specific assumptions. |
| `django` | `Python Debugger: Django` (debugpy, launch, `${workspaceFolder}/manage.py`, `args: [runserver]`, `django: true`) | Matches the Python extension's own auto-generated Django config. Assumes `manage.py` is at the container's workspace root — true for every current `django`-plugin container. |
| `rust` | `Attach` (`lldb` / CodeLLDB, `pid: "${command:pickProcess}"`) + `vadimcn.vscode-lldb` extension | CodeLLDB's own interactive process picker — no binary-path guess. A static "Debug" launch entry would need to assume the Cargo binary name equals the folder name, which cannot be safely overridden per-container under this repo's append-only merge model (see Constraints) — explicitly rejected. |
| `typescript` | none | No universal default: "Launch Current File" only works for plain `.js` or projects with a TS loader (ts-node/tsx) already registered — not guaranteed across containers, and (per the append-only constraint above) a wrong guess can't be patched per-container. Deliberately skipped rather than shipping a best-effort default. |
| `terraform` | none | Terraform has no VS Code debug adapter — it's declarative, nothing to step through. Not a gap to fill later; there's no standard content to add. |

`justMyCode` is omitted from the Python configs (its default is already `true`). `console: integratedTerminal` is kept explicit on Current File to match VS Code's own generated default.

## Non-Goals

- `tasks.json`, compound launch configs, `serverReadyAction` — not requested.
- TypeScript and Terraform debug configs — see table above.
- Per-container override-by-name for list fields — out of scope architecture change; not needed for this pass.

## Testing

No unit-test framework exists for this Ansible role. Verification is the existing golden-fixture flow:

```bash
make syntax       # ansible-playbook --syntax-check
make test         # renders group_vars/all.example.yml into tests/, refreshes tests/golden_output
make shellcheck   # lints generated *.sh
```

`python-example` in `group_vars/all.example.yml` gains the `django` plugin so `make test` exercises Current File + Attach + Django in one fixture. `rust-example` already exercises the `rust` plugin, so its regenerated fixture exercises the new Attach config and `vadimcn.vscode-lldb` extension automatically.
