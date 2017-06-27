FROM ubuntu:16.04

RUN apt update && apt install -y --no-install-recommends autoconf automake bash build-essential \
        ca-certificates clang cmake dpkg git icu-devtools libblocksruntime-dev libbsd-dev \
        libcurl4-openssl-dev libedit-dev libicu-dev libncurses5-dev libpython-dev libsqlite3-dev \
        libtool libxml2-dev ninja-build pkg-config python ssh sudo swig systemtap-sdt-dev tzdata \
        uuid-dev vim

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd swift --shell /bin/bash --groups sudo
RUN echo 'swift ALL = NOPASSWD: ALL' > /etc/sudoers.d/swift

ADD docker_tmp_data/swift.sh /home/swift/swift.sh
RUN chown swift:swift /home/swift
WORKDIR /home/swift
USER swift
RUN ./swift.sh
