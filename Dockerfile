FROM debian:bullseye

ARG WRT_DEPENDENCIES=""

RUN apt update -y && apt install -y \
	build-essential file g++ gawk gettext git \
	libssl-dev python3-distutils rsync unzip vim wget \
	$WRT_DEPENDENCIES

ARG USERNAME=""
ARG USERID=""
ARG USERDIR=/home/build
ARG WORKDIR="$USERDIR/wrt"

RUN useradd -m -d "$USERDIR" -u "$USERID" -s /bin/bash "$USERNAME"
USER "$USERNAME"
WORKDIR "$WORKDIR"

ARG WRT_FIRMWARE_REPO=""
ARG WRT_BRANCH=""

RUN git clone -b "$WRT_BRANCH" --single-branch "$WRT_FIRMWARE_REPO" .
RUN ./scripts/feeds update -a && ./scripts/feeds install -a

# COPY build.sh .
ENTRYPOINT [ "/bin/bash", "build.sh" ]
