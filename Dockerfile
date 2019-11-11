# ------------------------------------------------------------------------------
# ## Stage 1 ##

FROM ubuntu:bionic AS builder

RUN apt-get update && apt-get dist-upgrade --assume-yes
RUN apt-get install --no-install-recommends --assume-yes \
      autoconf                                           \
      automake                                           \
      build-essential                                    \
      ca-certificates                                    \
      curl                                               \
      diffutils                                          \
      git                                                \
      golang-go                                          \
      libtool                                            \
      openssl                                            \
      pkg-config

WORKDIR /tmp

## ctags ##
RUN git clone https://github.com/universal-ctags/ctags.git
RUN	cd ctags && ./autogen.sh && ./configure && make

## Hound ##
ENV GOPATH=/go
# Install /go/bin/houndd, https://github.com/hound-search/hound#using-go-tools
RUN go get github.com/hound-search/hound/cmds/...

## jsonnet ##
# XXX: we do have the alternative sjsonnet.jar
RUN	git clone https://github.com/google/jsonnet.git
RUN	make -C jsonnet

# ------------------------------------------------------------------------------
# ## Stage 2 ##

FROM ubuntu:bionic AS app

## Bootstrap ##

RUN apt-get update && apt-get dist-upgrade --assume-yes
# https://docs.docker.com/engine/admin/multi-service_container/
RUN apt-get install --no-install-recommends --assume-yes \
      cron                                               \
      curl                                               \
      diffutils                                          \
      git                                                \
      jq                                                 \
      make                                               \
      libtcnative-1                                      \
      nginx                                              \
      procps                                             \
      python3                                            \
      python3-pip                                        \
      python3-setuptools                                 \
      supervisor                                         \
      tomcat9                                            \
      vim
RUN apt-get autoremove

ENV BIN_DIR=/opt/bin
ENV PATH=${BIN_DIR}:${PATH}

RUN mkdir -p ${BIN_DIR}
COPY --from=builder /tmp/ctags/ctags ${BIN_DIR}
COPY --from=builder /go/bin/houndd ${BIN_DIR}
COPY --from=builder /tmp/jsonnet/jsonnet ${BIN_DIR}
RUN curl -L https://github.com/databricks/sjsonnet/releases/download/0.1.6/sjsonnet.jar \
      -o ${BIN_DIR}/sjsonnet.jar
RUN chmod +x ${BIN_DIR}/sjsonnet.jar


## OpenGrok ##

ARG OPENGROK_RELEASE
RUN curl -L https://github.com/OpenGrok/OpenGrok/releases/download/${OPENGROK_RELEASE}/opengrok-${OPENGROK_RELEASE}.tar.gz \
      -o /tmp/opengrok-${OPENGROK_RELEASE}.tar.gz
RUN mkdir -p /opengrok && tar zxvf /tmp/opengrok-${OPENGROK_RELEASE}.tar.gz --strip-components=1 -C /opengrok
# https://github.com/oracle/opengrok/tree/master/opengrok-tools#installation-on-the-target-system
RUN pip3 install /opengrok/tools/opengrok-tools.tar.gz


##

ADD scripts /scripts
WORKDIR /tmp


## Nginx ##

EXPOSE 8129


CMD ["make", "-C", "/scripts", "start-services"]
