WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

VERSION?=10.2.2

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/ghidra.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t yijinliu/ghidra:$(VERSION) --build-arg VERSION=$(VERSION) \
		--build-arg USER=${USER} --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) .

	# To run it:
	# docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:$HOME/.Xauthority -e DISPLAY=$DISPLAY -h $HOSTNAME -it --name ghidra_10.2.2 yijinliu/ghidra:10.2.2

clean:
	rm -rf docker_tmp_data
