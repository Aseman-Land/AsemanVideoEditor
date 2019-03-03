import QtQuick 2.0
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Labs 2.0
import AsemanQml.Modern 2.0 as Modern
import QtAV 1.6 as QtAV
import QtQuick.Window 2.2
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

Item {
    id: item
    width: zoom * 120*Devices.density * (virtualDuration / 60000)
    z: heldX? 100 : 0

    Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

    readonly property int virtualDuration: {
        if(stopPosition < 2000000000 && startPosition)
            return stopPosition - startPosition
        if(startPosition)
            return duration - startPosition
        if(stopPosition < 2000000000)
            return stopPosition
        return duration
    }

    property alias source: player.source
    property alias duration: player.duration
    property alias startPosition: player.startPosition
    property alias stopPosition: player.stopPosition
    property alias position: player.position
    property alias playbackRate: player.playbackRate
    property alias mediaPlayer: player
    property alias scene: player.parent

    property real zoom: 1

    property bool held
    property real heldX
    property alias itemScene: innerScene

    property real timeX
    property real mouseY
    property real globalContainsMouse
    readonly property bool containsMouse: timeX > 0 && timeX < width && globalContainsMouse
    property alias active: player.active
    property bool isTrueActive: false
    property int pinPosition

    readonly property string thumbPath: thumb1.source

    property real sliderValue
    readonly property real value: {
        var res = timeX
        return startPosition + ( res * virtualDuration / width )
    }

    onValueChanged: if(!player.playing && containsMouse && active && !zoomWidthAnim.running) player.seek(value)
    onContainsMouseChanged: if(!player.playing && !containsMouse && active) player.seek(sliderValue)
    onActiveChanged: if(!active) player.seek(0)
    onHeldChanged: heldX = 0
    onSourceChanged: refreshThumb()
    onStartPositionChanged: refreshThumb()
    onVirtualDurationChanged: refreshThumb()

    signal finished()
    signal forwardFinished()
    signal backwardFinished()
    signal duplicate(int position)
    signal split()
    signal deleteRequest()
    signal bookmark()
    signal renderRequest()
    signal properties()

    property string thumbSource1_cache

    function refreshThumb() {
        createThumb(startPosition, function(path){
            thumb1.source = path
        })
    }

    function createThumb(pos, callback) {
        var src = Tools.urlToLocalPath(source)
        var path = AsemanGlobals.screenshotsPath + "/" + Tools.md5(src + pos) + ".jpg"
        createThumbToPath(pos, path, callback)
    }

    function createThumbToPath(pos, dst1, callback) {
        var thumbSource1 = Devices.localFilesPrePath + dst1
        if(Tools.fileExists(dst1)) {
            callback(thumbSource1)
        } else
        if(thumbSource1_cache != thumbSource1) {
            thumbSource1_cache = thumbSource1
            ffmpeg.takeScreenshot(Tools.urlToLocalPath(source), pos, dst1, function(){
                callback(thumbSource1)
            })
        }
    }

    function move(position) {
        sliderValue = position
        player.seek(position)
    }

    function openMenu() {
        pinPosition = position
        menu.x = timeX
        menu.y = mouseY - menu.height
        menu.open()
    }

    FfmpegTools {
        id: ffmpeg
    }

    Item {
        anchors.fill: parent
        ProxyPlayer {
            id: player
            onPlayingChanged: sliderValue = player.position
            onPointerChangeRequest: sliderValue = position
            onPositionChanged: if(!containsMouse && playing) sliderValue = player.position
            onFinished: item.finished()
            onForwardFinished: item.forwardFinished()
            onBackwardFinished: item.backwardFinished()
            onReplaceRequest: {
                duplicate(position)
                Tools.jsDelayCall(200, deleteRequest)
            }
        }
    }

    Item {
        id: innerScene
        width: parent.width
        height: parent.height
        scale: held? (1 + 12*Devices.density / width) : 1
        opacity: held? 0.9 : 1
        x: held? heldX : animX

        property real animX: heldX

        Behavior on animX {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 400 }
        }
        Behavior on scale {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 400 }
        }
        Behavior on opacity {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 400 }
        }

        Modern.FastDropShadow {
            anchors.fill: background
//            anchors.margins: 1*Devices.density
            horizontalOffset: active || menu.visible? 0 : 1*Devices.density
            verticalOffset: active || menu.visible? 1 : 1*Devices.density
            radius: 6*Devices.density
            color: active || menu.visible? "#18f" : "#000"
            opacity: active || menu.visible? 0.8 : 0.6
            visible: !Devices.isWindows
            source: Devices.isWindows? null : background
        }

        Rectangle {
            id: background
            anchors.fill: parent
            anchors.topMargin: 56*Devices.density
            anchors.margins: 6*Devices.density
            radius: 6*Devices.density
            color: AsemanGlobals.darkMode? "#444" : "#e0e0e0"
            border.color: active || menu.visible? "#18f" : (AsemanGlobals.darkMode?"#222":"#ddd")
            border.width: Devices.isWindows? 1*Devices.density : 0

            QtLayouts.RowLayout {
                anchors.fill: parent
                anchors.margins: 8*Devices.density
                clip: true

                Image {
                    id: thumb1
                    QtLayouts.Layout.preferredHeight: parent.height
                    QtLayouts.Layout.preferredWidth: height
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width*1.2, height*1.2)
                    asynchronous: true
                }

                QtLayouts.ColumnLayout {
                    QtLayouts.Layout.fillWidth: true

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.pixelSize: 9*Devices.fontDensity
                        text: Tools.fileName(source)
                        opacity: 0.6
                    }

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.pixelSize: 8*Devices.fontDensity
                        opacity: 0.6
                        text: qsTr("From %1, To: %2").arg( timeToString(startPosition) ).arg( timeToString(startPosition + virtualDuration) ) + translationManager.refresher
                    }
                }
            }
        }
    }

    Rectangle {
        id: timePointer
        x: ((sliderValue - startPosition) * parent.width / virtualDuration) - width/2
        anchors.verticalCenter: parent.verticalCenter
        width: 2*Devices.density
        height: parent.height - 12*Devices.density
        radius: width/2
        color: AsemanGlobals.masterColor
        opacity: 0.8
        visible: player.playing || (active && isTrueActive) || menu.visible

        Behavior on opacity {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 350 }
        }
    }

    QtControls.Menu {
        id: menu
        y: item.height
        modal: true
        dim: false
        font.pixelSize: 10*Devices.fontDensity
        Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

        QtControls.MenuItem {
            text: qsTr("Bookmark") + translationManager.refresher
            focusPolicy: Qt.NoFocus
            onClicked: bookmark()

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: qsTr("Ctrl+B") + translationManager.refresher
            }
        }
        QtControls.MenuItem {
            text: qsTr("Render") + translationManager.refresher
            focusPolicy: Qt.NoFocus
            onClicked: renderRequest()

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: qsTr("Ctrl+S") + translationManager.refresher
            }
        }
        QtControls.MenuItem {
            text: qsTr("Split") + translationManager.refresher
            focusPolicy: Qt.NoFocus
            onClicked: split()

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: qsTr("S") + translationManager.refresher
            }
        }
        QtControls.MenuItem {
            text: qsTr("Duplicate") + translationManager.refresher
            focusPolicy: Qt.NoFocus
            onClicked: duplicate(0)

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: qsTr("D") + translationManager.refresher
            }
        }
        QtControls.MenuItem {
            text: qsTr("Delete") + translationManager.refresher
            focusPolicy: Qt.NoFocus
            onClicked: deleteRequest()

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: "Delete" + translationManager.refresher
            }
        }
        QtControls.MenuItem {
            focusPolicy: Qt.NoFocus
            text: qsTr("Properties") + translationManager.refresher
            onClicked: {
                properties()
            }

            QtControls.Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                opacity: 0.6
                text: qsTr("Ctrl+P") + translationManager.refresher
            }
        }
    }

    function timeToString(msecs) {
        var secs = Math.floor(msecs/1000)
        var s = secs % 60
        if(s < 10)
            s = "0" + s

        var m = Math.floor(secs / 60) % 60
        if(m < 10)
            m = "0" + m

        var h = Math.floor(secs / 3600)
        if(h)
            return h + ":" + m + ":" + s
        else
            return m + ":" + s
    }
}
