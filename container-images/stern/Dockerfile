ARG FROM_IMAGE_BUILDER
ARG FROM_IMAGE

FROM ${FROM_IMAGE_BUILDER} AS builder

ARG VERSION

RUN apk add --no-cache bash git make curl gcc

RUN curl -OL "https://github.com/stern/stern/archive/v${VERSION}.zip" && \
    unzip "v${VERSION}.zip" && cd "stern-${VERSION}" && \
    make build && mv dist/stern /go/bin/stern

FROM ${FROM_IMAGE}

LABEL maintainer="_me@spiarh.fr"

COPY --from=builder /go/bin/stern /usr/local/bin/stern

ENTRYPOINT ["/usr/local/bin/stern"]
