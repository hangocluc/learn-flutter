package com.example.learn_flutter

import com.xiaoyv.javaengine.JavaEngine
import com.xiaoyv.javaengine.compile.listener.CompilerListener
import com.xiaoyv.javaengine.compile.listener.ExecuteListener
import com.xiaoyv.javaengine.console.JavaConsole
import com.xiaoyv.javaengine.console.JavaConsole.AppendStdListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File


class MainActivity : FlutterActivity() {
    private val outBuffer = StringBuilder()
    private val errBuffer = StringBuilder()
    private val javaConsole = JavaConsole(
        object : AppendStdListener {
            override fun printStderr(err: CharSequence?) {
                errBuffer.appendLine(err)
            }

            override fun printStdout(out: CharSequence?) {
                outBuffer.appendLine(out)
            }
        }
    )


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "java_executor")
            .setMethodCallHandler { call, result ->
                if (call.method == "compileJava") {
                    val code = call.arguments as String

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val srcDir = File(filesDir, "java_src").apply { mkdirs() }
                            val file = File(srcDir, "JavaStudio.java")
                            file.writeText(code)

                            val classDir = File(filesDir, "class_output").apply { mkdirs() }

                            val dexDir = File(filesDir, "dex_output").apply { mkdirs() }
                            val dexFile = File(dexDir, "Main.dex")

                            outBuffer.clear()
                            errBuffer.clear()
                            javaConsole.start()

                            JavaEngine.getClassCompiler().compile(
                                file.absolutePath,
                                classDir.absolutePath,
                                object : CompilerListener() {
                                    override fun onSuccess(classFilePath: String) {
                                        JavaEngine.getDexCompiler().compile(
                                            classFilePath,
                                            dexFile.absolutePath,
                                            object : CompilerListener() {
                                                override fun onSuccess(dexFilePath: String) {
                                                    try {
                                                        kotlin.run {
                                                            val f = File(dexFilePath)
                                                            f.setReadable(true, true)
                                                            f.setWritable(false)
                                                            f.setExecutable(false)
                                                        }
                                                        val args = arrayOf<String>()
                                                        JavaEngine.getDexExecutor().exec(
                                                            dexFilePath,
                                                            args,
                                                            object : ExecuteListener {
                                                                override fun onExecuteFinish() {
                                                                    javaConsole.stop()
                                                                    CoroutineScope(Dispatchers.Main).launch {
                                                                        val output =
                                                                            if (errBuffer.isNotEmpty()) {
                                                                                "ERROR:\n$errBuffer"
                                                                            } else {
                                                                                outBuffer.toString()
                                                                            }
                                                                        result.success(output)
                                                                    }
                                                                }

                                                                override fun onExecuteError(error: Throwable) {
                                                                    javaConsole.stop()
                                                                    CoroutineScope(Dispatchers.Main).launch {
                                                                        result.error(
                                                                            "EXECUTION_ERROR",
                                                                            error.message,
                                                                            null
                                                                        )
                                                                    }
                                                                }
                                                            }
                                                        )
                                                    } catch (e: Exception) {
                                                        javaConsole.stop()
                                                        CoroutineScope(Dispatchers.Main).launch {
                                                            result.error(
                                                                "EXECUTION_ERROR",
                                                                e.message,
                                                                null
                                                            )
                                                        }
                                                    }
                                                }

                                                override fun onError(error: Throwable) {
                                                    javaConsole.stop()
                                                    CoroutineScope(Dispatchers.Main).launch {
                                                        result.error(
                                                            "DEX_ERROR",
                                                            error.message,
                                                            null
                                                        )
                                                    }
                                                }
                                            })
                                    }

                                    override fun onError(error: Throwable) {
                                        javaConsole.stop()
                                        CoroutineScope(Dispatchers.Main).launch {
                                            result.error("COMPILE_ERROR", error.message, null)
                                        }
                                    }
                                })
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("RUN_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}

