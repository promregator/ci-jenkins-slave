FROM ubuntu:16.04

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000


ENV JENKINS_HOME /var/jenkins_home

RUN groupadd -g ${gid} ${group}
RUN useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}
RUN echo "${user}:${password}" | chpasswd

RUN apt-get update && apt-get -y install -y \
    apt-transport-https \
    wget \
    curl \
    jq \
    git \
    vim \
    less \
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get -y install -y \
    maven \
    openjdk-8-jdk \
    openssh-server \
    ca-certificates \
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*


USER root

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D" ]


