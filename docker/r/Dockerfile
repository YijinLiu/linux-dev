FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
        bash build-essential curl gfortran git libbz2-dev libcurl4-openssl-dev liblzma-dev \
        libpcre2-dev libreadline-dev libx11-dev openjdk-11-jdk python3 python3-dev python3-pip ssh \
        sudo tzdata vim wget xorg-dev

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
RUN ./r.sh --version=$VERSION
WORKDIR /home/$USER

# docker run -it --user=${USER} -v /home/${USER}/projects:/home/${USER}/projects \
#     -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --device /dev/snd \
#     --name r-${USER} ${USER}/r:4.2.2
