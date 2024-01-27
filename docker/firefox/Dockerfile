FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
        bash build-essential curl dpkg git libasound2 libcanberra-gtk-module \
        libcanberra-gtk3-module libdbus-glib-1-2 libegl1 libgl1 libgtk3.0-cil libpci3 libx11-xcb1 \
        python3 python3-dev python3-pip ssh sudo tzdata vim wget && \
    python3 -m pip install mercurial

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
RUN ./build_firefox.sh --version=$VERSION
WORKDIR /home/$USER

# docker run -it --user=${USER} --workdir=/home/${USER} \
#     -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --device /dev/snd \
#     --name firefox-${USER} ${USER}/firefox:121.0.1
