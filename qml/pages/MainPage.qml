import AsemanQml.Base 2.0
import AsemanQml.Awesome 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import QtQuick 2.7
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import QtQuick.Window 2.12 as QtWindow
import "../toolkit" as ToolKit
import "../globals"

QtControls.Page {
    id: mainPage
    title: qsTr("Aseman Video Editor") + translationManager.refresher

    readonly property bool inputItemActivated: Qt.inputMethod.cursorRectangle != Qt.rect(0,0,0,0)

    ToolKit.GlobalKeyHandler {
        id: keyHandler
        active: !inputItemActivated
        onSpacePressed: timeline.play = !timeline.play
        onControlN: createNew()
        onControlR: reloadProject()
        onEsc: {
            if(timeline.lastPinner)
                timeline.lastPinner.destroy()

            mainScene.focus = true
            mainScene.forceActiveFocus()
        }
        onControlS: timeline.save()
        onControlB: timeline.bookmark()
        onLeftChanged: {
            timeline.play = false
            timeline.backward = left
        }
        onControlLeftChanged: {
            timeline.play = false
            timeline.fastBackward = controlLeft
        }
        onAltLeftChanged: {
            timeline.play = false
            timeline.slowBackward = altLeft
        }
        onRightChanged: {
            timeline.play = false
            timeline.forward = right
        }
        onControlRightChanged: {
            timeline.play = false
            timeline.fastForward = controlRight
        }
        onAltRightChanged: {
            timeline.play = false
            timeline.slowForward = altRight
        }
        onSPressed: timeline.splitCurrent()
        onDPressed: timeline.duplicate()
        onDeletePressed: timeline.deleteCurrent()
    }

    Rectangle {
        id: sidebarScene
        width: AsemanGlobals.sidebar? sidebarItem.width : 0
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        x: View.defaultLayout? 0 : parent.width - width
        color: AsemanGlobals.darkMode? "#444" : "#f0f0f0"

        Behavior on width {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 350 }
        }

        ToolKit.SideBar {
            id: sidebarItem
            width: 320*Devices.density
            height: parent.height
            x: View.defaultLayout? parent.width - width : 0
            onAddToTimeline: timeline.addToTimeline(item)
            onAddRequest: timeline.append(path)
            onRenderRequest: timeline.renderRequest(item)
        }
    }

    FastRectengleShadow {
        anchors.fill: mainScene
        color: "#000"
        radius: 8*Devices.density
    }

    Item {
        id: mainScene
        x: View.defaultLayout? parent.width - width : 0
        width: parent.width - sidebarScene.width
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        clip: true

        Rectangle {
            id: player
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: playbackPanel.top
            color: "#000"

            ToolKit.DynamicPlayer {
                id: dplayer
                anchors.fill: parent
                currentItem: timeline.trueItem? timeline.trueItem.mediaPlayer : null
            }
        }

        ToolKit.PlaybackPanel {
            id: playbackPanel
            width: parent.width
            playerObject: timeline
            anchors.bottom: timeline.top
            onAddRequest: timeline.append(path)
            onCutRequest: timeline.splitCurrent()
        }

        DropArea {
            anchors.fill: timeline
            onEntered: {
                drag.accepted = drag.hasUrls
            }
            onDropped: {
                if(drop.hasUrls) {
                    for(var i in drop.urls)
                        timeline.append(drop.urls[i])
                } if(drop.text.length ) {
                    timeline.addToTimeline( Tools.jsonToVariant(drop.text) )
                }
            }
        }

        ToolKit.TimeLine {
            id: timeline
            width: parent.width
            height: 150*Devices.density
            anchors.bottom: parent.bottom
            playerScene: player
            temporaryZoom: keyHandler.controlShift
            onAddBookmarkRequest: sidebarItem.addBookmark(source, startPosition, stopPosition, image)
            onPropertiesRequest: {
                sidebarItem.source = source
                sidebarItem.tabIndex = 0
                AsemanGlobals.sidebar = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                mainScene.focus = true
                mainScene.forceActiveFocus()
                mouse.accepted = false
            }
        }
    }

    Header {
        id: header
        width: parent.width
        text: mainPage.title
        titleFontSize: 11*Devices.fontDensity
        centerText: false
        shadow: true
        color: mainWin.isFullscreen? "#333" : AsemanGlobals.headerColor
        light: AsemanGlobals.headerIsDark || mainWin.isFullscreen

        Row {
            height: parent.height - Devices.statusBarHeight
            anchors.bottom: parent.bottom
            x: View.defaultLayout? parent.width - width - 4*Devices.density : 4*Devices.density
            layoutDirection: View.layoutDirection
            Material.theme: AsemanGlobals.headerIsDark || mainWin.isFullscreen? Material.Dark : Material.Light

            ToolKit.ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("About") + translationManager.refresher
                focusPolicy: Qt.NoFocus
                iconText: Awesome.fa_question
                onClicked: aboutDialog.open()
            }

            ToolKit.ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Settings") + translationManager.refresher
                focusPolicy: Qt.NoFocus
                iconText: Awesome.fa_cogs
                onClicked: showSettings()
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1*Devices.density
                height: 30*Devices.density
                color: mainWin.isFullscreen? "#fff" : AsemanGlobals.headerTextColor
                opacity: 0.3
            }

            ToolKit.ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Render") + translationManager.refresher
                focusPolicy: Qt.NoFocus
                iconText: Awesome.fa_video
                onClicked: timeline.prepareRender()
            }
        }
    }

    function createNew() {
        createNewDialog.open()
    }

    function reloadProject() {
        closeRequestCommand = 1
        AsemanApp.exit(0)
    }

    function showSettings() {
        settingsDialog.open()
    }

    function showProgressDialog() {
        return progressDialog_component.createObject(mainPage)
    }

    ToolKit.MetaDataDialog {
        id: metaDataDialog
        anchors.fill: parent
    }

    QtControls.Dialog {
        id: createNewDialog
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        title: qsTr("Create New") + translationManager.refresher
        dim: true
        modal: true
        standardButtons: QtControls.Dialog.Ok | QtControls.Dialog.Cancel

        QtControls.Label {
            text: qsTr("Are you sure about discard all changes?") + translationManager.refresher
        }

        onAccepted: {
            closeRequestCommand = 2
            AsemanApp.exit(0)
        }
    }

    QtControls.Dialog {
        id: aboutDialog
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        title: qsTr("About") + translationManager.refresher
        dim: true
        modal: true
        standardButtons: QtControls.Dialog.Ok
        Material.theme: Material.Light

        ToolKit.About {
            implicitWidth: 400*Devices.density
            implicitHeight: 300*Devices.density
        }
    }

    QtControls.Dialog {
        id: settingsDialog
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        title: qsTr("Settings") + translationManager.refresher
        dim: true
        modal: true
        standardButtons: QtControls.Dialog.Ok
        Material.theme: Material.Light

        ToolKit.Settings {
            implicitWidth: 450*Devices.density
            implicitHeight: 400*Devices.density
        }
    }

    Component {
        id: progressDialog_component
        ToolKit.ProgressDialog {
            x: parent.width/2 - width/2
            y: parent.height/2 - height/2
            width: 500*Devices.density
        }
    }
}
