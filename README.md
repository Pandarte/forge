# ⚡ APKforge

**Interface Android de compilation d'APK, pilotée depuis le téléphone.**

APKforge est une application Android (Kotlin / Jetpack Compose, Material 3
Expressive, couleurs Material You dynamiques) qui pilote une chaîne de
compilation locale tournant dans Termux. On colle l'URL d'un dépôt git, on
appuie sur **Compiler**, les logs défilent en direct, et l'APK produit est
récupérable à la fin — le tout sans quitter le téléphone.

<p align="left">
  <img alt="Plateforme" src="https://img.shields.io/badge/plateforme-Android%2012%2B-3DDC84">
  <img alt="Langage" src="https://img.shields.io/badge/Kotlin-Jetpack%20Compose-7F52FF">
  <img alt="minSdk" src="https://img.shields.io/badge/minSdk-26-blue">
  <img alt="compileSdk" src="https://img.shields.io/badge/compileSdk-36-blue">
</p>

---

## Fonctionnement

APKforge ne fait que l'**interface**. Toute la compilation se déroule côté
serveur, là où vit la chaîne `aapt2` + `qemu`. C'est une nécessité technique :
une application Android isolée dans son bac à sable ne peut pas lancer
`proot`/`qemu` elle-même.

```
  App APKforge (Compose)  ──HTTP 127.0.0.1:8765──▶  buildserver.py (Termux / proot)
        │                                                  │
   saisie de l'URL,                              lance android-builder.sh
   logs en direct,                               (clone, détecte, build via qemu)
   bouton installer
```

Le projet compagnon qui exécute réellement les builds est
[`android-build-tools`](https://github.com/Pandarte/android-build-tools).

## Prérequis

À configurer une fois sur le téléphone :

1. **Termux** installé, avec la chaîne
   [`android-build-tools`](https://github.com/Pandarte/android-build-tools) et
   son `buildserver.py` en place dans le proot Ubuntu.
2. **Le serveur lancé** :
   ```bash
   proot-distro login ubuntu
   python3 ~/buildserver/buildserver.py
   ```
   (ou en service automatique via `start-build-server.sh`.)
3. **APKforge** installée et lancée. Elle teste la connexion au serveur au
   démarrage.

Au premier lancement, si la chaîne n'est pas détectée, l'application propose un
bouton **Installer la chaîne** qui déclenche l'installation côté serveur et en
affiche les logs.

## Utilisation

1. Coller l'URL d'un dépôt git Android dans le champ en haut.
2. Appuyer sur **Compiler**.
3. Suivre les logs en direct dans la console.
4. Récupérer l'APK produit (`APKforge.apk`) à la fin.

## Compiler APKforge

APKforge se compile avec la chaîne qu'elle pilote — ou via l'intégration
continue.

**GitHub Actions** (le plus simple) : un push sur `main`/`master` déclenche le
workflow [`build.yml`](.github/workflows/build.yml), qui produit l'APK debug et
le met à disposition en artifact.

**En local** depuis Termux :
```bash
bash ~/android-build-tools/build-android-local.sh ~/forge
```

Projet Android natif : `compileSdk 36`, `minSdk 26`, AGP 8.13, Material 3
Expressive (`material3:1.4.0-alpha10`).

## Détails techniques

- **Material You dynamique** : actif sur Android 12 et plus ; repli sur une
  palette neutre en dessous.
- **Sécurité réseau** : le trafic en clair est restreint à `127.0.0.1` (voir
  [`network_security_config.xml`](app/src/main/res/xml/network_security_config.xml)).
  Rien ne quitte le téléphone.
- **Dépendances alpha** : Material 3 Expressive s'appuie sur des versions alpha
  qui évoluent vite. Si Gradle refuse une version, utiliser la dernière
  `material3` alpha disponible et le `compose-bom` correspondant.

## Structure du projet

```
app/src/main/
├── AndroidManifest.xml
├── assets/
│   ├── forge-install.sh          installation de la chaîne côté serveur
│   └── forge-start.sh            démarrage du serveur de build
├── java/fr/buildtool/app/
│   ├── MainActivity.kt           thème Material You + edge-to-edge
│   ├── BuildScreen.kt            UI : URL, bouton, console de logs, animation
│   ├── BuildViewModel.kt         état + polling des logs
│   ├── BuildClient.kt            client HTTP du serveur local
│   └── TermuxHelper.kt           interactions avec Termux
└── res/
    ├── drawable/                 icône adaptative (enclume + Android)
    ├── xml/network_security_config.xml
    └── values/strings.xml
```

## Projets liés

- [`android-build-tools`](https://github.com/Pandarte/android-build-tools) — la
  chaîne de compilation et le serveur HTTP qu'APKforge pilote.
