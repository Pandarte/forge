package fr.buildtool.app

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast

/** Lit un fichier des assets et renvoie son contenu. */
fun readAsset(ctx: Context, name: String): String =
    ctx.assets.open(name).bufferedReader().use { it.readText() }

/** Copie [text] dans le presse-papier. */
fun copyToClipboard(ctx: Context, label: String, text: String) {
    val cm = ctx.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    cm.setPrimaryClip(ClipData.newPlainText(label, text))
}

/**
 * Tente d'ouvrir Termux. Best-effort :
 *  1) essaie de lancer la commande directement via RUN_COMMAND (ne marche que
 *     si l'utilisateur a active allow-external-apps cote Termux) ;
 *  2) sinon, ouvre simplement l'app Termux ;
 *  3) sinon, propose le Play Store / F-Droid.
 * Renvoie un message d'etat a afficher.
 */
fun openTermux(ctx: Context): String {
    val pm = ctx.packageManager
    val pkg = "com.termux"
    val launch = pm.getLaunchIntentForPackage(pkg)
    return if (launch != null) {
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(launch)
        "Termux ouvert. Colle le script (appui long → Coller) puis Entrée."
    } else {
        // Termux pas installe : diriger vers F-Droid (source recommandee)
        runCatching {
            ctx.startActivity(Intent(Intent.ACTION_VIEW,
                Uri.parse("https://f-droid.org/packages/com.termux/"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        "Termux n'est pas installé. Installe-le depuis F-Droid, puis reviens."
    }
}

fun toast(ctx: Context, msg: String) =
    Toast.makeText(ctx, msg, Toast.LENGTH_LONG).show()
