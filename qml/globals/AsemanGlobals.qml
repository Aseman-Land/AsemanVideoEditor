pragma Singleton

import QtQuick 2.7
import AsemanQml.Base 2.0
import QtQuick.Controls.Material 2.1

AsemanObject {
    Material.theme: darkMode? Material.Dark : Material.Light

    property alias headerColor: _settings.headerColor
    readonly property color headerTrueColor: headerColor
    readonly property bool headerIsDark: {
        var avg = (headerTrueColor.r + headerTrueColor.g + headerTrueColor.b)/3
        return (avg < 0.5)
    }
    readonly property string headerTextColor: headerIsDark? "#fff" : "#333"

    readonly property variant nameFilters: ["*.mp4", "*.m4v", "*.mpg", "*.mpeg", "*.mkv", "*.wmv", "*.mov", "*.ts"]

    property color masterColor: "#2196F3"
    property color masterTextColor: "#ffffff"
    property color foregroundColor: Material.foreground
    property color backgroundColor: Material.background
    property color shadowColor: foregroundColor

    property bool shadow: false
    property bool inited: false

    property alias darkMode: _settings.darkMode
    property alias localeName: _settings.localeName
    property alias languageInited: _settings.languageInited
    property alias sidebar: _settings.sidebar
    property alias workingDirectory: _settings.workingDirectory
    property alias hardwareAccelaration: _settings.hardwareAccelaration
    property alias filesDirectory: _settings.filesDirectory
    property alias openDirectoryAtEnd: _settings.openDirectoryAtEnd
    property alias sidebarTabIndex: _settings.sidebarTabIndex

    property alias windowWidth: _settings.windowWidth
    property alias windowHeight: _settings.windowHeight

    readonly property string screenshotsPath: AsemanApp.homePath + "/screenshots"

    Component.onCompleted: {
        Tools.mkDir(screenshotsPath)
    }

    onDarkModeChanged: Material.theme = darkMode? Material.Dark : Material.Light

    Timer {
        interval: 800
        repeat: false
        running: true
        onTriggered: inited = true
    }

    Settings {
        id: _settings
        category: "General"
        source: AsemanApp.homePath + "/settings.ini"

        property int sidebarTabIndex: 0
        property bool sidebar: true
        property bool darkMode: true
        property bool languageInited: false
        property string localeName: "en"
        property string workingDirectory
        property bool openDirectoryAtEnd: true
        property bool hardwareAccelaration: true
        property string filesDirectory
        property string headerColor: "#009688"

        property real windowWidth: 1280
        property real windowHeight: 768

        Component.onCompleted: {
            if(workingDirectory.length == 0)
                workingDirectory = Devices.documentsLocation
            if(filesDirectory.length == 0)
                filesDirectory = Devices.documentsLocation
        }
    }
}

