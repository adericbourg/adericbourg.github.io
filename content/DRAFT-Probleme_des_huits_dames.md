Title: Problème des huit dames
Date: 2015-07-07
Category: Blog
Tags: algorithmique, python
Status: draft

J'ai rencontré le [problème des huits dames](https://fr.wikipedia.org/wiki/Probl%C3%A8me_des_huit_dames) lors d'un entretien d'embauche et, ayant lamentablement (et honteusement) échoué, mon orgueil m'a incité à pousser l'exercice plus en avant.

Le problème consiste à compter et identifier les différentes façons de placer sur un échiquier de 64 cases 8 dames de façon à ce que, relativement aux règles des échecs, elles ne se menacent pas mutuellement. Une dame peut se déplacer d'un nombre de cases arbitraire dans toutes les directions ; lorsqu'une dame est placée, la ligne, la colonne et les diagonales sur lesquelles elle se situe sont donc « condamnées ».


### Modélisation

On ne peut pas placer plusieurs reines sur une même ligne. On peut donc simplifier la modélisation en ne travaillant que sur les colonnes. Ainsi, on cherchera à ne retourner qu'un tableau d'index de colonne, chacun de ces index correspondant à la ligne de son propre index dans le tableau. Pour illustrer, on produira en retour le tableau `[x, y, z]` qui correspond en pratique aux coordonnées `(0, x)`, `(1, y)` et `(2, z)`.

![Représentation de la modélisation](/images/eight_queens/modelisation.png){.center}

