FROM lsiobase/alpine:3.5
MAINTAINER sparklyballs

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# copy prebuild files
COPY prebuilds/ /prebuilds/

# package version settings
ARG BOOKSONIC_VER="1.1.Beta1"

# environment settings
ENV BOOKSONIC_OPT_PREFIX="subsonic"

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	curl \
	openjdk8 \
	tar && \

# install runtime packages
 apk add --no-cache \
	ffmpeg \
	flac \
	lame \
	openjdk8-jre \
	ttf-dejavu && \

# install jetty-runner
 JETTY_VER=$(curl -v --silent \
	https://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-runner/maven-metadata.xml 2>&1 \
	| grep \<release\> | cut -f2 -d">"|cut -f1 -d"<") && \
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
