FROM golang:latest
RUN go install github.com/brimdata/zed/cmd/zed@latest
RUN go install github.com/brimdata/zed/cmd/zq@latest
RUN useradd -m -s /bin/bash zed
RUN mkdir /zed
#RUN chown zed:zed /zed
COPY docker-entrypoint.sh /docker-entrypoint.sh
WORKDIR /zed
#USER zed
RUN ZED_LAKE=/zed/.zedlake zed init
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
