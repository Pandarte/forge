package fr.buildtool.app

import android.os.Build
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Quand la langue change, AppCompat recree l'activite. Par defaut la
        // transition est seche (flash noir). On force un fondu enchaine pour que
        // l'ancien et le nouvel ecran se croisent en douceur.
        @Suppress("DEPRECATION")
        if (Build.VERSION.SDK_INT >= 34) {
            overrideActivityTransition(
                OVERRIDE_TRANSITION_OPEN,
                android.R.anim.fade_in, android.R.anim.fade_out,
            )
            overrideActivityTransition(
                OVERRIDE_TRANSITION_CLOSE,
                android.R.anim.fade_in, android.R.anim.fade_out,
            )
        } else {
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        }
        enableEdgeToEdge()
        setContent {
            ForgeTheme {
                BuildScreen()
            }
        }
    }
}

/**
 * Theme Material 3 avec couleurs dynamiques (Material You) sur Android 12+.
 * En dessous, repli sur une palette neutre et lisible.
 */
@Composable
fun ForgeTheme(content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()
    val ctx = LocalContext.current
    val colors = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        if (dark) dynamicDarkColorScheme(ctx) else dynamicLightColorScheme(ctx)
    } else {
        if (dark) darkColorScheme() else lightColorScheme()
    }
    MaterialTheme(colorScheme = colors, content = content)
}
