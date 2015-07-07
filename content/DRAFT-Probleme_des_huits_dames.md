Title: Problème des huit dames
Date: 2015-07-07
Category: Blog
Tags: algorithmique, java
Status: draft

J'ai rencontré le [problème des huits dames](https://fr.wikipedia.org/wiki/Probl%C3%A8me_des_huit_dames) lors d'un entretien d'embauche et, ayant lamentablement (et honteusement) échoué, mon orgueil m'a incité à pousser l'exercice plus en avant.

Le problème consiste à compter et identifier les différentes façons de placer sur un échiquier de 64 cases 8 dames de façon à ce que, relativement aux règles des échecs, elles ne se menacent pas mutuellement. Une dame peut se déplacer d'un nombre de cases arbitraire dans toutes les directions ; lorsqu'une dame est placée, la ligne, la colonne et les diagonales sur lesquelles elle se situe sont donc « condamnées ».

### Approche naïve : examen de l'intégralité des combinaisons

Cette approche revient à essayer toutes les combinaisons de placement des reines et de retenir celles pour lesquelles toutes les reines sont en sécurité.

> TODO

### Seconde approche : résolution récursive

Ce problème peut également être résolu par une approche récursive : une solution au problème des *n* dames peut être obtenue à partir d'une solution des *n-1* dames. On initialise alors la récurrence avec le problème à l'étape « 0 », soit un échiquier vide.

> TODO

### Troisième approche : programmation par contrainte

> TODO

### Comparaison des approches

> TODO
