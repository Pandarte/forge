# Forge — interface de compilation Android locale

App Android (Kotlin / Jetpack Compose, Material 3 Expressive, couleurs Material
You dynamiques) qui pilote la chaîne de compilation locale `android-build-tools`
via un petit serveur HTTP tournant dans Termux.

Page unique : tu colles une URL de dépôt git en haut, tu appuies sur **Compiler**,
les logs défilent en direct dessous, et à la fin tu installes l'APK produit.

## Architecture

```
  App Forge (Compose)  --HTTP 127.0.0.1:8765-->  buildserver.py (Termux/proot)
        |                                              |
   saisie URL, logs,                          lance android-builder.sh
   bouton installer                           (clone, detecte, build via qemu)
```

L'app ne fait QUE l'interface. Toute la compilation se passe côté serveur (là où
vit la chaîne aapt2+qemu). C'est obligatoire : une app Android sandboxée ne peut
pas lancer proot/qemu elle-même.

## Pré-requis (côté téléphone, une fois)

1. Termux installé, avec la chaîne `android-build-tools` (voir son README) et le
   `buildserver.py` placés dans le proot Ubuntu.
2. Le serveur lancé :
   ```bash
   proot-distro login ubuntu
   python3 ~/buildserver/buildserver.py
   ```
   (ou en service auto : voir `start-build-server.sh`.)
3. Forge installée et lancée. Elle teste la connexion au serveur au démarrage.

Au premier lancement, si la chaîne n'est pas installée, l'app propose un bouton
**Installer la chaîne** qui déclenche `setup-aapt2-qemu.sh` côté serveur et en
montre les logs.

## Compiler l'app Forge elle-même

Jolie boucle : Forge se compile avec la chaîne qu'elle pilote. Soit via GitHub
Actions (sûr), soit en local :
```bash
bash ~/android-build-tools/build-android-local.sh ~/Forge
```
(Projet Android natif, compileSdk 36, AGP 8.13 — aligné sur la chaîne.)

## État et limites — à lire

Ce projet est **complet en structure et en logique**, mais il n'a PAS encore été
compilé sur une vraie toolchain Android (impossible dans l'environnement où il a
été généré). Concrètement :

- **Versions de dépendances** : `material3:1.4.0-alpha10` (pour Material 3
  Expressive) et le compose-bom `2025.06.00` sont indiqués. Les versions alpha
  bougent vite ; si Gradle refuse une version, prends la dernière `material3`
  alpha disponible et le BOM correspondant. Les noms d'API Expressive
  (formes, motion) peuvent différer selon l'alpha.
- **Premier build = débogage probable**. Attends-toi à 1–3 erreurs de
  compilation à corriger (import manquant, signature d'API Compose qui a changé
  entre alphas). C'est normal pour du code Compose non compilé sur place.
- **Material You dynamique** : effectif sur Android 12+ (le tien l'est). En
  dessous, repli sur palette neutre.
- **Sécurité réseau** : l'app n'autorise le trafic clair que vers 127.0.0.1
  (voir `network_security_config.xml`). Rien ne sort du téléphone.

Quand tu le compileras (via GitHub Actions de préférence pour ce premier essai),
envoie-moi les erreurs de build s'il y en a, et on les corrige une par une.

## Fichiers

```
app/src/main/
  AndroidManifest.xml
  java/fr/buildtool/app/
    MainActivity.kt        theme Material You + edge-to-edge
    BuildScreen.kt         l'UI : URL, bouton, resultat, console de logs
    BuildViewModel.kt      etat + polling des logs
    BuildClient.kt         client HTTP du serveur local
  res/xml/network_security_config.xml
  res/values/strings.xml
```
