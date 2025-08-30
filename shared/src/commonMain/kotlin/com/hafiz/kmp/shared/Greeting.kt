package com.hafiz.kmp.shared

class Greeting {
    fun greet(): String = "Assalamu Alaikum from Kotlin Multiplatform! Running on ${getPlatformName()}"
}

expect fun getPlatformName(): String

