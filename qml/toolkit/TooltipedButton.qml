import QtQuick 2.0
import AsemanQml.Base 2.0
import AsemanQml.Awesome 2.0
import AsemanQml.Controls 2.0
import QtQuick.Controls 2.2 as QtControls
import "../globals"

QtControls.Button {
    id: btn

    property alias tooltip: tooltipLabel.text

    onHoveredChanged: {
        if(hovered)
            hoverTimer.restart()
        else {
            hoverTimer.stop()
            tooltipScene.show = false
        }
    }

    Timer {
        id: hoverTimer
        interval: 300
        repeat: false
        onTriggered: tooltipScene.show = true
    }

    Rectangle {
        id: tooltipScene
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: AsemanGlobals.masterColor
        width: tooltipLabel.width + 12*Devices.density
        height: tooltipLabel.height + 12*Devices.density
        radius: 5*Devices.density
        opacity: show && tooltip.length? 0.7 : 0
        visible: tooltip.length

        property bool show

        Behavior on opacity {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 350 }
        }

        QtControls.Label {
            id: tooltipLabel
            anchors.centerIn: parent
            color: AsemanGlobals.masterTextColor
            font.pixelSize: 9*Devices.fontDensity
        }
    }
}
