
#How does a gateway work?

A gateway is computer on the Freifunk network that announces that it can forward traffic into the Internet.
Our Freifunk network is IPv6 only, but since many services on the Internet do not not have IPv6 commectivity,
we employ a technique called DNS64 and NAT64 on the gateway.
IPv6 makes decentralized networks easier and is the future.

##What is DNS64?

On the Gateway runs a DNS server which always returns an IPv6 address.
If the target domain as a IPv6 address, it will be returned.
If there is onyl a IPv4 address available, a special IPv6 address is made up.
These special IPv6 address are contructed by using a special prefix (fdef:17a0:ffb1:1337::/64)
and adding the bytes of the IPv4 address to the end. We use the "bind" DNS server for this DNS64.
If the gateway itself has no IPv6 endpoint, all addresses will be constructed this way.

##What is NAT64?

NAT64 on the gateway translates all IPv6 packets using the special prefix to IPv4 packets.
The target IPv4 address extracted fro mthe IPv6 address of the packet.
For NAT64 we use the program called "tayga".

##What are IPv6 Router Advertisments?

This is similar to IPv4 DHCP, but more flexible. A host sends a request packet called IPv6 Router Solicitation
to all routers (to everyone who listens) and waits for incoming answers.
The answers are called Ipv6 Router Advertisments and includes a prefix and tells the receiver
if the sender is a gateway and what the DNS servers address is.
Usually the Gateways and DNS servers address are the same.
The prefix might be one for the internal network and/or a public prefix which allows
a host to give itself a public IP address. This will make a host reachable from the Internet.
Router Advertisments can be send out using the program called "radvd".

#Testing a gateway

To test a gateway in the Freifunk network, connect to the network and try the following steps.

##Test DNS64

Let's try to request the IPv6 address the IP address of a website that only can be reached using IPv4.
AAAA is a synonym for IPv6. We ask for an IPv6 address despite the fact that there is no offical entry.

    $ dig @fdef:17a0:ffb1:300::7 ipv4.whatismyv6.com AAAA
    
    ; <<>> DiG 9.9.5-9-Debian <<>> @fdef:17a0:ffb1:300::7 ipv4.whatismyv6.com AAAA
    ; (1 server found)
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52628
    ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    
    ;; QUESTION SECTION:
    ;ipv4.whatismyv6.com.           IN      AAAA
    
    ;; ANSWER SECTION:
    ipv4.whatismyv6.com.    10244   IN      AAAA    fdef:17a0:ffb1:1337::4275:2fd6
    
    ;; Query time: 150 msec
    ;; SERVER: fdef:17a0:ffb1:300::7#53(fdef:17a0:ffb1:300::7)
    ;; WHEN: Sat Mar 28 00:25:55 CET 2015
    ;; MSG SIZE  rcvd: 65

Since the website has no IPv6 addres/connectivity, the IPv6 address is constructed by the gateway
using a special prefix fdef:17a0:ffb1:1337::/64. The rest 4275:2fd6 is the IPv4 address.

Note:
  * hosts usually first try to request the IPv6 address or at least favor the IPv6 over an IPv4 address
  * when the gateway is has no native IPv6 endpoint, all connection are going through DNS64/NAT64
    * To access a computer on the Internet via IPv4 address, like "ping 8.8.8.8", is not possible the Router will discard the packet.

##Test IPv6 Router Advertisments

Send out a request for the gateways over the wireless interface called wlan0:

    $ rdisc6 -n wlan0
    Hop limit                 :           64 (      0x40)
    Stateful address conf.    :           No
    Stateful other conf.      :           No
    Router preference         :       medium
    Router lifetime           :          600 (0x00000258) seconds
    Reachable time            :  unspecified (0x00000000)
    Retransmit time           :  unspecified (0x00000000)
     Prefix                   : fdef:17a0:ffb1:300::/64
      Valid time              :        86400 (0x00015180) seconds
      Pref. time              :        14400 (0x00003840) seconds
     Prefix                   : 2001:bf7:1320:300::/64
      Valid time              :        86400 (0x00015180) seconds
      Pref. time              :        14400 (0x00003840) seconds
     Recursive DNS server     : fdef:17a0:ffb1:300::7
      DNS server lifetime     :          600 (0x00000258) seconds
     from fe80::ff:fe00:7

Among other replies, there should be a reply from the gateway we want to test.
The fe80::ff:fe00:7 address should be the link local (fe80:..) address
and the DNS server entry should contain the private (fdef:..) address of the gateway inside the Freifunk network.
Both addresses are assigned to bat0. The prefix must contain fdef:17a0:ffb1:300::/64 and can contain a public
prefix like 2001:bf7:1320:300::/64.

##Test Internet access

To actually test Internet connectivity. We must make sure that the default routing table contains
the default route pointing to the gateway.

    $ ip -6 r
    2001:bf7:1320:300::/64 dev wlan0  proto ra  metric 10 
    fdef:17a0:ffb1:300::/64 dev wlan0  proto ra  metric 10 
    fe80::/64 dev wlan0  proto kernel  metric 256 
    default via fe80::ff:fe00:7 dev wlan0  proto static  metric 1024

The defautl route will be set when the computer receives the IPv6 Router Advertisment packet.
Make sure it is the only default route, so to make sure we use this gateway.
Delete other default routes like this: "ip -6 route del default via fe80::ff:fe00:8 dev wlan0".

Now every Internet access should go trough the gateway.
Let's ping a native IPv6 server:

    $ ping6 2001:4860:4860::8888
    PING 2001:4860:4860::8888(2001:4860:4860::8888) 56 data bytes
    64 bytes from 2001:4860:4860::8888: icmp_seq=2 ttl=54 time=115 ms
    64 bytes from 2001:4860:4860::8888: icmp_seq=3 ttl=54 time=93.8 ms
    ^C
    --- 2001:4860:4860::8888 ping statistics ---
    3 packets transmitted, 2 received, 33% packet loss, time 2008ms
    rtt min/avg/max/mdev = 93.857/104.634/115.412/10.782 ms

Or access any website.
