ARG CADDY_BUILDER_VERSION=2.5.2
ARG CADDY_SECURITY_VERSION=v1.1.14
ARG ALPINE_VERSION=3.16.2

#Pull Caddy-Builder image to build custom version of Caddy with plugins
FROM caddy:${CADDY_BUILDER_VERSION}-builder AS builder

#Build custom version of Caddy with plugins
RUN xcaddy build \
    --with github.com/greenpau/caddy-security@${CADDY_SECURITY_VERSION} \
    --with github.com/greenpau/caddy-trace 

FROM alpine:${ALPINE_VERSION}

COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy
#Set relative folders
ENV XDG_CONFIG_HOME=/data \
    XDG_DATA_HOME=/config

#Add certs and tini
RUN apk add --no-cache \
    libc6-compat \
    ca-certificates \
    tini

# Create persistent data directories
RUN mkdir -p /etc/caddy \
    && mkdir -p /srv \
    && mkdir -p /data/caddy \
    && mkdir -p /config/caddy

# Add default config
ADD https://raw.githubusercontent.com/darox/caddy-security-rootless/main/Caddyfile /etc/caddy/Caddyfile

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home caddy \
    && chown -R caddy:caddy /usr/local/bin/caddy \
    && chown -R caddy:caddy /etc/caddy \
    && chown -R caddy:caddy /srv \
    && chown -R caddy:caddy /data \
    && chown -R caddy:caddy /config

ENTRYPOINT ["/sbin/tini", "--"]

USER caddy

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

EXPOSE 8080 9090

STOPSIGNAL SIGTERM
