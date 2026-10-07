package systems.peculiar.insights.flutter

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class CrashChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                CrashCapture.configure(
                    context,
                    CrashSettings(
                        directory = call.argument<String>("directory").orEmpty(),
                        appVersion = call.argument<String>("appVersion").orEmpty(),
                        appBuild = call.argument<String>("appBuild").orEmpty(),
                        capture = call.argument<Boolean>("capture") == true,
                    ),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
