#Ein Release fertig machen

Ein release besteht aus drei Schritten:
 * Images bauen
 * Manifest-Datei erstellen
 * Dateien auf den Update-Server kopieren

##Images bauen

Wie ein Image gebaut wird, wurde bereits beschrieben. Anstatt für jede Platform "Target Profile" und eventuell "Subtarget"
per "make menuconfig" von Hand zu selektieren, kann dies auch per Script geschehen:


```
#!/bin/sh

platforms='
	CONFIG_TARGET_ath25=y
	CONFIG_TARGET_ar71xx=y
	CONFIG_TARGET_brcm2708=y\nCONFIG_TARGET_brcm2708_bcm2708=y
	CONFIG_TARGET_brcm2708=y\nCONFIG_TARGET_brcm2708_bcm2709=y
	CONFIG_TARGET_bcm53xx=y
	CONFIG_TARGET_brcm47xx=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_rt305x=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_mt7620=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_mt7621=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_mt7628=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_rt3883=y
	CONFIG_TARGET_ramips=y\nCONFIG_TARGET_ramips_rt288x=y
'

#git clone ..

for platform in $platforms; do
	echo "$platform" > .config
	make defconfig
	platform_base="$(echo $platform | awk -F "=" '{print($1); exit;}')"
	models="$(grep $platform_base .config | awk '/^#/{print($2)}')"
	for model in $models; do
		rm -rf ./build_dir/target*
		# Select specific model
		echo "$platform" > .config
		echo "$model=y" >> .config
		echo "CONFIG_PACKAGE_freifunk-basic=y" >> .config

		# Debug output
		echo -e "Build:\n$(cat .config)"

		# Build image
		make defconfig
		make -j4
	done
done
```
*Achtung: Dieses Script funktioniert noch nicht korrekt und manchmal fehlen WLAN Treiber!*

Die Konfiguration für jedes Modell, neu zu generieren hat den Vorteil, das für jedes Model die Standardkonfiguration verwendet wird.
Ansonsten wird der kleinste gemeinsame Nenner der Platform genommen.
Übrigens, beide LEDE geht das wesentlich einfacher. "Target Profile" => "Multiple Devices", "Target Devices" =>  "Enable all profiles by default"  sowie "Use a per-device root filesystem ..." müssen aktiviert werden.

Die Images sollten dann irgendwann fertig sein.
Ein [Script](release_rename_images.sh) ermöglichst es, in den Namen der Image-Dateien z.B. ein 0.4.4-ffbi einzubauen.

Wenn der Linux Kernel vom Image startet, wird im Kernel Log (`dmesg`) der Name des Benutzer und Systems angezeigt, auf dem die Images
gebaut wurden. Mit einer [Änderung am System](kernel_email.md) kann dies z.B. auf die e-Mail-Adresse der Freifunk-Community gesetzt werden.


#Manifest-Datei erstellen

Die Manifest-Datei ist eine Textdatei und enthält den Namen der Imagedateien, die Firmwareversion, die Prüfsummen der Images
und digitale Unterschriften. Die digitalen Unterschriften stellen sicher, dass die Images autorisiert sind und nicht jemand
alle Router im Netz mit einem anderen Image flasht und damit kompromittiert.

##Erstellen der digitalen Signatur

Der Autoupdater Programm läuft auf dem Router und sucht in Intervallen unter angegebenen Adressen nach neuen Versionen der Firmware.
Wird eine gefunden, wird diese neue Firmware heruntergeladen und installiert. Die Router-Einstellungen bleiben erhalten. Ein Update sollte daher selten auffallen.

Um zu verhinden, dass andere Leute ein fremdes Images ins Netz stellen, werden die Images von einer oder mehreren Personen signiert.
Jede dieser Personen muss einen geheimen (secret key) und den dazugehörigen öffentlichen Schlüssel (public key) generieren.
Der öffentliche Schlüssel muss auf dem Router in der /etc/config/autoupdater eingetragen sein.

