IMAGE   := faangbait/workspaces-base
TAG     := latest
DOCKERFILE := .devcontainer/Dockerfile
CONTEXT := .devcontainer

.PHONY: build push all

build:
	buildah build --isolation chroot -f $(DOCKERFILE) -t $(IMAGE):$(TAG) $(CONTEXT)

push: build
	buildah push $(IMAGE):$(TAG)

all: push
