FROM ubuntu:16.04
MAINTAINER Chorke, Inc.<devs@chorke.org>

ENV container=docker
ADD assets /root/.docker
RUN /root/.docker/setup.sh

EXPOSE 22 80 88 389 636 750 749

CMD /usr/sbin/startup.sh && /usr/sbin/sshd -D
