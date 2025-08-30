package com.hafiz.kmp.composeapp

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight

internal actual fun getBrandTypography(): Typography {
    val poppins = FontFamily(
        Font(resId = R.font.poppins_regular, weight = FontWeight.Normal),
        Font(resId = R.font.poppins_semibold, weight = FontWeight.SemiBold),
        Font(resId = R.font.poppins_bold, weight = FontWeight.Bold),
    )
    val amiri = FontFamily(
        Font(resId = R.font.amiri_regular, weight = FontWeight.Normal),
        Font(resId = R.font.amiri_bold, weight = FontWeight.Bold),
    )
    return Typography().copy(
        bodyLarge = Typography().bodyLarge.copy(fontFamily = poppins),
        bodyMedium = Typography().bodyMedium.copy(fontFamily = poppins),
        titleLarge = Typography().titleLarge.copy(fontFamily = amiri),
        titleMedium = Typography().titleMedium.copy(fontFamily = amiri),
    )
}
