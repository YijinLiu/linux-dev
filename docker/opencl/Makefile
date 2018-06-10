WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

VERSION?=`date '+%Y-%m-%d'`

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/opencl.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t $(USER)/opencl:$(VERSION) \
	    --build-arg NAME=${USER} --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) .

clean:
	rm -rf docker_tmp_data
