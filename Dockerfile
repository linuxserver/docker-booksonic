FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BOOKSONIC_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# copy prebuild files
COPY prebuilds/ /prebuilds/

# environment settings
ENV BOOKSONIC_OPT_PREFIX="subsonic" \
LANG="C.UTF-8"

# package settings
ARG JETTY_VER="9.4.24.v20191120"

RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	--no-install-recommends \
	ca-certificates \
	ffmpeg \
	flac \
	fontconfig \
	jq \
	lame \
	openjdk-8-jre-headless \
	ttf-dejavu && \
 echo "**** fix XXXsonic status page ****" && \
 find /etc -name "accessibility.properties" -exec rm -fv '{}' + && \
 find /usr -name "accessibility.properties" -exec rm -fv '{}' + && \
 echo "**** install jetty-runner ****" && \
 mkdir -p \
	/tmp/jetty && \
 cp /prebuilds/* /tmp/jetty/ && \
 curl -o \
 /tmp/jetty/"jetty-runner-$JETTY_VER".jar -L \
	"https://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-runner/${JETTY_VER}/jetty-runner-{$JETTY_VER}.jar" && \
 cd /tmp/jetty && \
 install -m644 -D "jetty-runner-$JETTY_VER.jar" \
	/usr/share/java/jetty-runner.jar && \
 install -m755 -D jetty-runner /usr/bin/jetty-runner && \
 echo "**** install booksonic ****" && \
 if [ -z ${BOOKSONIC_RELEASE+x} ]; then \
	BOOKSONIC_RELEASE=$(curl -sX GET "https://api.github.com/repos/popeen/Booksonic-LegacyServer/releases/latest" \
	| jq -r '. | .tag_name'); \
 fi && \
 mkdir -p \
	/app/booksonic && \
 curl -o \
 /app/booksonic/booksonic.war -L \
	"https://github.com/popeen/Booksonic-LegacyServer/releases/download/${BOOKSONIC_RELEASE}/booksonic.war" && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 4040
VOLUME /config
