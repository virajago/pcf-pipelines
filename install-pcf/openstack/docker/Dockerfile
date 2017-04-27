FROM cloudfoundry/cflinuxfs2

RUN apt-get update
RUN apt-get -y install \
    python-pip \
    python3-dev \
    python-dev

RUN pip install \
    python-openstackclient \
    pytz \
    python-neutronclient

RUN wget https://github.com/pivotal-cf/om/releases/download/0.22.0/om-linux -O /usr/local/bin/om-tool
RUN wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.49/pivnet-linux-amd64-0.0.49 -O /usr/local/bin/pivnet-cli
RUN chmod 755 /usr/local/bin/om-tool
RUN chmod 755 /usr/local/bin/pivnet-cli
RUN om-tool --version
RUN pivnet-cli --version
   


