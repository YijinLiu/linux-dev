WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

VERSION?=0.2.2

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/flutter.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t ${USER}/flutter:$(VERSION) --build-arg VERSION=$(VERSION) \
		--build-arg USER=${USER} --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) .

clean:
	rm -rf docker_tmp_data
