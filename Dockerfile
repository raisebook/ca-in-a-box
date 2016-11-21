FROM alpine:latest

RUN apk --update add bash openssl

WORKDIR /root/ca

COPY templater.sh /usr/local/bin/
COPY tini-static /sbin/
COPY ca-in-a-box.sh /usr/local/bin/

RUN cd /root/ca && mkdir certs crl newcerts private && \
    chmod 700 private && \
    touch index.txt && \
    echo 1000 > serial

RUN mkdir -p intermediate/certs intermediate/crl intermediate/csr \
             intermediate/newcerts intermediate/private && \
    chmod 700 intermediate/private && \
    touch intermediate/index.txt && \
    echo 1000 > intermediate/serial && \
    echo 1000 > intermediate/crlnumber


VOLUME /root/cfg
COPY ./openssl.conf.tmpl /root/ca/openssl.conf.tmpl
COPY ./openssl-intermediate.conf.tmpl /root/ca/openssl-intermediate.conf.tmpl

ENTRYPOINT ["/sbin/tini-static", "--"]

CMD ["/usr/local/bin/ca-in-a-box.sh"]
