FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
        bash build-essential cmake curl gfortran git golang libatomic1 libbz2-dev \
	libcurl4-openssl-dev liblzma-dev libpcre2-dev libreadline-dev libx11-dev m4 ninja-build \
	patch pkg-config perl python3 python3-dev python3-pip libssl-dev sudo tzdata vim wget \
	xorg-dev && \
    pip install -U --no-cache-dir pip setuptools && \
    apt autoremove -y python3-pip && \
    pip3 install -U --no-cache-dir absl-py matplotlib numba

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

ARG USER
ARG UID
ARG GID

RUN groupadd -g $GID $USER
RUN useradd -u $UID -g $USER --groups sudo --shell /bin/bash $USER
RUN echo "$USER ALL = NOPASSWD: ALL" > /etc/sudoers.d/$USER

ADD docker_tmp_data/* /home/$USER/build/
RUN chown -R $USER:$USER /home/$USER
USER $USER
WORKDIR /home/$USER/build
RUN ./dart.sh --version=3.1.3 && \
    ./java.sh --version=21 && \
    ./julia.sh --version=1.9.3 && \
    ./r.sh --version=4.3.1 && \
    ./rust.sh --version=1.73.0 && \
    cd .. && sudo rm -rf build
WORKDIR /home/$USER

# docker run -it --user=${USER} -v /home/${USER}/projects:/home/${USER}/projects \
#     -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --device /dev/snd \
#     --name languages-${USER} ${USER}/languages:`date '+%Y-%m-%d'`

# docker run -ti --runtime=nvidia --shm-size=1g -e NVIDIA_VISIBLE_DEVICES=0 --cap-add=SYS_PTRACE \
#     --security-opt seccomp=unconfined -v /run/desktop/mnt/host/wslg/.X11-unix:/tmp/.X11-unix \
#     -v /run/desktop/mnt/host/wslg:/mnt/wslg -e DISPLAY=:0 -e WAYLAND_DISPLAY=wayland-0 \
#     -e XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir -e PULSE_SERVER=/mnt/wslg/PulseServer \
#     --name languages-${USER} ${USER}/languages:`date '+%Y-%m-%d'`
