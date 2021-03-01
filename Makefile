SHELL = /bin/bash

APP_NAME := code-indexer
REPOSITORY := dynofu/code-indexer

VERSION_TAG := 2020.02.28
IMAGE := $(REPOSITORY):$(VERSION_TAG)
CONTAINER := $(APP_NAME)

$(info REPOSITORY=$(REPOSITORY) VERSION_TAG=$(VERSION_TAG) IMAGE=$(IMAGE) CONTAINER=$(CONTAINER))

.DEFAULT_GOAL := docker-build


# ------------------------------------------------------------------------------
# ## Build and Release ##

# https://github.com/oracle/opengrok/releases
OPENGROK_RELEASE := 1.5.12


docker-build:
	DOCKER_BUILDKIT=1 docker build .                   \
	  --build-arg OPENGROK_RELEASE=$(OPENGROK_RELEASE) \
	  --tag $(REPOSITORY):$(VERSION_TAG)               \
	  --tag $(REPOSITORY):latest                       \
	  # END


docker-push:
	docker push $(REPOSITORY):$(VERSION_TAG)
	docker push $(REPOSITORY):latest


# manually build opengrok, not a necessary step.
build-opengrok:
	mkdir -p tmp
	[[ -e tmp/opengrok ]] || (cd tmp && git clone https://github.com/oracle/opengrok.git)
	cd tmp/opengrok;                                                           \
	  git show-ref --verify --quiet refs/heads/r$(OPENGROK_RELEASE)            \
	  || (git fetch --tags --force                                             \
	      && git checkout $(OPENGROK_RELEASE) -b r$(OPENGROK_RELEASE) --force) \
	# END
	@# https://github.com/oracle/opengrok/blob/master/docker/README.md#build-image-locally
	cd tmp/opengrok && ./mvnw -DskipTests=true clean package


# ------------------------------------------------------------------------------
# ## Test and Run ##

docker-start: docker-run
CMD :=
OPT :=

ifneq ($(wildcard scripts/repos.jsonnet),)
  REPOS_MAPPING := -v $${PWD}/scripts/repos.jsonnet:/scripts/repositories.jsonnet
else
  REPOS_MAPPING :=
endif


docker-run:
	docker rm $(CONTAINER) || true
	mkdir -p tmp
	mkdir -p src
	docker run --rm $(OPT) --name $(CONTAINER) \
	  -p 8129:8129                             \
	  $(REPOS_MAPPING)                         \
	  -v $${PWD}/tmp:/tmp                      \
	  -v $${PWD}/src:/src                      \
	  $(IMAGE)                                 \
	  $(CMD)                                   \
	# END


docker-bash:
	$(MAKE) docker-exec CMD=/bin/bash


docker-exec:
	docker exec -it $(CONTAINER) $(CMD)


docker-stop:
	docker stop $(CONTAINER)
