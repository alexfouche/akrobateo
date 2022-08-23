# forked from https://github.com/kontena/akrobateo/tree/master/lb-image
# and updated from https://github.com/k3s-io/klipper-lb/blob/master/package/Dockerfile

FROM alpine:3.15.4

RUN apk add -U --no-cache iptables ip6tables sudo

RUN addgroup akrobateo && \
    adduser -G akrobateo -H -s /sbin/nologin -D akrobateo && \
    echo "akrobateo ALL=(root) NOPASSWD: /sbin/iptables /sbin/ip6tables" > /etc/sudoers.d/akrobateo

ADD entrypoint.sh /entrypoint.sh

USER akrobateo

CMD ["/entrypoint.sh"]
