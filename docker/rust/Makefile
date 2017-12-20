WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/rust.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t yijinliu/rust:`date '+%Y-%m-%d'` .

clean:
	rm -rf docker_tmp_data
