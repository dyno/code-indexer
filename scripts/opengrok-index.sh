#!/bin/bash

dlog() {
  date +"%Y-%m-%dT%H:%M:%S $1"
}

dlog "OpenGrok Indexing Begin ..."

set -o xtrace

# generated from repositories.jsonnet
REPO_CONFIG_JSON=/scripts/repositories.json
# CTAGS=${BIN_DIR}/ctags
# https://packages.ubuntu.com/focal/amd64/universal-ctags/filelist
CTAGS=/usr/bin/ctags-universal

jq -r '.[] | [.url, .branch, .name] | @tsv' ${REPO_CONFIG_JSON} | while read -r repo branch name; do
  if [ ${branch} = "master" ]; then
    repo_path=/src/${name}
  else
    repo_path=/src/${name}-${branch}
  fi
  if [ -d "${repo_path}" ]; then
    # https://stackoverflow.com/questions/9589814/how-do-i-force-git-pull-to-overwrite-everything-on-every-pull
    (cd "${repo_path}" && git fetch origin "${branch}" && git reset --hard FETCH_HEAD)
  else
    # https://stackoverflow.com/questions/41233378/cloning-specific-branch
    git clone "${repo}" -b "${branch}" "${repo_path}"
  fi
done

# log indexing progress
if [[ ! -f /var/opengrok/logging.properties ]]; then
  cp /opengrok/doc/logging.properties /var/opengrok/logging.properties
  sed -i -e 's/java.util.logging.ConsoleHandler.level = WARNING/java.util.logging.ConsoleHandler.level = INFO/' \
    /var/opengrok/logging.properties
fi

# https://github.com/oracle/opengrok/wiki/How-to-setup-OpenGrok#step3---indexing
# java -jar /opengrok/lib/opengrok.jar for options.
opt_notify_server=
if supervisorctl -c /scripts/supervisord.ini status tomcat9 | grep -q RUNNING; then
  opt_notify_server="-U http://localhost:8080/source"
fi

opengrok-indexer                                                      \
  -J=-Djava.util.logging.config.file=/var/opengrok/logging.properties \
  -a /opengrok/lib/opengrok.jar                                       \
  --                                                                  \
  -c ${CTAGS}                                                         \
  -s /var/opengrok/src                                                \
  -d /var/opengrok/data                                               \
  -P                                                                  \
  -G                                                                  \
  -W /var/opengrok/etc/configuration.xml                              \
  --analyzer .sc:ScalaAnalyzer                                        \
		--ignore 'd:.idea'                                                \
		--ignore 'd:.gradle'                                              \
		--ignore 'd:.ipynb_checkpoints'                                   \
		--ignore 'd:.metals'                                              \
		--ignore 'd:.pytest_cache'                                        \
		--ignore 'd:.venv'                                                \
		--ignore 'd:.vim'                                                 \
		--ignore 'd:__pycache__'                                          \
		--ignore 'd:opengrok'                                             \
		--ignore 'd:opengrok-tools'                                       \
		--ignore 'd:tmp'                                                  \
		--ignore 'd:target'                                               \
		--ignore 'd:zold'                                                 \
		--ignore 'f:*.ipynb'                                              \
		--ignore 'f:*.jar'                                                \
		--ignore 'f:*.class'                                              \
		--ignore 'f:*.log'                                                \
		--ignore 'f:*-output.xml'                                         \
  ${opt_notify_server}

dlog "OpenGrok Indexing End."
