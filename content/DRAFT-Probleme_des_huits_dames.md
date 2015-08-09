Title: Problème des huit dames
Date: 2015-07-07
Category: Blog
Tags: algorithmique, python
Status: draft

J'ai rencontré le [problème des huits dames](https://fr.wikipedia.org/wiki/Probl%C3%A8me_des_huit_dames) lors d'un entretien d'embauche et, ayant lamentablement (et honteusement) échoué, mon orgueil m'a incité à pousser l'exercice plus en avant.

Le problème consiste à compter et identifier les différentes façons de placer sur un échiquier de 64 cases 8 dames de façon à ce que, relativement aux règles des échecs, elles ne se menacent pas mutuellement. Une dame peut se déplacer d'un nombre de cases arbitraire dans toutes les directions ; lorsqu'une dame est placée, la ligne, la colonne et les diagonales sur lesquelles elle se situe sont donc « condamnées ».


### Modélisation

On ne peut pas placer plusieurs reines sur une même ligne. On peut donc simplifier la modélisation en ne travaillant que sur les colonnes. Ainsi, on cherchera à ne retourner qu'un tableau d'index de colonne, chacun de ces index correspondant à la ligne de son propre index dans le tableau. Pour illustrer, on produira en retour un tableau de la forme `[x, y, z]` qui correspond en pratique aux coordonnées `(0, x)`, `(1, y)` et `(2, z)`.

Représentons cette modélisation dans le cas de la résolution du problème avec huit dames.

![Représentation de la modélisation](/images/eight_queens/modelisation.png){.center}

> **Note :** en Python, la fonction [`enumerate`](https://docs.python.org/2/library/functions.html#enumerate) permet d'obtenir de façon immédiate ce résultat.
>
>     >>> list(enumerate([3, 2, 1]))
>     [(0, 3), (1, 2), (2, 1)]
>

Il est alors « facile » de déterminer si une dame est en sécurité connaîssant la position des autres :

 * Par construction, aucune dame ne peut être sur la même ligne.
 * Deux dames sont sur la même colonne lorsque leur index de colonne est la même (`c[i] == c[j]`).
 * Deux dames sont sur la même diagonale lorsque leur différence d'index dans le tableau (donc leur différence d'index de ligne) est égal à leur différence d'index de colonne (`abs(c[i] - c[j]) == abs(i - j)`). La valeur absolue permet de traiter indifféremment les diagonales « montantes » et les diagonales « descendantes ».

Ainsi, les solutions, lorsqu'elles existent, forment un sous-ensemble des permutations de {1 ; 2 ; ... ; *n* - 1} (où *n* est le nombre de dames et la dimension de l'échiquier).

![Représentation de la modélisation](/images/eight_queens/diagonale.png){.center}

### Approche naïve : examen de l'intégralité des permutations

Cette approche revient à essayer toutes les combinaisons de placement des reines et de retenir celles pour lesquelles toutes les reines sont en sécurité. Compte tenu du fait que deux dames ne peuvent être sur la même colonne, la solution est une permutation de la suite d'entiers de 0 à *n* - 1.

#### Génération des permutations

