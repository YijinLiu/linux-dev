WORK_DIR:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

SRC?=1
BLAS?=MKL

default: clean
	cd $(WORK_DIR)
	mkdir docker_tmp_data
	for i in ../../system/deep-learning.sh ; do \
	    cp -apf $$i docker_tmp_data/ ; \
	    done
	docker build -t yijinliu/deep-learning-`echo $(BLAS) | tr A-Z a-z`:`date '+%Y-%m-%d'` \
		--build-arg SRC=$(SRC) --build-arg BLAS=$(BLAS) .

clean:
	rm -rf docker_tmp_data
