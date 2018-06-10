#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;92m'
YELLOW='\e[0;33m'
NC='\e[0m'

usage() {
    echo "Options:
    --vimrc     Customize vimrc
    --docker    Install docker
"
}

OPTS=`getopt -n 'opencl.sh' -a -o i:p: \
             -l intel_neo_version:,prefix: \
             -- "$@"`
rc=$?
if [ $rc != 0 ] ; then
    usage
    exit 1
fi

intel_neo_version=18.22.10890
prefix=/usr/local
eval set -- "$OPTS"
while true; do
    case "$1" in
        -i | --intel_neo_version ) intel_neo_version=$2 ; shift 2 ;;
        -p | --prefix ) prefix=$2 ; shift 2 ;;
        -- ) shift; break ;;
        * ) echo -e "${RED}Invalid option: -$1${NC}" >&2 ; usage ; exit 1 ;;
    esac
done

install_deps() {
    sudo apt update && sudo apt install -y --no-install-recommends \
        autoconf bison build-essential clang-4.0 cmake flex libpciaccess-dev libtool libz-dev \
        patch pkg-config python
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install deps.${NC}"
        return 1
    fi
}

install_opencl_headers() {
    if [ ! -d "khronos" ]; then
        git clone --depth=1 https://github.com/KhronosGroup/OpenCL-Headers khronos
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download OpenCL-Headers.${NC}"
            return 1
        fi
    fi
    sudo mkdir -p $prefix/include &&
    sudo cp -av khronos/CL $prefix/include/
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install OpenCL-Headers.${NC}"
        return 1
    fi
}

install_icd_loader() {
    if [ ! -d "OpenCL-ICD-Loader" ]; then
        git clone --depth=1 https://github.com/KhronosGroup/OpenCL-ICD-Loader
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download OpenCL-ICD-Loader.${NC}"
            return 1
        fi
        cd OpenCL-ICD-Loader 
        patch -l -p1 <<-EOD
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 84a03f0..678f1ba 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -2,13 +2,15 @@ cmake_minimum_required (VERSION 2.6)
 
 project (OPENCL_ICD_LOADER)
 
+set (CMAKE_CXX_FLAGS "-g")
+set (CMAKE_C_FLAGS "-g")
 set (CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin)
 set (CMAKE_LIBRARY_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
 
 set (OPENCL_ICD_LOADER_SOURCES icd.c icd_dispatch.c)
 
 if ("\${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
-    list (APPEND OPENCL_ICD_LOADER_SOURCES icd_linux.c icd_exports.map)
+    list (APPEND OPENCL_ICD_LOADER_SOURCES icd_linux.c)
 else ()
     list (APPEND OPENCL_ICD_LOADER_SOURCES icd_windows.c icd_windows_hkr.c OpenCL.def OpenCL.rc)
     include_directories (\$ENV{DXSDK_DIR}/Include)
@@ -22,11 +24,10 @@ endif ()
 
 include_directories (\${OPENCL_INCLUDE_DIRS})
 
-add_library (OpenCL SHARED \${OPENCL_ICD_LOADER_SOURCES})
-set_target_properties (OpenCL PROPERTIES VERSION "1.2" SOVERSION "1")
+add_library (OpenCL STATIC \${OPENCL_ICD_LOADER_SOURCES})
 
 if ("\${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
-    set_target_properties (OpenCL PROPERTIES LINK_FLAGS "-pthread -Wl,--version-script -Wl,\${CMAKE_CURRENT_SOURCE_DIR}/icd_exports.map")
+    target_link_libraries (OpenCL "pthread")
 else()
     target_link_libraries (OpenCL cfgmgr32.lib)
 endif ()
EOD
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to patch OpenCL-ICD-Loader.${NC}"
            return 1
        fi
    else
        cd OpenCL-ICD-Loader
    fi
    make && sudo install build/libOpenCL.a $prefix/lib/
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build OpenCL-ICD-Loader.${NC}"
        return 1
    fi
    cd ..
}

install_clinfo() {
    if [ ! -d "clinfo" ]; then
        git clone --depth=1 https://github.com/Oblomov/clinfo -b 2.2.18.04.06 
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download clinfo source code.${NC}"
            return 1
        fi
		cd clinfo
		patch -l -p1 <<-EOD
diff --git a/Makefile b/Makefile
index e61f5dd..05497a6 100644
--- a/Makefile
+++ b/Makefile
@@ -40,7 +40,7 @@ MANDIR ?= \$(PREFIX)/man
 MANMODE ?= 444
 
 # Common library includes
-LDLIBS = -lOpenCL -ldl
+LDLIBS = -lOpenCL -lpthread -ldl
 
 # OS-specific library includes
 LDLIBS_Darwin = -framework OpenCL
EOD
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to patch clinfo.${NC}"
            return 1
        fi
	else
        cd clinfo
    fi
    make PREFIX=$prefix && sudo make install PREFIX=$prefix
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build clinfo.${NC}"
        return 1
    fi
    cd ..
}

clone_igc_repo() {
    manifest=$1
    project=$2
    groups=(`cat $manifest | tr -d '\n' | sed "s/.*\\s$project:\\s*\\(\\S*\\): \\(\\S*\\)\\s*\\(\\S*\\): \\(\\S*\\)\\s*\\(\\S*\\): \\(\\S*\\)\\s*\\(\\S*\\): \\(\\S*\\).*/\\1 \\2 \\3 \\4 \\5 \\6 \\7 \\8/"`)
    repo_url=
    repo_branch=
    repo_rev=
    for (( i=0; i<8; i+=2 )) ; do
        case "${groups[$i]}" in
            "repository" ) repo_url=${groups[$i+1]} ;;
            "branch" ) repo_branch=${groups[$i+1]} ;;
            "revision" ) repo_rev=${groups[$i+1]} ;;
        esac
    done
    if [ "$repo_rev" == "HEAD" ]; then
        git clone --depth=1 $repo_url -b $repo_branch $project
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to clone $project.${NC}"
            return 1
        fi
    else
        echo "git clone $repo_url -b $repo_branch $project"
        git clone $repo_url -b $repo_branch $project
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to clone $project.${NC}"
            return 1
        fi
        cd $project
        git checkout $repo_rev
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to checkout $project@$repo_rev.${NC}"
            return 1
        fi
        cd ..
    fi
}

