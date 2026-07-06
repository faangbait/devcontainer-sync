# Devcontainer Sync

An Ansible role for generating consistent `.devcontainer` directories across multiple projects.

## Requirements

- Ansible Core
- ShellCheck (used by `make test`)
- Projects stored beneath one workspace root
- Run commands from this repository so `ansible.cfg`, `inventory.yml`, and the local role are loaded

`group_vars/all.yml` contains the local project inventory and is intentionally ignored by Git. Use `group_vars/all.example.yml` as the tracked example.

## Configuration

Each entry requires a unique `name`:

```yaml
devcontainers:
  - name: api
    primary_language: python

  - name: nested-site
    path: monorepo/sites/nested
    primary_language: python
    plugins:
      - django
```

`name` identifies the configuration and its source directory under `files/`. The target project root is `path` when provided, otherwise `name`.

Both values must be relative paths beneath `workspace_root`; absolute paths and `..` traversal are rejected.

### Plugins

`primary_language` does two things when matching entries exist:

1. Selects a default image from `devcontainer_primary_language_images`.
2. Selects the plugin with the same name from `devcontainer_plugins`.

`plugins` adds more plugin fragments. The role defaults currently select `codex` and `claude` for every container.

```yaml
- name: infrastructure
  primary_language: terraform
  plugins:
    - aws
    - python
```

Use `primary_language: python` with `plugins: [django]` for Django projects. Django is a concern layered onto Python, not an image language.

### Baseline Editor Support

Every generated container includes these baseline extensions:

- `EditorConfig.EditorConfig`
- `redhat.vscode-yaml`
- `timonwong.shellcheck`
- `usernamehw.errorlens`
- `github.vscode-github-actions`

The role also writes a conservative `.editorconfig` at each project root. It standardizes UTF-8, LF endings, final newlines, and trailing whitespace without imposing indentation or a formatter. Prettier is intentionally not installed or enabled globally; formatter ownership remains language- and project-specific.

### Persistent Caches

Caches are opt-in plugins. Shared download caches persist across projects, while build output and shell history use project-scoped volume names.

| Plugin | Persistent data |
| --- | --- |
| `cache_cargo` | Cargo registry, Git checkouts, and project `target/` |
| `cache_node` | npm cache and pnpm store |
| `cache_python` | pip and uv caches |
| `cache_terraform` | Terraform provider plugin cache |
| `cache_ansible` | Ansible Galaxy collections |
| `shell_history` | Project-specific Bash history via `HISTFILE` |

Example:

```yaml
- name: api
  primary_language: python
  plugins:
    - cache_python
    - cache_ansible
    - shell_history
```

Cache plugins create and assign ownership of their mounted directories during `postCreateCommand`, before `install.sh` runs.

### AWS SSO

Selecting the `aws` plugin requires:

```yaml
devcontainer_aws_sso:
  start_url: https://example.awsapps.com/start/#
  account_id: "123456789012"
  role_name: AdministratorAccess
  session_name: example-sso  # optional; default: default-sso
  region: us-east-1          # optional; default: us-east-1
```

The role generates `.devcontainer/aws_configure.sh` and always runs it from `install.sh`. The script writes the AWS SSO profile and installs an interactive Bash wrapper for `aws`.

The wrapper does not log in at shell startup. On an authenticated AWS command, it checks the current identity, runs `aws sso login` only when credentials are unavailable or expired, then runs the requested command. Explicit `aws sso login`, configuration, help, and version commands bypass the check.

This hook applies to interactive Bash shells. Noninteractive automation should establish credentials explicitly rather than relying on an interactive SSO prompt.

### Supported Values

Mapping values are recursively merged:

- `container_env`
- `remote_env`
- `features`
- `vscode_settings`

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

Scalar values such as `image`, `name`, `path`, `python_version`, and `update_remote_user_uid` are replaced by the container entry.

The effective merge order is:

1. `devcontainer_defaults`
2. The `primary_language` plugin, when one exists
3. Default plugins
4. Explicit plugins
5. The individual devcontainer entry

Unknown plugins and incorrectly typed values fail with an assertion before files are rendered.

### Lifecycle And Installation

Lifecycle lists are joined with `&&`, so execution stops on the first failure. Empty lifecycle commands are omitted from `devcontainer.json`.

Dependency installation belongs in `install_steps`, which runs from `postCreateCommand`. Keep `postAttachCommand` fast and reserve `post_start_commands` for lightweight, idempotent work needed after every container start.

The role always appends this to `postCreateCommand`:

```bash
bash "${containerWorkspaceFolder}/.devcontainer/install.sh"
```

`install.sh` derives and exports `containerWorkspaceFolder`, contains merged `install_steps`, and runs with `set -euo pipefail`. Generated shell scripts are checked by ShellCheck during `make test`. Do not repeat language-plugin setup in individual entries unless the project needs additional behavior.

`devcontainer.json` is serialized directly by the task; there is no pass-through JSON template. Static `.editorconfig` content is copied from the role files directory.

## Usage

The default workspace root is `~/dev/`. Override it with an environment variable:

```bash
export WORKSPACE_ROOT=/path/to/projects
```

Preview changes:

```bash
make check
```

Apply changes:

```bash
make apply
```

Missing targets are skipped by default. Create them with:

```bash
make create-missing
```

Run syntax validation:

```bash
make syntax
```

Lint generated shell scripts:

```bash
make shellcheck
```

Render `group_vars/all.example.yml` into `tests/`:

```bash
make test
```

## Backups

When `devcontainer_sync_backup_existing_dir` is enabled, a changed role-managed `.devcontainer` file causes the existing `.devcontainer` directory to move to `.devcontainer-bak-<timestamp>` before rendering. Role-managed files are:

- `devcontainer.json`
- `install.sh`
- `aws_configure.sh` when the AWS plugin is selected

Changes only to `.editorconfig` or files from `files/` do not trigger a whole-directory backup. `.editorconfig` and extra files use Ansible's individual file backup behavior when `devcontainer_sync_backup` is enabled.

Use `make rm-bak WORKSPACE_ROOT=/path/to/projects` to remove timestamped directory backups.

## Extra Project Files

Place additional files under `files/<name>/`. The source key is always the devcontainer `name`; `path` only changes the destination project root.

```text
files/
└── nested-site/
    ├── id_rsa
    └── scripts/
        └── setup.sh
```

With the earlier `nested-site` example, these become:

```text
monorepo/sites/nested/.devcontainer/id_rsa
monorepo/sites/nested/.devcontainer/scripts/setup.sh
```

Role-managed files cannot be overridden through `files/`. Extra-file copy output uses `no_log` so secrets are not printed in Ansible diffs.

## Contributing

Run these before committing:

```bash
make syntax
make test
```

Commit generated fixture changes under `tests/` when behavior changes.
