Title: Gestion des accès concurrents sur un cache de DAO
Date: 2015-11-07
Category: Blog
Tags: java, guava, cache, dao, verrou, concurrence


L'ajout d'un cache sur un DAO est une opération courante et la bibliothèque Guava, très répandue, a par ailleurs énormément simplifié sa mise en œuvre. Néanmoins, il reste encore extrêmement facile de se tromper avec cette bibliothèque et... de réaliser un cache qui ne fonctionne pas.

### Contexte

Partons d'une interface de DAO « classique » permettant de réaliser les opérations *CRUD*. On y ajoute une méthode `getAll` qui retourne l'intégralité des objets (vous allez voir, c'est pour votre bien).

```java
public interface Dao {
  Optional<MyObject> get(String id);
  Iterable<MyObject> getAll();
  void save(MyObject myObject);
  void delete(String id);
}
```

Sans accorder d'importance à l'implémentation du DAO accédant effectivement aux données persistées, contentons-nous de supposer que ses performances ne sont pas suffisantes pour répondre aux sollicitations auxquelles est soumise notre application.


### Cache des données

On se propose d'utiliser [Guava](https://github.com/google/guava) pour implémenter ce cache. On utilise dans cet exemple un [`LoadingCache`](https://github.com/google/guava/wiki/CachesExplained) qui ira chercher en base la donnée s'il n'a pas déjà été sollicité pour celle-ci : on charge les valeurs une à une à la demande. Il permet également de rafraîchir les données automatiquement à intervalle régulier.

L'encapsulation des données de cache dans des `Optional` est un parti pris. Deux choix étaient possibles :

 * on peut choisir d'ignorer les valeurs inexistantes, auquel cas, si celles-ci sont demandées plusieurs fois, ce sont autant d'appels à la base qui seront faits ;
 * on peut également choisir de placer une sentinelle dans le cache (en l'occurrence, l'instance « absente » d'`Optional`).

Les deux approches ont leur avantages et leurs inconvénients et leur utilisation dépend de votre application et de vos besoins.

```java
LoadingCache<String, MyObject> cache = CacheBuilder.newBuilder()
    .build(new CacheLoader<String, Optional<MyObject>>() {
      @Override
      public Optional<MyObject> load(String key) throws Exception {
        return dbDao.get(key);
      }
    });
```

### Implémentation naïve (et fausse)

En première approche, on peut supposer qu'il « suffit » de mettre à jour le cache pour chaque opération d'écriture sur la base de données. Une implémentation dans cette optique ressemblerait à ceci.

```java
public class CachedDao implements Dao {

  // DAO accédant aux données persistées.
  // Dans la vraie vie, vous l'auriez injecté, hein ?
  private final DbDao dbDao;

  private final LoadingCache<String, MyObject> cache = createCache();

  public CachedDao() {
    this.dbDao = new DbDao();
    // Initialisation du cache : nécessaire pour utiliser le cache sur getAll.
    initCache();
  }

  public Optional<MyObject> get(String id) {
    return cache.get(id);
  }

  public Iterable<MyObject> getAll() {
    return cache.asMap()
                .values()
                .stream()
                .map(Optional::get)
                .collect(Collectors.toList());
  }

  public void save(MyObject myObject) {
    dbDao.save(myObject);
    cache.refresh(myObject.getId());
  }

  public void delete(String id) {
    dbDao.delete(id);
    cache.refresh(id);
  }

  public void refresh() {
    // Vidage intégral du cache puis rechargement.
    cache.invalidateAll();
    initCache();
  }

  private void initCache() {
    for (MyObject myObject : dbDao.getAll()) {
      cache.put(myObject.getId(), Optional.of(myObject));
    }
  }
}
```

Pourquoi cette implémentation ne fonctionne pas ?

Dans le cas de multiples appels concurrents, des interruptions peuvent avoir lieu à tout moment. L'appel à `delete` peut être interrompu entre la mise à jour de la base (`dbDao.delete(id)`) et le rafraîchissement du cache (`cache.refresh(id)`). Si cette interruption se fait à la faveur d'une lecture (`get`), cette dernière se fera sur un cache qui n'est pas encore mise à jour et donc renverra une donnée « périmée ». Rien ne dit qu'il est impératif de récupérer la dernière version de la donnée : suivant votre application, cela peut être acceptable.

Mais alors, pire : supposons qu'un appel à `getAll` provoque une interruption pendant un rafraîchissement du cache, au milieu de la boucle de rechargement de la méthode `initCache`. On retourne alors une version incohérente (partielle) des données. Cette situation n'est, elle, pas acceptable.


### Le problème des lecteurs et des rédacteurs

Le cas de figure dans lequel nous nous trouvons correspond à un problème bien connu formulé par Edsger Dijkstra pour modéliser... les accès aux bases de données. Ceux-ci sont soumis à deux contraintes :

 * plusieurs lecteurs doivent pouvoir lire dans la base simultanément ;
 * si un rédacteur est en train de modifier la base de données, aucun autre utilisateur (qu'il soit lecteur ou rédacteur) ne doit pouvoir y accéder.

Une solution simple revient à attendre, lorsqu'un rédacteur se présente, d'attendre que tous les lecteurs soient partis et de bloquer l'entrée à tout nouvel utilisateur. En utilisant un sémaphore (`db`) et un compteur (`rc`), cela reviendrait à :

 0. Le premier lecteur à entrer acquiert le sémaphore `db`.
 0. Tous les lecteurs entrant incrémentent le compteur `rc`.
 0. En sortant, ils décrémentent ce compteur.
 0. Le dernier lecteur à sortir débloque le sémaphore `db` et autorise alors un rédacteur en attente, s'il y en a un, à entrer.

Sur notre exemple de DAO, la modification se ferait de la sorte (ce qui n'est pas explicitement redéfini n'a pas changé) :


```java
public class CachedDao implements Dao {

  private final Semaphore lock = new Semaphore(1);
  private final AtomicLong concurrentAccess = new AtomicLong(0);

  public Optional<MyObject> get(String id) throws InterruptedException {
    if (concurrentAccess.incrementAndGet() == 1) {
      // Premier lecteur à entrer
      lock.acquire();
    }

    Optional<MyObject> returnValue = Optional.ofNullable(cache.getIfPresent(id));

    if (concurrentAccess.decrementAndGet() == 0) {
      // Dernier lecteur à sortir
      lock.release();
    }

    return returnValue;
  }

  public void save(MyObject myObject) throws InterruptedException {
    // Attente que le dernier utilisateur sorte
    lock.acquire();

    dbDao.save(myObject);
    cache.refresh(myObject.getId());

    // Libération pour qu'un utilisateur puisse revenir
    lock.release();
  }

  public void delete(String id) throws InterruptedException {
    // Idem.
  }
}

```

Mais s'il rentre un lecteur toutes les deux millisecondes et qu'il faut cinq millisecondes à chaque lecteur pour terminer sa consultation, il y aura toujours des lecteurs présents et le rédacteur ne pourra jamais entrer.

Pour éviter cela, il faut que lorsqu'un rédacteur est en attente, tout lecteur qui se présente reste « derrière » le rédacteur et attende qu'il ait terminé.

En Java, [la classe `ReentrantReadWriteLock`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/locks/ReentrantReadWriteLock.html) permet de répondre à cette condition. Il encapsule deux types de verrous :

 * un verrou en lecture que tous les lecteurs peuvent « passer » tant qu'aucun verrou en écriture n'a été posé ;
 * un verrou en écriture que tous les rédacteurs peuvent « passer » tant qu'aucun verrou en lecture ou en écriture n'a été posé.

Exemple en lecture :

```java
ReadWriteLock readWriteLock = new ReentrantReadWriteLock();

readWriteLock.readLock().lock();

  // Cette section est accessible par plusieurs lecteurs simultanément
  // si aucun verrou en écriture n'a été acquis.

readWriteLock.readLock().unlock();
```

Exemple en écriture :

```java
ReadWriteLock readWriteLock = new ReentrantReadWriteLock();

readWriteLock.writeLock().lock();

  // Cette section est accessible par un seul rédacteur à la fois
  // si aucun verrou n'est acquis (en lecture ou en écriture).

readWriteLock.writeLock().unlock();
```

### Implémentation « sûre »

Nous pouvons réutiliser notre implémentation naïve : si elle n'était pas sûre, son intention restait valable. Pour l'adapter, on ajoute :

 * des verrous en lecture sur les méthodes de lecture ;
 * des verrous en écriture sur les méthodes d'écriture ;
 * et... c'est tout.

Il est en revanche nécessaire de « protéger » la libération des verrous. Si un traitement se passe mal — si par exemple si une exception est lancée — le verrou doit malgré tout être libéré. On encapsulera donc tout le code des sections critiques dans un bloc `try` / `finally`.

Le code n'ayant pas changé pa rapport à la première version n'est pas représenté.

```java
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class CachedDao implements Dao {

  private final ReadWriteLock rwLock = new ReentrantReadWriteLock();

  public Optional<MyObject> get(String id) {
    rwLock.readLock().lock();
    try {
      return unsafeGet(id);
    } finally {
      rwLock.readLock().unlock();
    }
  }

  public Iterable<MyObject> getAll() {
    rwLock.readLock().lock();
    try {
      return cache.asMap()
                  .values()
                  .stream()
                  .map(Optional::get)
                  .collect(Collectors.toList());
    } finally {
      rwLock.readLock().unlock();
    }
  }

  public void save(MyObject myObject) {
    rwLock.writeLock().lock();
    try {
      unsafeSave(myObject);
    } finally {
      rwLock.writeLock().unlock();
    }
  }

  public void delete(String id) {
    rwLock.writeLock().lock();
    try {
      unsafeDelete(id);
    } finally {
      rwLock.writeLock().unlock();
    }
  }

  public void refresh() {
    rwLock.writeLock().lock();
    try {
      unsafeRefresh();
    } finally {
      rwLock.writeLock().unlock();
    }
  }

  private Optional<MyObject> unsafeGet(String id) {
    return Optional.ofNullable(cache.getIfPresent(id));
  }

  private void unsafeSave(MyObject myObject) {
    dbDao.save(myObject);
    cache.refresh(myObject.getId());
  }

  private void unsafeDelete(String id) {
    dbDao.delete(id);
    cache.refresh(id);
  }

  private void unsafeRefresh() {
    // Vidage intégral du cache puis rechargement.
    cache.invalidateAll();
    initCache();
  }

  private void initCache() {
    for (MyObject myObject : dbDao.getAll()) {
      cache.put(myObject.getId(), Optional.of(myObject));
    }
  }
}

```

### Pour aller plus loin

Le DAO présenté ici est « sûr » dans la mesure où il garantit la cohérence avec la base des données retournées. En revanche, pour cela, un compromis sur les performances a du être fait. En effet, cette implémentation ne permet pas d'écritures simultanées : la modification de deux objets distincts n'est pas possible.

Peut-on faire mieux ? Si vous pensez que oui, quelle serait votre approche ?
