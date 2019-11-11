SHELL = /bin/bash

APP_NAME := code-indexer
REPOSITORY := dynofu/code-indexer

VERSION_TAG := 2019.11.11
IMAGE := $(REPOSITORY):$(VERSION_TAG)
CONTAINER := $(APP_NAME)

$(info REPOSITORY=$(REPOSITORY) VERSION_TAG=$(VERSION_TAG) IMAGE=$(IMAGE) CONTAINER=$(CONTAINER))

.DEFAULT_GOAL := docker-build


# ------------------------------------------------------------------------------
# ## Build and Release ##

# https://github.com/oracle/opengrok/releases
OPENGROK_RELEASE := 1.3.3

build-opengrok:
	mkdir -p tmp
	[[ ! -e tmp/opengrok ]] && cd tmp && git clone https://github.com/oracle/opengrok.git || true
	cd tmp/opengrok; \
	  git show-ref --verify --quiet refs/heads/r$(OPENGROK_RELEASE) \
	  || git checkout $(OPENGROK_RELEASE) -b r$(OPENGROK_RELEASE) --force
	@# https://github.com/oracle/opengrok/blob/master/docker/README.md#build-image-locally
	cd tmp/opengrok && ./mvnw -DskipTests=true clean package

docker-build:
	docker build .                                     \
	  --build-arg OPENGROK_RELEASE=$(OPENGROK_RELEASE) \
	  --tag $(REPOSITORY):$(VERSION_TAG)               \
	  --tag $(REPOSITORY):latest                       \
	  # END

docker-push:
	docker push $(REPOSITORY):$(VERSION_TAG)
	docker push $(REPOSITORY):latest


# ------------------------------------------------------------------------------
# ## Test and Run ##

docker-start: docker-run
CMD :=
OPT :=
docker-run:
	docker rm $(CONTAINER) || true
	mkdir -p tmp
	mkdir -p src
	docker run --rm $(OPT) --name $(CONTAINER) \
	  -p 8129:8129                             \
	  -v $${PWD}/scripts:/scripts              \
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
