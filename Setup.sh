#ubuntu:20.04
#name="Java Build Tools" \
#maintainer="Ravikishore <ravikishorefst@gmail.com>" \
#license="Apache-2.0" \
#version="latest" \
#summary="Convenient Docker image to build Java applications." \
#description="Convenient Docker image to build Java applications."
#================================================
# Customize sources for apt-get
#================================================
DISTRIB_CODENAME=$(cat /etc/*release* | grep DISTRIB_CODENAME | cut -f2 -d'=') \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME} main universe\n" > /etc/apt/sources.list \
    && echo "deb http://archive.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-updates main universe\n" >> /etc/apt/sources.list \
    && echo "deb http://security.ubuntu.com/ubuntu ${DISTRIB_CODENAME}-security main universe\n" >> /etc/apt/sources.list
apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install software-properties-common \
  && add-apt-repository -y ppa:git-core/ppa
#========================
# Miscellaneous packages
# iproute which is surprisingly not available in ubuntu:15.04 but is available in ubuntu:latest
# OpenJDK8
# rlwrap is for azure-cli
# groff is for aws-cli
# tree is convenient for troubleshooting builds
#========================
apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    azure-cli \
    iproute2 \
    openssh-client ssh-askpass\
    ca-certificates \
    gpg gpg-agent \
    openjdk-8-jdk \
    tar zip unzip \
    wget curl \
    git \
    build-essential \
    less nano tree \
    jq \
    python3 python3-pip groff \
    rlwrap \
    rsync \
  && apt-get clean \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

# Update pip after install
pip3 install --upgrade pip setuptools
pip3 install yq
#==========
# Maven
#==========
curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
MAVEN_HOME == /usr/share/maven

wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
  && unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip \
  && ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle \
  && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip
#==========
# Selenium
#==========
mkdir -p /opt/selenium \
  && wget --no-verbose http://selenium-release.storage.googleapis.com/$SELENIUM_MAJOR_VERSION/selenium-server-standalone-$SELENIUM_VERSION.jar -O /opt/selenium/selenium-server-standalone.jar
pip3 install -U selenium

#========================================
# Add normal user with passwordless sudo
#========================================
useradd jenkins --shell /bin/bash --create-home \
   && usermod -a -G sudo jenkins \
   && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'jenkins:secret' | chpasswd

#====================================
# AWS CLI
#====================================
pip3 install awscli
mkdir -p /home/jenkins/.local/bin/ \
  && ln -s /usr/local/bin/pip /home/jenkins/.local/bin/pip \
  && chown -R jenkins:jenkins /home/jenkins/.local
#====================================
# NODE JS
# See https://github.com/nodesource/distributions/blob/master/README.md
# See https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
#====================================
curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install -y nodejs \
    && apt-get clean
#====================================
# YARN, GRUNT, GULP
#====================================
npm install --global grunt-cli yarn gulp

#====================================
# Kubernetes CLI
# See https://storage.googleapis.com/kubernetes-release/release/stable.txt
#====================================
curl https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

#====================================
# OPENSHIFT V3 CLI
# Only install "oc" executable, don't install "openshift", "oadmin"...
# See https://github.com/openshift/origin/releases
#====================================
mkdir /var/tmp/openshift \
      && wget -O - "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" \
      | tar -C /var/tmp/openshift --strip-components=1 -zxf - \
      && mv /var/tmp/openshift/oc /usr/local/bin \
     && rm -rf /var/tmp/openshift

