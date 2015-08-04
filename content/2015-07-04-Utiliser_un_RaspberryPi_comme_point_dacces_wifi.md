Title: Utiliser un Raspberry Pi comme point d'accès Wifi
Date: 2015-07-04
Category: Blog
Tags: wifi, raspberrypi, linux, iptables

Dans cet article, nous verrons comment configurer un Raspberry Pi en tant que
point d'accès Wifi.

### Pré-requis

Je supposerai que vous avez à disposition :

 * [Un Raspberry Pi](https://www.raspberrypi.org/)
 * La distribution [Raspbian](https://www.raspbian.org/) ou toute autre
   distribution Linux
 * Un *dongle* Wifi (déjà installé et détecté)

Dans la suite, on considèrera que l'interface sans fil est nommée `wlan0`.  

### Définition d'une adresse IP statique

Dans le fichier `/etc/network/interfaces`, supprimer les lignes suivantes :

    iface wlan0 inet manual
    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

Les remplacer par :

    allow-hotplug wlan0
    iface wlan0 inet static
    address 192.168.100.1
    netmask 255.255.255.0

Redémarrez le réseau :

    sudo service networking restart

### Installation d'un serveur DHCP

Le serveur DHCP permet d'attribuer automatiquement une adresse IP aux machines
qui se connecteront à votre réseau Wifi.

Installez le paquet *[isc-dhcp-server](https://packages.debian.org/isc-dhcp-server)* :

    sudo apt-get install isc-dhcp-server

À ce stade, le service ne devrait pas démarrer correctement :

    Generating /etc/default/isc-dhcp-server...
    [FAIL] Starting ISC DHCP server: dhcpd[....] check syslog for diagnostics. ... failed!
     failed!
    invoke-rc.d: initscript isc-dhcp-server, action "start" failed.

Vous pouvez ignorer ces erreurs pour le moment.

Éditez le fichier de configuration du serveur : `/etc/dhcp/dhcpd.conf` et
commentez les options *domain-name* et *domain-name-servers* :

    #option domain-name "example.org";
    #option domain-name-servers ns1.example.org, ns2.example.org;

Décommentez la ligne *authoritative*. Cela permet d'indiquer à votre serveur
DHCP qu'il est le seul à fournir des adresses IP sur ce réseau et donc possède
la pleine connaissance des
[baux accordés](http://www.linux-france.org/prj/edu/archinet/systeme/ch27s03.html).

    # If this DHCP server is the official DHCP server for the local
    # network, the authoritative directive should be uncommented.
    authoritative;

Enfin, configurez le comportement du serveur DHCP :

    subnet 192.168.100.0 netmask 255.255.255.0 {
      range 192.168.100.10 192.168.100.50;
      option broadcast-address 192.168.100.255;
      option routers 192.168.100.1;
      default-lease-time 600;
      max-lease-time 7200;
      option domain-name "local";
      option domain-name-servers 80.67.169.12;
    }

Le paramètre *range* limite la place d'adresses IP qui seront alouées. On en
permet ici 51 : c'est probablement beaucoup (trop) s'il s'agit de votre réseau
personnel.

L'option *broadcast-address* spécifie l'adresse IP telle que les paquets qui
seront envoyés sur cette adresse seront interceptés par toutes les machines
présentes sur ce réseau (ayant donc une IP entre 192.166.100.1 et
192.168.100.254 car le masque de sous réseau est 255.255.255.0).

Quant à elle, l'option *routers* indique l'adresse de la passerelle, c'est à
dire la machine par laquelle passent tous les paquets sortants du réseau (en
direction ou en provenance d'Internet par exemple). 

On attribue ici un bail pour une durée de 600 secondes avec le paramètre
*default-lease-time*. C'est cette durée qui sera utilisée si le client ne
précise rien. S'il demande un bail en précisant une durée, celle-ci lui sera
accordée si elle ne dépasse pas 7200 secondes, comme défini avec le paramètre
*max-lease-time*.

Cet exemple utilise le DNS de [FDN](https://www.fdn.fr) (ligne *domain-name-servers*).
Vous pouvez bien évidemment en utiliser d'autres (certains préfèrent
[ceux de Google](https://developers.google.com/speed/public-dns/)...).

Déclarez enfin l'interface sans fil comme l'interface par défaut pour répondre
aux requêtes DHCP dans le fichier `/etc/default/isc-dhcp-server` :

    # On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
    #       Separate multiple interfaces with spaces, e.g. "eth0 eth1".
    #INTERFACES=""
    INTERFACES="wlan0"

### Installation de *hostapd*

[Hostapd](https://w1.fi/hostapd/) est un démon permettant de créer un point
d'accès sans fil. Pour l'installer :

    sudo apt-get install hostapd

Créez son fichier de configuration, `/etc/hostapd/hostapd.conf` :

    interface=wlan0
    driver=nl80211
    ssid=<YOUR SSID>
    hw_mode=g
    channel=6
    macaddr_acl=0
    auth_algs=1
    ignore_broadcast_ssid=0
    wpa=2
    wpa_passphrase=<YOUR PASSPHRASE>
    wpa_key_mgmt=WPA-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP

Remplacez dans cet exemple :

 * `<YOUR SSID>` par le nom que vous souhaitez donner à votre réseau ;
 * `<YOUR PASSPHRASE>` par le mot de passer permettant l'accès au réseau.

Déclarez enfin ce fichier afin qu'il soit utilisé par hostapd dans
`/etc/default/hostapd` en ajoutant la ligne :

    DAEMON_CONF="/etc/hostapd/hostapd.conf"

### Configuration du routage entre l'interface sans fil et l'interface filaire

Activer le routage IP dans le fichier `/etc/sysctl.conf` en décommentant la
ligne suivante :

    net.ipv4.ip_forward=1

Pour activer ce routage immédiatement (sans avoir besoin de redémarrer), lancez
la commande :

    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

Vous pouvez enfin configurer le routage en utilisant
*[iptables](http://ipset.netfilter.org/iptables.man.html)* :

    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

### Persistence des règles *iptables*

Les règles *iptables* définies précédemment sont perdues au au redémarrage. Pour
les recharger à chaque lancement de la machine, vous pouvez utiliser le paquet
*[iptables-persistent](https://packages.debian.org/iptables-persistent)*. Pour
l'installer :

    sudo apt-get install iptables-persistent

Par défaut, il demandera si vous souhaitez enregistrer les règles actuellement
définies. Choisissez « oui ». Si vous souhaitez les redéfinir ultérieurement,
vous pourrez les enregistrer en invoquant la cible *save* et les recharger avec
*reload* :

    sudo /etc/init.d/iptables-persistent save
    sudo /etc/init.d/iptables-persistent reload


### La voie est libre

À ce stade, vous deviez être en mesure de vous connecter au point d'accès de
façon transparente. Étant donnée la richesse des matériels et leurs
spécificités, je ne garantis pas que ce « mode d'emploi » soit universel.
J'espère néanmoins qu'il vous aura aidé en première approche à monter votre
propre point d'accès Wifi.
