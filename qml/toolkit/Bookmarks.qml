import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Layouts 1.3 as QtLayouts
import QtQuick.Controls.Material 2.1
import "../globals"

Item {
    Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

    function append(source, startPosition, stopPosition, image) {
        var uuid = Tools.createUuid()
        lmodel.append( {"source": source,
                        "startPosition": startPosition,
                        "stopPosition": stopPosition,
                        "image": image,
                        "uuid": uuid} )
    }

    signal addToTimeline(variant item)
    signal renderRequest(variant item)

    AsemanListModel {
        id: lmodel
        cachePath: AsemanApp.homePath + "/bookmarks.dat"
    }

    AsemanListView {
        id: listv
        anchors.fill: parent
        model: lmodel

        property int lastDraggedIndex: -1

        delegate: Item {
            id: bitem
            width: listv.width
            height: 60*Devices.density
            opacity: dropArea.containsDrag? 0.5 : 1

            QtLayouts.RowLayout {
                width: parent.width - 40*Devices.density
                layoutDirection: View.layoutDirection
                anchors.centerIn: parent

                RoundedImage {
                    QtLayouts.Layout.preferredHeight: 40*Devices.density
                    QtLayouts.Layout.preferredWidth: height
                    source: Devices.localFilesPrePath + model.image
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    radius: 5*Devices.density
                }

                QtLayouts.ColumnLayout {
                    QtLayouts.Layout.fillWidth: true

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        text: qsTr("File: %1").arg( Tools.fileName(model.source) ) + translationManager.refresher
                        font.pixelSize: 10*Devices.fontDensity
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: 0.8
                    }

                    QtControls.Label {
                        QtLayouts.Layout.fillWidth: true
                        text: qsTr("From %1, To: %2").arg( timeToString(model.startPosition) ).arg( timeToString(model.stopPosition) ) + translationManager.refresher
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
                        listv.lastDraggedIndex = index
                        drag.mimeData.text = Tools.variantToJson( lmodel.get(model.index) )
                        drag.start()

                        listv.lastDraggedIndex = -1
                    }
                }

                onReleased: {
                    if( Math.floor(mouseX - pinX) < 4*Devices.density && Math.floor(mouseY - pinY) < 4*Devices.density ) {
                        addToTimeline( lmodel.get(model.index) )
                    }
                }

                property int pinX
                property int pinY
            }

            DropArea {
                id: dropArea
                anchors.fill: parent
                onEntered: if(listv.lastDraggedIndex >= 0) drag.accepted = true
                onDropped: {
                    if(listv.lastDraggedIndex < 0)
                        return

                    lmodel.move(listv.lastDraggedIndex, index)
                }
            }

            DragObject {
                id: drag
                source: bitem
                mimeData: MimeData {}
            }

            QtControls.Menu {
                id: menu
                modal: true
                dim: false
                font.pixelSize: 10*Devices.fontDensity
                Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light

                QtControls.MenuItem {
                    text: qsTr("Render") + translationManager.refresher
                    focusPolicy: Qt.NoFocus
                    onClicked: renderRequest(lmodel.get(model.index))
                }
                QtControls.MenuItem {
                    text: qsTr("Add to Timeline") + translationManager.refresher
                    focusPolicy: Qt.NoFocus
                    onClicked: addToTimeline( lmodel.get(model.index) )
                }
                QtControls.MenuItem {
                    text: qsTr("Delete") + translationManager.refresher
                    focusPolicy: Qt.NoFocus
                    onClicked: {
                        deleteDialog.bookmarkIndex = model.index
                        deleteDialog.open()
                    }
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

    QtControls.Dialog {
        id: deleteDialog
        parent: mainPage
        x: parent.width/2 - width/2
        y: parent.height/2 - height/2
        title: qsTr("Delete") + translationManager.refresher
        dim: true
        modal: true
        standardButtons: QtControls.Dialog.Ok | QtControls.Dialog.Cancel

        property int bookmarkIndex

        QtControls.Label {
            text: qsTr("Are you sure about delete this bookmark?") + translationManager.refresher
        }

        onAccepted: lmodel.remove(bookmarkIndex)
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

