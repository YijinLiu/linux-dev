# To run the container:
#   docker run -it --net host -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --name servo-${USER} yijinliu/servo

WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../user/build_servo.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t yijinliu/servo:`date '+%Y-%m-%d'` .

clean:
	rm -rf docker_tmp_data
