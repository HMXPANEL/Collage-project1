#!/usr/bin/env python3
"""Patch the CI-generated android platform for flutter_local_notifications.

`flutter create` scaffolded android/ has no notification permissions and no
desugaring. Run right after `flutter create`, before `flutter build`.
Fails loudly if an expected anchor vanished so CI surfaces template drift.

Safe to run repeatedly (idempotent).
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]

MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
GRADLE = ROOT / "android/app/build.gradle.kts"

PERMISSIONS = """    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
"""
RECEIVERS = """        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""


def fail(msg):
    print(f"[patch-android] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    manifest = MANIFEST.read_text()
    gradle = GRADLE.read_text()

    if "POST_NOTIFICATIONS" not in manifest:
        if "</application>" not in manifest:
            fail("AndroidManifest has no </application> anchor")
        if "<application" not in manifest:
            fail("AndroidManifest has no <application anchor")
        manifest = manifest.replace(
            "<application", PERMISSIONS + "    <application", 1
        )
        manifest = manifest.replace(
            "</application>", RECEIVERS + "    </application>", 1
        )
        MANIFEST.write_text(manifest)
        print("[patch-android] added notification permissions and receivers")

    if "isCoreLibraryDesugaringEnabled" not in gradle:
        if "compileOptions {" not in gradle:
            fail("app/build.gradle.kts has no compileOptions block")
        gradle = gradle.replace(
            "compileOptions {\n",
            "compileOptions {\n"
            "        isCoreLibraryDesugaringEnabled = true\n",
            1,
        )
        if "coreLibraryDesugaring" not in gradle:
            dep = (
                'dependencies {\n'
                '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n'
                '}\n'
            )
            if "flutter {" in gradle:
                gradle = gradle.replace(
                    "flutter {\n",
                    dep + "\nflutter {\n",
                    1,
                )
            else:
                gradle = gradle.rstrip("\n") + "\n\n" + dep
        GRADLE.write_text(gradle)
        print("[patch-android] enabled core library desugaring")


if __name__ == "__main__":
    main()