import QtQuick 2.0
import AsemanQml.Base 2.0
import AsemanQml.Awesome 2.0
import AsemanQml.Controls 2.0
import QtQuick.Controls 2.2 as QtControls

QtControls.ToolButton {
    id: control

    property string iconText

    contentItem: Item {
        implicitWidth: column.width + 20*Devices.density
        implicitHeight: 32*Devices.density

        Row {
            id: column
            spacing: 10*Devices.density
            anchors.centerIn: parent
            layoutDirection: View.layoutDirection

            QtControls.Label {
                height: 20*Devices.density
                anchors.verticalCenter: parent.verticalCenter
                text: control.iconText
                font.family: Awesome.family
                font.pixelSize: 12*Devices.fontDensity
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            QtControls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font.pixelSize: 10*Devices.fontDensity
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}
