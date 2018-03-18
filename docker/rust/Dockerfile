FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash build-essential dpkg git ssh sudo tzdata vim wget

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
RUN ./rust.sh --rust_ver=$VERSION
WORKDIR /home/$USER
