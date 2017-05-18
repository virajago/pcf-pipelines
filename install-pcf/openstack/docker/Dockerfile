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