clone_repo() {
    manifest=$1
    project=$2
    groups=(`cat $manifest | tr -d '\n' | sed "s/.*\\sdest_dir: $project\\s*repository: \\(\\S*\\)\\s*revision: \\(\\S*\\)\s*type: git.*/\\1 \\2/"`)
    repo_url=${groups[0]}
    repo_rev=${groups[1]}
    git clone $repo_url $project
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to clone $project.${NC}"
        return 1
    fi
    cd $project
    git checkout $repo_rev
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to checkout $project@$repo_rev.${NC}"
        return 1
    fi
    cd ..
}

install_intel_neo() {
    arch=$1
    case "$arch" in
        broadwell | skylake | silvermont | goldmont-plus ) ;;
        * ) echo -e "${YELLOW}Architecture $arch might not be supported.${NC}"
    esac
    if [ ! -d "compute-runtime" ]; then
        git clone --depth=1 https://github.com/intel/compute-runtime -b $intel_neo_version
        rc=$?
        if [ $rc != 0 ]; then
            echo -e "${RED}Failed to download compute-runtime source code.${NC}"
            return 1
        fi
    fi
    for igc_dep in llvm_source llvm_patches clang_source common_clang ; do
        if [ ! -d "$igc_dep" ]; then
            clone_igc_repo compute-runtime/manifests/igc.yml $igc_dep
            rc=$?
            if [ $rc != 0 ]; then
                return 1
            fi
        fi
    done
    for dep in gmmlib igc ; do
        if [ ! -d "$dep" ]; then
            clone_repo compute-runtime/manifests/manifest.yml $dep
            rc=$?
            if [ $rc != 0 ]; then
                return 1
            fi
        fi
    done
    ROOT=$(pwd)
    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release $ROOT/compute-runtime && make -j$(nproc)
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to build Intel NEO driver.${NC}"
        return 1
    fi
    # ldconfig if needed otherwise Neo driver won't be able to find so of these so that are needed
    # to compile program.
    sudo make install && sudo ldconfig
    rc=$?
    if [ $rc != 0 ]; then
        echo -e "${RED}Failed to install Intel NEO driver.${NC}"
        return 1
    fi
    cd ..
}

install_cl_driver() {
    vendor=`cat /proc/cpuinfo  | grep vendor_id | head -1 | sed "s/vendor_id\\s*:\\s*\\(\\S*\\)/\\1/"`
    arch=`gcc -march=native -Q --help=target | grep '\-march=' | sed "s/\\s*-march=\\s*\\(\\S*\\)/\\1/"`
    if [ "$vendor" == "GenuineIntel" ] ; then
        install_intel_neo $arch
    fi
}

install_deps &&
install_opencl_headers &&
install_icd_loader &&
install_clinfo &&
install_cl_driver
