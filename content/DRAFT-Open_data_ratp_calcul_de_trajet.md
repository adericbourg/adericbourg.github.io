Title: Calcul d'itinéraire à partir des données RATP
Date: 2015-09-12
Category: Blog
Tags: opendata, ratp
Status: draft

La RATP progresse dans l'[ouverture de ses données](http://data.ratp.fr) et même si elle ne propose pas encore un accès à son [système SIEL](https://fr.wikipedia.org/wiki/Syst%C3%A8me_d'information_en_ligne), elle propose néanmoins les données de son offre de transport au [format GTFS](https://developers.google.com/transit/gtfs/). Une bonne occasion de s'initier au calcul d'itinéraire !

### Format des données

> TODO

Un détail est à noter quant aux horaires : ceux-ci sont fournis pour la journée qui peut se terminer... le lendemain. Un métro circulant le dimanche à 1h du matin sera en réalité rattaché à la journée du samedi. Ainsi, son horaire ne sera pas « à 1h le dimanche» mais « à 25h le samedi ». Bien que cette astuce puisse sembler tordue, elle simplifie en pratique beaucoup de choses, notamment pour maintenir la continuité des missions : il serait absurde de découper la mission d'un train sous prétexte qu'il roule à cheval sur deux jours calendaires.

### Calcul d'itinéraire

L'histoire et le contexte des calculs d'itinéraires est très bien synthétisé par [Tristram Gräbener](https://twitter.com/tristramg) dans son [Petit historique du calcul d'itinéraire](http://blog.tristramg.eu/petit-historique-du-calcul-ditineraire.html). Probablement plus hipster que je ne veux bien l'admettre, j'ai choisi d'utiliser le plus récent : le *[Connection Scan Algorithm](http://i11www.iti.uni-karlsruhe.de/extra/publications/dpsw-isftr-13.pdf)*.

Cet algorithme, tenant en quelques lignes, se « contente » de parcourir une table horaire précalculée des connexions entre les stations et de retenir la solution optimale en temps de trajet. Une connexion représente une possibilité de trajet entre deux stations. On la modélise donc par un quadruplet contenant la station de départ, la station d'arrivée, l'heure de départ et l'heure d'arrivée. La table horaire devient alors simplement une liste de ces connexions triées par heure de départ croissante.
