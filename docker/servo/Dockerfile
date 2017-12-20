FROM ubuntu:16.04

RUN apt update && \
    apt install -y --no-install-recommends bash build-essential dpkg git ssh sudo tzdata vim wget

RUN echo America/Los_Angeles > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd servo --shell /bin/bash --groups sudo
RUN echo 'servo ALL = NOPASSWD: ALL' > /etc/sudoers.d/servo

ADD docker_tmp_data/* /home/servo/build/
RUN chown -R servo:servo /home/servo
USER servo
WORKDIR /home/servo/build
RUN ./build_servo.sh
WORKDIR /home/servo
