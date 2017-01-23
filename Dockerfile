FROM alpine:latest
MAINTAINER joff@joff.codes
ENTRYPOINT ["/sbin/tini-static", "--"]
CMD ["/usr/local/bin/ca-in-a-box.sh"]

RUN apk --update add bash openssl ca-certificates py2-pip
RUN pip install awscli

WORKDIR /root/ca

COPY templater.sh /usr/local/bin/
COPY tini-static /sbin/
COPY ca-in-a-box.sh export-root.sh _ca_functions.sh /usr/local/bin/

COPY ./openssl.conf.tmpl /root/openssl.conf.tmpl
COPY ./openssl-intermediate.conf.tmpl /root/openssl-intermediate.conf.tmpl

VOLUME /root/cfg
VOLUME /root/output
