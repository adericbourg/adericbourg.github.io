Title: Shell shock : un obus dans les dents de bash
Date: 2014-09-26
Category: Blog
Tags: bash, sécurité, cve
Summary: On a vu sortir aujourd'hui une faille de Bash. Comment est-elle exploitable et quels sont les risques ?

Vous avez probablement entendu parler de Shell shock qui, outre l'association de troubles psychiques et physiques observés chez http://fr.wikipedia.org/wiki/Obusite[certains soldats de la Première Guerre Mondiale], désigne également la vulnérabilité [CVE-2014-6271](http://www.cert.ssi.gouv.fr/site/CERTFR-2014-ALE-006/index.html) touchant GNU bash. Elle permet à un attaquant de provoquer une exécution de code arbitraire à distance.

## Mon dieu, mais c'est horrible !

Il faut avouer que ça ne présage pas d'une franche partie de rigolade.

Tout d'abord, de nombreux programmes interagissent avec le shell. Nous savons que ce n'est généralement pas une bonne idée mais cela nous simplifie parfois grandement la tâche (on dit souvent qu'un bon développeur est un développeur fainéant). La surface d'attaque est donc très étendue.

Par ailleurs, si les systèmes « évidents » seront patchés (un serveur web par exemple), certaines machines plus obscures ne le seront pas : pensez par exemple à des périphériques tels que les caméras connectées (ou plus largement tout ce que vous pouvez trouver sur l'Internet des objets). Rien n'exclut qu'elles exposent des services basés sur des scripts shell et si ce shell est bash, le périphérique devient vulnérable. Comme il y a fort à parier qu'aucune procédure de mise à jour de ces périphériques n'ait été définie, ces périphérques resteront vulnérables ad vitam aeternam.

## J'exige des explications

Bash permet d'exporter des variables mais aussi des fonctions à destination d'autres instances de bash. L'export de fonction utilise une variable d'environnement portant le nom de la-dite fonction dont la valeur commence par () { :

```bash
foo=() {
    du code
}
```

À l'import, il se contente aveuglément d'interpréter cela en remplaçant le signe « = » par une espace. C'est ainsi que bash ne se limite pas à interpréter le corps de la fonction mais qu'il poursuit le parsing et exécute les commandes qui suivent la définition de la fonction. Par exemple, définir une variable d'environnement de cette sorte :

```bash
FOO=() { ignored; }; /bin/yolo
```

exécutera `/bin/yolo` quand l'environnement sera importé par bash.

Ainsi, tout système utilisant bash est vulnérable, mais il est particulièrement vulnérable :

* s'il expose un service sur le réseau (a fortiori sur Internet) ;
* que ce service exploite des paramètres passés par le client et qu'il les stocke dans une variable d'environnement ;
* et que ce service lance bash pour un traitement quelconque.

Pour savoir si votre machine est vulnérable, vous pouvez lancer :

```bash
$ env VAR='() { 0; }; echo danger' bash -c "echo bonjour"

Si tout va bien, vous devriez observer ceci :

```bash
$ env VAR='() { 0; }; echo danger' bash -c "echo bonjour"
bash: warning: VAR: ignoring function definition attempt
bash: error importing function definition for `VAR'
bonjour
```

Si tout ne va pas bien, vous observerez :


```bash
$ env VAR='() { 0; }; echo danger' bash -c "echo bonjour"
danger
bonjour
```

À noter que Linux n'est pas le seul système touché. Tous les systèmes Unix (ce qui inclut Mac OS) sont concernés.

## M'enfin, qui serait assez bête pour exposer un machin bash sur Internet ?

Moi – et probablement vous aussi – mais je ne pense pas que ce soit de la bêtise.

Pour l'instant, le vecteur de propagation semble être la requête HTTP à destination d'un script CGI. Le serveur web _Apache httpd_ utilise par exemple des scripts (donc potentiellement bash) pour certaines fonctions C, Python ou PHP (si ce dernier est lancé en mode CGI). C'est ainsi que quelques robots parcourent en ce moment même le web en positionnant leur en-tête _User-Agent_ comme suit afin de dresser leur annuaire des machines vulnérables : `User-Agent: () { :; } /bin/ping -c x.y.z.q`. Si vous souhaitez vérifier vos logs HTTP, vous pouvez lancer `egrep '\(\ *\)\ *\{' /var/log/nginx/*` par exemple.


Ce n'est donc pas si rare et c'est sans compter les applications largement déployées qui utilisent CGI (cPanel par exemple).

Enfin – et plus localement, certains clients DHCP utilisent également des scripts pour configurer le système. Si le serveur est corrompu (ou mal intentionné), cela permet d'exécuter des commandes – vraisemblablement en _root_ – sur la machine cliente.
Il ne peut plus rien nous arriver d'affreux maintenant

Une fois le patch passé, vous devriez déjà être plus sereins. Néanmoins, [comme l'indique RedHat](https://securityblog.redhat.com/2014/09/24/bash-specially-crafted-environment-variables-code-injection-attack/), le patch fourni laisse quelques trous dans la raquette. Il est notamment possible, sous certaines conditions, d'exécuter du code contenu dans des variables d'environnement (CVE-2014-7169). Reste à attendre le patch du patch.

Pour tester votre vulnérabilité à [CVE-2014-7169](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-7169), vous pouvez lancer :

```bash
$ env X='() { (a)=>\' sh -c "echo date"; cat echo
```

Si vous obtenez la date, votre système est vulnérable.

À suivre, donc.