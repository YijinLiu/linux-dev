WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

VERSION?=1.9.3

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/julia.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	done
	docker build -t $(USER)/julia:$(VERSION) --build-arg VERSION=$(VERSION) \
	    --build-arg USER=$(USER) --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) .

clean:
	rm -rf docker_tmp_data
