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

#### transfers.txt

`transfers.txt` regroupe les correspondances entre plusieurs points d'arrêt.

Pour prendre un exemple :
```
from_stop_id,to_stop_id,transfer_type,min_transfer_time
4211780,2270,2,212
4472773,1724,2,228
3619167,2276,2,252
```

Prenons la première ligne : la correspondance se fait entre l'arrêt « 4211780 » et l'arrêt « 2270 ». Un recherche dans le fichier `stops.txt` permet de donner un nom humainement compréhensible à ces identifiants : ils correspondent ici tous les deux au point d'arrêt « Mairie de Saint-Ouen ».

À partir du l'identifiant d'un point d'arrêt, on peut également ressortir les identifiants de course (`trip_id`). Prenons-en un au hasard :

```
$ grep 2270 stop_times.txt | cut -d, -f1 | head -n1
10017622880912417
```

À partir de cet identifiant, on peut retrouver la route associée (`route_id`) :

```
$ grep 10017622880912417 trips.txt | cut -d, -f1
1197623
```

On trouve donc qu'il s'agissait (encore...) de la ligne 13 dans le sens « retour » :

```
$ grep ^1197623, routes.txt
1197623,100,"13","(CHATILLON - MONTROUGE <-> ST-DENIS-UNIVERSITE/LES COURTILLES) - Retour",,1,,FFFFFF,000000
```

Vérifions par acquit de conscience l'autre identifiant de point d'arrêt :

```
$ grep 4211780 stop_times.txt | cut -d, -f1 | head -n1
119841521246955
$ grep 119841521246955 trips.txt
1364288,1984152,119841521246955,,1,1,
$ grep 1364288 routes.txt
1364288,100,"N44","(GARGES-SARCELLES RER <-> GARE DE L'EST) - Retour",,3,,FFFFFF,000000
```

Il s'agit donc du [Noctilien N44](http://www.ratp.fr/informer/pdf/orienter/f_horaire.php?fm=gif&loc=noctilien&nompdf=n44) qui passe effectivement par « Mairie de Saint-Ouen ». La boucle est bouclée.

### Calcul d'itinéraire

