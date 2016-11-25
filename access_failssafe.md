# Den Failsafe-Modus nutzen

Wenn man sich aus irgendeinem Grund aus dem Router ausgeschlossen hat,
hilft der sogenannte Failsafe-Modus, um die Einstellungen des Routers
zurückzusetzen, zu reparieren oder ein komplett neues Image einzuspielen.
Im Failsafe-Modus läuft der Router mit minimalen Einstellungen und ignoiriert
alle Änderungen am System.

Dabei handelt es sich um einen Mechanismus der in OpenWrt eigebaut ist.
Daher ist auch die [Anleitung](http://wiki.openwrt.org/de/doc/howto/generic.failsafe) von OpenWrt zu empfehlen.

Zum Aktivieren muss der Router aus- und wieder angestellt werden.
Während des Neustarts des Routers muss dabei zum richtigen Zeitpunkt
der Reset-Knopf betätigt werden. Ein mehrfaches betätigen ist daher zu
empfehlen, um den richtigen Zeitpunkt nicht zu verpassen.
Sonst heißt es Neustarten und wieder probieren.

Ist im richtigen Moment der Failsafe aktiviert worden, blinkt sofort eine der LEDs
am Gerät ca. 5 mal die Sekunde.

Als nächstes muss der eigene Computer mit dem Router per Netzwerkkabel
verbunden werden und dem Computer manuell die IP Adresse 192.168.1.2 (oder höher) gegeben werden.

Nun kann man sich per Telnet auf dem Router einloggen:
```
telnet 192.168.1.1
```

Normalerweise sollte jeder der LAN-Anschlüsse funktionieren.
Bei einigen Modellen funktioniert das jedoch nur der WAN-Anschluss.
Ist der Failsafe aktiviert, muss dann probiert werden.

##Router Zurücksetzen
Soll nun der Router zurückgesetzt werden reicht es den Befehl `firstboot` auszuführen,
die Sicherheitsabfrage zu bestätigen und den Router neu zu starten.

##Konfiguration Reparieren

Um Einstellungen zu ändern müssen diese zuerst wieder mit dem Befehl `mount_root`
zugänglich gemacht werden:
```
mount_root
```

Nun kann mit dem Editor `vi`, die Datei auf dem Router editiert/repariert werden, z.B.:

```
vi /etc/config/network
```

Die Bedienung von `vi` ist jedoch gewöhnungsbedürftig. Eine Anleitung
für Neulinge wird empfohlen.

##Neues Image einspielen

Um ein neues Image aufzuspielen, muss dieses auf den Router in das Verzeichnis
/tmp kopiert werden. Dieses Verzeichnis ist Teil des RAM-Speichers und hat genug Platz.

Dafür eigenen sich zwei Ansätze:
- kopieren per SCP bzw. PuTTY
- kopieren mit wget und eigenem Webserver

PuTTY bietet sich bei Windows-Systemen an, wget bei Linux-Systemen.

###Kopieren per PuTTY

Um sich mit PuTTY zu verbinden, wird über die bestehende Konsole (z.B. wie oben beschrieben per telnet)
der SSH-Server auf dem Router gestartet:

```
/etc/init.d/dropbear start
```

Nun sollte ein Zugang per PuTTY möglich sein. Die Zieladresse ist 192.168.1.1, der Benutzername root 
und das Passwortfeld muss leer gelassen werden.

Mit PuTTY kann jetzt auch per SCP (Secure Copy) das neue Image vom eigen Rechner in das Verzeichnis /tmp
des Routers kopiert werden können.

###Kopieren mit wget

Funktioniert die Methode mit PuTTY/SCP nicht, kann lokal ein Webserver gestartet werden.
Ein einfacher Webserver kann gestartet werden, indem im Verzeichnis mit dem neuen Image,
der Python Web-Server gestartet wird:

```
python -m SimpleHTTPServer
```

Auf dem Router kann das Image nun per wget heruntergeladen werden (hier für einen wr1043 v1):
```
cd /tmp/
wget http://192.168.1.2:8000/openwrt-ar71xx-generic-tl-wr1043nd-v1-squashfs-sysupgrade.bin
```

###Flashen
Ist das neue Image auf dem Router, kann nun geflasht werden:
```
sysupgrade -n openwrt-ar71xx-generic-tl-wr1043nd-v1-squashfs-sysupgrade.bin
```

Der Router sollte nun mit dem neuen Image geflasht werden und dann neu starten.
