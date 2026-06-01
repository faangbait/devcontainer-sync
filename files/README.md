# Project-specific .devcontainer files

Put files here when a project needs additional files inside its `.devcontainer`
directory.

The directory name mirrors the project path from `group_vars/all.yml`, excluding
`.devcontainer/devcontainer.json`.

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

`devcontainer.json` and `install.sh` stay template-managed and are ignored from
the extra files tree.
