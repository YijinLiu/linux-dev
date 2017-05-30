FROM ubuntu:16.04

RUN apt update
RUN apt install -y --no-install-recommends bash build-essential clang cmake dpkg git \
        libcairo-dev libdispatch-dev libffi-dev libgnutls-dev libjpeg-dev libtiff-dev libxml2-dev \
        libxt-dev \
        software-properties-common ssh sudo tzdata vim

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd objc --shell /bin/bash --groups sudo
RUN echo 'objc ALL = NOPASSWD: ALL' > /etc/sudoers.d/objc

ADD docker_tmp_data/gnustep.sh /home/objc/gnustep.sh
RUN chown objc:objc /home/objc
WORKDIR /home/objc
USER objc
RUN ./gnustep.sh
