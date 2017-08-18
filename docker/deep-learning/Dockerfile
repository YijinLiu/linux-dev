FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash build-essential dpkg git ssh sudo tzdata vim wget

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd dl --shell /bin/bash --groups sudo
RUN echo 'dl ALL = NOPASSWD: ALL' > /etc/sudoers.d/dl

ADD docker_tmp_data/deep-learning.sh /home/dl/build/deep-learning.sh
RUN chown -R dl:dl /home/dl
USER dl
WORKDIR /home/dl/build
ARG SRC
ARG BLAS
RUN ./deep-learning.sh --src=$SRC --blas=$BLAS
WORKDIR /home/dl
