ARG BASE_IMAGE=ghcr.io/linuxserver/baseimage-selkies:debiantrixie
FROM debian:trixie-slim AS ltfs-build
ARG LTFS_REF=v2.4.9.0-10523
ARG BUILD_JOBS=4
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates build-essential autoconf automake libtool pkg-config libicu-dev icu-devtools libxml2-dev uuid-dev libfuse-dev libsnmp-dev libssl-dev
RUN git clone --depth 1 --branch "$LTFS_REF" https://github.com/LinearTapeFileSystem/ltfs.git /tmp/ltfs && cd /tmp/ltfs && ./autogen.sh && ./configure --prefix=/opt/ltfs && make -j"$BUILD_JOBS" && make install
RUN git clone --depth 1 https://github.com/scsitape/stenc.git /tmp/stenc && cd /tmp/stenc && ./autogen.sh && ./configure --prefix=/opt/stenc && make -j"$BUILD_JOBS" && make install
FROM debian:trixie-slim AS dar-build
ARG DAR_VERSION=2.8.6
ARG DAR_SHA256=d56caeb6c86f751cb454d8fef45f3daecc508f208290d9f51e8c75bba5dc46c5
ARG BUILD_JOBS=4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl build-essential pkg-config libgcrypt20-dev libgpg-error-dev libbz2-dev liblzma-dev liblzo2-dev libzstd-dev libcurl4-openssl-dev libssl-dev libacl1-dev libattr1-dev libcap-dev zlib1g-dev libargon2-dev
RUN curl -fL --retry 5 "https://downloads.sourceforge.net/project/dar/dar/$DAR_VERSION/dar-$DAR_VERSION.tar.gz" -o /tmp/dar.tar.gz && echo "$DAR_SHA256  /tmp/dar.tar.gz" | sha256sum -c - && mkdir /tmp/dar && tar -xzf /tmp/dar.tar.gz -C /tmp/dar --strip-components=1 && cd /tmp/dar && ./configure --prefix=/opt/dar && make -j"$BUILD_JOBS" && make install
FROM ${BASE_IMAGE}
ENV TITLE="DAR Explorer / LTFS" PIXELFLUX_WAYLAND=false SELKIES_DESKTOP=false START_DOCKER=false NO_FULL=true PATH="/opt/dar/bin:${PATH}" LD_LIBRARY_PATH="/opt/dar/lib:/opt/ltfs/lib:/opt/stenc/lib"
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-gi gir1.2-gtk-4.0 gir1.2-vte-3.91 python3-cairo python3-gi-cairo fuse3 libfuse2t64 libicu76 libxml2-16 libsnmp40t64 mt-st lsscsi sg3-utils util-linux procps sudo libgcrypt20 libgpg-error0 libbz2-1.0 liblzma5 liblzo2-2 libzstd1 libcurl4t64 libssl3t64 libacl1 libattr1 libcap2 zlib1g libargon2-1 libmagic1t64 libgmp10 xdg-utils && rm -rf /var/lib/apt/lists/*
COPY --from=ltfs-build /opt/ltfs /opt/ltfs
COPY --from=ltfs-build /opt/stenc /opt/stenc
COPY --from=dar-build /opt/dar /opt/dar
COPY root/ /
COPY scripts/root-tape-command /usr/local/bin/root-tape-command
COPY scripts/start-dar-explorer /usr/local/bin/start-dar-explorer
RUN chmod 755 /usr/local/bin/root-tape-command /usr/local/bin/start-dar-explorer /defaults/autostart /defaults/autostart_wayland && for x in ltfs mkltfs mt stenc fusermount3 fusermount umount; do ln -s root-tape-command "/usr/local/bin/$x"; done && printf '/opt/dar/lib\n/opt/ltfs/lib\n/opt/stenc/lib\n' > /etc/ld.so.conf.d/dar-ltfs.conf && ldconfig && mkdir -p /ltfs /backup /restore /workspace/dar-explorer && python3 -c 'import gi; gi.require_version("Gtk","4.0"); gi.require_version("Vte","3.91"); from gi.repository import Gtk,Vte'
EXPOSE 3001
VOLUME /config