Zum Generieren eines Schlüsselpaares wird ecdsautils verwendet.

Installation:
```
sudo apt-get install cmake pkg-config g++

wget http://git.universe-factory.net/libuecc/snapshot/libuecc-7.zip
unzip libuecc-7.zip
cd libuecc-7
cmake .
make
make install
cd ..
rm -rf libuecc*

apt-get install pkg-config

wget https://github.com/tcatm/ecdsautils/archive/v0.3.2.zip -O ecdsautils-0.3.2.zip
unzip ecdsautils-0.3.2.zip
cd ecdsautils-0.3.2/
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake .
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

Auf dem Router sind in der Konfigurationsdatei /etc/config/autoupdater im Eintrag "mirror" die Adresse und Pfad eingetragen, unter dem die Images (und das sogenannte manifest) zu finden sein sollen.

#Manifest-Datei erstellen

Die Datei `manifest` sieht z.B. folgendermaßen aus:

```
BRANCH=stable

# model version sha512sum filename
tp-link-tl-wdr4300-v1 0.4 c300c2b80a8863506cf3b19359873c596d87af3183c4826462dfb5aa69bec7ce65e3db23a9f6f779fd0f3cc50db5d57070c2b62942abf4fb0e08ae4cb48191a0 gluon-0.4-tp-link-tl-wdr4300-v1-sysupgrade.bin

# after three dashes follow the ecdsa signatures of everything above the dashes
---
49030b7b394e0bd204e0faf17f2d2b2756b503c9d682b135deea42b34a09010bff139cbf7513be3f9f8aae126b7f6ff3a7bfe862a798eae9b005d75abbba770a
```
Zuerst müssen die drei Bindestriche und alles danach entfernt werden. Dann wird die Signatur dieser "rohen" Manifest-Datei erzeugt.

```
ecdsasign manifest < secret.key
```

Jede Signatur wird an das Manifest angehängt (eine Signatur pro Zeile).
Es muss eine ausreichende Anzahl von Signaturen (zwei oder mehr) vorliegen.
Nach der letzten Signatur folgt eine abschließende leere Zeile.
Um in Zukunft das Manifest zu aktualisieren, gibt es auch ein [Script](release_update_manifest.sh).

Hinweis:
 * Die Spalten im Manifest dürfen nur mit *einem* Leerzeichen getrennt werden.
 * Der Zeilenumbruch vor den drei Bindestrichen darf nicht entfernt werden, viele Editoren zeigen das nicht korrekt an.
 * Die Bezeichnung des Routermodells im Manifest (z.B. ,,tp-link-tl-wdr4300-v1") wird mit folgender Zeile erstellt:  
   ```cat /tmp/sysinfo/model | tr '[A-Z]' '[a-z]' | sed -r 's/[^a-z0-9]+/-/g;s/-$//'```
* sollte libuecc.so.0 nicht gefunden werden, dann funktioniert eventuell folgendes:  
   ```LD_PRELOAD="/usr/local/lib/libuecc.so" ecdsasign manifest < secret.key```

# Dateien auf den Update-Server kopieren

Die Datei `manifest` und die `*sysupgrade.bin` Dateien liegen alle in dem Verzeichnis,
das in der Firmware der Router in der Datei /etc/config/autoupdater angegeben wurde.

Ein Router wird mehrmals am Tag prüfen, ob unter der angegebenen Stelle ein manifest
verfügbar ist (siehe auch /etc/crontabs/root). Falls das der Fall ist und wenn die Versionsnummer höher ist, wird geschaut ob die Mindestanzahl
der geforderten Unterschriften vorhanden ist und mit den Unterschriften übereinstimmen. Stimmt alles, dann wird das passende image heruntergeladen,
die Prüfsumme überprüft und das Update angewendet. Der Router startet dann neu.
