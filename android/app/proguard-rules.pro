# JavaCompileEngine pulls in kotlinx.coroutines FastServiceLoader, which optionally
# references Eclipse JDT at runtime via reflection (not bundled in the APK).
-dontwarn org.eclipse.jdt.internal.compiler.tool.EclipseCompiler
-dontwarn org.eclipse.jdt.**
