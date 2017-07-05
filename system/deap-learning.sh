#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

install_pkgs() {
    sudo apt install -y build-essential clang cmake cpio curl graphviz python-dev python-nose-cov \
        python-nose-yanc python-pip python-scipy python-wheel wget &&
    sudo pip install --upgrade pip &&
    sudo pip install graphviz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install packages!${NC}"
        return 1
    fi
}

# Visit https://registrationcenter.intel.com/en/products/postregistration/?sn=33RM-JFS6X66V
# to find latest versions of MKL and IPP.

install_mkl() {
    wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11544/l_mkl_2017.3.196.tgz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download Intel MKL!${NC}"
        return 1
    fi
    tar xvzf l_mkl_2017.3.196.tgz &&
    chmod +x l_mkl_2017.3.196/install.sh &&
    echo '
ACCEPT_EULA=accept
CONTINUE_WITH_OPTIONAL_ERROR=yes
PSET_INSTALL_DIR=/usr/local/mkl
CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes
COMPONENTS=DEFAULTS
PSET_MODE=install
SIGNING_ENABLED=yes
ARCH_SELECTED=ALL
' > mkl_2017.3.196.silent.cfg &&
    sudo l_mkl_2017.3.196/install.sh -s mkl_2017.3.196.silent.cfg
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Intel MKL!${NC}"
        return 1
    fi
}

install_ipp() {
    wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11545/l_ipp_2017.3.196.tgz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download Intel IPP!${NC}"
        return 1
    fi
    tar xvzf l_ipp_2017.3.196.tgz &&
    chmod +x l_ipp_2017.3.196/install.sh &&
    echo '
ACCEPT_EULA=accept
CONTINUE_WITH_OPTIONAL_ERROR=yes
PSET_INSTALL_DIR=/usr/local/ipp
CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes
COMPONENTS=DEFAULTS
PSET_MODE=install
SIGNING_ENABLED=yes
ARCH_SELECTED=ALL
' > ipp_2017.3.196.silent.cfg &&
    sudo l_ipp_2017.3.196/install.sh -s ipp_2017.3.196.silent.cfg
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Intel IPP!${NC}"
        return 1
    fi
}

install_daal() {
    git clone https://github.com/01org/daal -b 2017_u3
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download Intel DAAL source!${NC}"
        return 1
    fi
    cd daal
    make _daal _release_c _release_p PLAT=lnx32e COMPILER=gnu &&
    sudo cp -av __release_lnx_gnu /usr/local/daal
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile Intel DAAL!${NC}"
        return 1
    fi
    cd ..
}

install_mkl_dnn() {
    git clone https://github.com/01org/mkl-dnn -b v0.9
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download Intel MKL-DNN source!${NC}"
        return 1
    fi
    cd mkl-dnn
    mkdir -p build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mkl-dnn .. && make && sudo make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile Intel MKL-DNN!${NC}"
        return 1
    fi
    cd ../..
}

install_theano_pip() {
    sudo pip install Theano
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Theano!${NC}"
        return 1
    fi
}

install_theano_src() {
    git clone https://github.com/Theano/Theano -b rel-0.9.0
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download Theano source!${NC}"
        return 1
    fi
    cd Theano
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Theano!${NC}"
        return 1
    fi
    cd ..
}

install_tensorflow_pip() {
    sudo pip install tensorflow
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install TensorFlow!${NC}"
        return 1
    fi
}

install_bazel() {
    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to add bazel apt rep!${NC}"
        return 1
    fi
    curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add - &&
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to add bazel apt key!${NC}"
        return 1
    fi
    sudo apt update && sudo apt install -y bazel
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install bazel!${NC}"
        return 1
    fi
}

install_computecpp() {
    wget https://raw.githubusercontent.com/yijinliu/linux-dev/master/3rd_party/ComputeCpp-CE-0.2.1-Ubuntu.16.04-64bit.tar.gz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download ComputeCpp!${NC}"
        return 1
    fi
    tar xvzf ComputeCpp-CE-0.2.1-Ubuntu.16.04-64bit.tar.gz -C /usr/local
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install ComputeCpp!${NC}"
        return 1
    fi
}

