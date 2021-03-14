#!/usr/bin/env bash

source base.sh

case "$1"
    up)
        ip link add "$WIREGUARD_NAME" type wireguard || die

        wg set \
            private-key <(echo "$WIREGUARD_PRIVATE_KEY") \
            peer "$WIREGUARD_VPN_PUBLIC_KEY" \
                endpoint "$WIREGUARD_ENDPOINT" \
                allowed-ips "$WIREGUARD_ALLOWED_IPS" || die

        ip link set "$WIREGUARD_NAME" netns "$NETNS_NAME" || die

        # Addresses are comma-separated, so to split them.
        xargs -d ',' -I '{}' \
            ip -n "$NETNS_NAME" address add '{}' dev "$VPN_WIREGUARD_NAME" \
            <<<"$WIREGUARD_IP_ADDRESSES" || die

        ip -n "$NETNS_NAME" link set "$WIREGUARD_NAME" up || die
        ip -n "$NETNS_NAME" route add default dev "$WIREGUARD_NAME" || die
        ;;

    down)
        # We need to delete the WireGuard interface. It's initially created in
        # the init network namespace, then moved to the VPN namespace.
        # Depending how well the "up" operation went, it might be in either.
        ip -n "$NETNS_NAME" link delete "$WIREGUARD_NAME" ||
            ip link delete "$WIREGUARD_NAME" || die
        ;;
esac

