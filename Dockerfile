FROM lsiobase/alpine:3.6
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy prebuild files
COPY prebuilds/ /prebuilds/

# environment settings
ENV BOOKSONIC_OPT_PREFIX="subsonic"

# package settings
ARG BOOKSONIC_VER="1.1.Beta1"
ARG JETTY_VER="9.3.14.v20161028"

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	curl \
	tar \
	openjdk8 && \

# install runtime packages
 apk add --no-cache \
	ffmpeg \
	flac \
	lame \
	ttf-dejavu \
	openjdk8-jre && \

# install jetty-runner
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

# install booksonic
 mkdir -p \
	/app/booksonic && \
 curl -o \
 /app/booksonic/booksonic.war -L \
	"https://github.com/popeen/Popeens-Subsonic/releases/download/${BOOKSONIC_VER}/booksonic.war" && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 4040
VOLUME /books /config /podcasts
