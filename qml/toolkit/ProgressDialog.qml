import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import AsemanQml.Labs 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

QtControls.Dialog {
    dim: true
    modal: true
    closePolicy: QtControls.Popup.NoAutoClose
    standardButtons: QtControls.Dialog.Cancel
    onVisibleChanged: if(!visible) destroy()

    property alias description: descriptionText.text
    property alias progress: progressBar.value
    property alias indicator: indicatorObj.running

    Component.onCompleted: open()

    QtLayouts.ColumnLayout {
        anchors.fill: parent

        QtLayouts.RowLayout {
            QtLayouts.Layout.fillWidth: true
            QtLayouts.Layout.fillHeight: true

            QtControls.BusyIndicator {
                id: indicatorObj
                QtLayouts.Layout.preferredHeight: 32*Devices.density
                QtLayouts.Layout.preferredWidth: height
                running: false
            }

            QtControls.Label {
                id: descriptionText
                QtLayouts.Layout.fillWidth: true
                QtLayouts.Layout.fillHeight: true
                lineHeight: 1.2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }

        QtControls.ProgressBar {
            id: progressBar
            QtLayouts.Layout.fillWidth: true
            from: 0
            to: 100

            Behavior on value {
                NumberAnimation { duration: 300 }
            }
        }
    }
}
