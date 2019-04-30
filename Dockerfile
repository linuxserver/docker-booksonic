FROM lsiobase/ubuntu:bionic as buildstage

# version tag
ARG BOOKSONIC_RELEASE

RUN \
 echo "**** install build packages ****" && \
 apt-get update && \
 apt-get install -y \
        git \
        jq \
        openjdk-8-jdk && \
 apt-get install -y \
        --no-install-recommends \
	maven 
RUN \
 echo "**** Get and checkout source at version ****" && \
 if [ -z ${BOOKSONIC_RELEASE+x} ]; then \
	BOOKSONIC_RELEASE=$(curl -sX GET "https://api.github.com/repos/popeen/Popeens-Subsonic/releases/latest" \
	| jq -r '. | .tag_name'); \
 fi && \
 git clone https://github.com/popeen/Popeens-Subsonic.git /booksonic && \
 cd /booksonic && \
 git checkout ${BOOKSONIC_RELEASE}

RUN \
 echo "**** build war ****" && \
 cd /booksonic && \
 mvn clean package

# runtime stage
FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballsi,thelamer"

# copy prebuild files
COPY prebuilds/ /prebuilds/

# environment settings
ENV BOOKSONIC_OPT_PREFIX="subsonic" \
LANG="C.UTF-8"

# package settings
ARG JETTY_VER="9.3.14.v20161028"

RUN \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	--no-install-recommends \
	ca-certificates \
	ffmpeg \
	flac \
	fontconfig \
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
 mkdir -p \
	/app/booksonic && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /
COPY --from=buildstage /booksonic/subsonic-main/target/booksonic.war /app/booksonic/booksonic.war

# ports and volumes
EXPOSE 4040
VOLUME /books /config /podcasts
