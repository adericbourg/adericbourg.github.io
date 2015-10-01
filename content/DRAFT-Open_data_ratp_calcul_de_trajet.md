Title: Calcul d'itinéraire à partir des données RATP
Date: 2015-09-12
Category: Blog
Tags: opendata, ratp
Status: draft

La RATP progresse dans l'[ouverture de ses données](http://data.ratp.fr) et même si elle ne propose pas encore un accès à son [système SIEL](https://fr.wikipedia.org/wiki/Syst%C3%A8me_d'information_en_ligne), elle propose néanmoins les données de son offre de transport au [format GTFS](https://developers.google.com/transit/gtfs/). Une bonne occasion de s'initier au calcul d'itinéraire !

### Format des données

Le format GTFS est un standard et la RATP se conforme à ce standard, simple et bien documenté. Nous n'en retiendrons que certains en première approche.

#### routes.txt

Le fichier décrit le nom et la direction des routes. Une route est assimilable à un trajet (origine - destination).

Prenons l'exemple de la ligne 13 du métro parsien dont le plan simplifié est représenté sur la figure ci-dessous. Cette ligne est parcourue par quatre routes :

* Châtillon - Montrouge en direction de Saint-Denis Université ;
* Châtillon - Montrouge en direction de Gennevilliers Les Courtilles ;
* Saint-Denis Université en direction de Châtillon - Montrouge ;
* Gennevilliers Les Courtilles en direction de Châtillon - Montrouge.

![Plan simplifié de la ligne 13 du métro parisien](/images/connection_scan_algorithm/ligne13.png){.center}

Le fichier `routes.txt` contient pour cette ligne :

```
route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color
1197620,100,"13","(CHATILLON - MONTROUGE <-> ST-DENIS-UNIVERSITE/LES COURTILLES) - Aller",,1,,FFFFFF,000000
1197621,100,"13","(CHATILLON - MONTROUGE <-> ST-DENIS-UNIVERSITE/LES COURTILLES) - Aller",,1,,FFFFFF,000000
1197622,100,"13","(CHATILLON - MONTROUGE <-> ST-DENIS-UNIVERSITE/LES COURTILLES) - Retour",,1,,FFFFFF,000000
1197623,100,"13","(CHATILLON - MONTROUGE <-> ST-DENIS-UNIVERSITE/LES COURTILLES) - Retour",,1,,FFFFFF,000000
```

#### stops.txt

Ce fichier liste les arrêts avec, éventuellement, quelques informations complémentaires. La RATP fournit l'adresse la plus proche de l'arrêt ainsi que les coordonnées GPS de son centre (dans le cas d'une station qui dispose de plusieurs sorties). À noter que ce fichier n'est pas ordonné selon le sens de parcours des missions sur la ligne.

Exemple des quatre premières stations de la ligne 13 :

```
stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,location_type,parent_station
2397,,"Pernety","Raymond Losserand (72 rue) - 75114",48.833933819810916,2.31790897216328,0,
1969,,"Châtillon Montrouge","République (220 avenue de la) - 92020",48.810283363510756,2.3012888709759522,0,
2406,,"Place de Clichy","Clichy (terre-plein face au 7 place de) - 75109",48.883203999876585,2.3272660246411383,0,
...
```

#### trips.txt

Ce fichier liste les courses et les associe à une route. Nous reviendrons sur son utilité en observant les horaires d'arrêt.

Exemple sur la ligne 13 :

```
route_id,service_id,trip_id,trip_headsign,trip_short_name,direction_id,shape_id
1197620,1762288,10017622880912413,101,101,0,
1197620,1762289,10017622890912413,101,101,0,
1197620,1762292,10017622920912413,101,101,0,
...
```

#### stops_times.txt

Ce fichier présente les horaires des courses aux stations (points d'arrêt). Ce fichier est trié par course et par heure d'arrêt en station.

Un détail est à noter quant aux horaires : ceux-ci sont fournis pour la journée qui peut se terminer... le lendemain. Un métro circulant le dimanche à 1h du matin sera en réalité rattaché à la journée du samedi. Ainsi, son horaire ne sera pas « à 1h le dimanche» mais « à 25h le samedi ». Bien que cette astuce puisse sembler tordue, elle simplifie en pratique beaucoup de choses, notamment pour maintenir la continuité des missions : il serait absurde de scinder la mission d'un train sous prétexte qu'il roule à cheval sur deux jours calendaires.

Exemple pour la ligne 13 :
```
trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,shape_dist_traveled
10017622880912413,19:38:00,19:38:00,1969,1,,
10017622880912413,19:40:00,19:40:00,1880,2,,
10017622880912413,19:41:00,19:41:00,1879,3,,
```

Dans cet exemple, pour la course présentée, le véhicule s'arrête à 19:38:00 à l'arrêt 1969 (Châtillon - Montrouge) et en repart à la même heure. On en déduira qu'on ne prend vraisemblabement pas en compte le temps d'arrêt en station. Il arrive ensuite à la station 1880 (Malakoff - Rue Etienne Dolet) à 19:40:00, puis à la station 1879 (Malakoff - Plateau de Vanves) à 19:41:00, etc.

### Calcul d'itinéraire

L'histoire et le contexte des calculs d'itinéraires est très bien synthétisé par [Tristram Gräbener](https://twitter.com/tristramg) dans son [Petit historique du calcul d'itinéraire](http://blog.tristramg.eu/petit-historique-du-calcul-ditineraire.html). Probablement plus hipster que je ne veux bien l'admettre, j'ai choisi d'utiliser le plus récent : le *[Connection Scan Algorithm](http://i11www.iti.uni-karlsruhe.de/extra/publications/dpsw-isftr-13.pdf)*.

Cet algorithme, tenant en quelques lignes, se « contente » de parcourir une table horaire précalculée des connexions entre les stations et de retenir la solution optimale en temps de trajet. Une connexion représente une possibilité de trajet entre deux stations. On la modélise donc par un quadruplet contenant la station de départ, la station d'arrivée, l'heure de départ et l'heure d'arrivée. La table horaire devient alors simplement une liste de ces connexions triées par heure de départ croissante.
