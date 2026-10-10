package com.mammon.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val MammonDark = darkColorScheme(
    primary = Color.White,
    onPrimary = Color.Black,
    background = Color.Black,
    onBackground = Color(0xFFF7F7F7),
    surface = Color(0xFF1C1C1E),
    onSurface = Color(0xFFF7F7F7),
    surfaceVariant = Color(0xFF262628),
    onSurfaceVariant = Color(0xFFB7B7BD),
    outline = Color(0xFF3B3B3F)
)

@Composable
fun MammonTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = MammonDark,
        content = content
    )
}
