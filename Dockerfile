FROM debian:bullseye
ARG WRT_DEPENDENCIES=""
RUN apt update -y && apt install -y \
	build-essential file g++ gawk gettext git \
	libssl-dev python3-distutils rsync unzip vim wget \
	$WRT_DEPS

RUN useradd -m -s /bin/bash build
USER build
RUN mkdir /home/build/wrt
WORKDIR /home/build/wrt

ARG WRT_FIRMWARE_REPO=""
ARG WRT_BRANCH=""
RUN git clone -b "$WRT_BRANCH" --single-branch "$WRT_FIRMWARE" .
RUN ./scripts/feeds update -a && ./scripts/feeds install -a

COPY build.sh .
ENTRYPOINT [ "/bin/bash", "/home/build/wrt/build.sh" ]
