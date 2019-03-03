import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Awesome 2.0
import AsemanQml.Widgets 2.0
import AsemanQml.Modern 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

Item {

    QtLayouts.ColumnLayout {
        anchors.fill: parent
        spacing: 10*Devices.density

        Image {
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            QtLayouts.Layout.preferredWidth: 128*Devices.density
            QtLayouts.Layout.preferredHeight: QtLayouts.Layout.preferredWidth
            source: "../icons/icon.png"
            sourceSize: Qt.size(width*1.2, height*1.2)
        }

        QtControls.Label {
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            text: qsTr("Aseman Video Editor")
            font.pixelSize: 16*Devices.fontDensity
        }

        QtControls.Label {
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            text: qsTr("Smooth and Light Video Editor that created by Aseman Team")
            font.pixelSize: 10*Devices.fontDensity
        }

        Item {
            QtLayouts.Layout.preferredWidth: 1*Devices.density
            QtLayouts.Layout.fillHeight: true
        }

        QtControls.Button {
            QtLayouts.Layout.alignment: Qt.AlignHCenter
            QtLayouts.Layout.preferredWidth: 128*Devices.density
            text: qsTr("Home Page")
            highlighted: true
            onClicked: Qt.openUrlExternally("https://aseman.io")
        }
    }

}
