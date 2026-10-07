package systems.peculiar.insights.flutter

import android.content.Context
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

internal data class CrashSettings(
    val directory: String,
    val appVersion: String,
    val appBuild: String,
    val capture: Boolean,
)

internal object CrashCapture {
    private val settings = AtomicReference<CrashSettings?>(null)
    private val installed = AtomicBoolean(false)

    fun install(context: Context) {
        if (!installed.compareAndSet(false, true)) {
            return
        }
        Thread.setDefaultUncaughtExceptionHandler(
            JvmCrashHandler(
                previous = Thread.getDefaultUncaughtExceptionHandler(),
                packageName = context.packageName,
                settings = settings::get,
            ),
        )
        NativeSignals.install()
    }

    fun configure(context: Context, update: CrashSettings) {
        settings.set(update)
        NativeSignals.configure(
            update.directory,
            update.appVersion,
            update.appBuild,
            File(context.applicationInfo.sourceDir).parent.orEmpty(),
            update.capture,
        )
    }
}

internal object NativeSignals {
    init {
        System.loadLibrary("peculiar_insights_crash")
    }

    @JvmStatic
    external fun configure(
        directory: String,
        version: String,
        build: String,
        prefix: String,
        capture: Boolean,
    )

    @JvmStatic
    external fun install()
}
