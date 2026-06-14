#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# forge-install.sh  --  INSTALLATION COMPLETE depuis zero
# A coller et lancer dans TERMUX (pas dans le proot).
#
# Met en place : proot-distro + Ubuntu, JDK, SDK Android, la chaine aapt2+qemu,
# le serveur de build, et le lance. Apres ca, l'app Forge fonctionne.
#
# Idempotent : relancable sans tout casser.
# =============================================================================
set -e

echo "######################################################"
echo "#  Forge - installation complete (Termux -> Ubuntu)  #"
echo "######################################################"

# --- 0. Termux : storage + paquets de base -----------------------------------
echo "== [0/7] Termux : preparation =="
yes | pkg update || true
yes | pkg install -y proot-distro git wget tar
# acces au stockage (pour deposer les APK dans Telechargements)
termux-setup-storage || true

REPO_RAW="https://raw.githubusercontent.com/Pandarte/android-build-tools/master"
# ^ adapte si ton repo d'outils a un autre nom/branche.

# --- 1. Ubuntu via proot -----------------------------------------------------
echo "== [1/7] Installation d'Ubuntu (proot-distro) =="
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/containers/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    proot-distro install ubuntu
else
    echo "Ubuntu deja installe."
fi

# --- 2. tout le reste se passe DANS Ubuntu -----------------------------------
echo "== [2/7] Configuration a l'interieur d'Ubuntu =="

# On ecrit un sous-script qui sera execute dans le proot.
INNER="/data/data/com.termux/files/home/.forge-inner-setup.sh"
cat > "$INNER" <<'INNEREOF'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "  -> paquets Ubuntu"
apt-get update -y
apt-get install -y --no-install-recommends \
    openjdk-21-jdk-headless wget unzip zip git python3 \
    qemu-user gcc ca-certificates

echo "  -> SDK Android (cmdline-tools)"
export ANDROID_HOME="$HOME/android-sdk"
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    cd /tmp
    wget -q -O cmd.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip -q cmd.zip -d "$ANDROID_HOME/cmdline-tools"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
echo "  -> plateformes SDK (34, 35, 36) + build-tools + platform-tools"
yes | sdkmanager "platform-tools" "build-tools;36.0.0" \
    "platforms;android-34" "platforms;android-35" "platforms;android-36" >/dev/null 2>&1 || true

echo "  -> Node.js (via nvm) pour les projets Capacitor / React Native"
# Le node/npm d'apt sur Ubuntu recent est souvent casse (module 'glob'
# introuvable). On installe Node 20 LTS via nvm, qui embarque un npm sain,
# puis on cree des liens dans /usr/local/bin pour que node/npm soient
# accessibles meme en shell non-interactif (quand le serveur lance le build).
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    apt-get remove -y nodejs npm >/dev/null 2>&1 || true
    apt-get autoremove -y >/dev/null 2>&1 || true
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm install 20
    nvm use 20
    ln -sf "$(which node)" /usr/local/bin/node
    ln -sf "$(which npm)"  /usr/local/bin/npm
    ln -sf "$(which npx)"  /usr/local/bin/npx
fi
echo "     node $(node --version 2>/dev/null), npm $(npm --version 2>/dev/null)"
# Capacitor CLI global (utile pour 'cap sync')
npm install -g @capacitor/cli >/dev/null 2>&1 || true

echo "  -> recuperation des outils Forge (android-build-tools + serveur)"
cd "$HOME"
TOOLS="$HOME/android-build-tools"
if [ ! -d "$TOOLS" ]; then
    # tente un clone ; sinon, l'app aura depose les fichiers (voir note plus bas)
    git clone --depth 1 https://github.com/Pandarte/android-build-tools.git "$TOOLS" \
        || echo "  (clone impossible : depose les scripts manuellement dans $TOOLS)"
fi

echo "  -> installation de la chaine aapt2+qemu"
if [ -f "$TOOLS/setup-aapt2-qemu.sh" ]; then
    bash "$TOOLS/setup-aapt2-qemu.sh"
else
    echo "  ATTENTION: setup-aapt2-qemu.sh introuvable dans $TOOLS"
fi

echo "  -> serveur de build"
mkdir -p "$HOME/buildserver"
# le buildserver.py est fourni par l'app ; si present a cote, on le copie
[ -f "$TOOLS/buildserver.py" ] && cp "$TOOLS/buildserver.py" "$HOME/buildserver/" || true

echo "  Configuration interne terminee."
INNEREOF
chmod +x "$INNER"

proot-distro login ubuntu -- bash "$INNER"

# --- 3. service de demarrage auto du serveur ---------------------------------
echo "== [6/7] Service de demarrage automatique du serveur =="
pkg install -y termux-services || true
SVC="$PREFIX/var/service/forge-server"
mkdir -p "$SVC"
cat > "$SVC/run" <<'RUNEOF'
#!/data/data/com.termux/files/usr/bin/sh
exec proot-distro login ubuntu -- python3 /root/buildserver/buildserver.py
RUNEOF
chmod +x "$SVC/run"
sv-enable forge-server 2>/dev/null || true

# --- 4. lancement immediat ---------------------------------------------------
echo "== [7/7] Demarrage du serveur =="
echo "Le serveur va demarrer. Laisse Termux ouvert (ou en arriere-plan)."
echo "Retourne dans l'app Forge et appuie sur 'Reessayer'."
echo
proot-distro login ubuntu -- python3 /root/buildserver/buildserver.py
