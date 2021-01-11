---
Title: Comment rendre vos utilisateurs heureux (avec vos métriques)
Category: Blog
Tags: sre, métriques, expérience utilisateur, bonnes pratiques
Date: 2100-01-01
Status: draft
---

Ça y est ! Mon application est déployée en production et reçoit du trafic ! C'est maintenant
que les choses sérieuses commencent : les utilisateurs seront les meilleurs ambassadeurs pour
en faire la promotion... ou pour en dire leur déception. Ce serait utile d'avoir des retours
sur leur perception, de pouvoir mesurer leur expérience mais je n'ai pas le budget pour lancer
une étude.

Je fais donc avec les moyens du bord, et ils sont déjà riches ! Et si je commençais par utiliser
mes métriques applicatives ?

## Adopter de justes proportions

En me mettant à la place de mes utilisateurs, je me dis que ce qui peut arriver de pire serait
de tomber sur une erreur bloquante. C'est quelque chose que je peux mesurer en utilisant  les
codes HTTP des réponses de mon application.

Je ne suis pas parfait : je sais qu'il y en a et qu'il risque d'y en avoir toujours, ne serait-ce
que parce que mon infrastructure n'est pas parfaite et que certains composants peuvent parfois
tomber. Je ne vise pas le zéro absolu mais j'aimerais en avoir le moins possible. Quand soudain,
j'observe une augmentation exponentielle du nombre « d'erreurs 500 » !

![Augmentation exponentielle du nombre de réponses HTTP avec un statut 500](/images/utilisateurs_heureux_metriques/500_exp_increase.png){.center}

Pourquoi cette augmentation subite ? Je n'ai pourtant pas déployé de nouvelle version depuis
quelques jours. Je commence à paniquer. En regardant les logs, ce sont les mêmes erreurs que
d'habitude. Je sais bien que j'aurais dû corriger ça avant mais il y en avait peu, ça n'était
pas prioritaire. Là, c'est l'explosion !

L'explosion, vraiment ? Y en a-t-il vraiment plus qu'avant ? En quantité, c'est certain, mais
qu'en est-il _proportionnellement_ au trafic de mon application ?

* Si cette augmentation du nombre d'erreur s'observe à nombre constant de requêtes, il y a
  effectivement un problème dont je veux être alerté, et vite.
* En revanche, si le nombre de requêtes varie dans les mêmes proportions que le nombre d'erreurs,
  cela semble plus cohérent. Être réveillé la nuit par une alerte qui indique que le trafic a
  augmenté mais tout est normal me mettrait de mauvaise humeur.

![Deux profils du nombre de requêtes associé : nombre constant et croissance exponentielle](/images/utilisateurs_heureux_metriques/500_over_total_request.png){.center}

Une façon d'éviter cette possible confusion est d'exprimer les indicateurs comme une _proportion_
_d'événements valides qui étaient bons_. Si cette formulation peut sembler abstraite, sa mise en
place est beaucoup plus simple. Dans notre exemple d'un système répondant à des requêtes, on
peut mesurer la proportion de requêtes ayant abouti à une réponse de code HTTP de classe 200, 300
ou 400 par rapport au nombre total de requêtes.

> _Pourquoi prendre les codes HTTP de classe 400 comme des succès ?_
>
> S'ils sont perçus comme une erreur vis-à-vis de votre client, il représentent en réalité un
> cas prévu qui correspond à une action non-autorisée de votre utilisateur. Essayer d'accéder à
> une page nécessitant une authentification sans s'être préalablement connecté n'est pas autorisé :
> retourner autre chose qu'un code HTTP 403 serait probablement une erreur.

## Prendre le temps, et le bon

J'ai compris la leçon et j'ai exprimé une métrique importante de mon application comme une
proportion. Le système d'alerte se comporte comme une guirlande de Noël. L'alerte sonne, tout
est rouge, et le temps que je regarde, tout est revenu à la normale. Je pars me faire un café
et en revenant, l'alerte a encore oscillé trois fois entre « tout va bien » et « tout brûle ».

En regardant la courbe, je reste circonspect.

![Courbe d'une métrique quelconque présentant une forte variance sur des périodes de temps très courtes](/images/utilisateurs_heureux_metriques/whatever_short_time_window.png){.center}

Je ne vois rien sur cette courbe. La variance est trop grande, je ne peux en dégager aucune tendance
à l'œil nu. Une solution à cela est de lisser par une fonction d'agrégation sur une fenêtre du temps
plus large que la période d'échantillonnage de vos métriques.



![Courbe d'une métrique quelconque présentant une forte variance sur des périodes de temps très courtes avec en superposition la moyenne glissante sur quelques minutes, beaucoup plus stable](/images/utilisateurs_heureux_metriques/whatever_long_time_window.png){.center}


## Dites 33

## Partez en voyage

## C'est pas tout mais...

pas révélateur de l'ux

> Cet article a également été décliné sous forme d'une présentation aux
> _Human Talks_ Paris le 14 janvier 2020 sous le titre
> [How to make your users happy (with your metrics)](https://www.youtube.com/watch?v=gNMtIdWKfEg).