Il est possible de déterminer toutes les permutations possibles d'un tableau en utilisant — par exemple — l'[algorithme de Heap](https://en.wikipedia.org/wiki/Heap%27s_algorithm) qui minimise le nombre de mouvements nécessaires à l'obtention de l'intégralité des permutations. Une permutation est obtenue de la précédente en interchangeant la position de deux éléments (et seulement deux).

J'en propose une implémentation récursive : compte tenu des dimensions des tableaux de notre problème, cela reste raisonnable ; on ne risque pas le dépassement de la capacité de la pile d'exécution.

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

En pratique, la bibliothèque standard Python propose dans le module [`itertools`](https://docs.python.org/2/library/itertools.html) une fonction générant ces permutations. Mesurons grossièrement le temps d'exécution de ce code avec les deux implémentations :

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

On a vu que l'ensemble des solutions était contenu dans l'ensemble des permutations de {1 ; 2 ; ... ; *n* - 1}, soit l'ensemble des permutations de *n* entiers distincts. De par cette modélisation :

 * puisqu'on ne peut pas mettre deux valeurs au même index d'un tableau, les dames ne peuvent pas être sur la même ligne ;
 * par construction de l'ensemble sur lequel on initialise les permutations, aucune dame ne peut être sur la même colonne qu'un autre.

 Il reste alors à appliquer directement la formule de vérification des diagonales proposée dans le paragraphe *Modélisation*.

```python
def is_safe(permutation):
    size = len(permutation)
    for i in range(size):
        for j in range(i + 1, size):
            if abs(permutation[i] - permutation[j]) == abs(i - j):
                return False
    return True
```

On initialise la première permutation à `[0, 1, 2, ..., n - 1]` avec `range(n)`. Une fois les permutations calculées, le câblage de l'ensemble est immédiat.

```python
def solve(board_size):
    from itertools import permutations
    solutions = []
    for permutation in permutations(range(board_size)):
        if is_safe(permutation):
            solutions.append(permutation)
    return solutions
```

#### Représentation des solutions

Il est toujours plus simple de vérifier les solutions en les visualisant. [Le nombre de solutions en fonction du nombre de dames étant connu](https://en.wikipedia.org/wiki/Eight_queens_puzzle#Counting_solutions), on ajoute le nombre de solutions trouvées pour faciliter la validation de l'algorithme.

```python
def print_solutions(solutions, board_size):
    separator = '+---' * board_size + '+'
    for solution in solutions:
        for column in solution:
            print separator
            print '|   ' * column + '| ♛ |' + '   |' * (board_size - 1 - column)
        print separator
        print
    print "Found", len(solutions), "solutions"

size = 8
solutions = solve(size)
print_solutions(solutions, size)
```

```text
# 91 autres solutions
# [...]

+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   | ♛ |
+---+---+---+---+---+---+---+---+
|   |   |   | ♛ |   |   |   |   |
+---+---+---+---+---+---+---+---+
| ♛ |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | ♛ |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   | ♛ |   |   |
+---+---+---+---+---+---+---+---+
|   | ♛ |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   | ♛ |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   | ♛ |   |   |   |
+---+---+---+---+---+---+---+---+

Found 92 solutions
```

Il faut environ 60 ms pour obtenir l'intégralité des solutions et les représenter.

```
$ time python brute-force.py
python brute-force.py  0,06s user 0,00s system 91% cpu 0,061 total
```

Pour cette dimension, c'est tout à fait acceptable et on pourrait s'en contenter. On pourrait... mais ça ne serait pas satisfaisant pour la curiosité !

### Seconde approche : algorithme de retour sur trace (*backtracking*)

Cet algorithme parcourt toutes les possibilités en éliminant d'emblée toute solution partielle qui ne convient pas. Il permet donc d'éviter de nombreuses combinaisons : il est en ce sens plus économe que l'algorithme de force brute. La résolution du problème revient alors à un parcours de graphe (sans cycle).

#### Exemple

Commençons par un exemple simple. On souhaite obtenir les combinaisons de nœuds permettant de former le mot « BLOG » en parcourant l'arbre. On continue de descendre dans l'arbre tant que la combinaison permet d'obtenir une solution (nœuds bleus). Dès que celle-ci ne le permet plus (nœud rouge), on ignore les branches suivantes (nœud gris).

Dans cet exemple, on n'obtient qu'une solution mais rien n'empêche d'en avoir plusieurs.

![Exemple de backtracking](/images/eight_queens/backtracking.png){.center}

#### Résolution

On conserve la même modélisation : les *n* dames sont réparties sur les *n* lignes à raison d'une par ligne. On place les dames une par une tant que cela est possible. Si le placement d'une dame échoue — donc qu'il n'existe pas de position telle que la dame puisse être en sécurité, on remet en question les choix précédents afin de sortir du blocage. On revient alors à un point où des alternatives étaient possibles et on essaie la possibilité suivante.

L'arbre qui sera parcouru contient toutes les positions des dames, valides ou non. On a donc un arbre de la forme de la figure ci-dessous.

![Application du backtracking au problème](/images/eight_queens/backtracking_queens.png){.center}

Commençons par nous pencher sur la fonction indiquant si une dame est en sécurité. Nous ne fonctionnons plus avec des permutations contenant toutes les positions des dames mais sur des positions partielles valides par rapport auxquelles on vérifie si l'on peut ajouter une dame à une position donnée. Plutôt que de vérifier à nouveau la validité de l'intégralité de la solution, on vérifie que l'ajout d'une dame à la position donnée produit une solution valide.

On teste donc :

 * que la colonne que laquelle la dame a été placée n'est pas déjà attribuée à une autre dame en vérifiant que le tableau de solutions ne contient pas la colonne que l'on cherche à attribuer ;
 * qu'aucune dame ne se trouve sur les mêmes diagonales que la nouvelle.

```python
def is_safe(col, queens):
    line = len(queens)
    return (not col in queens and
            not any(abs(col - x) == line - i for i,x in enumerate(queens)))
```

Passons à la résolution en elle-même. Pour chaque nouvelle ligne, on va tester l'intégralité des colonnes au regard des solutions obtenues jusqu'à la ligne précédente. Cela donne :

```python
def solve(n):
    # Initialisation des solutions pour une taille 0 (tableau contenant un tableau vide)
    solutions = [ [] ]
    for row in range(n):
        solutions = [solution + [i] for solution in solutions
                                    for i in range(n)
                                    if is_safe(i, solution)]
    return solutions
```

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
