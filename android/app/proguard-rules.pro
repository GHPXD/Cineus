# The transitive Room 2.2.5 consumer rule retains database classes but omits
# their no-argument constructors. R8 full mode can remove those constructors,
# breaking WorkManager's reflective database creation before Flutter starts.
# Match the corrected AndroidX Room rule while retaining release optimization.
# https://android.googlesource.com/platform/frameworks/support/+/e4765e38e27a3f4d86188b996df97a52403dff46
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
