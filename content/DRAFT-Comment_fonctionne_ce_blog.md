Title: Pourquoi ce blog ne tourne-t-il pas sur un Raspberry Pi ?
Date: 2015-06-23
Category: Blog
Tags: blog, python, pelican, git, github
Status: draft

Bien qu'il soit très simple, monter ce blog m'a demandé un certain temps. Quel moteur utiliser ? Où l'héberger ? La plus grande difficulté n'a, finalement, pas été le choix à proprement parler mais le choix parmi les *nombreux* choix possibles. Sans savoir si j'avais l'engagement, la motivation et l'assiduité nécessaire à l'alimenter tant qualitativement que quantitativement, je me suis posé la contrainte d'un coût nul ou minime et d'un investissement en temps minimal.

### Première intuition

À force de parler d’auto-hébergement, pourquoi déléguer ça un autre quand je peux le faire chez moi et garder la main sur mes données ?, je ne pouvais pas ne pas ne serait-ce qu’essayer au moment d’ouvrir ce blog. Ayant un Raspberry Pi qui dormait dans un coin de mon bureau, j’ai décidé de le mettre à contribution.

Spontanément, je me suis tourné vers le « classique » [Wordpress](https://fr.wordpress.org/) que j'avais l'habitude d'utiliser. En estimant la charge à deux visiteurs par jour (en comptant les robots) en moyenne et dix si je tweete un aricle, autrement dit, en estimant que la machine ne ferait rien la plupart du temps et servirait une requête de temps en temps, elle tiendrait la charge. Je ne suis pas développeur PHP et j'ai une mauvaise intuition.

Si l'on résume l'ensemble :

* [Raspbian](https://www.raspbian.org/) (dérivé de Debian pour Raspberry Pi) ;
* Apache httpd avec le module PHP5 ;
* MySQL ;
* WordPress.


### Au démoulage

Si l'on mesure naïvement le temps de chargement d'une page, on obtient :

    $ for i in $(seq 1 10); do curl -o /dev/null -s -w %{time_total}\\n http://blog.dericbourg.net; done
    1,661
    1,645
    1,649
    1,653
    1,648
    1,635
    1,644
    1,645
    1,671
    1,645

On ne peut pas dire que les performances soient satisfaisantes : servir une page demande plus d'une seconde et demie.

La mesure a été réalisée en local pour ne bien mesurer que les performances de la machine et éviter autant que possible les latences réseau (même si je suis derrière une box fibre).

Détaillons la temporalité de la requête en affichant :

 * la durée de résolution du nom de domaine `time_namelookup` ;
 * la durée d'établissement de la connextion TCP `time_connect` ;
 * la durée d'attente avant que le transfert ne se lance effectivement `time_pretransfer` ;
 * la durée d'attente du premier octet, `time_starttransfer`, qui inclut la durée d'attente du lancement du transfert (valeur précédente) et le temps nécessaire au serveur à calculer le résultat.

On obtient, en ajoutant en dernière colonne le temps total :

    $ for i in $(seq 1 10); do curl -o /dev/null -s -w %{time_namelookup}\\t%{time_connect}\\t%{time_pretransfer}\\t%{time_starttransfer}\\t\\t%{time_total}\\n http://blog.dericbourg.net; done
    0,012   0,021   0,021   1,651           1,653
    0,004   0,027   0,027   1,647           1,648
    0,004   0,020   0,020   1,659           1,660
    0,004   0,017   0,017   1,651           1,652
    0,004   0,017   0,017   1,653           1,654
    0,004   0,016   0,016   1,648           1,649
    0,004   0,025   0,025   1,656           1,658
    0,004   0,016   0,017   1,648           1,649
    0,004   0,013   0,013   1,636           1,639
    0,012   0,022   0,022   1,648           1,649

C'est donc le calcul du résultat qui est le plus coûteux en temps. Cela inclut l'interprétation du PHP mais également l'ensemble des requêtes en base.


### Nginx, par curiosité

Réalisons la même mesure sur [Nginx](http://nginx.org/) utilisant [php5-fpm](http://php-fpm.org/). On obtient :

    $ for i in $(seq 1 10); do curl -o /dev/null -s -w %{time_namelookup}\\t%{time_connect}\\t%{time_pretransfer}\\t%{time_starttransfer}\\t\\t%{time_total}\\n http://blog.dericbourg.net; done
    0,012   0,021   0,021   1,491           1,498
    0,004   0,017   0,017   1,467           1,468
    0,004   0,017   0,017   1,490           1,494
    0,004   0,013   0,013   1,471           1,473
    0,004   0,014   0,014   1,463           1,464
    0,004   0,014   0,014   1,488           1,489
    0,004   0,016   0,016   1,480           1,482
    0,004   0,014   0,014   1,465           1,466
    0,004   0,018   0,018   1,489           1,492
    0,004   0,018   0,018   1,485           1,487

On reste sur le même ordre de grandeur en gagnant malgré tout 10% : rien de significatif. La durée de calcul de la page est toujours trop importante. À ce stade, on ne peut pas conclure grand chose pour autant :

 * soit les modules d'interprétation de PHP ont des performances similaires ;
 * soit l'essentiel du temps consommé est ailleurs.





 $ ps -eo pid,bsdtime,pcpu,comm|grep 'mysql\|php\|nginx'
 4058   0:00  0.1 mysqld_safe
 4397   0:02  1.8 mysqld
 4583   0:00  0.0 nginx
 4584   0:00  0.0 nginx
 4626   0:00  0.0 php5-fpm
 4627   0:10 10.6 php5-fpm
 4628   0:07  7.8 php5-fpm



 bsdtime     TIME      accumulated cpu time, user + system.  The display format is usually "MMM:SS", but can be shifted to the right if the process used more than 999 minutes of cpu time.
 comm        COMMAND   command name (only the executable name).
 cputime     TIME      cumulative CPU time, "[DD-]hh:mm:ss" format.  (alias time)
 pcpu        %CPU      see %cpu.  (alias %cpu).


Creuser aussi `pidstat -dl 1` (IO / process), plus `iotop`
Attente des IO (nombre de ticks) : https://serverfault.com/questions/169676/howto-check-disk-i-o-utilisation-per-process
