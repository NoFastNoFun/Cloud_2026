# Document d'Architecture Technique (DAT) - Synthèse Décisionnelle

**Projet :** GreenLeaf - Opération Black Friday 2026
**Public Cible :** Direction Générale, Sponsors Métier, Comité d'Architecture

---

## 1. Résumé Exécutif (Executive Summary)

Pour réussir l'opération "Black Friday", GreenLeaf doit relever un défi critique : **accueillir jusqu'à 90 000 clients simultanément sans le moindre ralentissement ni interruption de service, tout en blindant la sécurité des données et en réduisant drastiquement les coûts d'hébergement inutiles.** 

Ce document présente la stratégie de la plateforme Cloud (AWS) que nous avons conçue. Plus qu'un simple empilement de serveurs, nous avons construit une véritable **usine digitale automatisée**. Elle est capable de multiplier sa puissance en direct face à l'afflux des clients, et de se rétracter quand le magasin se vide. Le tout est déployable sur commande, car toute l'infrastructure est devenue de la propriété intellectuelle stockée sous forme de code (*Infrastructure as Code*).

## 2. Les Engagements de Service (Les Promesses Métier)

Notre conception ne s'appuie pas sur des espoirs, mais sur des indicateurs démontrés qui garantissent le Chiffre d'Affaires de GreenLeaf :
*   **0 perte de Chiffre d'Affaires due au krach** : L'infrastructure a été certifiée pour encaisser le volume des 90 000 utilisateurs sans tomber.
*   **Abolition de l'abandon de panier (Latence cible < 2s)** : Nous avons démontré sous charge sévère un temps de réponse ahurissant de **135 millisecondes**, garantissant une navigation instantanée pour le client.
*   **Fiabilité transactionnelle (Max 1% d'erreur autorisé)** : Les tirs de charge intensifs valident un taux d'échec de **0 %**.
*   **Continuité d'activité garantie** : En cas de catastrophe continentale chez notre hébergeur (AWS), le site peut renaître de ses cendres sur une autre région d'Europe (Plan de Reprise d'Activité).

## 3. Vue d'Ensemble de l'Architecture (Comment ça marche ?)

Pour comprendre notre dispositif, il suffit de l'imaginer comme un centre commercial physique ultra-moderne :

1. **Le Vigile et la Vitrine (AWS CloudFront & bouclier WAF)**
   C'est la première ligne de défense. Le WAF agit comme la sécurité qui bloque instantanément les hackers et les vagues de piratage. CloudFront est notre vitrine ultra-rapide : elle distribue le catalogue, les images et les recherches à **85% des visiteurs sans même les faire entrer dans le magasin principal**. C'est notre secret absolu pour servir 90 000 personnes sans exploser les budgets.
2. **Le Super-Aiguilleur (L'Équilibreur de charge ALB)**
   Il s'assure qu'aucun de nos serveurs n'est surchargé. Dès qu'un client "entre", il est dirigé vers la caisse la moins occupée du magasin, garantissant fluidité et zéro attente.
3. **Le Moteur Élastique (L'Auto Scaling EC2)**
   Ce sont nos serveurs (les employés de caisse). La magie du Cloud opère ici : s'il y a 10 clients, l'infrastructure allume 1 seul serveur. Si les 90 000 arrivent d'un coup, l'architecture instancie automatiquement et en quelques secondes des dizaines de serveurs pour absorber le choc, et surtout, **elle les détruit automatiquement une fois la vague passée** pour stopper la facturation tarifaire de l'hébergeur.
4. **Le Coffre-Fort central blindé (La Base de données RDS & son Proxy)**
   C'est là que vivent nos produits et nos commandes clients. Pour éviter que le coffre ne se fige sous le poids de millions de requêtes, nous l'avons protégé avec un "sas" de filtrage intelligent (RDS Proxy) qui empêche le dysfonctionnement même en cas de folie acheteuse mondiale.

## 4. Sécurité et Protection de la Donnée (L'Assurance Tous Risques)

La conception s'est alignée sur le modèle militaire du **Zéro Confiance (Zero Trust)** :
- **Invisibilité absolue :** Nos serveurs et nos bases de données clients sont placés dans des "sous-réseaux privés". Ils sont **physiquement imperméables à l'Internet public**. Aucun pirate ne peut frapper la base de données depuis l'extérieur.
- **Défense en profondeur :** Seul notre aiguilleur (ALB) a le droit de parler avec nos serveurs. Et seuls nos serveurs ont le droit de parler à notre base de données. Tous les chemins de traverse ont été murés.
- **Chiffrement Industriel :** Toutes les bases de données importantes sont chiffrées au repos par la suite AWS KMS, au standard de la norme AES-256 (standard défensif et bancaire).
- **Le coffre à secrets :** Aucun mot de passe n'existe dans le code de nos développeurs. L'architecture va injecter et injecter elle-même des mots de passe rotatifs et cryptés depuis un coffre impénétrable (AWS Secrets Manager).

## 5. Gouvernance Financière "FinOps" (Maîtrise du budget)

Un ingénieur lambda aurait empilé d'énormes serveurs "au cas où" en gaspillant des milliers d'euros. L'ingénierie que nous avons déployée adopte une stratégie **FinOps by design** :
- **Le "Right-sizing" :** Notre socle standard repose sur des micro-serveurs (	3.micro), qui sont parmi les moins chers de l'offre AWS. L'autoscaling linéaire compense leur petite taille, offrant une facturation chirurgicalement liée au trafic.
- **Hack tarifaire réseau :** Les composants classiques d'AWS (les NAT Gateways) coûtent extrêmement cher chaque mois (plus de 30€ fixe plus le trafic). Nous avons programmé Terraform pour installer une "NAT Instance" customisée d'une valeur de 4€, remplissant le même rôle, réduisant ce poste de coût d'un facteur 10.
- **Stratégie d'éviction du "stockage mort" :** La rétention des millions de journaux de connexion et logs a été plafonnée intentionnellement à 3 jours, évitant de payer indéfiniment du stockage mortuaire obsolète.

## 6. Le Plan de Reprise d'Activité (Le Parachute de Secours)

Si la région principale (en Irlande) d'Amazon tombe totalement en panne ou brûle :
- Notre infrastructure n'est plus un amas de clics manuels et de câbles informatiques. C'est un code source de 2 MégaOctets (Terraform).
- Nous avons programmé une bascule d'urgence vers l'Allemagne (Francfort). Il suffit d'activer un levier central (enable_dr = true), et en quelques minutes l'outil "imprime" les serveurs en Allemagne et dévie les clients. Ce cluster de secours est "froid" au quotidien, garantissant un coût d'usage proche de Zéro lorsqu'il n'y a pas d'urgence.

## 7. Conclusion pour Validation de la Direction

En adoptant cette conception architecturale certifiée par les tirs de performances k6, la Direction Générale et ses Sponsors investissent dans bien plus qu'une mise à niveau "Black Friday". Vous devenez propriétaires d'une **usine digitale performante, extrêmement agressive sur la réduction des coûts dormants, sécurisée dès l'entrée et prête à s'étendre à l'infini.**


