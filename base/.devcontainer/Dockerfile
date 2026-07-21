FROM registry.access.redhat.com/ubi10/ubi-minimal:latest

RUN microdnf install -y --releasever 10 --setopt=install_weak_deps=0 --nodocs \
    crypto-policies-scripts \
    shadow-utils \
    findutils \
    gdb-gdbserver \
    gzip \
    tar \
    git-core \
    && microdnf clean all
    

LABEL devcontainer.metadata='[\
  {\
    "capAdd": ["SYS_PTRACE"],\
    "securityOpt": ["seccomp=unconfined"],\
    "containerEnv": {\
      "ENV": "~/.bashrc"\
    }\
  }\
]'

LABEL maintainer="S Smith <root@madeof.glass>"

ENV container=oci
ENV LANG=C.UTF-8

ARG containerWorkspaceFolderBasename
WORKDIR /workspaces/${containerWorkspaceFolderBasename}

CMD ["/bin/bash"]
