FROM debian:bullseye
RUN apt update -y &&\
    apt install build-essential ccache ecj fastjar file g++ gawk \
    gettext git java-propose-classpath libelf-dev libncurses5-dev \
    libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
    python3-distutils python3-setuptools python3-dev rsync subversion \
    swig time xsltproc zlib1g-dev -y
RUN useradd -m -s /bin/bash build
USER build
RUN mkdir /home/build/openwrt
WORKDIR /home/build/openwrt
ENTRYPOINT [ "/bin/bash", "/home/build/openwrt/build.sh" ]
