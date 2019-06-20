---
Title: Je fais passer des entretiens de code aux entreprises qui me recrutent
Category: Blog
Tags: recrutement, qualité
Status: draft
Date: 2100-01-01
---

La réalisation par le candidat d'un exercice de code est de plus en plus fréquent lors des
entretiens de recrutement d'un développeur. Je trouve d'ailleurs cela plutôt rassurant
quant aux critère de sélection : si l'exercice est bien conçu, cela permet de mettre le
candidat en situation proche de ce qui lui sera demandé.

Mais si le candidat est évalué, qu'en est-il de l'entreprise ? Le processus de recrutement
est censé permettre à l'entreprise de retenir ou non un candidat, mais aussi au candidat de
retenir ou non une entreprise. Alors pourquoi ne pas évaluer ce qu'a produit l'équipe
jusqu'alors ?

J'ai passé quelques entretiens récemment et j'ai soumis les entreprises à cet exercice. La
plupart a été surprise de cette demande mais toutes se sont prêtées au jeu.

## (Absence de) Méthodologie

Mon premier objectif au cours d'un processus de recrutement est de déterminer si oui ou non
j'ai envie de travailler pour cette entreprise. Je n'ai donc pas visé l'entreprise qui aurait
le plus gros score au regard de critères subjectifs ou arbitraires et je n'ai pas défini de
critères mesurables.

Pour cette fois, même si j'ai dressé une liste de points à observer, seul mon ressenti
lors de l'examen a compté dans la balance. Dans cette façon de procéder, j'ai très vite
senti un biais : lorsque je ne « sentais » pas la personne en face de moi, mon impression
vis-à-vis du code était plus négative qu'elle n'aurait pu. J'ai choisi de le négliger car
même si cet exercice ne vise pas directement à évaluer mes éventuels futurs collègues, si
un malaise avec eux lors de cet entretien est un signal à prendre en compte sur notre
capacité à travailler ensemble. Lors de ces processus de recrutement, j'ai demandé à
rencontrer mon équipe d'accueil sur un temps informel : l'occasion de confirmer ou
d'infirmer le ressenti inter-personnel.

## Angles d'observation

J'ai abordé cet exercice en essayant de ne pas laisser d'angle mort tout en sachant qu'il
y en aurait (sic). Dans ma demande, j'ai essayé de montrer des limites floues afin de laisser
l'équipe ou mon interlocuteur aborder ce qui lui semble important. J'ai évoqué :

* l'aspect global du code ;
* les choix de _build_, test et déploiement ;
* l'installation d'un environnement de développement (poste du développeur) ;
* tout élément intéressant qui pourrait être abordé dans ce cadre.

### Environnement de développement

Sur ces aspect, j'ai observé (consciemment) :

* les outils utilisés et leur adhérence au projet (s'il est légitime de n'avoir qu'un seul
  outil de _build_, dans quelles circonstances un projet peut-il être adhérent à l'IDE ?) ;
* la complexité pour construire un projet de bout en bout (combien de commandes, quels outils),
  en ayant l'intuition qu'un projet compliqué à construire est probablement mal conçu ou mal
  entretenu ;
* le temps de construction d'un projet en local (la durée minimale avant d'avoir un retour sur
  ce que l'on vient d'écrire) ;
* la présence et la qualité d'une documentation de démarrage, un « guide du nouvel arrivant ».

J'essaie également de me faire une idée sur la complexité d'installer un environnement de
développement. Mon expérience semble m'indiquer que plus cette installation est complexe ou
compliquée, plus l'environnement est fragile et l'installation non-répétable.

Un script d'installation peut-être un fort gain de temps s'il ne se fait pas au détriment de
la connaissance de chacun de son environnement : qui sait comment fonctionne ce script
d'installation ?

### Gestion du code source

Je demande à voir l'historique du projet et quelques revues de code.

* Par quel système le code est-il géré ?
* Quel est le processus d'acceptation du code ?
* Qui est responsable des revues de code s'il y en a ?
* Quels sont les critères d'évaluation lors d'une revue de code ?
* Comment sont rédigés les messages de _commit_ ?
* Quel contexte est donné dans un _commit_ (à une éventuelle spécification, à un système de
  suivi des bugs...) ?

### Structure du projet

L'évaluation de la qualité d'un projet n'est pas toujours évidente, en particulier, pour moi,
lorsque je ne maîtrise pas du tout la langage utilisé. Dans ce cas, c'est également l'occasion
de mettre à l'épreuve les qualités de pédagogue de mon interlocuteur !

Pour ce volet, j'essaie de partir d'une vue d'ensemble :

* Puis-je distinguer les responsabilité de cette application d'un coup d'œil ?
* Comment le projet est-il structuré ?
* Y a-t-il un découpage purement technique ? Purement fonctionnel ?

### Qualité du code

Je demande ensuite à me montrer le jeu de tests d'une fonctionnalité « pas trop simple »
mais « pas trop complexe » non plus et j'essaie de comprendre quelle est cette fonctionnalité
à partir de ce que je vois des tests.

* Le nommage du test suffit-il à en comprendre l'objectif ?
* Faut-il regarder l'implémentation pour comprendre ce qui est vraiment testé ?
* L'implémentation du test est-elle elle-même à la portée de ma compréhension ?
* Le nom du test est-il en phase avec son implémentation ?

Une fois les tests passés en revue et la fonctionnalité comprise, je passe à son implémentation.
La simplicité des tests donne une première indication de la qualité de l'implémentation :
complexité d'instanciation, nombre de fonctions ou de méthodes exposées, nombre d'instructions
pour réaliser une opération... Sans qu'il soit possible de fixer un seuil pertinent, je fais
confiance à ma perception et à mon jugement pour déterminer si les APIs et les abstractions
sont pertinentes.

Si le concept existe dans le langage utilisé, les imports des tests et de l'implémentation permettent
de se faire une idée de la séparation des responsabilités et d'éventuelles fuites de détail
d'implémentation.

Certains IDEs affichent des avertissements quant à la qualité du code : observer leur présence
(ou non) et leur nature peut indiquer le soin apporté à la qualité et à la lisibilité du code :

* un avertissement pertinent non-corrigé n'indique pas d'intérêt de l'équipe vis-à-vis de la
  qualité du code ;
* un avertissement non-pertinent est signe de mauvais paramétrage de l'IDE (le bruit risque de cacher
  des choses plus sérieuses).

Enfin, à l'issue de cette lecture de code, je me pose la question : « Est-ce que je me projette à
travailler sur cette base de code ? ». Un doute peut être éloquent.

### Automatisation

Build, déploiement continu, feedback loop, rapports de qualité de code
Tests d'intégration

### Rendons à Joel ce qui est à Joel

Je ne m'en suis rendu compte qu'après-coup, mais cette demande s'approche d'un
_[Joel Test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/)_.
Même si le contenu a pris de l'âge (20 ans !), il me semble toujours être un bon point de départ
pour évaluer le potentiel de progression d'une entreprise ou d'une équipe.

## Un premier exemple

TODO

## Un second exemple

TODO

## Un troisième exemple

TODO

J'ai interrompu l'entretien au bout de 2h30.
