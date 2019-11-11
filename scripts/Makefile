SHELL = /bin/bash


# https://stackoverflow.com/questions/5873025/heredoc-in-a-makefile
define OPENGROK_INDEX_SCRIPT
#!/bin/bash

supervisorctl -c $(SCRIPTS)/supervisord.ini start opengrok_index
endef
export OPENGROK_INDEX_SCRIPT

BIN_DIR := /opt/bin
SCRIPTS := /scripts

.DEFAULT_GOAL := generate_config

bootstrap: makedirs opengrok-deploy generate_config
start-services: bootstrap opengrok-index
	/usr/bin/supervisord -c $(SCRIPTS)/supervisord.ini

generate_config: jsonnet opengrok-crontab
.PHONY: jsonnet
jsonnet:
	# XXX: https://github.com/databricks/sjsonnet/issues/46
	command -v jsonnet && jsonnet_cmd=jsonnet || jsonnet_cmd=$(BIN_DIR)/sjsonnet.jar; \
	  $${jsonnet_cmd} -S --multi . repositories.jsonnet
	ln -sf $(SCRIPTS)/hound_config.json /tmp/hound_config.json

pandoc:
	pandoc --from markdown --to html -o README.html README.md

clean:
	rm -rf repositories.json hound_config.json

# target only available inside container
ifneq ($(wildcard /opengrok/lib/opengrok.jar),)

.PHONY: makedirs
makedirs:
	@# hound
	mkdir -p /tmp/hound_data
	@# opengrok
	@# https://github.com/oracle/opengrok/blob/master/opengrok-web/src/main/webapp/WEB-INF/web.xml
	mkdir -p /tmp/opengrok_data
	mkdir -p /src
	mkdir -p /var/opengrok/etc
	[[ -d /var/opengrok/data ]] || ln -sf /tmp/opengrok_data /var/opengrok/data
	[[ -d /var/opengrok/src ]] || ln -sf /src /var/opengrok/
	@# tomcat9
	mkdir -p /tmp/tomcat9_temp
	[[ -e /var/lib/tomcat9/temp ]] || ln -sf /tmp/tomcat9_temp /var/lib/tomcat9/temp

opengrok-deploy:
	opengrok-deploy /opengrok/lib/source.war /var/lib/tomcat9/webapps

opengrok-crontab:
	# schedule the indexing hourly
	echo "$${OPENGROK_INDEX_SCRIPT}" >/etc/cron.hourly/opengrok-index
	chmod +x /etc/cron.hourly/opengrok-index

opengrok-index:
	cd /tmp && $(SCRIPTS)/opengrok-index.sh

status:
	supervisorctl -c $(SCRIPTS)/supervisord.ini status

start-%:
	if ! supervisorctl -c $(SCRIPTS)/supervisord.ini status $* | grep -q RUNNING; then \
	  supervisorctl -c $(SCRIPTS)/supervisord.ini restart $* ; \
	fi

restart-%:
	supervisorctl -c $(SCRIPTS)/supervisord.ini restart $*
endif
