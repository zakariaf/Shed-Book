package com.shedbook.shedbook

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // KILL THE ANDROID 12+ SPLASH EXIT FADE.
        //
        // Our splash and our first frame are the same solid field, so the
        // platform's exit animation is a crossfade between two identical images.
        // It costs a visible beat at the one moment the product's promise is
        // "the page is already there" — and it is the kind of thing nobody sees
        // on an emulator and everybody sees on a cold launch in a dark shed.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
    }
}
