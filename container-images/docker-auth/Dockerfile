FROM golang:1.14-alpine AS builder

ARG VERSION=1.5.0

RUN set -ex && apk add --no-cache git make py2-pip && \
    pip install GitPython

RUN git clone https://github.com/cesanta/docker_auth.git && \
    cd docker_auth/auth_server && \
    git checkout "tags/${VERSION}" -b "${VERSION}" && \
    make deps && make generate && make

FROM r.spiarh.fr/alpine:latest

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/docker_auth/auth_server/auth_server /usr/local/bin/auth_server

EXPOSE 5001

USER 1871

ENTRYPOINT ["/usr/local/bin/auth_server"]

CMD ["/config/auth_config.yml"]
