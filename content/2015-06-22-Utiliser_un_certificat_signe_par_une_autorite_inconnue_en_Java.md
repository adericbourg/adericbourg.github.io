Title: Utiliser un certificat signé par une autorité inconnue en Java
Date: 2015-06-22
Category: Blog
Tags: ssl, tls, java, certificat, signature

Lorsque vous vous connectez à un serveur en utilisant un certificat TLS (le grand frère de SSL depuis une quinzaine d'années), votre client en vérifie la signature. Celle-ci permet de vérifier que : 

 * celui-ci provient bien d'un émetteur connu ;
 * qu'il n'a pas été modifié depuis son émission.

## Le doute

Il arrive que le certificat soit signé en utilisant un certificat qui est lui-même signé par un autre certificat, lui-même encore signé par... bref : la signature peut remonter sur plusieurs niveaux hiérarchiques. Dans les faits, cela ne change pas grand chose : la vérification sera tout simplement récursive. Le tout est de rencontrer dans la chaîne, généralement « tout en haut » la signature issue d'un certificat faisant autorité. Ces autorités sont connues à l'avance et vous pouvez les vérifier dans les paramètres de votre natigateur ou, par exemple, dans le répertoire `/etc/ssl/certs` si vous êtes sous Linux.

Il s'agit donc d'une liste fermée qui vous a été fournie par un biais ou un autre mais surtout par en biais en lequel vous avez confiance (ou en lequel on vous a obligé à avoir confiance). Mais rien n'oblige qui que ce soit à utiliser l'une de ces autorités racines : on peut également utiliser un certificat auto-signé. Dans ce cas, rien ne permet de garantir avec certitude l'émetteur : au même titre que vous ferez confiance en l'identité de quelqu'un s'il vous présente sa carte d'identité éditée par l'État, vous aurez probablement des doutes si l'on ne vous présente qu'un papier signé par la-dite personne affirmant sa bonne foi. 

Dans la « vraie vie », ce n'est pas parce qu'un individu n'est pas en mesure de vous présenter un document officiel d'identité qu'il est malhonnête. S'il vous présente son badge d'accès à l'entreprise dans laquelle vous travaillez, vous lui ferez confiance et saurez que c'est l'un de vos collègues. Dans ce cas, c'est votre entreprise qui fait autorité et vous faites confiance à son processus d'attribution des badges. De la même façon, un serveur qui utilise un certificat qui n'est pas signé par une autorité reconnue peut tout à fait venir en paix avec de bonnes intentions. 

Un certificat accepté et reconnu dans un environnement restreint est donc préférable à pas de certificat du tout.

## L'arrivée des problèmes

Mais, généralement, lorsque votre client ne connaît pas l'autorité de certification racine, il refuse par défaut la connexion : 

    $ curl -v https://www.exemple.com
    * Rebuilt URL to: https://www.example.com/
    * Hostname was NOT found in DNS cache
    *   Trying 1.2.3.4...
    * Connected to www.example.com (1.2.3.4) port 443 (#0)
    * successfully set certificate verify locations:
    *   CAfile: none
        CApath: /etc/ssl/certs
    * SSLv3, TLS handshake, Client hello (1):
    * SSLv3, TLS handshake, Server hello (2):
    * SSLv3, TLS handshake, CERT (11):
    * SSLv3, TLS alert, Server hello (2):
    * SSL certificate problem: unable to get local issuer certificate
    * Closing connection 0

## Comment se connecter, alors ?

Face à cela (ignorons la [référence à SSLv3](https://fr.wikipedia.org/wiki/POODLE) pour l'instant), deux options sont possible (la troisième, refiler le bébé à votre collègue, n'étant pas traitée ici) :

 * ignorer les doutes quant au certificat et risquer de communiquer des informations sensibles à un tiers (c'est la porte ouvert à une [attaque de l'homme du milieu](https://fr.wikipedia.org/wiki/Attaque_de_l%27homme_du_milieu) puisque vous ne vérifiez plus du tout avec qui vous échangez des données) ;
 * indiquer que l'on connaît l'autorité racine ou l'une des autorités intermédiaires. 

Je ne peux que vous déconseiller avec toute la vigueur qui m'est donnée la première solution et vous apporter tout mon soutien pour la seconde. 

Pour reprendre l'exemple ci-dessus, l'appel avec `curl` est simplement complété avec l'option `--cacert` :

    $ curl -v https://www.example.com --cacert cert.pem

## Depuis une application Java

Le même mécanisme s'applique lorsque vous vous connectez à un service en utilisant une application Java. Si le certificat n'est pas sûr, vous vous verrez refuser la connexion : 

    sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target

Tout comme avec `curl`, il existe une option pour spécifier un certificat faisant autorité. Il faut avant tout le stocker dans un conteneur spéficique à la JVM puis de préciser son emplacement dans la propriété système `javax.net.ssl.trustStore`. 

Pour créer ce conteneur, on utilise l'outil `keytool` fourni avec le JDK. 

    $ keytool -importcert -file cert.cer -keystore keystore.jks
    Entrez le mot de passe du fichier de clés :  
    Ressaisissez le nouveau mot de passe :  
    # Ici s'affichent les détails du certificat que vous importez
    Faire confiance à ce certificat ? [non] :  oui
    Certificat ajouté au fichier de clés

Reste à le déclarer dans votre application : 

    System.setProperty("javax.net.ssl.trustStore", "/path/to/keystore.jks"); 
    System.setProperty("javax.net.ssl.trustStorePassword", ******);

La propriété `javax.net.ssl.trustStorePassword` correspond au mot de passe que vous avez saisi à l'import du certificat en utilisant `keytool`. Dès lors, vous pouvez vous connecter aux services sécurisés utilisant un certificat propre à votre entreprise.


## Solution globale

Il peut être pénible d'utiliser ce morceau de code dans chacune de vos applications, ou tout au moins fastidieux. Heureusement, il est également possible d'enregistrer un certificat au niveau de la JVM. On le déclare alors une bonne fois pour toutes.

Si vous avez parcouru le répertoire `/etc/ssl/certs` évoqué au début de cet article, vous y aurez peut-être remarqué un répertoire `java`. Il s'agit du portefeuille de certificats dédié à la JVM.

Pour y ajouter un certificat, lancez en tant qu'utilisateur privilégié (*root*) : 

    keytool -import -alias CertificatDeMonEntreprise \
      -keypass changeit \
      -keystore $JAVA_HOME/jre/lib/security/cacerts \
      -file cert.pem

Notez le mot de passe par défaut du *keystore*: « changeit ». Il s'agit du mot de passe par défaut et je vous encourage, si ce n'est déjà fait, à le changer.

Cette opération est à réaliser sur votre machine de développement mais également sur l'intégralité des serveurs susceptibles d'exécuter vos applications. C'est là qu'une solution de déploiement automatique devient pertinente.

Vous êtes maintenant capable de vous connecter depuis une application Java à l'ensemble des services exposés le certificat TLS de votre entreprise et ce sans nécessiter d'adaptation du code. 


## Depuis une application Java (bis)

Si, par malheur, vous ne pouvez pas déposer de fichier sur la machine exécutant votre application (c'est le cas sur certains hébergement « cloud » que je n'aime pas utiliser), vous pouvez toujours « stocker » votre *keystore* dans votre livrable (jar, war...). Mais... vous ne pourrez pas l'utiliser directement. 

La propriété `javax.net.ssl.trustStore` ne permet pas de déclarer de référence à un fichier dans le *package*. On peut en revanche l'écrire « à la main » sur le disque. L'exemple qui suit utilise [Guava](https://github.com/google/guava).

    File tempDir = Files.createTempDir();
    File myStore = new File(tempDir, "keystore.jks");
    try (InputStream storeStream = MyExample.class.getClassLoader().getResourceAsStream("keystore.jks");
            FileOutputStream outputStream = new FileOutputStream(myStore)) {
            ByteStreams.copy(storeStream, outputStream);
            System.setProperty("javax.net.ssl.trustStore", myStore.getAbsolutePath());
            System.setProperty("javax.net.ssl.trustStorePassword", *******);
    } catch (IOException e) {
            logger.error("Cannot set trust store", e);
    }

Voilà qui devrait vous permettre de communiquer avec le reste du monde.

