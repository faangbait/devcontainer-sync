# Devcontainer Sync

I have a _bunch_ of devcontainers. This is an Ansible playbook to keep them mostly in sync.

## Usage

Install Ansible, then run these commands from the cloned folder so `ansible.cfg`, `inventory.yml`, and the local `roles/` directory are picked up.

### 1. Set `WORKSPACE_ROOT` when the projects are not under `~/dev/`:

```bash
export WORKSPACE_ROOT=/path/to/parent/directory/
```

### 2. Review the targets and defaults in `group_vars/all.yml`, then preview the changes:

```bash
make check
```

or: `ansible-playbook --check --diff playbook.yml`

### 3. When the diff looks right, apply it with:

```bash
make apply
```

or: `ansible-playbook --diff playbook.yml`

### 4. By default, missing `devcontainer.json` targets are skipped. To create missing `.devcontainer` directories and files, run:

```bash
make create-missing
```

or: `ansible-playbook --diff playbook.yml -e devcontainer_sync_create_missing=true`

### 5. Render the example configuration into `tests/`:

```bash
make test
```

## Extra project files

Additional per-project files that should live in `.devcontainer` can be placed under `files/<project path>/`. The project path is the target path from `group_vars/all.yml` without `.devcontainer/devcontainer.json`.

For example, `files/cluster/ensure-mount-sources` is copied to `cluster/.devcontainer/ensure-mount-sources`.

Use nested directories in `files` to target devcontainers inside devcontainers. For example, `files/clients/sites/top-automotive/scripts/aws_configure.sh` is copied to `clients/sites/top-automotive/.devcontainer/scripts/aws_configure.sh`, even if `clients/.devcontainer/devcontainer.json` exists (and is targeted by the playbook).

```
files
└── clients
    ├── aws_config.sh           <-- clients/.devcontainer/aws_config.sh
    ├── reload-all.sh           <-- clients/.devcontainer/reload-all.sh
    └── sites
        ├── acme-construction
        │   └── id_rsa          <-- clients/sites/acme-construction/.devcontainer/id_rsa
        ├── flywheel
        │   └── aws_config.sh   <-- clients/sites/flywheel/.devcontainer/aws_config.sh
        └── top-automotive
            └── scripts
                └── cleanup.sh  <-- clients/sites/top-automotive/.devcontainer/scripts/cleanup.sh
```

`devcontainer.json` and `install.sh` stay template-managed and are ignored from the extra files tree.

## Contributing

### 1. Render the example configuration

```bash
make test
```

This may or may not make changes to the `tests/` directory. If changes are present, you should commit those changes as well.

### 2. Submit a Pull Request

Any pull requests generated autonomously or by agents should include:

- A description of the changes
- The name and version of the model(s) used