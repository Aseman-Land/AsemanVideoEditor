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

    AsemanFlickable {
        id: flick
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: scene.height
        contentWidth: scene.width

        Item {
            id: scene
            width: flick.width
            height: {
                var res = column.height + column.y*2
                if(res < flick.height)
                    res = flick.height
                return res
            }

            QtLayouts.ColumnLayout {
                id: column
                y: 0*Devices.density
                width: parent.width - 2*y
                spacing: 8*Devices.density
                x: y

                QtControls.Label {
                    QtLayouts.Layout.fillWidth: true
                    horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                    font.bold: true
                    text: qsTr("Language") + ":" + translationManager.refresher
                }

                QtControls.ComboBox {
                    id: langCombo
                    QtLayouts.Layout.fillWidth: true
                    font.pixelSize: 10*Devices.fontDensity
                    textRole: "name"
                    model: {
                        var res = new Array
                        for(var i in translationManager.translations)
                            res[res.length] = {"name": translationManager.translations[i], "locale": i}
                        return res
                    }
                    onCurrentIndexChanged: {
                        if(!inited)
                            return

                        var locale = model[currentIndex].locale
                        AsemanGlobals.localeName = locale
                    }
                    delegate: QtControls.ItemDelegate {
                        width: langCombo.width

                        QtControls.Label {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 11*Devices.fontDensity
                            text: modelData.name
                        }
                    }

                    property bool inited: false
                    Component.onCompleted: {
                        for(var i in model) {
                            if(model[i].locale == AsemanGlobals.localeName) {
                                currentIndex = i
                                break
                            }
                        }
                        inited = true
                    }
                }

                Item {
                    QtLayouts.Layout.preferredWidth: 1
                    QtLayouts.Layout.preferredHeight: 4*Devices.density
                }

                QtControls.Label {
                    QtLayouts.Layout.fillWidth: true
                    horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                    font.bold: true
                    text: qsTr("Save Settings") + ":" + translationManager.refresher
                }

                QtLayouts.RowLayout {
                    QtLayouts.Layout.fillWidth: true
                    layoutDirection: View.layoutDirection

                    QtControls.Switch {
                        onCheckedChanged: if(inited) AsemanGlobals.openDirectoryAtEnd = checked
                        Component.onCompleted: {
                            checked = AsemanGlobals.openDirectoryAtEnd
                            inited = true
                        }
                        property bool inited: false
                    }

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                        text: qsTr("Open Directory at End") + translationManager.refresher
                    }
                }

                Item {
                    QtLayouts.Layout.preferredWidth: 1
                    QtLayouts.Layout.preferredHeight: 4*Devices.density
                }

                QtControls.Label {
                    QtLayouts.Layout.fillWidth: true
                    horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                    font.bold: true
                    text: qsTr("Decoder") + ":" + translationManager.refresher
                }

                QtLayouts.RowLayout {
                    QtLayouts.Layout.fillWidth: true
                    layoutDirection: View.layoutDirection

                    QtControls.Switch {
                        onCheckedChanged: if(inited) AsemanGlobals.hardwareAccelaration = checked
                        Component.onCompleted: {
                            checked = AsemanGlobals.hardwareAccelaration
                            inited = true
                        }
                        property bool inited: false
                    }

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                        text: qsTr("Hardware Accelaration") + translationManager.refresher
                    }
                }

                Item {
                    QtLayouts.Layout.preferredWidth: 1
                    QtLayouts.Layout.preferredHeight: 4*Devices.density
                }

                QtControls.Label {
                    QtLayouts.Layout.fillWidth: true
                    horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                    font.bold: true
                    text: qsTr("Appearance") + ":" + translationManager.refresher
                }

                QtControls.Button {
                    QtLayouts.Layout.preferredWidth: 150*Devices.density
                    font.pixelSize: 11*Devices.fontDensity
                    QtLayouts.Layout.alignment: View.defaultLayout? Qt.AlignLeft : Qt.AlignRight
                    text: qsTr("Header Color") + translationManager.refresher
                    onClicked: AsemanGlobals.headerColor = Desktop.getColor(AsemanGlobals.headerColor)
                    Material.background: AsemanGlobals.headerColor
                    Material.foreground: AsemanGlobals.headerTextColor
                }

                QtLayouts.RowLayout {
                    QtLayouts.Layout.fillWidth: true
                    layoutDirection: View.layoutDirection

                    QtControls.Switch {
                        onCheckedChanged: if(inited) AsemanGlobals.darkMode = checked
                        Component.onCompleted: {
                            checked = AsemanGlobals.darkMode
                            inited = true
                        }
                        property bool inited: false
                    }

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                        text: qsTr("Dark mode") + translationManager.refresher
                    }
                }
            }
        }


        QtControls.ScrollBar.vertical: QtControls.ScrollBar {
            parent: flick.parent
            anchors.top: flick.top
            anchors.right: flick.right
            anchors.margins: 2*Devices.density
            anchors.bottom: flick.bottom
            width: 10*Devices.density
        }
    }
}
