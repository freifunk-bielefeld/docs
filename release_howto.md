#Ein Release fertig machen

Ein release besteht aus drei Schritten:
 * Images bauen
 * Manifest-Datei erstellen
 * Dateien auf den Update-Server kopieren

##Images bauen

Ein Image zu bauen wurde bereits geschrieben, nur das im Menü von "Target Profile" der Punkt "Default Target (all drivers)"
ausgewählt wird. Nach dem Bauen für verschiedene Plattformen ("Target System") sidn die Images fertig.

Wenn ein Linux Kernel startet wird im Kernel Log der Name des Benutzer und Systems angezeigt auf dem die Images
gebaut wurde. Mit einer temporären Änderung am System kann dies z.B. auf die email-Adresse der Freifunk-Community gesetzt werden.

#Manifest-Datei erstellen

Die Manifest-Datei ist eine Textdatei und enthält den Namen der Imagedateien, die Firmwareversion, die Prüfsummen der Images
und digitale Unterschriften. Die digitalen Unterschriften stellen sicher, das die Images autorisiert sind und nicht jemand
alle Router im Netz mit einem anderen Image flasht und damit kompromittiert.

##Erstellen der digitalen Signatur

Der Autoupdater ist ein Program das auf dem Router läuft und in intervallen unter einer angegebenen Adresse nach neuen Versionen der Fimrware sucht.
Wird eine gefunden wird eine neue Firmware heruntergeladen und installiert. Die Einstellungen bleiben erhalten. Ein Update sollte daher selten auffallen.

Um zu verhinden das andere Leute ein fremdes Images ins Netz stellen, werden die Images von einer oder mehreren Personen signiert.
Jede dieser Personen muss einen geheimen (secret key) und den dazugehörigen öffentlichen Schlüssel (public key) generieren.
Der öffentliche Schlüssel muss auf dem Router in der /etc/config/autoupdater eingetragen sein.

Zum generieren eines Schlüsselpaares wird ecdsautils verwendet.

Installation:
```
sudo apt-get install cmake pkg-config g++

wget http://git.universe-factory.net/libuecc/snapshot/libuecc-4.zip
unzip libuecc-4.zip
cd libuecc-4
cmake .
make
make install
cd ..
rm -rf libuecc*

apt-get install pkg-config

wget https://github.com/tcatm/ecdsautils/archive/v0.3.2.zip -O ecdsautils-0.3.2.zip
unzip ecdsautils-0.3.2.zip
cd ecdsautils-0.3.2/
cmake .
make
make install
cd ..
rm -rf ecdsautils*

ldconfig
```

Nun kann ein neues Schlüsselpaar (bestehend aus zwei Dateien) generiert werden:
```
ecdsakeygen -s > secret.key
ecdsakeygen -p < secret.key > public.key
```

Auf dem Router sind in der Konfigurationsdatei /etc/config/autoupdater im Eintrag ,,mirror" die Adresse und Pfad eingetragen unter dem die images (und das sogenannte manifest) zu finden sein sollen.

#Manifest-Datei erstellen

Die Datei manifest sieht z.B. folgendermaßen aus:

```
BRANCH=stable

# model version sha512sum filename
tp-link-tl-wdr4300-v1 0.4 c300c2b80a8863506cf3b19359873c596d87af3183c4826462dfb5aa69bec7ce65e3db23a9f6f779fd0f3cc50db5d57070c2b62942abf4fb0e08ae4cb48191a0 gluon-0.4-tp-link-tl-wdr4300-v1-sysupgrade.bin

# after three dashes follow the ecdsa signatures of everything above the dashes
---
49030b7b394e0bd204e0faf17f2d2b2756b503c9d682b135deea42b34a09010bff139cbf7513be3f9f8aae126b7f6ff3a7bfe862a798eae9b005d75abbba770a
```
Die Signatur wird erzeugt indem die drei Bindestriche und alles danach entfernt wird. Damit wird dann die Signatur erzeugt.

```
ecdsasign manifest < secret.key
```

Jede Signatur wird an das Manifest angehängt (eine Signatur pro Zeile).
Die Signaturen von allen Personen werden an das Manifest angehängt.
Nach der letzten Signatur folgt eine abschließenden leere Zeile.

Hinweis:
 * Die Spalten im manifest dürfen nur mit *einem* Leerzeichen getrennt werden
 * der Zeilenumbruch vor den drei Bindestrichen darf nicht entfernt werden, viele Editoren machen zeigen das nicht korrekt an
 * Die Bezeichnung des Routermodells im Manifest (z.B. ,,tp-link-tl-wdr4300-v1") wir mit folgender Zeile erstellt:  
   ```cat /tmp/sysinfo/model | tr '[A-Z]' '[a-z]' | sed -r 's/[^a-z0-9]+/-/g;s/-$//'```

# Dateien auf den Update-Server kopieren

Die Datei `manifest` und die ganzen `*sysupgrade.bin` Images liegen alle in einem Verzeichnis
das in der Firmware der Router in der Datei /etc/config/autoupdater angegeben wurde.

Ein Router wird mehrmals am Tag schauen ob unter der angegebenen Stelle ein manifest
verfügbar ist. Wenn ja, und wenn die Version neuer ist, wird geschaut ob die Mindestanzahl
der geforderten validen Unterschriften vorhanden ist. Wenn ja, dann wird das passende image heruntergeladen,
die Prüfsumme überprüft und das Update angewendet.
