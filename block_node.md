# Wie einen problematischen Knoten blockieren

Es kann passieren, dass ein Knoten das Netz stört
und irgendwie geblockt werden muss.
Dieser Ansatz funktioniert nur, wenn alle Serverbetreiber
kooperieren.

Der Vorgang besteht aus drei Schritten:
 * Herausfinden der öffentlichen IP Adresse des Knotens
 * Finden des fastd-Schlüssels, den der Knoten verwendet
 * Blocken des fastd-Schlüssels auf allen Servern

Zuallererst ist oft nur die interne IP-Adresse des problematischen Knotens bekannt.
Man beginnt mit einem Server. Optimalerweise einer, mit dem sich der Knoten verbunden hat.
Auf diesem Server werden z.B. mit ping viele Daten in Richtung dieses Knotens gesendet.

```
ping -i 0.0001 -s 12000 <node_adresse>
```

Geht der meiste Traffic nun zu der Adresse X im Internet,
dann ist das mit hoher Wahrscheinlichkeit der gesuchte Knoten,
bzw. der zugehörige Internetanschluss.

Die gesuchte Adresse kann mit itop oder tcpdump auf dem
Internetanschluss des Servers (oft eth0) ausgemacht werden

Stellt es sich heraus, das es sich um einen anderer Server handelt,
so muss der Vorgang auf diesem wiederholt werden.

Irgendwann ist die Addresse des Internetanschlusses, über die der Knoten verbunden ist,
gefunden. Dann kann über den Status-Socket von fastd der fastd-Schlüssel herausgesucht
werden, den der Knoten verwendet.

Ein Status-Socket steht zur Verfügung, wenn fastd entweder mit z.B. ```--status-socket /var/run/fastd.sock```
gestartet wurde, oder in der fastd.conf eine Zeile mit ```status socket "/var/run/fastd.sock";``` enthalten ist.

Der (Unix-) Socket läßt sich dann z.B. mit socat auslesen:

```
socat - UNIX-CONNECT:/tmp/fastd.sock
```

Der fastd-Schlüssel muss nun auf allen Servern gesperrt werden:

/etc/fastd/fastd.conf
```
on verify "[ $PEER_KEY != X ]";
```

(X sei hier der Schlüssel der gesperrt werden soll)
