# The purpose of this Makefile is to help remembering and centralize various build or management commands

# https://blog.mindlessness.life/makefile/2019/11/17/the-language-agnostic-all-purpose-incredible-makefile.html
# '- cmd' will ignore errors
# '@cmd' will not output command

help:
	@echo ''
	@echo -e 'usage: \e[1mmake <target> [registry_login=<registry_token>] [registry_token=<registry_token>]\e[0m'
	@echo '    registry_login =	provide a login name to registry. Defaults to "nologin"'
	@echo '    registry_token =	provide a registry token, needed to push images to registry'
	@echo ''
	@echo Make targets:
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m    make \1\\x1b[m:\2/' | column -c2 -t -s :)"
	@echo ''

all: help


# Two flavors of variables:
#     - recursive (use =) - only looks for the variables when the command is used, not when it’s defined.
#     - simply expanded (use :=) - like normal imperative programming – only those defined so far get expanded
#     - ?= only sets variables if they have not yet been set
#     - != can be used to execute a shell script and set a variable to its output
registry_fqdn := ghcr.io
build_date != date -u +'%Y%m%d_%H%M'
git_commit_sha_short != git rev-parse --short HEAD
SHELL := /bin/bash
OS = $(shell uname | tr '[A-Z]' '[a-z]')

ifndef registry_login
	registry_login = nologin
endif


image-build-akrobateo-0.1.1: line_red  ## build container image akrobateo 0.1.1
	docker build -t alexfouche/akrobateo:0.1.1.${build_date}.${git_commit_sha_short} -f Dockerfile .

image-build-akrobateo-lb-0.1.1: line_red  ## build container image akrobateo 0.1.1
	docker build -t alexfouche/akrobateo-lb:0.1.1.${build_date}.${git_commit_sha_short} -f lb-image/Dockerfile lb-image

image-push-akrobateo-0.1.1: line_red  ## push lastly built container image akrobateo 0.1.1 to registry
	@version=`docker image list alexfouche/akrobateo:0.1.1.* --format "{{.Tag}}" | sort -n | tail -1` ;\
	docker login "${registry_fqdn}"/alexfouche -u "${registry_login}" -p "${registry_token}" ;\
	docker tag alexfouche/akrobateo:$$version "${registry_fqdn}"/alexfouche/akrobateo:$$version ;\
	echo docker push "${registry_fqdn}"/alexfouche/akrobateo:$$version ;\
	docker push "${registry_fqdn}"/alexfouche/akrobateo:$$version

image-push-akrobateo-lb-0.1.1: line_red  ## push lastly built container image akrobateo-lb 0.1.1 to registry
	@version=`docker image list alexfouche/akrobateo-lb:0.1.1.* --format "{{.Tag}}" | sort -n | tail -1` ;\
	docker login "${registry_fqdn}"/alexfouche -u "${registry_login}" -p "${registry_token}" ;\
	docker tag alexfouche/akrobateo-lb:$$version "${registry_fqdn}"/alexfouche/akrobateo-lb:$$version ;\
	echo docker push "${registry_fqdn}"/alexfouche/akrobateo-lb:$$version ;\
	docker push "${registry_fqdn}"/alexfouche/akrobateo-lb:$$version

patch-akrobateo-deployment-0.1.1: line_red  ## patch Kubernetes deployment of app 'akrobateo' to lastly built container image akrobateo 0.1.1 version
	@version=`docker image list alexfouche/akrobateo:0.1.1.* --format "{{.Tag}}" | sort -n | tail -1` ;\
	sed -i "s%image: ${registry_fqdn}/alexfouche/akrobateo:0\.1\.1\..*%image: ${registry_fqdn}/alexfouche/akrobateo:$$version%" deploy/04_operator.yaml

patch-akrobateo-lb-deployment-0.1.1: line_red  ## patch Kubernetes deployment of app 'akrobateo-lb' to lastly built container image akrobateo-lb 0.1.1 version
	@version=`docker image list alexfouche/akrobateo-lb:0.1.1.* --format "{{.Tag}}" | sort -n | tail -1` ;\
	sed -i "s%value: ${registry_fqdn}/alexfouche/akrobateo-lb:0\.1\.1\..*%value: ${registry_fqdn}/alexfouche/akrobateo-lb:$$version%" deploy/04_operator.yaml

deploy-akrobateo: line_red  ## submit deployment of app 'akrobateo' to Kubernetes
	kubectl apply -k deploy


clean:  # Clean some remnant files
	- rm .make.* 2>/dev/null || true
	- rm .rerun.json 2>/dev/null  || true  # Created by Bolt
	- rm -rf packer-* || true

line_blue:
	@echo -e "\e[44m#########################################################################################################################################################\e[0m"

line_green:
	@echo -e "\e[42m#########################################################################################################################################################\e[0m"

line_pink:
	@echo -e "\e[45m#########################################################################################################################################################\e[0m"

line_red:
	@echo -e "\e[41m#########################################################################################################################################################\e[0m"


# any prerequisites of .PHONY target are always determined to be out-of-date, and will be always be run.
.PHONY: all help clean logs

.DEFAULT_GOAL := help

# some_other_thing: .make.some_other_thing

# .make.some_other_thing: .make.prerequisite_thing
#     do_something
#     touch .make.some_other_thing
