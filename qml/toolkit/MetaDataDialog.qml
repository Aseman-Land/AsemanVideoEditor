import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import AsemanQml.Awesome 2.0
import AsemanQml.Labs 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

Item {
    id: mdd

    readonly property string historyPath: AsemanApp.homePath + "/metadata.cache"

    function open() {
        var dlg = dialog_component.createObject(this)
        dlg.open()
        return dlg
    }

    Component {
        id: dialog_component

        QtControls.Dialog {
            id: dialog
            x: parent.width/2 - width/2
            y: parent.height/2 - height/2
            width: 500*Devices.density
            height: 300*Devices.density
            title: qsTr("Prepare for Render") + translationManager.refresher
            dim: true
            modal: true
            standardButtons: QtControls.Dialog.Ok | QtControls.Dialog.Cancel
            Material.theme: Material.Light
            onVisibleChanged: if(!visible) destroy()
            onAccepted: {
                var encoderType = (encoder.currentIndex? encoder.currentText : "")

                var map = {"title": ""}
                map["resolW"] = resolW.text
                map["resolH"] = resolH.text
                map["framerate"] = framerate.text
                map["encoder"] = encoder.currentIndex

                doRender(map, Qt.size(resolW.text, resolH.text), framerate.text, encoderType, filePath.text)
                Tools.writeText(historyPath, Tools.variantToJson(map))
            }

            Component.onCompleted: {
                var res = Tools.jsonToVariant( Tools.readText(historyPath) )
                if(res && res.resolW) resolW.text = res.resolW
                if(res && res.resolH) resolH.text = res.resolH
                if(res && res.framerate) framerate.text = res.framerate
                if(res && res.encoder) encoder.currentIndex = res.encoder; else encoder.currentIndex = 1
//                creation_time.date = (res.creation_time? Tools.datefromString(res.creation_time, "yyyy-MM-ddThh:mm:ss.000000Z") : new Date)
            }

            signal doRender(variant metadata, variant resolution, int frameRate, string encoder, string dest)

            Item {
                anchors.fill: parent

                QtLayouts.ColumnLayout {
                    id: panel
                    width: parent.width
                    anchors.bottom: parent.bottom

                    QtLayouts.RowLayout {
                        layoutDirection: View.layoutDirection

                        QtControls.Label {
                            QtLayouts.Layout.topMargin: 12*Devices.density
                            QtLayouts.Layout.alignment: Qt.AlignTop
                            text: qsTr("Destination") + ":"
                            font.bold: true
                        }

                        QtControls.TextField {
                            id: filePath
                            QtLayouts.Layout.alignment: Qt.AlignVCenter
                            QtLayouts.Layout.fillWidth: true
                            readOnly: true
                            selectByMouse: true
                            font.pixelSize: 10*Devices.fontDensity
                            text: {
                                var res = AsemanGlobals.workingDirectory + "/untitled.mp4"
                                return res
                            }
                        }

                        QtControls.Button {
                            QtLayouts.Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 12*Devices.fontDensity
                            font.family: Awesome.family
                            text: Awesome.fa_folder_open
                            flat: true
                            onClicked: {
                                var path = Desktop.getSaveFileName(mainWin, qsTr("Select Path"), [], AsemanGlobals.workingDirectory)
                                if(path.length)
                                    filePath.text = path
                            }
                        }
                    }

                    QtLayouts.RowLayout {
                        layoutDirection: View.layoutDirection

                        QtControls.Label {
                            QtLayouts.Layout.topMargin: 12*Devices.density
                            QtLayouts.Layout.alignment: Qt.AlignTop
                            text: qsTr("Resolution") + ":"
                            font.bold: true
                        }

                        QtControls.TextField {
                            id: resolW
                            QtLayouts.Layout.maximumWidth: 70*Devices.density
                            QtLayouts.Layout.alignment: Qt.AlignVCenter
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 10*Devices.fontDensity
                            validator: RegExpValidator { regExp: /[1-9]\d+/ }
                            text: "1280"
                        }

                        QtControls.Label {
                            QtLayouts.Layout.topMargin: 12*Devices.density
                            QtLayouts.Layout.alignment: Qt.AlignTop
                            QtLayouts.Layout.maximumWidth: 40*Devices.density
                            horizontalAlignment: Text.AlignHCenter
                            text: "x"
                        }

                        QtControls.TextField {
                            id: resolH
                            QtLayouts.Layout.maximumWidth: 70*Devices.density
                            QtLayouts.Layout.alignment: Qt.AlignVCenter
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 10*Devices.fontDensity
                            validator: RegExpValidator { regExp: /[1-9]\d+/ }
                            text: "720"
                        }
                    }

                    QtLayouts.RowLayout {
                        QtLayouts.Layout.fillWidth: true
                        layoutDirection: View.layoutDirection

                        QtLayouts.RowLayout {
                            QtLayouts.Layout.fillWidth: true
                            layoutDirection: View.layoutDirection

                            QtControls.Label {
                                QtLayouts.Layout.topMargin: 12*Devices.density
                                QtLayouts.Layout.alignment: Qt.AlignTop
                                text: qsTr("Framerate") + ":"
                                font.bold: true
                            }

                            QtControls.TextField {
                                id: framerate
                                QtLayouts.Layout.alignment: Qt.AlignVCenter
                                QtLayouts.Layout.maximumWidth: 70*Devices.density
                                selectByMouse: true
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 10*Devices.fontDensity
                                validator: RegExpValidator { regExp: /[1-9]\d+/ }
                                text: "30"
                            }
                        }

                        Item {
                            QtLayouts.Layout.preferredHeight: 1
                            QtLayouts.Layout.preferredWidth: 10*Devices.density
                        }

                        QtLayouts.RowLayout {
                            layoutDirection: View.layoutDirection

                            QtControls.Label {
                                QtLayouts.Layout.topMargin: 16*Devices.density
                                QtLayouts.Layout.alignment: Qt.AlignTop
                                text: qsTr("Encoder") + ":"
                                font.bold: true
                            }

                            QtControls.ComboBox {
                                id: encoder
                                QtLayouts.Layout.fillWidth: true
                                QtLayouts.Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: 10*Devices.fontDensity
                                model: ["Ultra Fast", "libx264", "libx265", "libtheora", "libxvid", "libvpx", "mpeg2video"]
                            }
                        }
                    }
                }
            }
        }
    }
}
