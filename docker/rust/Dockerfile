FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash build-essential dpkg git ssh sudo tzdata vim wget

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd rust --shell /bin/bash --groups sudo
RUN echo 'rust ALL = NOPASSWD: ALL' > /etc/sudoers.d/rust

ADD docker_tmp_data/* /home/rust/build/
RUN chown -R rust:rust /home/rust
USER rust
WORKDIR /home/rust/build
RUN ./rust.sh
WORKDIR /home/rust
