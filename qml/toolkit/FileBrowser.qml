import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import AsemanQml.Awesome 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

Item {
    Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light
    clip: true

    function append(source, startPosition, stopPosition, image) {
        var uuid = Tools.createUuid()
        lmodel.append( {"source": source,
                        "startPosition": startPosition,
                        "stopPosition": stopPosition,
                        "image": image,
                        "uuid": uuid} )
    }

    signal addRequest(string path)

    signal addToTimeline(variant item)

    FileSystemModel {
        id: lmodel
        folder: {
            var dir = AsemanGlobals.filesDirectory
            if(Devices.isWindows && dir.length < 3)
                dir += "/"
            return dir
        }

        showDirsFirst: true
        showDotAndDotDot: false
        showFiles: true
        nameFilters: AsemanGlobals.nameFilters
        onFolderChanged: listv.positionViewAtBeginning()
    }

    AsemanListView {
        id: listv
        width: parent.width
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        model: lmodel

        delegate: Item {
            id: bitem
            width: listv.width
            height: 50*Devices.density

            QtLayouts.RowLayout {
                width: parent.width - 40*Devices.density
                layoutDirection: View.layoutDirection
                anchors.centerIn: parent

                Item {
                    QtLayouts.Layout.preferredHeight: 40*Devices.density
                    QtLayouts.Layout.preferredWidth: height

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6*Devices.density
                        source: model.fileIsDir? "../icons/folder.png" : "../icons/video.png"
                        sourceSize: Qt.size(width*1.2, height*1.2)
                    }
                }

                QtLayouts.ColumnLayout {
                    QtLayouts.Layout.fillWidth: true

                    QtControls.Label {
                        horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                        QtLayouts.Layout.fillWidth: true
                        text: model.fileName
                        font.pixelSize: 10*Devices.fontDensity
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: 0.8
                    }

                    QtControls.Label {
                        horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                        QtLayouts.Layout.fillWidth: true
                        text: model.fileMime
                        font.pixelSize: 8*Devices.fontDensity
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: 0.8
                    }
                }
            }

            QtControls.ItemDelegate {
                anchors.fill: parent
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    if(model.fileIsDir)
                        return
                    menu.x = mouseX
                    menu.y = mouseY
                    menu.open()
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: {
                    pinX = mouseX
                    pinY = mouseY
                }

                onPositionChanged: {
                    if( Math.floor(mouseX - pinX) > 4*Devices.density || Math.floor(mouseY - pinY) > 4*Devices.density ) {
                        drag.start()
                    }
                }

                onReleased: {
                    if( Math.floor(mouseX - pinX) < 4*Devices.density && Math.floor(mouseY - pinY) < 4*Devices.density ) {
                        if(model.fileIsDir)
                            AsemanGlobals.filesDirectory = model.filePath
                        else
                            addRequest( Devices.localFilesPrePath + model.filePath )
                    }
                }

                property int pinX
                property int pinY
            }

            DragObject {
                id: drag
                source: bitem
                mimeData: MimeData {
                    urls: [Devices.localFilesPrePath + model.filePath]
                }
            }

            QtControls.Menu {
                id: menu
                modal: true
                dim: false
                font.pixelSize: 10*Devices.fontDensity
                Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

                QtControls.MenuItem {
                    text: qsTr("Add to Timeline") + translationManager.refresher
                    focusPolicy: Qt.NoFocus
                    onClicked: addRequest( Devices.localFilesPrePath + model.filePath )
                }
                QtControls.MenuItem {
                    text: qsTr("MetaData") + translationManager.refresher
                    focusPolicy: Qt.NoFocus
                    onClicked: metaDataRequest(model.filePath)
                }
            }
        }

        QtControls.ScrollBar.vertical: QtControls.ScrollBar {
            parent: listv.parent
            anchors.top: listv.top
            anchors.left: listv.left
            anchors.margins: 2*Devices.density
            anchors.bottom: listv.bottom
            width: 10*Devices.density

            Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light
        }
    }

    FastRectengleShadow {
        anchors.fill: header
        color: "#000"
        radius: 8*Devices.density
    }

    Rectangle {
        id: header
        width: parent.width
        height: 40*Devices.density
        color: AsemanGlobals.darkMode? "#333" : "#fff"

        QtLayouts.RowLayout {
            anchors.fill: parent
            anchors.margins: 4*Devices.density
            layoutDirection: View.layoutDirection

            ToolButton {
                QtLayouts.Layout.preferredHeight: 30*Devices.density
                text: qsTr("Back") + translationManager.refresher
                focusPolicy: Qt.NoFocus
                iconText: View.defaultLayout? Awesome.fa_angle_left : Awesome.fa_angle_right
                onClicked: AsemanGlobals.filesDirectory = Tools.fileParent(lmodel.folder)
            }

            QtControls.ComboBox {
                id: driveCombo
                QtLayouts.Layout.preferredHeight: 36*Devices.density
                QtLayouts.Layout.preferredWidth: 60*Devices.density
                font.pixelSize: 9*Devices.fontDensity
                visible: Devices.isWindows
                model: {
                    var list = new Array
                    if(!Devices.isWindows)
                        return list
                    var drives = ["C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "Z"]
                    for(var i in drives) {
                        if( !Tools.fileExists( drives[i] + ":/" ) )
                            continue;

                        list[list.length] = drives[i] + ":/"
                    }
                    return list
                }
                delegate: QtControls.ItemDelegate {
                    width: driveCombo.width
                    Material.theme: Material.Light

                    QtControls.Label {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10*Devices.fontDensity
                        text: modelData
                        color: "#333"
                    }
                }
                onCurrentTextChanged: if(inited) AsemanGlobals.filesDirectory = currentText
                Component.onCompleted: {
                    if(!Devices.isWindows)
                        return
                    var drive = AsemanGlobals.filesDirectory.slice(0, 3)
                    var data = model
                    for(var i in data)
                        if(data[i].toUpperCase() == drive.toUpperCase())
                        {
                            currentIndex = i
                            break
                        }

                    inited = true
                }
                property bool inited
            }

            QtControls.Label {
                horizontalAlignment: View.defaultLayout? Text.AlignLeft : Text.AlignRight
                font.pixelSize: 9*Devices.fontDensity
                QtLayouts.Layout.fillWidth: true
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                maximumLineCount: 1
                text: View.defaultLayout? ": " + Tools.fileName(lmodel.folder) : Tools.fileName(lmodel.folder) + " :"
                color: AsemanGlobals.masterColor
            }
        }
    }
}

