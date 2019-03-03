import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import QtQuick 2.7
import QtQuick.Controls 2.0 as QtControls
import QtQuick.Window 2.12 as QtWindow
import QtQuick.Controls.Material 2.2
import "../globals"

AsemanWindow {
    id: mainWin
    width: AsemanGlobals.windowWidth * Devices.density
    height: AsemanGlobals.windowHeight * Devices.density
    visible: true
    Material.accent: Material.Blue
    font.family: translationManager.localeName == "fa"? iran_sans.name : ubuntu_font.name

    onWidthChanged: AsemanGlobals.windowWidth = width / Devices.density
    onHeightChanged: AsemanGlobals.windowHeight = height / Devices.density

    property bool isFullscreen: mainWin.visibility === QtWindow.Window.FullScreen || mainWin.visibility === QtWindow.Window.Maximized

    Loader {
        id: loader
        anchors.fill: parent
        asynchronous: true
        source: "MainWindow_desktop.qml"
    }

    Rectangle {
        anchors.fill: parent
        color: AsemanGlobals.headerColor
        opacity: loader.status == Loader.Ready? 0 : 1

        QtControls.BusyIndicator {
            width: 64*Devices.density
            height: width
            anchors.centerIn: parent
            running: loader.status != Loader.Ready
            Material.accent: mainWin.isFullscreen? "#fff" : AsemanGlobals.headerTextColor
        }

        Behavior on opacity {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 300 }
        }
    }
}
