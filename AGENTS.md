# AGENTS.md

Navigation guide for AI agents. Organized by the type of change being requested.

## Architecture overview

`group_vars/all.yml` — the user's configuration: a list of containers and global AWS SSO settings.
`roles/devcontainer_sync/defaults/main.yml` — role defaults: all plugin definitions, default image, and base container settings.

Ansible merges in this order (last wins): `devcontainer_defaults` → merged plugin values → per-container config from `devcontainers[*]`.

---

## Query: "add/change something for [language] containers"

`rust`, `python`, `typescript`, `terraform`, `java`, etc. are **primary languages**. A primary language is just a plugin that also sets the container image automatically.

**Global plugin config** (affects every container using that language):
```
roles/devcontainer_sync/defaults/main.yml
  devcontainer_plugins.<language>:
    install_steps: [...]
    vscode_extensions: [...]
    vscode_settings: {...}
    features: {...}
    mounts: [...]
    post_create_commands: [...]
    container_env: {...}
```

**Language → image mapping** (which base image a language container gets):
```
roles/devcontainer_sync/defaults/main.yml
  devcontainer_primary_language_images:
    rust: ...
    python: ...
    typescript: ...
    java: ...
```

**Per-container override** (affects only one container):
```
group_vars/all.yml
  devcontainers:
    - name: <container-name>
      primary_language: rust   # sets image + activates rust plugin
      install_steps: [...]     # appended to plugin's install_steps
```

---

## Query: "add/change something for all containers"

Defaults applied to every container before plugins and per-container config:
```
roles/devcontainer_sync/defaults/main.yml
  devcontainer_defaults:
    image: ...
    install_steps: [...]
    vscode_extensions: [...]
    vscode_settings: {...}
    features: {...}
    mounts: [...]
    post_create_commands: [...]
    post_start_commands: [...]
    post_attach_commands: [...]
    initialize_commands: [...]
    container_env: {...}
    remote_env: {...}
    run_args: [...]
    plugins: [...]             # plugins active on every container by default
```

---

## Query: "add a new plugin"

Add an entry to:
```
roles/devcontainer_sync/defaults/main.yml
  devcontainer_plugins:
    <plugin-name>:
      install_steps: [...]
      vscode_extensions: [...]
      ...
```

Containers opt in via:
```
group_vars/all.yml
  devcontainers:
    - name: <container-name>
      plugins:
        - <plugin-name>
```

---

## Query: "add/modify a specific container"

```
group_vars/all.yml
  devcontainers:
    - name: <container-name>       # required; also the workspace subfolder name by default
      path: <relative-path>        # optional override if workspace path differs from name
      primary_language: <lang>     # optional; sets image + activates language plugin
      image: <image>               # optional; overrides primary_language image
      plugins: [...]               # additional plugins beyond defaults
      install_steps: [...]
      vscode_extensions: [...]
      vscode_settings: {...}
      features: {...}
      mounts: [...]
      run_args: [...]
      container_env: {...}
      remote_env: {...}
      post_create_commands: [...]
      post_start_commands: [...]
      post_attach_commands: [...]
      initialize_commands: [...]
      update_remote_user_uid: true  # optional
```

---

## Query: "add/change VS Code extensions"

| Scope | Path |
|---|---|
| All containers | `defaults/main.yml → devcontainer_defaults.vscode_extensions` |
| All rust containers | `defaults/main.yml → devcontainer_plugins.rust.vscode_extensions` |
| One container | `group_vars/all.yml → devcontainers[name=X].vscode_extensions` |

---

## Query: "add/change mounts"

| Scope | Path |
|---|---|
| All containers | `defaults/main.yml → devcontainer_defaults.mounts` |
| Language/plugin | `defaults/main.yml → devcontainer_plugins.<name>.mounts` |
| One container | `group_vars/all.yml → devcontainers[name=X].mounts` |

Cache-related plugins (`cache_cargo`, `cache_node`, `cache_python`, etc.) manage their own mounts.

---

## Query: "add an install step"

| Scope | Path |
|---|---|
| All containers | `defaults/main.yml → devcontainer_defaults.install_steps` |
| Language/plugin | `defaults/main.yml → devcontainer_plugins.<name>.install_steps` |
| One container | `group_vars/all.yml → devcontainers[name=X].install_steps` |

`install_steps` are rendered into `.devcontainer/install.sh` via `templates/install.sh.j2`. Lists from defaults, plugins, and per-container config are **appended** (not replaced).

---

## Query: "add a devcontainer feature"

```
roles/devcontainer_sync/defaults/main.yml
  devcontainer_plugins.<name>:
    features:
      ghcr.io/devcontainers/features/<feature>:<version>:
        optionKey: value
```

Or per-container in `group_vars/all.yml → devcontainers[name=X].features`.

---

## File map

| File | Purpose |
|---|---|
| `group_vars/all.yml` | User config: container list, AWS SSO |
| `group_vars/all.example.yml` | Example showing all common patterns |
| `roles/devcontainer_sync/defaults/main.yml` | All plugin definitions, defaults, image map |
| `roles/devcontainer_sync/tasks/sync_devcontainer.yml` | Merge logic: how defaults + plugins + per-container combine |
| `roles/devcontainer_sync/templates/install.sh.j2` | Template for the generated install.sh |
| `roles/devcontainer_sync/templates/aws_configure.sh.j2` | Template for AWS SSO setup script |
| `files/<container-name>/` | Extra static files copied into a container's `.devcontainer/` |