> **Note :** en Python, la fonction [`enumerate`](https://docs.python.org/2/library/functions.html#enumerate) permet d'obtenir de façon immédiate ce résultat.
>
>     >>> list(enumerate([3, 2, 1]))
>     [(0, 3), (1, 2), (2, 1)]
>

Il est alors « facile » de déterminer si une dame est en sécurité connaîssant la position des autres :

 * par construction, aucune dame ne peut être sur la même ligne ;
 * deux dames sont sur la même colonne lorsque leur index de colonne est la même (`c[i] == c[j]`) ;
 * deux dames sont sur la même diagonale lorsque leur différence d'index dans le tableau est égal à leur différence d'index de colonne (`abs(c[i] - c[j]) == abs(i - j)`).

![Représentation de la modélisation](/images/eight_queens/diagonale.png){.center}

### Approche naïve : examen de l'intégralité des permutations

Cette approche revient à essayer toutes les combinaisons de placement des reines et de retenir celles pour lesquelles toutes les reines sont en sécurité.

> TODO

#### Génération des permutations

Il est possible de déterminer toutes les permutations possibles d'un tableau en utilisant — par exemple — l'[algorithme de Heap](https://en.wikipedia.org/wiki/Heap%27s_algorithm). J'en propose une implémentation récursive : compte tenu des dimensions des tableaux de notre problème, cela reste raisonnable (on ne risque pas le dépassement de capacité de pile d'exécution).

```python
def permutations(array):
    def __permutations(array, size):
        if size == 1:
            yield array
        else:
            for i in range(size):
                for p in  __permutations(array, size - 1):
                    yield p
                if size % 2 == 0:
                    array[i], array[size - 1] = array[size - 1], array[i]
                else:
                    array[0], array[size - 1] = array[size - 1], array[0]

    return __permutations(array, len(array))
```

Pour donner un exemple :

```python
>>> for perm in permutations(['a', 'b', 'c']): print perm
...
['a', 'b', 'c']
['b', 'a', 'c']
['c', 'a', 'b']
['a', 'c', 'b']
['b', 'c', 'a']
['c', 'b', 'a']
```

En pratique, la bibliothèque standard Python propose dans le module [`itertools`](https://docs.python.org/2/library/itertools.html) une fonction générant ces permutations. Mesurons le temps d'exécution de ce code avec les deux implémentations :

```python
a = [0, 1, 2, 3, 4, 5, 6]
for i in range(10000):
    for perm in permutations(a):
        perm
```

```
# Heap
$ time python heaps.py
real    0m42.860s
user    0m42.832s
sys     0m0.008s

# itertools
$ time python itertools.py
real    0m3.433s
user    0m3.428s
sys     0m0.000s
```

La fonction de la blbliothèque standard est bien plus performante que l'implémentation proposée ci-dessus (et heureusement). On utilisera donc celle-ci pour la résolution du problème : autant ne pas tendre le bâton pour se faire battre.

#### Résolution

> TODO

### Seconde approche : résolution récursive

Ce problème peut également être résolu par une approche récursive : une solution au problème des *n* dames peut être obtenue à partir d'une solution des *n-1* dames. On initialise alors la récurrence avec le problème à l'étape « 0 », soit un échiquier vide.

> TODO

Pour mieux comprendre cet algorithme, il en existe une [version animée détaillant les étapes de la résolution](https://www.cs.usfca.edu/~galles/visualization/RecQueens.html).

### Troisième approche : recherche en profondeur

> TODO

### Quatrième approche : programmation par contraintes

Un problème de satisfaction de contraintes (ou CSP pour *Constraint Satisfaction Problem*) désigne l'ensemble des problèmes définis par... des contraintes. Sa résolution consiste à chercher une solution les respectant. Pour cela, on décrit un modèle définit par :

 * un ensemble de variables ;
 * un ensemble de contraintes régissant ces variables.

À partir de ce modèle, le système cherchera une solution et la proposera si elle existe. En revanche, il ne proposera qu'une seule solution : la résolution d'un problème par contraintes n'a pas vocation à chercher l'ensemble exhaustif des solutions.

En Python, la bibliothèque [Numberjack](http://numberjack.ucc.ie) facilite la programmation par contraintes. Ils fournissent d'ailleurs une [solution pour le problème des *n* dames](http://numberjack.ucc.ie/examples/nqueens).

Dans le cas générique des *N* dames, on définit dans notre ensemble de variables les dames. Chacun d'elles est de type `Variable(N)`, soit une variable dans un domaine compris entre 0 et *N*. La contrainte `AllDiff` impose à toutes les expressions qui lui sont passées d'êtres différentes. On impose donc :

 * que toutes les dames soient dans des colonnes différentes (`AllDiff( queens )`) ;
 * que toutes les dames soient sur des diagonales différentes (combinaison de `AllDiff( [queens[i] + i for i in range(N)] )` et `AllDiff( [queens[i] - i for i in range(N)] )`).

On suppose donc que chaque dame est sur une ligne distincte : la dame 0 sera sur la ligne 0, la dame 1 sur la ligne 1, etc.

La description du modèle devient :

```python
from Numberjack import *

def model_queens(N):
    queens = [Variable(N) for i in range(N)]
    model  = Model(
        AllDiff( queens ),
        AllDiff( [queens[i] + i for i in range(N)] ),
        AllDiff( [queens[i] - i for i in range(N)] )
        )
    return (queens, model)
```

La résolution du problème est alors immédiate :

```python
def solve_queens(param):
    (queens,model) = model_queens(param['N'])
    solver = model.load(param['solver'])
    solver.solve()
    print_chessboard(queens)
    print 'Nodes:', solver.getNodes(), ' Time:', solver.getTime()

def print_chessboard(queens):
    separator = '+---'*len(queens)+'+'
    for queen in queens:
        print separator
        print '|   '*queen.get_value()+'| Q |'+'   |'*(len(queens)-1-queen.get_value())
    print separator

solve_queens(input({'solver':'Mistral', 'N':10}))
```

La proposition d'une solution est également très rapide :

```
+---+---+---+---+---+---+---+---+
| Q |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   | Q |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   | Q |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   | Q |   |   |
+---+---+---+---+---+---+---+---+
|   |   | Q |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   | Q |   |
+---+---+---+---+---+---+---+---+
|   | Q |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   | Q |   |   |   |   |
+---+---+---+---+---+---+---+---+
Nodes: 24  Time: 0.0
```

Une mesure plus fine du temps d'exécution indique qu'il a fallu environ 20 millisecondes pour proposer cette solution (qui inclut le temps d'exécution total du programme Python).


### Comparaison des approches

> TODO
