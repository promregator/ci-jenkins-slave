FROM ubuntu:16.04

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

USER root

ENV JENKINS_HOME /var/jenkins_home

COPY credentials/jenkins.creds /tmp/jenkins.creds

RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
	&& cat /tmp/jenkins.creds | chpasswd \
	&& rm -f /tmp/jenkins.creds

# Prepare install of CF CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add - && \
	echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list

RUN apt-get update && apt-get -y install -y \
    apt-transport-https \
    wget \
    curl \
    jq \
    git \
    vim \
    less \
    ca-certificates \
    software-properties-common \
    golang \
    cf-cli \
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*


# for installation of docker client, please also see
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
	add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"


RUN apt-get update && apt-get -y install -y \
    maven \
    openjdk-8-jdk \
    openssh-server \
    docker-ce \
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*

# see also https://github.com/ansible/ansible-container/issues/141
RUN mkdir -p /var/run/sshd

# Install github cli
# see also https://hub.github.com/
COPY data/hub.profile.sh /etc/profile.d/

RUN mkdir /tmp/hub && cd /tmp/hub && \
	git clone https://github.com/github/hub.git . && \
	chmod +x script/build && \
	script/build -o /opt/hub && \
	chmod +x /etc/profile.d/hub.profile.sh

USER root

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D" ]


