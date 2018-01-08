FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash build-essential dpkg git ssh sudo tzdata vim wget

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd ovpn --shell /bin/bash --groups sudo
RUN echo 'ovpn ALL = NOPASSWD: ALL' > /etc/sudoers.d/ovpn

ADD docker_tmp_data/* /home/ovpn/build/
RUN chown -R ovpn:ovpn /home/ovpn
USER ovpn
WORKDIR /home/ovpn/build
RUN ./openvpn.sh --init
WORKDIR /home/ovpn
