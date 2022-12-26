FROM ubuntu:22.04

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

USER root

ENV JENKINS_HOME /var/jenkins_home

# TZdata needs to be configured to run apt-get properly
# see also https://rtfm.co.ua/en/docker-configure-tzdata-and-timezone-during-build/
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY credentials/jenkins.creds /tmp/jenkins.creds

RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && chown g+w
	&& cat /tmp/jenkins.creds | chpasswd \
	&& rm -f /tmp/jenkins.creds

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
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*


# Preparation of install of CF CLI
# Warning! wget required (thus needs to be in a own block)
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add - && \
	echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list

# for installation of docker client, please also see
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
	add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	   $(lsb_release -cs) \
	   stable"


# NB: Golang required for github cli
RUN apt-get update && apt-get -y install -y \
    maven \
    golang-1.18-go \
    openjdk-17-jdk \
    openssh-server \
    docker-ce \
    cf-cli \
    && apt-get -q autoremove \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/*

# see also https://github.com/ansible/ansible-container/issues/141
RUN mkdir -p /var/run/sshd

# Fix missing host keys
RUN /usr/bin/ssh-keygen -A

# Install go 1.18, which is required to install github cli
ENV PATH "$PATH:/usr/lib/go-1.18/bin"

# Install github cli
# see also https://hub.github.com/
RUN mkdir /tmp/hub && cd /tmp/hub && \
	git clone https://github.com/github/hub.git . && \
	chmod +x script/build && \
	script/build -o /opt/github/hub && \
	rm -rf /tmp/hub

# Necessary (fake) environment options to permit tests for Docker Image script (see also a0dd11362fc286305d95e9ba3d35a59f15d76624 in promregator/promregator)
RUN mkdir -p /home/promregator /run/secrets && \
        chown ${user}:${group} /home/promregator /run/secrets

ENV PATH "$PATH:/opt/github"

ENV JAVA_HOME "/usr/lib/jvm/java-17-openjdk-amd64"

USER root

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D" ]