L'histoire et le contexte des calculs d'itinéraires est très bien synthétisé par [Tristram Gräbener](https://twitter.com/tristramg) dans son [Petit historique du calcul d'itinéraire](http://blog.tristramg.eu/petit-historique-du-calcul-ditineraire.html). Probablement plus hipster que je ne veux bien l'admettre, j'ai choisi d'utiliser le plus récent : le *[Connection Scan Algorithm](http://i11www.iti.uni-karlsruhe.de/extra/publications/dpsw-isftr-13.pdf)*.

Cet algorithme, tenant en quelques lignes, se « contente » de parcourir une table horaire précalculée des connexions entre les stations et de retenir la solution optimale en temps de trajet. Une connexion représente une possibilité de trajet entre deux stations. On la modélise donc par un quadruplet contenant la station de départ, la station d'arrivée, l'heure de départ et l'heure d'arrivée. La table horaire devient alors simplement une liste de ces connexions triées par heure de départ croissante.


#### Alimentation des données : parsing des fichiers GTFS

Les fichiers GTFS, bien que portant l'extension `.txt` sont manipulables commes des fichiers CSV. Dans la suite, on utilisera des structures qui sont (presque) calquées sur le format de ces fichiers.

Sur le principe, leur parsing est immédiat. Prenons par exemple le cas des routes (on utilise ici [scala-csv](https://github.com/tototoshi/scala-csv)) :

```scala
import com.github.tototoshi.csv._
val routes: List[Route] = CSVReader.
  open(new File("routes.txt")).
  allWithHeaders().
  map(Route.parse)

case class Route(routeId: Long, routeShortName: String, routeLongName: String, routeDesc: String)

object Route {
  def parse(fields: Map[String, String]) = {
    Route(
      fields("route_id").toLong,
      fields("route_short_name"),
      fields("route_long_name"),
      fields("route_desc")
    )
  }
}
```

Dans la pratique, la volumétrie des horaires des courses rend l'opération plus complexe :

```
$ wc -l *
        2 agency.txt
    65937 calendar_dates.txt
     4578 calendar.txt
     1067 routes.txt
    26653 stops.txt
 10402381 stop_times.txt
    80338 transfers.txt
   417920 trips.txt
```

Pour simplifier la suite de cet article, nous ne traiterons que les lignes de métro et les lignes de RER exploitées par la RATP. On parsera les données ligne par ligne dans la structure `GtfsData` pour ensuite les fusionner :

```scala
case class GtfsData(
  name: String,
  routes: Iterable[Route],
  trips: Iterable[Trip],
  stops: Iterable[Stop],
  stopTimes: Iterable[StopTime],
  transfers: Iterable[Transfer]
)

// Fusion des données de ligne
val gtfsData = GtfsData(
  "RATP",
  lines.flatMap(_.routes),
  lines.flatMap(_.trips),
  lines.flatMap(_.stops),
  lines.flatMap(_.stopTimes),
  lines.flatMap(_.transfers)
)
```

#### Construction de la table horaire

La table horaire est, comme nous l'avons vu, une séquence de connexions modélisées par des quadruplets contenants chacun la station de départ, la station d'arrivée, l'heure de départ et l'heure d'arrivée.

```scala
case class Timetable(connections: Seq[Connection])
case class Connection(
  departureStation: Int,
  arrivalStation: Int,
  departureTimestamp: Int,
  arrivalTimestamp: Int
)
```

Sa construction se fait en deux étapes :

0. en ingérant les connexions issues des courses (successions de points d'arrêts sur une même ligne) ;
0. en ingérant les connexions issues des correspondances (« ponts » entre les courses).

##### Connexions issues des courses

On ingère les horaires des courses en les groupant par... course et en prenant soin de ne pas « mélanger » les horaires de deux courses. Prenons l'exemple ci-dessous : les ceux courses fréquentent la même ligne mais ne s'arrêtent pas aux mêmes arrêts. Il n'y a pas de correspondance entre les deux.

```
 Course I : A (t1) --------------------> B (t3)
Course II :               C (t2) --------------------> D (t4)
```

Le fichier `stop_times.txt` ressemblerait à :

```
trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,shape_dist_traveled
I, t1, t1, A, 1, ,
II, t2, t2, C, 1, ,
I, t3, t3, B, 1, ,
II, t4, t4, D, 1, ,
```

Une lecture indépendante de l'identifiant de course (`trip_id`) amalgamerait donc ces deux courses et induirait de fausses correspondances.

La création de la table horaire se fait en groupant deux à deux les horaires d'arrêt au sein d'une même course. Pour chaque élément à l'indice `i`, on créera une connexion partant de l'arrêt à cet indice et arrivant à l'arrêt de l'indice `i+1`. On implémente cette construction avec une fonction récursive qui dépile un à un les horaires de course.


```scala
val connectionsFromStopTimes = gtfsData.
  stopTimesByTripId.
  values.
  flatMap(stopTimesToConnections)

def stopTimesToConnections(stopTimes: Iterable[StopTime]): Iterable[Connection] = {
  @tailrec
  def loop(stopTimes: List[StopTime], connections: List[Connection]): List[Connection] = {
    stopTimes match {
      // Aucun horaire (n'arrive que si la collection initiale est vide).
      // On n'a rien à faire de plus, on retourne les connexions (vides).
      case Nil => connections
      // Dernier horaire : il est connecté au précédent et n'ira pas plus loin.
      // On en a terminé et on retourne les connexions.
      case head :: Nil => connections
      // Cas général : il reste des stations après la première de la collection.
      // On créé une connexion entre celle-ci et la première des suivantes.
      case head :: tail =>
        val departureStop = head.stopId.toInt
        val arrivalStop = tail.head.stopId.toInt
        val departureTime = durationToTimestamp(head.departureTime)
        val arrivalTime = durationToTimestamp(tail.head.departureTime)
        val connection = Connection(departureStop, arrivalStop, departureTime, arrivalTime)
        // Étape suivante de la récursion
        loop(tail, connections :+ connection)
    }
  }
  // Initialisation de la récursion
  loop(stopTimes.toList, List())
}
```

Dans cet exemple de code, la fonction `durationToTimestamp` retourne un timestamp correspondant à l'heure effective pour la journée en cours à partir de l'heure seule fournie dans les données. Par exemple, le 01/01/2016, la durée `19h32min27s` permettra d'obtenir le timestamp équivalent à `2016-01-01T19:32:27.0Z`.

##### Connexions issues des correspondances

Le fichier `transfers.txt` nous donne les correspondances disponibles sur une ligne. L'objectif de cette étape est de :

 * ne conserver que les correspondances de notre réseau (dans cet exemple, nous ne travaillons pas sur les bus, on les éliminera donc) ;
 * créer toutes les entrées de la table horaire correspondant à cette correspondance.

Le filtrage des correspondances est aisé avec notre structure de données. Nous disposons déjà de l'ensemble des stations du réseau. Il nous suffit de vérifier que ces correspondances ont lieu entre deux stations du réseau.

```scala
case class GtfsData(...) {
  // Indexation des stations du réseau
  val stopsByStopId: Map[Long, Stop] = stops.map(stop => stop.stopId -> stop)(collection.breakOut)
}

val filteredTransfers: Iterable[Transfer] = gtfsData.transfers.filter(transfer =>
  // Filtrage des correspondances avec des stations hors du réseau
  gtfsData.stopsByStopId.contains(transfer.fromStopId) &&
    gtfsData.stopsByStopId.contains(transfer.toStopId)
)
```

Cela étant fait, pour chacune de ces correspondances, on créé dans la table horaire une connexion correspondant à chaque horaire de passage à cette station. On utilisera pour cela les données issues de `stop_times.txt`.

```scala
def transfersToConnections(filteredTransfers: Iterable[Transfer]): Iterable[Connection] = {
  @tailrec
  def loop(transfers: Iterable[Transfer], connections: List[Connection]): List[Connection] = {
    transfers match {
      // Aucune correspondance à traiter. On en a terminé et on sort avec
      // la liste construite jusqu'ici.
      case Nil => connections
      // Il reste au moins une correspondance à traiter (tail peut être Nil).
      case head :: tail =>
        val departureStop = head.fromStopId
        val arrivalStop = head.toStopId
        // Pour chaque horaire de train à cette station, on créé
        // une entrée dans la table horaire.
        val transferConnections: List[Connection] = gtfsData.
          stopTimesByStopId(departureStop).
          map(stopTime => {
            val connectionDepartureTime = durationToTimestamp(stopTime.arrivalTime)
            Connection(
              departureStop,
              arrivalStop,
              connectionDepartureTime,
              connectionDepartureTime + head.minTransferTime
            )
          })
        // Étape suivante de la récursion.
        loop(tail, connections ++ transferConnections)
    }
  }
  // Initialisation de la récursion.
  loop(filteredTransfers.toList, List())
}
```

##### Fusion des deux tables horaires

On a construit jusqu'ici deux tables horaires :

 * l'une issue des horaires des trains en station ;
 * l'autre issue des correspondances entre les trains.

Reste maintenant à fusionner les deux. N'oublions pas que cette table doit être triée par heure de départ croissante. À ce détail près, cette étape est immédiate.

```scala
val connectionsFromStopTimes = gtfsData.
  stopTimesByTripId.
  values.
  flatMap(stopTimesToConnections)
val connectionsFromTransfers = transfersToConnections(gtfsData)

val connections = (connectionsFromStopTimes ++ connectionsFromTransfers).
  toList.
  sortBy(_.arrivalTimestamp)
```

#### Exploitation de la table horaire : calcul d'itinéraire

##### Explication de l'algorithme

> TODO

##### Exemple

Partons d'un trajet entre [Maubert-Mutualité et Voltaire]( http://www.vianavigo.com/fr/itineraire-plan-de-quartier/?criteria=1&mrq=&id=&departure=Maubert+-+Mutualit%C3%A9%2C+Paris&departureType=StopArea&departureCity=Paris&departureCoordX=&departureCoordY=&departureExternalCode=59357&departureCityCode=75000&arrival=Voltaire+%2F+L%C3%A9on+Blum%2C+Paris&arrivalType=StopArea&arrivalCity=Paris&arrivalCityCode=75000&arrivalCoordX=&arrivalCoordY=&arrivalExternalCode=59616&date=25%2F10%2F2015&dateFormat=dd%2FMM%2Fyyyy&sens=1&hour=18&min=00&moreCriterions=true&via=&viaType=&viaCity=&viaCityCode=&viaExternalCode=&_train=on&rer=true&_rer=on&metro=true&_metro=on&_bus=on&_tram=on&walkSpeed=0&spcar=%C3%A2&hpx=1&hat=1&L=0&submitSearchItinerary=&ajid=/stif_web_carto/comp/itinerary/search.html_&_=1445793804586) en partant à 18h.

```scala
val maubert = 2350
val voltaireLeonBlum = 1633

csa.compute(
  maubert,
  voltaireLeonBlum,
  durationToTimestamp(Duration.ofHours(18))
)
```

On obtient le trajet :

```
Solution found with 15 connections
  Maubert-Mutualité -> Cluny-La Sorbonne
  Cluny-La Sorbonne -> Odéon
  Odéon -> Odéon
  Odéon -> Saint-Michel
  Saint-Michel -> Cité
  Cité -> Châtelet
  Châtelet -> Les Halles
  Les Halles -> Etienne Marcel
  Etienne Marcel -> Réaumur-Sébastopol
  Réaumur-Sébastopol -> Strasbourg-Saint-Denis
  Strasbourg-Saint-Denis -> Strasbourg-Saint-Denis
  Strasbourg-Saint-Denis -> République
  République -> Oberkampf
  Oberkampf -> Saint-Ambroise
  Saint-Ambroise -> Voltaire (Léon Blum)
Total transit time: 21 minutes
```
