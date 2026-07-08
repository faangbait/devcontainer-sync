# VS Code launch.json Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `.vscode/launch.json` render pipeline to `devcontainer-sync`, merged the same way as every other list field, and populate it for `python`, `django`, and `rust`.

**Architecture:** New `vscode_launch_configurations` list field, merged `devcontainer_defaults → plugin(s) → per-container` with `list_merge='append_rp'` (same as `vscode_extensions`). Rendered as its own `.vscode/launch.json` file (outside `.devcontainer/`, since the Dev Container spec's `customizations.vscode` has no `launch` key), built inline via `set_fact` + `to_nice_json`, same pattern as `devcontainer.json` itself. Per-file backup (`devcontainer_sync_backup`), not the whole-directory `.devcontainer-bak-*` move.

**Tech Stack:** Ansible (`ansible.builtin.*` modules, Jinja2), no new dependencies.

## Global Constraints

- This repo's list-merge is append-only (`list_merge='append_rp'`) — no per-container override-by-name exists. Do not add any launch config whose content depends on an unverifiable per-project assumption (e.g. guessing a Cargo binary name) — see design doc `docs/superpowers/specs/2026-07-08-vscode-launch-json-standardization-design.md`.
- No new template file — build JSON content inline via `set_fact`, matching the existing `devcontainer.json` pattern in `roles/devcontainer_sync/tasks/sync_devcontainer.yml`.
- Verification for every task in this plan is: `make syntax`, and where a task changes rendered output, `make test` (regenerates `tests/` fixtures + `tests/golden_output`) followed by `make shellcheck`.
- TypeScript and Terraform get no launch config content this pass (see design doc). Do not add plugin content for them.

---

### Task 1: Add `vscode_launch_configurations` field, validation, and render pipeline

**Files:**
- Modify: `roles/devcontainer_sync/defaults/main.yml:37` (add empty default)
- Modify: `roles/devcontainer_sync/tasks/sync_devcontainer.yml:79-111` (validation assert)
- Modify: `roles/devcontainer_sync/tasks/sync_devcontainer.yml:146-260` (new set_fact + render tasks)

**Interfaces:**
- Consumes: existing `devcontainer` merged fact (already built by "Merge devcontainer values" task at `sync_devcontainer.yml:70-77`); existing `devcontainer_sync_should_render` fact (`sync_devcontainer.yml:202-204`); existing `devcontainer_sync_target_root` fact.
- Produces: `devcontainer.vscode_launch_configurations` (list of mappings, may be empty) available to every later task/plugin; `devcontainer_vscode_launch_json` fact (dict with `version`/`configurations` keys, only set when the list is non-empty) consumed by Task 1's own render step and by nothing else.

- [ ] **Step 1: Add the empty default field**

In `roles/devcontainer_sync/defaults/main.yml`, in the `devcontainer_defaults:` block, add the new field next to `vscode_settings`:

```yaml
  vscode_settings: {}
  vscode_launch_configurations: []
  mounts: []
```

(Insert the new line between the existing `vscode_settings: {}` and `mounts: []` lines.)

- [ ] **Step 2: Add validation to the merged-values assert**

In `roles/devcontainer_sync/tasks/sync_devcontainer.yml`, find the "Validate merged devcontainer values" task (`ansible.builtin.assert`). Add these three lines directly after the existing `vscode_extensions` checks and before the `mounts` checks:

```yaml
      - devcontainer.vscode_extensions is sequence
      - devcontainer.vscode_extensions is not string
      - devcontainer.vscode_extensions | select('string') | list | length == devcontainer.vscode_extensions | length
      - devcontainer.vscode_launch_configurations is sequence
      - devcontainer.vscode_launch_configurations is not string
      - devcontainer.vscode_launch_configurations | select('mapping') | list | length == devcontainer.vscode_launch_configurations | length
      - devcontainer.mounts is sequence
```

- [ ] **Step 3: Add the JSON-content set_fact**

In the same file, immediately after the "Build devcontainer.json content" task (ends around what is currently line 195, right before "Check target devcontainer file"), add:

```yaml
- name: Build vscode launch.json content
  ansible.builtin.set_fact:
    devcontainer_vscode_launch_json: >-
      {{
        {
          'version': '0.2.0',
          'configurations': devcontainer.vscode_launch_configurations,
        }
      }}
  when: devcontainer.vscode_launch_configurations | length > 0
```

- [ ] **Step 4: Add the render tasks**

In the same file, immediately after the "Render .editorconfig" task, add:

```yaml
- name: Ensure .vscode directory exists
  ansible.builtin.file:
    path: "{{ [workspace_root, devcontainer_sync_target_root, '.vscode'] | path_join }}"
    state: directory
    mode: "0755"
  when:
    - devcontainer_sync_should_render
    - devcontainer.vscode_launch_configurations | length > 0

- name: Render .vscode/launch.json
  ansible.builtin.copy:
    content: "{{ devcontainer_vscode_launch_json | to_nice_json(indent=4) }}\n"
    dest: "{{ [workspace_root, devcontainer_sync_target_root, '.vscode/launch.json'] | path_join }}"
    mode: "0644"
    backup: "{{ devcontainer_sync_backup }}"
  when:
    - devcontainer_sync_should_render
    - devcontainer.vscode_launch_configurations | length > 0
```

- [ ] **Step 5: Verify syntax**

Run: `make syntax`
Expected: `playbook: playbook.yml` with no errors.

- [ ] **Step 6: Verify no behavior change yet**

Run: `make test`
Expected: exits 0; `git diff tests/` shows **no changes** (no plugin populates `vscode_launch_configurations` yet, so the list is still empty everywhere and no `.vscode/launch.json` files are created).

Run: `git status --short tests/`
Expected: empty output.

- [ ] **Step 7: Commit**

```bash
git add roles/devcontainer_sync/defaults/main.yml roles/devcontainer_sync/tasks/sync_devcontainer.yml
git commit -m "feat: add vscode_launch_configurations merge field and .vscode/launch.json render pipeline"
```

---

### Task 2: Populate Python and Django launch configs

**Files:**
- Modify: `roles/devcontainer_sync/defaults/main.yml` (`devcontainer_plugins.python` and `devcontainer_plugins.django` blocks)

**Interfaces:**
- Consumes: `vscode_launch_configurations` field from Task 1.
- Produces: nothing new consumed by later tasks — this is leaf plugin content.

- [ ] **Step 1: Add Python configs**

In `roles/devcontainer_sync/defaults/main.yml`, in the `python:` plugin block, add `vscode_launch_configurations` after the existing `vscode_settings:` block (i.e. as a new top-level key of the `python:` plugin, at the same indentation as `vscode_extensions:` and `vscode_settings:`):

```yaml
    vscode_launch_configurations:
      - name: "Python Debugger: Current File"
        type: debugpy
        request: launch
        program: "${file}"
        console: integratedTerminal
      - name: "Python Debugger: Attach"
        type: debugpy
        request: attach
        connect:
          host: localhost
          port: 5678
```

- [ ] **Step 2: Add Django config**

In the same file, in the `django:` plugin block, add `vscode_launch_configurations` after the existing `vscode_settings:` block:

```yaml
    vscode_launch_configurations:
      - name: "Python Debugger: Django"
        type: debugpy
        request: launch
        program: "${workspaceFolder}/manage.py"
        args:
          - runserver
        django: true
```

- [ ] **Step 3: Verify syntax**

Run: `make syntax`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add roles/devcontainer_sync/defaults/main.yml
git commit -m "feat: add Python and Django vscode launch configurations"
```

(Fixture regeneration and verification happens in Task 4, after `group_vars/all.example.yml` is updated to exercise the `django` plugin.)

---

### Task 3: Populate Rust launch config

**Files:**
- Modify: `roles/devcontainer_sync/defaults/main.yml` (`devcontainer_plugins.rust` block)

**Interfaces:**
- Consumes: `vscode_launch_configurations` field from Task 1.
- Produces: nothing new consumed by later tasks.

- [ ] **Step 1: Add the CodeLLDB extension and Attach config**

In `roles/devcontainer_sync/defaults/main.yml`, the `rust:` plugin block currently looks like:

```yaml
  rust:
    install_steps:
      - sudo apt install -y python-is-python3
      - cargo install --locked cargo-nextest
    vscode_settings:
      rust-analyzer.runnables.test.overrideCommand:
        - cargo
        - nextest
        - run
        - --package
        - ${package}
        - --release
        - --
        - ${test_name}
        - ${exact}
        - --nocapture
        - --include-ignored
```

Change it to add `vscode_extensions` and `vscode_launch_configurations`:

```yaml
  rust:
    install_steps:
      - sudo apt install -y python-is-python3
      - cargo install --locked cargo-nextest
    vscode_extensions:
      - vadimcn.vscode-lldb
    vscode_settings:
      rust-analyzer.runnables.test.overrideCommand:
        - cargo
        - nextest
        - run
        - --package
        - ${package}
        - --release
        - --
        - ${test_name}
        - ${exact}
        - --nocapture
        - --include-ignored
    vscode_launch_configurations:
      - name: "Attach"
        type: lldb
        request: attach
        pid: "${command:pickProcess}"
```

- [ ] **Step 2: Verify syntax**

Run: `make syntax`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add roles/devcontainer_sync/defaults/main.yml
git commit -m "feat: add Rust vscode launch configuration (CodeLLDB attach)"
```

---

### Task 4: Update fixtures and regenerate golden output

**Files:**
- Modify: `group_vars/all.example.yml` (`python-example` entry)
- Regenerate (via `make test`, not hand-edited): `tests/python-example/`, `tests/rust-example/`, `tests/golden_output`

**Interfaces:**
- Consumes: all plugin content from Tasks 1-3.
- Produces: nothing consumed by later tasks — this is the verification checkpoint for the whole plan.

- [ ] **Step 1: Add the django plugin to python-example**

In `group_vars/all.example.yml`, the `python-example` entry currently reads:

```yaml
  - name: python-example
    image: mcr.microsoft.com/devcontainers/python:3.10
    primary_language: python
    python_version: "3.10"
    plugins:
      - aws
      - cache_python
      - cache_ansible
      - shell_history
    install_steps:
      - sudo apt update
      - sudo apt install -y --no-install-recommends ansible
```

Add `django` to its `plugins` list:

```yaml
  - name: python-example
    image: mcr.microsoft.com/devcontainers/python:3.10
    primary_language: python
    python_version: "3.10"
    plugins:
      - aws
      - django
      - cache_python
      - cache_ansible
      - shell_history
    install_steps:
      - sudo apt update
      - sudo apt install -y --no-install-recommends ansible
```

- [ ] **Step 2: Regenerate fixtures**

Run: `make test`
Expected: exits 0. This runs `ansible-playbook` against `group_vars/all.example.yml` with `devcontainer_sync_create_missing=true`, then rewrites `tests/golden_output`, then runs `make shellcheck`.

- [ ] **Step 3: Inspect the new Python fixture**

Run: `cat tests/python-example/.vscode/launch.json`
Expected JSON (key order from `to_nice_json` alphabetizes dict keys, list order is preserved):

```json
{
    "configurations": [
        {
            "console": "integratedTerminal",
            "name": "Python Debugger: Current File",
            "program": "${file}",
            "request": "launch",
            "type": "debugpy"
        },
        {
            "connect": {
                "host": "localhost",
                "port": 5678
            },
            "name": "Python Debugger: Attach",
            "request": "attach",
            "type": "debugpy"
        },
        {
            "args": [
                "runserver"
            ],
            "django": true,
            "name": "Python Debugger: Django",
            "program": "${workspaceFolder}/manage.py",
            "request": "launch",
            "type": "debugpy"
        }
    ],
    "version": "0.2.0"
}
```

If the file doesn't match, re-check Task 2's indentation (the `vscode_launch_configurations` keys must be siblings of `vscode_extensions`/`vscode_settings` inside the `python:`/`django:` plugin blocks, not nested inside `vscode_settings`).

- [ ] **Step 4: Inspect the new Rust fixture**

Run: `cat tests/rust-example/.vscode/launch.json`
Expected:

```json
{
    "configurations": [
        {
            "name": "Attach",
            "pid": "${command:pickProcess}",
            "request": "attach",
            "type": "lldb"
        }
    ],
    "version": "0.2.0"
}
```

Run: `grep vadimcn tests/rust-example/.devcontainer/devcontainer.json`
Expected: one line containing `"vadimcn.vscode-lldb"` inside the `extensions` array.

- [ ] **Step 5: Confirm untouched fixtures are still untouched**

Run: `cat tests/cloud-example/.vscode/launch.json 2>&1`
Expected: `cat: tests/cloud-example/.vscode/launch.json: No such file or directory` (terraform gets no launch config, so no `.vscode` directory is created for it).

Run: `cat tests/node-example/.vscode/launch.json 2>&1`
Expected: same "No such file or directory" (typescript gets no launch config).

- [ ] **Step 6: Review the full diff**

Run: `git status --short tests/ group_vars/all.example.yml`
Expected: modified `tests/golden_output`, modified `group_vars/all.example.yml`, new `tests/python-example/.vscode/launch.json`, new `tests/rust-example/.vscode/launch.json`. `tests/cloud-example/` and `tests/node-example/` should show no `.vscode` changes.

- [ ] **Step 7: Commit**

```bash
git add group_vars/all.example.yml tests/
git commit -m "test: exercise django plugin in python-example fixture, regenerate golden output"
```

---

### Task 5: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: nothing.

- [ ] **Step 1: Add the new field to README's "Supported Values" list**

In `README.md`, find this block:

```markdown
List values are merged with Ansible's `append_rp` behavior, preserving order while replacing duplicates:

- `plugins`
- `vscode_extensions`
- `mounts`
- `run_args`
- `post_start_commands`
- `post_create_commands`
- `post_attach_commands`
- `initialize_commands`
- `install_steps`
```

Add `vscode_launch_configurations` after `vscode_extensions`:

```markdown
List values are merged with Ansible's `append_rp` behavior, preserving order while replacing duplicates:

- `plugins`
- `vscode_extensions`
- `vscode_launch_configurations`
- `mounts`
- `run_args`
- `post_start_commands`
- `post_create_commands`
- `post_attach_commands`
- `initialize_commands`
- `install_steps`
```

Directly below that list, add a callout about the append-only limitation (this explains, in the docs, why `rust`'s toolkit is Attach-only and why `typescript`/`terraform` are empty):

```markdown
List merges are append-only — there is no override-by-name. A plugin default that turns out wrong for a specific project can't be replaced per-container, only appended alongside. Keep plugin-level list defaults (especially `vscode_launch_configurations`) free of per-project assumptions (binary names, entry files, package names) for this reason.
```

- [ ] **Step 2: Document the `.vscode/launch.json` file**

In `README.md`, find the "Backups" section:

```markdown
## Backups

When `devcontainer_sync_backup_existing_dir` is enabled, a changed role-managed `.devcontainer` file causes the existing `.devcontainer` directory to move to `.devcontainer-bak-<timestamp>` before rendering. Role-managed files are:

- `devcontainer.json`
- `install.sh`
- `aws_configure.sh` when the AWS plugin is selected

Changes only to `.editorconfig` or files from `files/` do not trigger a whole-directory backup. `.editorconfig` and extra files use Ansible's individual file backup behavior when `devcontainer_sync_backup` is enabled.
```

Change the last paragraph to mention `.vscode/launch.json`:

```markdown
Changes only to `.editorconfig`, `.vscode/launch.json`, or files from `files/` do not trigger a whole-directory backup. `.editorconfig`, `.vscode/launch.json`, and extra files use Ansible's individual file backup behavior when `devcontainer_sync_backup` is enabled. `.vscode/launch.json` is only rendered when the merged `vscode_launch_configurations` list is non-empty for that container.
```

- [ ] **Step 3: Add an AGENTS.md query section**

In `AGENTS.md`, immediately after the existing "Query: add/change mounts" section (before "Query: add an install step"), add:

```markdown
---

## Query: "add/change VS Code debug launch configurations"

| Scope | Path |
|---|---|
| All containers | `defaults/main.yml → devcontainer_defaults.vscode_launch_configurations` |
| All python containers | `defaults/main.yml → devcontainer_plugins.python.vscode_launch_configurations` |
| One container | `group_vars/all.yml → devcontainers[name=X].vscode_launch_configurations` |

Renders to `<container_root>/.vscode/launch.json` (outside `.devcontainer/` — the Dev Container spec's `customizations.vscode` has no `launch` key). Only written when the merged list is non-empty. List merges are append-only (no override-by-name) — do not add plugin-level defaults that depend on per-project assumptions (binary names, entry files). See `roles/devcontainer_sync/defaults/main.yml → devcontainer_plugins.python` / `.django` / `.rust` for examples.
```

- [ ] **Step 4: Commit**

```bash
git add README.md AGENTS.md
git commit -m "docs: document vscode_launch_configurations and the append-only merge constraint"
```

---

### Task 6: Final full-suite verification

**Files:** none (verification only)

**Interfaces:** none

- [ ] **Step 1: Run full syntax check**

Run: `make syntax`
Expected: no errors.

- [ ] **Step 2: Run full test suite one more time to confirm idempotence**

Run: `make test`
Expected: exits 0; `git status --short` shows no changes (fixtures already match from Task 4).

- [ ] **Step 3: Run shellcheck**

Run: `make shellcheck`
Expected: no errors (already ran as part of `make test`, this confirms it independently).

- [ ] **Step 4: Confirm working tree is clean**

Run: `git status --short`
Expected: empty output (everything already committed in Tasks 1-5).