install_tensorflow_src() {
    git clone https://github.com/tensorflow/tensorflow -b v1.2.1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download TensorFlow source!${NC}"
        return 1
    fi
    cd tensorflow
    chmod +x ./configure &&
    sudo updatedb &&
    echo "/usr/bin/python
/usr/local/lib/python2.7/dist-packages
y
n
/usr/local/mkl
-march=native
y
y
n
y
n
y
n
/usr/bin/clang++
/usr/bin/clang
/usr/local/ComputeCpp-CE-0.2.1-Linux
" | ./configure
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to configure Tensorflow!${NC}"
        return 1
    fi
    cd ..
    # TODO: After https://github.com/bazelbuild/bazel/issues/1920 is fixed, build static c/c++
    # libraries.
    bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package \
        //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so &&
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build Tensorflow!${NC}"
        return 1
    fi
    sudo install bazel-bin/tensorflow/libtensorflow.so bazel-bin/tensorflow/libtensorflow_cc.so \
        /usr/local/lib &&
    sudo cp -av tensorflow /usr/local/include/ &&
    sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1-cp27-cp27mu-linux_x86_64.whl
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Tensorflow!${NC}"
        return 1
    fi
    cd ..
}

install_mxnet_pip() {
    sudo pip install mxnet
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install MXNet!${NC}"
        return 1
    fi
}


install_mxnet_src() {
    git clone --recursive https://github.com/dmlc/mxnet -b v0.10.0
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download MXNet source!${NC}"
        return 1
    fi
    cd mxnet
    echo "
diff --git a/Makefile b/Makefile
index c71cb13..7b70127 100644
--- a/Makefile
+++ b/Makefile
@@ -94,7 +94,7 @@ ifeq ($(USE_MKL2017), 1)
 	CFLAGS += -DUSE_MKL=1
 	CFLAGS += -I$(ROOTDIR)/src/operator/mkl/
 	CFLAGS += -I$(MKLML_ROOT)/include
-	LDFLAGS += -L$(MKLML_ROOT)/lib
+	LDFLAGS += -L$(MKLML_ROOT)/lib/intel64
 ifeq ($(USE_MKL2017_EXPERIMENTAL), 1)
 	CFLAGS += -DMKL_EXPERIMENTAL=1
 else
diff --git a/mshadow/make/mshadow.mk b/mshadow/make/mshadow.mk
index 0ff2fbd..931a9e1 100644
--- a/mshadow/make/mshadow.mk
+++ b/mshadow/make/mshadow.mk
@@ -52,10 +52,10 @@ ifeq ($(USE_INTEL_PATH), NONE)
 else
 	MKLROOT = $(USE_INTEL_PATH)/mkl
 endif
-	MSHADOW_LDFLAGS += -L${MKLROOT}/../compiler/lib/intel64 -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_intel_thread.a -Wl,
--end-group -liomp5 -ldl -lpthread -lm
+	MSHADOW_LDFLAGS += -L${MKLROOT}/../compiler/lib/intel64 -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_intel_thread.a 
-Wl,--end-group -ldl -lpthread -lm
 else
 ifneq ($(USE_MKLML), 1)
-  MSHADOW_LDFLAGS += -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5
+  MSHADOW_LDFLAGS += -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core
 endif
 endif
 else
" | patch -p1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch MXNet!${NC}"
        return 1
    fi
    make USE_BLAS=mkl MKLML_ROOT=/opt/intel/mkl USE_MKL2017=1 USE_MKL2017_EXPERIMENTAL=1 \
         USE_STATIC_MKL=1 USE_OPENCV=0 USE_OPENMP=0
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile MXNet!${NC}"
        return 1
    fi
    cd python
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install MXNet!${NC}"
        return 1
    fi
    cd ../..
}

install_pkgs &&
install_mkl &&
install_ipp &&
install_daal &&
install_mkl_dnn &&
install_theano_src &&
install_bazel &&
install_computecpp &&
install_tensorflow_src &&
install_mxnet_src
