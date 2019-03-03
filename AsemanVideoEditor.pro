QT += widgets quick network asemangui asemancore asemangui
CONFIG += c++11

TARGET = aseman-video-editor

macx : ICON = qml/icons/icon.icns
win32: RC_ICONS = qml/icons/icon.ico

SOURCES += main.cpp \  
    ffmpegtools.cpp \
    ffmpegqmltools.cpp

HEADERS += \
    ffmpegtools.h \
    ffmpegqmltools.h

RESOURCES += qml.qrc
