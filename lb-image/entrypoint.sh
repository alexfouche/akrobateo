#!/bin/sh

# forked from https://github.com/kontena/akrobateo/tree/master/lb-image
# and updated from https://github.com/k3s-io/klipper-lb/blob/master/entry

set -e -u

trap exit TERM INT

echo "Setting up forwarding from port $SRC_PORT to $DEST_IP:$DEST_PORT/$DEST_PROTO"

# Setup the actual forwarding
if echo ${DEST_IP} | grep -Eq ":"
then
    if [ `cat /proc/sys/net/ipv6/conf/all/forwarding` != 1 ]; then
        echo "forwarding is not enabled"
        exit 1
    fi
    ip6tables -t nat -I PREROUTING ! -s ${DEST_IP}/128 -p ${DEST_PROTO} --dport ${SRC_PORT} -j DNAT --to [${DEST_IP}]:${DEST_PORT}
    ip6tables -t nat -I POSTROUTING -d ${DEST_IP}/128 -p ${DEST_PROTO} -j MASQUERADE
else
    if [ `cat /proc/sys/net/ipv4/ip_forward` != 1 ]; then
        echo "ip_forward is not enabled"
        exit 1
    fi
    iptables -t nat -I PREROUTING ! -s ${DEST_IP}/32 -p ${DEST_PROTO} --dport ${SRC_PORT} -j DNAT --to ${DEST_IP}:${DEST_PORT}
    iptables -t nat -I POSTROUTING -d ${DEST_IP}/32 -p ${DEST_PROTO} -j MASQUERADE
fi

echo "Forwarding set up succesfully, taking Cinderella nap..."

if [ ! -e /tmp/pause ]; then
    mkfifo /tmp/pause
fi
</tmp/pause &
wait $!
