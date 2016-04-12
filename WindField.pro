TEMPLATE = app

QT += qml quick widgets svg

SOURCES += src/main.cpp

RESOURCES += \
    code.qrc \
    assets.qrc \
    assets/animations/assets-animations-ballon.qrc \
    assets/animations/assets-animations-drag.qrc \
    assets/animations/assets-animations-feel.qrc \
    assets/animations/assets-animations-intensite.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

DISTFILES += \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew.bat \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

