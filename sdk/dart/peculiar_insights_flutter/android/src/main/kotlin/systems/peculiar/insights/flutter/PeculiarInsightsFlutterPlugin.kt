package systems.peculiar.insights.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class PeculiarInsightsFlutterPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CrashCapture.install(binding.applicationContext)
        MethodChannel(binding.binaryMessenger, CHANNEL)
            .setMethodCallHandler(CrashChannelHandler(binding.applicationContext))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MethodChannel(binding.binaryMessenger, CHANNEL).setMethodCallHandler(null)
    }

    private companion object {
        const val CHANNEL = "peculiar_insights_flutter/native_crashes"
    }
}
