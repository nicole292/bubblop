package com.bubblop.game

import android.util.Log
import com.google.android.play.agesignals.AgeSignalsAccessRequest
import com.google.android.play.agesignals.AgeSignalsManager
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import com.google.android.play.agesignals.ApplicableAgeFeaturesRequest
import com.google.android.play.agesignals.model.AgeSignalsStatus
import com.google.android.play.agesignals.model.ApplicableAgeFeature
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play Age Signals (age assurance laws, e.g. California AB 1043 and
 * Brazil's Digital ECA, from January 2027), done the same way as FLOWLINE.
 *
 * Bubblop is the same 4+ game for every age: no ads, purchases, accounts,
 * chat or data collection. So it only does what those laws ask of an app:
 * where Play says mandatory age sharing applies to this user, it requests
 * the age signal (Play shows its own prompt if needed) and then checks it.
 * The age range is not stored, sent anywhere or used for anything (Play's
 * API terms allow it only for age-appropriate experiences). Elsewhere it
 * does nothing at all.
 *
 * The game calls "check" once per launch (lib/services/age_signals.dart).
 * It never fails: it always answers with a short status for the log.
 */
class MainActivity : FlutterActivity() {
    private var running = false
    private var done = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "check") check { status -> result.success(status) } else result.notImplemented()
        }
    }

    private fun check(reply: (String) -> Unit) {
        // Once per launch.
        if (running || done) {
            reply(if (running) "running" else "already_checked")
            return
        }
        running = true
        val finish: (String) -> Unit = { status ->
            running = false
            done = true
            Log.i(TAG, "age signals: $status")
            runOnUiThread { reply(status) }
        }
        try {
            val manager = AgeSignalsManagerFactory.create(applicationContext)
            manager.getApplicableAgeFeatures(ApplicableAgeFeaturesRequest.builder().build())
                .addOnSuccessListener { features ->
                    val f = features.features()
                    if (f == null || !f.contains(ApplicableAgeFeature.MANDATORY_SHARING)) {
                        finish("not_required")
                    } else {
                        requestAccess(manager, finish)
                    }
                }
                .addOnFailureListener { e -> finish("error: ${e.message}") }
        } catch (t: Throwable) {
            finish("error: $t")
        }
    }

    private fun requestAccess(manager: AgeSignalsManager, finish: (String) -> Unit) {
        val request = AgeSignalsAccessRequest.builder().setActivity(this).build()
        manager.requestAgeSignalsAccess(request)
            .addOnSuccessListener { access ->
                when (access.ageSignalsStatus()) {
                    AgeSignalsStatus.SHARED ->
                        manager.checkAgeSignals(AgeSignalsRequest.builder().build())
                            // Received and deliberately not kept: the game is the same for all ages.
                            .addOnSuccessListener { finish("shared") }
                            .addOnFailureListener { e -> finish("error: ${e.message}") }
                    AgeSignalsStatus.VERIFICATION_REQUIRED -> finish("verification_required")
                    else -> finish("not_shared")
                }
            }
            .addOnFailureListener { e -> finish("error: ${e.message}") }
    }

    private companion object {
        const val CHANNEL = "com.bubblop.game/age_signals"
        const val TAG = "BubblopAgeSignals"
    }
}
