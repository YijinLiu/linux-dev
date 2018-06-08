FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash ca-certificates dpkg git \
        sudo tzdata && \
    echo America/Los_Angeles > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

ARG NAME
ADD docker_tmp_data/opencl.sh /home/$NAME/build/
ARG UID
ARG GID
RUN groupadd -g $GID $NAME && \
    useradd -u $UID -g $NAME --groups sudo --shell /bin/bash $NAME && \
    echo "$NAME ALL = NOPASSWD: ALL" > /etc/sudoers.d/$NAME && \
    chown -R $NAME:$NAME /home/$NAME
USER $NAME
WORKDIR /home/$NAME
RUN cd build && ./opencl.sh && cd .. && sudo rm -rf build
