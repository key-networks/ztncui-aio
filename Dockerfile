FROM debian:sid-slim AS builder
ENV NODEJS_MAJOR=14

ARG DEBIAN_FRONTEND=noninteractive
LABEL MAINTAINER="Key Networks https://key-networks.com"
LABEL Description="ztncui (a ZeroTier network controller user interface) + ZeroTier network controller"
ADD VERSION .

# BUILD ZTNCUI IN FIRST STAGE
WORKDIR /build
RUN apt update -y && \
    apt install curl gnupg2 ca-certificates zip unzip build-essential git --no-install-recommends -y && \
    curl -sL -o node_lts.sh https://deb.nodesource.com/setup_lts.x && \
    bash node_lts.sh && \
    apt install -y nodejs --no-install-recommends && \
    rm -f node_lts.sh && \
    git clone https://github.com/key-networks/ztncui && \
    npm install -g node-gyp pkg && \
    cd ztncui/src && \
    npm install && \
    pkg -c ./package.json -t "node${NODEJS_MAJOR}-linux-x64" bin/www -o ztncui && \
    zip -r /build/artifact.zip ztncui node_modules/argon2/build/Release

# BUILD GO UTILS
FROM golang:buster AS argong
WORKDIR /buildsrc
COPY argon2g /buildsrc/argon2g
COPY fileserv /buildsrc/fileserv
RUN mkdir -p binaries && \
    cd argon2g && \
    go mod download && \
    go build -ldflags='-s -w' -trimpath -o ../binaries/argon2g && \
    cd .. && \
    git clone https://github.com/jsha/minica && \
    cd minica && \
    go mod download && \
    go build -ldflags='-s -w' -trimpath -o ../binaries/minica && \
    cd .. && \
    git clone https://github.com/tianon/gosu && \
    cd gosu && \
    go mod download && \
    go build -o ../binaries/gosu -ldflags='-s -w' -trimpath && \
    cd .. && \
    cd fileserv && \
    go build -ldflags='-s -w' -trimpath -o ../binaries/fileserv main.go


# START RUNNER
FROM debian:sid-slim AS runner
RUN apt update -y && \
    apt install curl gnupg2 ca-certificates unzip supervisor net-tools procps --no-install-recommends -y && \
    groupadd -g 2222 zerotier-one && \
    useradd -u 2222 -g 2222 zerotier-one && \
    curl -sL -o ztone.sh https://install.zerotier.com && \
    bash ztone.sh && \
    rm -f ztone.sh && \
    apt clean -y && \
    rm -rf /var/lib/zerotier-one && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/key-networks/ztncui
COPY --from=builder /build/artifact.zip .
RUN unzip ./artifact.zip && \
    rm -f ./artifact.zip

COPY --from=argong /buildsrc/binaries/gosu /bin/gosu
COPY --from=argong /buildsrc/binaries/minica /usr/local/bin/minica
COPY --from=argong /buildsrc/binaries/argon2g /usr/local/bin/argon2g
COPY --from=argong /buildsrc/binaries/fileserv /usr/local/bin/gfileserv

COPY start_zt1.sh /start_zt1.sh
COPY start_ztncui.sh /start_ztncui.sh
COPY supervisord.conf /etc/supervisord.conf

RUN chmod 4755 /bin/gosu && \
    chmod 0755 /usr/local/bin/minica && \
    chmod 0755 /usr/local/bin/argon2g && \
    chmod 0755 /usr/local/bin/gfileserv && \
    chmod 0755 /start_*.sh

EXPOSE 3000/tcp
EXPOSE 3180/tcp
EXPOSE 8000/tcp
EXPOSE 3443/tcp

WORKDIR /
VOLUME ["/opt/key-networks/ztncui/etc"]
VOLUME [ "/var/lib/zerotier-one" ]
ENTRYPOINT [ "/usr/bin/supervisord" ]
