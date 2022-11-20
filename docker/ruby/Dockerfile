FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && \
    apt install -y --no-install-recommends autoconf bash bison build-essential ca-certificates \
        dpkg git gperf libedit-dev libffi-dev libssl-dev libyaml-dev openssl pkg-config rustc ssh \
        sudo tzdata unzip vim wget zlib1g-dev

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

ARG USER
ARG UID
ARG GID
ARG VERSION

RUN groupadd -g $GID $USER
RUN useradd -u $UID -g $USER --groups sudo --shell /bin/bash $USER
RUN echo "$USER ALL = NOPASSWD: ALL" > /etc/sudoers.d/$USER

ADD docker_tmp_data/* /home/$USER/build/
RUN chown -R $USER:$USER /home/$USER
USER $USER
WORKDIR /home/$USER/build
RUN sudo apt install -y --no-install-recommends ruby && \
    ./ruby.sh --version=$VERSION && \
    sudo apt autoremove -y ruby
WORKDIR /home/$USER
