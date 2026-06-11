# Project-Specific `.devcontainer` Files

Place files here when a project needs additional content in its generated `.devcontainer` directory.

The source directory is `files/<devcontainer.name>/`. The destination is `<workspace_root>/<path-or-name>/.devcontainer/`.

```yaml
- name: nested-site
  path: monorepo/sites/nested
```

```text
files/nested-site/id_rsa
files/nested-site/scripts/setup.sh
```

renders to:

```text
monorepo/sites/nested/.devcontainer/id_rsa
monorepo/sites/nested/.devcontainer/scripts/setup.sh
```

The project-root `.editorconfig` is role-managed separately. `devcontainer.json` and `install.sh` are always role-managed. `aws_configure.sh` is also role-managed when the AWS plugin is selected. Extra-file copy tasks use `no_log` so file contents are not exposed in Ansible output.
