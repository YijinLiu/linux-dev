FROM ubuntu:16.04

RUN apt update && apt upgrade -y && \ 
    apt install -y --no-install-recommends bash build-essential ca-certificates \
        dpkg git ssh sudo tzdata vim wget

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
RUN ./flutter.sh --flutter_ver=$VERSION
WORKDIR /home/$USER

# docker run -it --user=${USER} --workdir=/home/${USER} \
#     -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --device /dev/snd \
#     --name flutter-${USER} ${USER}/flutter:0.2.2
