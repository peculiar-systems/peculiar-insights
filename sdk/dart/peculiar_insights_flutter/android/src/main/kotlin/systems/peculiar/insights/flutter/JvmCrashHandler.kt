package systems.peculiar.insights.flutter

import android.os.Process
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID
import kotlin.system.exitProcess

internal class JvmCrashHandler(
    private val previous: Thread.UncaughtExceptionHandler?,
    private val packageName: String,
    private val settings: () -> CrashSettings?,
) : Thread.UncaughtExceptionHandler {
    override fun uncaughtException(thread: Thread, error: Throwable) {
        settings()
            ?.takeIf { it.capture && it.directory.isNotEmpty() }
            ?.let { current -> runCatching { write(current, thread, error) } }
        previous?.uncaughtException(thread, error) ?: terminate()
    }

    private fun terminate(): Nothing {
        Process.killProcess(Process.myPid())
        exitProcess(10)
    }

    private fun write(settings: CrashSettings, thread: Thread, error: Throwable) {
        val id = UUID.randomUUID().toString()
        val report = JSONObject()
            .put("id", id)
            .put("timeMillis", System.currentTimeMillis())
            .put("exceptionType", error.javaClass.name)
            .put("message", error.message.orEmpty())
            .put("thread", thread.name)
            .put("appVersion", settings.appVersion)
            .put("appBuild", settings.appBuild)
            .put("frames", JSONArray(error.stackTrace.map(::frameOf)))
        val directory = File(settings.directory)
        val temporary = File(directory, "$id.json.tmp")
        temporary.writeText(report.toString())
        temporary.renameTo(File(directory, "$id.json"))
    }

    private fun frameOf(element: StackTraceElement): JSONObject = JSONObject()
        .put("module", element.className)
        .put("function", element.methodName)
        .put("file", element.fileName.orEmpty())
        .put("line", maxOf(element.lineNumber, 0))
        .put("inApp", element.className.startsWith("$packageName."))
}
