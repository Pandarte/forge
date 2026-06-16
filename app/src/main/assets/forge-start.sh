#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# forge-start.sh  --  DEMARRAGE RAPIDE
# A coller et lancer dans TERMUX. Suppose que l'installation complete a deja
# ete faite. Verifie la chaine, la repare si besoin, puis lance le serveur.
# =============================================================================
set -u

echo "=== Forge - demarrage rapide ==="

# Proot a utiliser pour la compilation (Debian minimal).
DISTRO="debian"

# verifie que le proot existe (test robuste : dossier rootfs, independant des
# options de proot-distro qui varient selon les versions)
DISTRO_ROOT="$PREFIX/var/lib/proot-distro/containers/$DISTRO"
if [ ! -d "$DISTRO_ROOT" ]; then
    echo "ERREUR: le proot '$DISTRO' n'est pas installe."
    echo "Lance d'abord le script d'installation complete (bootstrap-debian-build.sh)."
    exit 1
fi

# sous-script execute dans le proot : verifie/repare la chaine, puis sert
INNER="/data/data/com.termux/files/home/.forge-start-inner.sh"
cat > "$INNER" <<'INNEREOF'
#!/bin/bash
set -u
HOME_DIR="$HOME"
TOOLS="$HOME/android-build-tools"
SHIM="$HOME/aapt2-shim"
AAPT2="$HOME/aapt2-x86/aapt2"
SERVER="$HOME/buildserver/buildserver.py"

echo "-- verification de la chaine --"
need_setup=0
[ -x "$SHIM" ]  || { echo "  shim manquant"; need_setup=1; }
[ -x "$AAPT2" ] || { echo "  aapt2 x86 manquant"; need_setup=1; }
command -v qemu-x86_64 >/dev/null || { echo "  qemu manquant"; need_setup=1; }

if [ "$need_setup" = 1 ]; then
    echo "-- reparation de la chaine (setup) --"
    if [ -f "$TOOLS/setup-aapt2-qemu.sh" ]; then
        bash "$TOOLS/setup-aapt2-qemu.sh" || {
            echo "ECHEC du setup. Lance l'installation complete."; exit 1; }
    else
        echo "ERREUR: $TOOLS/setup-aapt2-qemu.sh introuvable. Installation complete requise."
        exit 1
    fi
else
    echo "  chaine OK."
fi

# test rapide du shim
if "$SHIM" version 2>/dev/null | grep -q "Android Asset Packaging Tool"; then
    echo "  shim fonctionnel : $("$SHIM" version 2>/dev/null)"
else
    echo "  AVERTISSEMENT: le shim ne repond pas comme attendu."
fi

if [ ! -f "$SERVER" ]; then
    echo "ERREUR: serveur introuvable a $SERVER"
    echo "Re-depose buildserver.py (ou relance l'installation complete)."
    exit 1
fi

echo "-- demarrage du serveur --"
echo "Laisse Termux ouvert. Retourne dans Forge et appuie sur 'Reessayer'."
echo
exec python3 "$SERVER"
INNEREOF
chmod +x "$INNER"

exec proot-distro login "$DISTRO" -- bash "$INNER"
