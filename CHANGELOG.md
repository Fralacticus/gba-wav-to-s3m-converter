## 1.4.0

- Ajout validation des spécifications requises : Si le fichier wav (commande file), ou les fichiers wav (commande folder), ne respectent pas les spécifications alors le programme se termine prématurément en indiquant celles qui ne sont pas respectées.

## 1.3.0

- Ajout possibilité, pour la commande `file`, de choisir l'intervalle de secondes entre chaque segment (par défaut 5s)
    - argument : `--split_interval_sec` ou `-s` suivit du nombre secondes (entier supérieur à 0)
 
## 1.2.0

- Suppression 2eme canal non utilisé
- Amélioration action de déploiement: cible linux et macOS en plus

## 1.1.1

- Ajout et correction temp dynamique

## 1.1.0

- Retrait adhérence au logiciel externe SoX

## 1.0.0

- Version initiale.
