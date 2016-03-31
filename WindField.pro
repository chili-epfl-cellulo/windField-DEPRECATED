TEMPLATE = app

QT += qml quick widgets

SOURCES += main.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

DISTFILES += \
    CircleObstacle.png \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    assets/FinalMap.jpg \
    assets/FinalMap.png

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

OTHER_FILES += \
    renderer.js \
    three.js \
    Leaf.qml \
    main.qml \
    PressureField.qml \
    UIPanel.qml \
    assets/background.jpg \
    assets/europe.jpg \
    assets/CircleObstacle.png \
    assets/leaf.png \
    android/AndroidManifest.xml \
    PressurePointPanel.qml \
    assets/buttons/updateOff.png \
    assets/buttons/updateOn.png \
    assets/final.js \
    windsim.js \
    PressurePoint.qml \
    CanvasField.qml \
    MainForm.qml

