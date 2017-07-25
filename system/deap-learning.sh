#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --src=       Whether to build from source
    --blas=      atlas/openblas/mkl
"
}

src=1
blas=mkl

OPTS=`getopt -n 'deap-learning.sh' -o s:,b: -l src:,blas: -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi
eval set -- "$OPTS"
while true; do
    case "$1" in
        -s | --src )                src="$2" ; shift 2 ;;
        -b | --blas )               blas="$2" ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done
echo -e ${GREEN}BLAS: $blas${NC}

install_pkgs() {
    sudo apt install -y --no-install-recommends autoconf automake build-essential clang cmake cpio \
        curl flex gfortran graphviz libboost-dev libtool locate python-dev python-nose-cov \
        python-nose-yanc python-pip python-setuptools python-wheel python-yaml swig unzip wget &&
    sudo -H pip install --upgrade pip &&
    sudo apt remove -y python-pip &&
    sudo pip install cython graphviz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install packages!${NC}"
        return 1
    fi
}

install_atlas() {
    wget https://managedway.dl.sourceforge.net/project/math-atlas/Stable/3.10.3/atlas3.10.3.tar.bz2
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download ATLAS source!${NC}"
        return 1
    fi
    tar xvjf atlas3.10.3.tar.bz2
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to extract ATLAS source!${NC}"
        return 1
    fi
    wget http://www.netlib.org/lapack/lapack-3.7.1.tgz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download LAPACK source!${NC}"
        return 1
    fi
    cd ATLAS
    mkdir build
    cd build
    ../configure --prefix=/usr/local/ATLAS --cripple-atlas-performance --dylibs -t 0 \
        --with-netlib-lapack-tarfile=../../lapack-3.7.1.tgz
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to configure ATLAS!${NC}"
        return 1
    fi
    make && sudo make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build ATLAS!${NC}"
        return 1
    fi
    cd ../..
}

install_openblas() {
    git clone https://github.com/xianyi/OpenBLAS -b v0.2.19
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download OpenBLAS source!${NC}"
        return 1
    fi
    cd OpenBLAS
    make USE_THREAD=0 USE_OPENMP=0 -j $(nproc) &&
    sudo make PREFIX=/usr/local/OpenBLAS install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile OpenBLAS!${NC}"
        return 1
    fi
    cd ..
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
PSET_INSTALL_DIR=/usr/local/intel
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

install_blas() {
    case "$blas" in
        "atlas" ) install_atlas ;;
        "openblas" ) install_openblas ;;
        "mkl" ) install_mkl ;;
        * ) echo -e "${YELLOW}No BLAS will be install.${NC}"
    esac
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
PSET_INSTALL_DIR=/usr/local/intel
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
    sudo cp -av __release_lnx_gnu /usr/local/intel/daal
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
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/intel/mkl-dnn .. && make && sudo make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile Intel MKL-DNN!${NC}"
        return 1
    fi
    cd ../..
}

install_numpy() {
    git clone https://github.com/numpy/numpy -b v1.13.1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download numpy source!${NC}"
        return 1
    fi
    cd numpy
    echo "diff --git a/numpy/distutils/system_info.py b/numpy/distutils/system_info.py
index 0fba865..39d624b 100644
--- a/numpy/distutils/system_info.py
+++ b/numpy/distutils/system_info.py
@@ -961,7 +961,7 @@ class djbfft_info(system_info):
 class mkl_info(system_info):
     section = 'mkl'
     dir_env_var = 'MKLROOT'
-    _lib_mkl = ['mkl_rt']
+    _lib_names = ['mkl_rt']

     def get_mkl_rootdir(self):
         mklroot = os.environ.get('MKLROOT', None)
@@ -1011,7 +1011,7 @@ class mkl_info(system_info):
     def calc_info(self):
         lib_dirs = self.get_lib_dirs()
         incl_dirs = self.get_include_dirs()
-        mkl_libs = self.get_libs('mkl_libs', self._lib_mkl)
+        mkl_libs = self.get_libs('mkl_libs', self._lib_names)
         info = self.check_libs2(lib_dirs, mkl_libs)
         if info is None:
             return" | patch -l -p1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch numpy!${NC}"
        return 1
    fi
    blas_cfg=
    if [ "$blas" == "atlas" ] ; then
        blas_cfg='[atlas]
library_dirs = /usr/local/ATLAS/lib
include_dirs = /usr/local/ATLAS/include'
    elif [ "$blas" == "openblas" ] ; then
        blas_cfg='[openblas]
library_dirs = /usr/local/OpenBLAS/lib
runtime_library_dirs = /usr/local/OpenBLAS/lib
include_dirs = /usr/local/OpenBLAS/include'
    elif [ "$blas" == "mkl" ] ; then
        blas_cfg='[mkl]
library_dirs = /usr/local/intel/mkl/lib/intel64
runtime_library_dirs = /usr/local/intel/mkl/lib/intel64
include_dirs = /usr/local/intel/mkl/include'
    fi
    echo "[ALL]
library_dirs = /usr/local/lib
include_dirs = /usr/local/include
${blas_cfg}" > site.cfg
    python setup.py build -j $(nproc) &&
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile numpy!${NC}"
        return 1
    fi
    cd ..
}

install_scipy() {
    git clone https://github.com/scipy/scipy -b v0.19.1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download scipy source!${NC}"
        return 1
    fi
    cd scipy
    python setup.py build -j $(nproc) &&
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile scipy!${NC}"
        return 1
    fi
    cd ..
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
    python setup.py build &&
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Theano!${NC}"
        return 1
    fi
    cd ..
}

install_theano() {
    if [ -z "$src" ]; then
        install_theano_pip
    else
        install_theano_src
    fi
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
    sudo tar xvzf ComputeCpp-CE-0.2.1-Ubuntu.16.04-64bit.tar.gz -C /usr/local
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install ComputeCpp!${NC}"
        return 1
    fi
}

install_headers() {
    src=$1
    dst=$2
    for header in $(find $src -name "*.h") ; do
        dir=$(dir $header)
        sudo mkdir -p $dst/$dir && sudo cp $header $dst/$dir
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to install $header!${NC}"
            return 1
        fi
    done
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
    intel_cfgs=
    if [ "$blas" == "mkl" ] ; then
        intel_cfgs="y
n
/usr/local/intel/mkl"
    else
        intel_cfgs="n"
    fi
    echo "/usr/bin/python
/usr/local/lib/python2.7/dist-packages
$intel_cfgs
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
    # TODO: After https://github.com/bazelbuild/bazel/issues/1920 is fixed, build static c/c++
    # libraries.
    bazel build --config=opt --jobs=$(nproc) //tensorflow/tools/pip_package:build_pip_package \
        //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so &&
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build Tensorflow!${NC}"
        return 1
    fi
    sudo mkdir -p /usr/local/lib &&
    sudo install bazel-bin/tensorflow/libtensorflow.so bazel-bin/tensorflow/libtensorflow_cc.so \
        /usr/local/lib &&
    install_headers tensorflow /usr/local/include &&
    sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1-cp27-cp27mu-linux_x86_64.whl
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Tensorflow!${NC}"
        return 1
    fi
    cd ..
}

install_tensorflow() {
    if [ -z "$src" ]; then
        install_tensorflow_pip
    else
        install_bazel &&
        install_computecpp &&
        install_tensorflow_src
    fi
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
    echo 'diff --git a/Makefile b/Makefile
index c71cb13..7b70127 100644
--- a/Makefile
+++ b/Makefile
@@ -94,7 +94,7 @@ ifeq ($(USE_MKL2017), 1)
      CFLAGS += -DUSE_MKL=1
      CFLAGS += -I$(ROOTDIR)/src/operator/mkl/
      CFLAGS += -I$(MKLML_ROOT)/include
-     LDFLAGS += -L$(MKLML_ROOT)/lib
+     LDFLAGS += -L$(MKLML_ROOT)/lib/intel64 -Wl,-rpath $(MKLML_ROOT)/lib/intel64
 ifeq ($(USE_MKL2017_EXPERIMENTAL), 1)
      CFLAGS += -DMKL_EXPERIMENTAL=1
 else
diff --git a/mshadow/make/mshadow.mk b/mshadow/make/mshadow.mk
index 0ff2fbd..955a94c 100644
--- a/mshadow/make/mshadow.mk
+++ b/mshadow/make/mshadow.mk
@@ -70,16 +70,18 @@ ifeq ($(USE_MKLML), 1)
 endif

 ifeq ($(USE_BLAS), openblas)
-	MSHADOW_LDFLAGS += -lopenblas
+     MSHADOW_CFLAGS += -I/usr/local/OpenBLAS/include
+     MSHADOW_LDFLAGS += -L/usr/local/OpenBLAS/lib -Wl,-rpath /usr/local/OpenBLAS/lib -lopenblas
 else ifeq ($(USE_BLAS), perfblas)
-	MSHADOW_LDFLAGS += -lperfblas
+     MSHADOW_LDFLAGS += -lperfblas
 else ifeq ($(USE_BLAS), atlas)
-	MSHADOW_LDFLAGS += -lcblas
+     MSHADOW_CFLAGS += -I/usr/local/ATLAS/include
+     MSHADOW_LDFLAGS += -L/usr/local/ATLAS/lib -Wl,-rpath /usr/local/ATLAS/lib -lsatlas
 else ifeq ($(USE_BLAS), blas)
-	MSHADOW_LDFLAGS += -lblas
+     MSHADOW_LDFLAGS += -lblas
 else ifeq ($(USE_BLAS), apple)
-	MSHADOW_CFLAGS += -I/System/Library/Frameworks/Accelerate.framework/Versions/Current/Frameworks/vecLib.framework/Versions/Current/Headers/
-	MSHADOW_LDFLAGS += -framework Accelerate
+     MSHADOW_CFLAGS += -I/System/Library/Frameworks/Accelerate.framework/Versions/Current/Frameworks/vecLib.framework/Versions/Current/Headers/
+     MSHADOW_LDFLAGS += -framework Accelerate
 endif

 ifeq ($(PS_PATH), NONE)' | patch -l -p1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch MXNet!${NC}"
        return 1
    fi
    BLAS_ARGS=
    if [ "$blas" == "mkl" ] ; then
        BLAS_ARGS="USE_BLAS=mkl MKLML_ROOT=/usr/local/intel/mkl USE_MKL2017=1 USE_MKL2017_EXPERIMENTAL=1 USE_STATIC_MKL=1 USE_INTEL_PATH=/usr/local/intel"
    elif [ "$blas" == "openblas" ] ; then
        BLAS_ARGS="USE_BLAS=openblas"
    elif [ "$blas" == "atlas" ] ; then
        BLAS_ARGS="USE_BLAS=atlas"
    fi
    make ${BLAS_ARGS} USE_OPENCV=0 USE_OPENMP=0 -j $(nproc)
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile MXNet!${NC}"
        return 1
    fi
    cd python
    python setup.py build &&
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install MXNet!${NC}"
        return 1
    fi
    cd ../..
}

install_mxnet() {
    if [ -z "$src" ]; then
        install_mxnet_pip
    else
        install_mxnet_src
    fi
}

install_pytorch() {
    git clone https://github.com/pytorch/pytorch -b v0.1.12
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download pytorch source!${NC}"
        return 1
    fi
    cd pytorch
    BLAS_LIBS=
    BLAS_LFLAGS=
    if [ "$blas" == "mkl" ] ; then
        BLAS_LIBS="mkl_rt"
        BLAS_LFLAGS="-L/usr/local/intel/mkl/lib/intel64 -Wl,-rpath,/usr/local/intel/mkl/lib/intel64"
    elif [ "$blas" == "openblas" ] ; then
        BLAS_LIBS="openblas"
        BLAS_LFLAGS="-L/usr/local/OpenBLAS/lib -Wl,-rpath,/usr/local/OpenBLAS/lib"
    elif [ "$blas" == "atlas" ] ; then
        BLAS_LIBS="satlas lapack"
        BLAS_LFLAGS="-L/usr/local/ATLAS/lib -Wl,-rpath,/usr/local/ATLAS/lib"
    fi
    echo "diff --git a/torch/lib/TH/CMakeLists.txt b/torch/lib/TH/CMakeLists.txt
index c4e6694..43873c5 100644
--- a/torch/lib/TH/CMakeLists.txt
+++ b/torch/lib/TH/CMakeLists.txt
@@ -43,7 +43,7 @@ IF(UNIX)
 ENDIF(UNIX)

 # OpenMP support?
-SET(WITH_OPENMP ON CACHE BOOL \"OpenMP support if available?\")
+SET(WITH_OPENMP 0 ON CACHE BOOL \"OpenMP support if available?\")
 IF (APPLE AND CMAKE_COMPILER_IS_GNUCC)
   EXEC_PROGRAM (uname ARGS -v  OUTPUT_VARIABLE DARWIN_VERSION)
   STRING (REGEX MATCH \"[0-9]+\" DARWIN_VERSION \${DARWIN_VERSION})
@@ -275,17 +275,10 @@ ELSE()
   ENDIF()
 ENDIF()

-FIND_PACKAGE(BLAS)
-IF(BLAS_FOUND)
-  SET(USE_BLAS 1)
-  TARGET_LINK_LIBRARIES(TH \${BLAS_LIBRARIES})
-ENDIF(BLAS_FOUND)
-
-FIND_PACKAGE(LAPACK)
-IF(LAPACK_FOUND)
-  SET(USE_LAPACK 1)
-  TARGET_LINK_LIBRARIES(TH \${LAPACK_LIBRARIES})
-ENDIF(LAPACK_FOUND)
+SET(USE_BLAS 1)
+SET(USE_LAPACK 1)
+TARGET_LINK_LIBRARIES(TH ${BLAS_LIBS})
+SET_TARGET_PROPERTIES(TH PROPERTIES LINK_FLAGS \"${BLAS_LFLAGS}\")

 IF (UNIX AND NOT APPLE)
    INCLUDE(CheckLibraryExists)" | patch -l -p1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch pytorch!${NC}"
        return 1
    fi
    python setup.py build &&
    sudo python setup.py install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install pytorch!${NC}"
        return 1
    fi
    cd ..
}

install_protobuf() {
    git clone https://github.com/google/protobuf -b v3.3.0
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download protobuf source!${NC}"
        return 1
    fi
    cd protobuf
    ./autogen.sh &&
    ./configure --enable-static --disable-shared --with-pic &&
    make -j $(nproc) && sudo make install
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile protobuf!${NC}"
        return 1
    fi
    cd ..
}

install_cntk() {
    git clone https://github.com/Microsoft/CNTK -b v2.0
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to download CNTK source!${NC}"
        return 1
    fi
    cd CNTK
    echo 'diff --git a/bindings/python/cntk/train/distributed.py b/bindings/python/cntk/train/distributed.py
index 0129f5e..2cd579a 100644
--- a/bindings/python/cntk/train/distributed.py
+++ b/bindings/python/cntk/train/distributed.py
@@ -12,8 +12,6 @@ from cntk.internal import typemap
 # If other OS has similar OpenMPI MPI_Init failure, add dll load to global here
 import platform
 import ctypes
-if platform.system() == '"'Linux'"':
-    ctypes.CDLL("libmpi.so.12", mode=ctypes.RTLD_GLOBAL)

 __doc__= '"'''"'\
 Distributed learners manage learners in distributed environment.
diff --git a/bindings/python/setup.py b/bindings/python/setup.py
index 0ce327f..960b1c8 100644
--- a/bindings/python/setup.py
+++ b/bindings/python/setup.py
@@ -125,7 +125,7 @@ else:
     # Expecting the dependent libs (libcntklibrary-2.0.so, etc.) inside
     # site-packages/cntk/libs.
     runtime_library_dirs = ['"'"'$ORIGIN/cntk/libs'"'"']
-    os.environ["CXX"] = "mpic++"
+    os.environ["CXX"] = "g++"

 cntkV2LibraryInclude = os.path.join(CNTK_SOURCE_PATH, "CNTKv2LibraryDll", "API")
 cntkBindingCommon = os.path.join(CNTK_PATH, "bindings", "common")
diff --git a/Makefile b/Makefile
index cde0f34..2c499e6 100644
--- a/Makefile
+++ b/Makefile
@@ -175,7 +175,7 @@ ifeq ("$(MATHLIB)","mkl")
   LIBS_LIST += m
 ifeq ("$(MKL_THREADING)","sequential")
   LIBPATH += $(MKL_PATH)/$(CNTK_CUSTOM_MKL_VERSION)/x64/sequential
-  LIBS_LIST += mkl_cntk_s
+  LIBS_LIST += mkl_cntk_s pthread
 else
   LIBPATH += $(MKL_PATH)/$(CNTK_CUSTOM_MKL_VERSION)/x64/parallel
   LIBS_LIST += mkl_cntk_p iomp5 pthread
diff --git a/configure b/configure
index 9c11800..700c0cd 100755
--- a/configure
+++ b/configure
@@ -98,7 +98,7 @@ default_jdk="jvm/java-7-openjdk-amd64"

 mathlib=

-have_mpi=yes
+have_mpi=no
 default_use_mpi=$have_mpi

 default_use_1bitsgd=no
@@ -107,7 +107,7 @@ enable_1bitsgd=$default_use_1bitsgd
 default_use_code_coverage=no
 enable_code_coverage=$default_use_code_coverage

-default_use_asgd=yes
+default_use_asgd=no
 enable_asgd=$default_use_asgd

 # List from best to worst choice
@@ -364,10 +364,10 @@ function show_help ()
     echo "  --with-build-top=directory build directory $(show_default $build_top)"
     echo "  --add directory add directory to library search path"
     echo "  --1bitsgd[=(yes|no)] use 1Bit SGD $(show_default ${default_use_1bitsgd})"
-    echo "  --asgd[=(yes|no)] use ASGD powered by Multiverso $(show_default $(default_use_asgd))"
-    echo "  --cuda[=(yes|no)] use cuda GPU $(show_default $(default_use_cuda))"
-    echo "  --python[=(yes|no)] with Python bindings $(show_default $(default_use_python))"
-    echo "  --java[=(yes|no)] with Java bindings $(show_default $(default_use_java))"
+    echo "  --asgd[=(yes|no)] use ASGD powered by Multiverso $(show_default ${default_use_asgd})"
+    echo "  --cuda[=(yes|no)] use cuda GPU $(show_default ${default_use_cuda})"
+    echo "  --python[=(yes|no)] with Python bindings $(show_default ${default_use_python})"
+    echo "  --java[=(yes|no)] with Java bindings $(show_default ${default_use_java})"
     echo "  --with-jdk[=directory] $(show_default $(find_jdk))"
     echo "  --mpi[=(yes|no)] use MPI communication $(show_default ${default_use_mpi})"
     echo "  --gdr[=(yes|no)] use GPUDirect RDMA $(show_default ${default_cuda_gdr})"
@@ -1095,20 +1095,6 @@ then
     fi
 fi

-if test x$boost_path = x
-then
-    boost_path=$(find_boost)
-    if test x$boost_path = x
-    then
-        echo Cannot locate Boost libraries. See
-        echo   https://github.com/Microsoft/CNTK/wiki/Setup-CNTK-on-Linux#boost-library
-        echo for installation instructions.
-        exit 1
-    else
-        echo Found Boost at $boost_path
-    fi
-fi
-
 if test x$protobuf_path = x
 then
     protobuf_path=$(find_protobuf)
@@ -1123,20 +1109,6 @@ then
     fi
 fi

-if test x$mpi_path = x
-then
-    mpi_path=$(find_mpi)
-    if test x${mpi_path} = x
-    then
-        echo Cannot locate MPI library. See
-        echo   https://github.com/Microsoft/CNTK/wiki/Setup-CNTK-on-Linux#open-mpi
-        echo for installation instructions.
-        exit 1
-    else
-        echo Found MPI at $mpi_path
-    fi
-fi
-
 config=$build_top/Config.make
 echo Generating $config
 echo "#Configuration file for cntk" > $config' | patch -l -p1
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to patch CNTK source!${NC}"
        return 1
    fi
    if [ "$blas" == "mkl" ] ; then
        wget --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" \
            https://www.microsoft.com/en-us/cognitive-toolkit/wp-content/uploads/sites/3/2017/05/CNTKCustomMKL-Linux-3.tgz
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download CNTKCustomMKL-Linux-3.tgz!${NC}"
            return 1
        fi
        sudo mkdir /usr/local/CNTKCustomMKL &&
        sudo tar xzvf CNTKCustomMKL-Linux-3.tgz -C /usr/local/CNTKCustomMKL
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to install CNTKCustomMKL!${NC}"
            return 1
        fi
        ./configure --with-buildtype=release --with-mkl-sequential=/usr/local/CNTKCustomMKL
    elif [ "$blas" == "openblas" ] ; then
        ./configure --with-buildtype=release --with-openblas=/usr/local/OpenBLAS
    else
        echo -e "${YELLOW}CNTK needs MKL or OpenBLAS!${NC}"
        return
    fi
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to configure CNTK!${NC}"
        return 1
    fi
    make PYTHON_SUPPORT=true PYTHON_VERSIONS=27 PYTHON27_PATH=/usr/bin/python BOOST_PATH= -j $(nproc) &&
    sudo pip install python/cntk-2.0-cp27-cp27mu-linux_x86_64.whl
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to compile CNTK!${NC}"
        return 1
    fi
    cd ..
}

install_pkgs &&
install_blas &&
install_numpy &&
install_scipy &&
install_theano &&
install_tensorflow &&
install_mxnet &&
install_pytorch &&
install_protobuf &&
install_cntk &&
sudo apt autoremove -y
