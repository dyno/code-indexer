# ------------------------------------------------------------------------------
FROM ubuntu:focal AS app

## Bootstrap ##

RUN apt-get update && apt-get dist-upgrade --assume-yes
# https://docs.docker.com/engine/admin/multi-service_container/
RUN DEBIAN_FRONTEND=noninteractive apt-get install \
        --no-install-recommends --assume-yes       \
      cron                                         \
      curl                                         \
      diffutils                                    \
      git                                          \
      golang-go                                    \
      jq                                           \
      jsonnet                                      \
      make                                         \
      nginx                                        \
      openssl                                      \
      pkg-config                                   \
      procps                                       \
      python3                                      \
      python3-pip                                  \
      python3-setuptools                           \
      supervisor                                   \
      tomcat9                                      \
      universal-ctags                              \
      vim
RUN apt-get autoremove

ENV BIN_DIR=/opt/bin
ENV PATH=${BIN_DIR}:${PATH}

RUN mkdir -p ${BIN_DIR}

## Hound ##

ENV GOPATH=/go
# Install /go/bin/houndd, https://github.com/hound-search/hound#using-go-tools
RUN go get github.com/hound-search/hound/cmds/...
RUN cp /go/bin/houndd ${BIN_DIR}

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
