package com.alphaness.alphanessone

import android.os.Bundle
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		// Enable edge-to-edge for Android 15+ compatibility without deprecated APIs
		enableEdgeToEdge(
			statusBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT),
			navigationBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT)
		)
		super.onCreate(savedInstanceState)

		// Let the content draw behind system bars
		WindowCompat.setDecorFitsSystemWindows(window, false)
	}
}
