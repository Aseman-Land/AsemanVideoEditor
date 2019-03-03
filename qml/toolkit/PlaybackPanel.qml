import QtQuick 2.0
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Awesome 2.0
import QtAV 1.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Controls.Material 2.1
import "../globals"

Rectangle {
    color: AsemanGlobals.darkMode? "#444" : "#f0f0f0"
    height: 40*Devices.density
    Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

    property TimeLine playerObject

    signal addRequest(string path)
    signal cutRequest()

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8*Devices.density

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_plus
            tooltip: qsTr("Add File") + translationManager.refresher
            onClicked: {
                var path = Desktop.getOpenFileName(mainWin, qsTr("Open View"), [], Devices.documentsLocation)
                if(path.length)
                    addRequest(Devices.localFilesPrePath + path)
            }
        }
    }

    Row {
        anchors.centerIn: parent

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_fast_backward
            tooltip: qsTr("8x Backward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.fastBackward = pressed
            }
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_backward
            tooltip: qsTr("2x Backward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.backward = pressed
            }
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_step_backward
            tooltip: qsTr("0.2x Backward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.slowBackward = pressed
            }
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 14*Devices.fontDensity
            text: playerObject && playerObject.play? Awesome.fa_pause : Awesome.fa_play
            tooltip: qsTr("Play") + translationManager.refresher
            onClicked: playerObject.play = !playerObject.play
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_step_forward
            tooltip: qsTr("0.2x Forward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.slowForward = pressed
            }
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_forward
            tooltip: qsTr("2x Forward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.forward = pressed
            }
        }

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_fast_forward
            tooltip: qsTr("8x Forward") + translationManager.refresher
            onPressedChanged: {
                playerObject.play = false
                playerObject.fastForward = pressed
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8*Devices.density

        TooltipedButton {
            height: 40*Devices.density
            width: height
            flat: true
            focusPolicy: Qt.NoFocus
            font.family: Awesome.family
            font.pixelSize: 10*Devices.fontDensity
            text: Awesome.fa_cut
            tooltip: qsTr("Split Video") + translationManager.refresher
            onClicked: cutRequest()
        }
    }
}
