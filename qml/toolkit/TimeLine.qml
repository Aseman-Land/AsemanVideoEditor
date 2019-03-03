import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Labs 2.0
import QtAV 1.6 as QtAV
import QtQuick.Window 2.2
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Controls.Material 2.1
import "../globals"

Rectangle {
    id: timeline
    color: AsemanGlobals.darkMode? "#333" : "#fafafa"

    property real from: 0
    property real to: 1
    property bool temporaryZoom
    property real zoom: zoomValue
    property alias zoomValue: lastStateSettings.zoom
    readonly property real maximumZoom: 32
    readonly property real minutesWidth: zoom * 120*Devices.density

    property real _temporaryZoomCache
    property real _temporaryContentX
    onTemporaryZoomChanged: {
        var mMouseX = marea.mouseX/zoomValue
        var gMouseX = marea.mouseX - flick.contentX
        var newZoom = zoomValue
        if(temporaryZoom) {
            _temporaryZoomCache = newZoom
            _temporaryContentX = flick.contentX
            newZoom = maximumZoom
        } else {
            newZoom = _temporaryZoomCache
        }

        var newContentX = mMouseX*newZoom - gMouseX
        if(!temporaryZoom)
            newContentX = _temporaryContentX
        if(newContentX < 0)
            newContentX = 0

        zoomWidthAnim.from = zoomValue
        zoomWidthAnim.to = newZoom
        zoomWidthAnim.start()

        zoomOffsetAnim.from = flick.contentX
        zoomOffsetAnim.to = newContentX
        zoomOffsetAnim.start()
    }

    property bool fastBackward
    property bool backward
    property bool slowBackward
    property bool play
    property bool slowForward
    property bool forward
    property bool fastForward

    readonly property string currentSource: {
        if(!itemsRow.trueActive)
            return ""
        return itemsRow.trueActive.source
    }
    property alias trueItem: itemsRow.trueItem

    property Item playerScene

    signal move(real position)
    signal addBookmarkRequest(string source, int startPosition, int stopPosition, string image)
    signal propertiesRequest(string source)

    function append(source) {
        metadataFfmpeg.getData(Tools.urlToLocalPath(source), function(res){
            lmodel.append({"source": source, "startPosition": 0, "stopPosition": res.duration})
        })
    }

    function addToTimeline(item) {
        lmodel.append(item)
    }

    property variant fakeTimeline: new Array
    function renderRequest(item) {
        prepareRender()
        fakeTimeline = [item]
    }

    function splitCurrent() {
        var item = itemsRow.trueItem
        if(!item)
            item = itemsRow.currentItem
        if(!item)
            return

        item.pinPosition = item.position
        item.split()
    }

    function deleteCurrent() {
        var item = itemsRow.trueItem
        if(!item)
            item = itemsRow.currentItem
        if(!item)
            return

        item.deleteRequest()
    }

    function duplicate() {
        var item = itemsRow.trueItem
        if(!item)
            item = itemsRow.currentItem
        if(!item)
            return

        item.duplicate()
    }

    function prepareRender() {
        fakeTimeline = new Array
        var dlg = metaDataDialog.open()
        dlg.doRender.connect( function(metadata, resolution, frameRate, encoder, dest) {
            doRender(metadata, resolution, frameRate, encoder, dest, function(localSource, dialog) {
                console.debug(localSource)
                console.debug(Tools.variantToJson(metadata))

                var dir = Tools.fileParent(localSource)
                var tempFile = dir + "/" + Tools.fileName(localSource) + "_temp." + Tools.fileSuffix(localSource)
                metadataFfmpeg.setMetaData(localSource, metadata, tempFile, function(progress){
                    if(progress == 1) {
                        if(Tools.fileExists(tempFile)) {
                            Tools.deleteFile(localSource)
                            Tools.rename(tempFile, localSource)
                        }

                        Tools.jsDelayCall(2000, function(){
                            if(AsemanGlobals.openDirectoryAtEnd)
                                Qt.openUrlExternally( Devices.localFilesPrePath + Tools.fileParent(localSource) )
                            dialog.destroy()
                        })
                    }
                })
            })
        })
    }

    property FfmpegTools ffmpeg
    function doRender(metadata, resolution, frameRate, encoder, path, callback) {
        if(ffmpeg)
            return

        var array = new Array
        for(var i=0; i<(fakeTimeline.length? fakeTimeline.length : lmodel.count); i++) {
            var map = (fakeTimeline.length? fakeTimeline[i] : lmodel.get(i))
            var inputFile = Tools.urlToLocalPath(map.source)
            var startTime = map.startPosition
            var endTime = map.stopPosition
            if(inputFile.length == 0)
                continue

            var job = {"inputFile": inputFile, "startTime": startTime, "endTime": endTime}
            array[array.length] = job
        }

        if(array.length > 1 && encoder == "")
            encoder = "libx264"

        console.debug(Tools.variantToJson(array))
        console.debug(metadata, resolution, frameRate, encoder, path)

        Tools.mkDir( Tools.fileParent(path) )

        var objTitle = qsTr("Render")
        var description = qsTr("Rendering to the \"%1\"").arg(path)

        var obj = showProgressDialog()
        obj.title = objTitle + " - 0.0%"
        obj.description = description + "\n -> " + qsTr("Preparing...");
        obj.indicator = true
        obj.height = 240*Devices.density

        console.debug(path)

        ffmpeg = ffmpegComponent.createObject(obj)
        ffmpeg.render(array, resolution, frameRate, encoder, path, function(progress){
            var progressPercent = progress*100
            if(progressPercent < obj.progress)
                return
            if(progressPercent > 100)
                return

            var singleStep = 1 / (array.length + 1)
            var step = Math.floor(progress / singleStep)

            if(step < array.length)
                obj.description = description + "\n -> " + qsTr("Split part %1 from \"%2\"").arg(step+1).arg(Tools.fileName( array[step].inputFile ) + "." + Tools.fileSuffix( array[step].inputFile ))
            else
                obj.description = description + "\n -> " + qsTr("Merging all splitted parts...")

            if(progress > 0.99999999999) {
                progress = 1
                progressPercent = 100

                if(progressPercent == 100) {
                    if(callback != undefined) {
                        obj.description = description + "\n -> " + qsTr("Writing metadatas...")
                        callback(path, obj)
                    } else
                        obj.destroy()
                }
            }

            var titlePercent = Math.floor(progressPercent*10)
            if(titlePercent % 10 == 0)
                titlePercent = titlePercent/10 + ".0"
            else
                titlePercent = titlePercent/10

            obj.title = objTitle + " - " + titlePercent + "%"
            obj.progress = progressPercent
        })
    }

    function save() {

        var item = itemsRow.trueItem
        if(!item)
            return

        item.renderRequest()
    }

    function bookmark() {
        var item = itemsRow.trueItem
        if(!item)
            return

        item.bookmark()
    }

    function properties() {
        var item = itemsRow.trueItem
        if(!item)
            return

        item.properties()
    }

    function takeSnapshot() {
        var item = itemsRow.trueItem
        if(!item)
            return

        var pos = item.position
        var path = Desktop.getSaveFileName(mainWin)
        if(path.length)
            item.createThumbToPath(pos, path, function(){})
    }

    onPlayChanged: {
        if(!itemsRow.trueItem) {
            if(play)
                Tools.jsDelayCall(100, function(){ play = false })
            return
        }

        if(play)
            itemsRow.trueItem.mediaPlayer.play()
        else
            itemsRow.trueItem.mediaPlayer.pause()
    }

    FfmpegTools {
        id: metadataFfmpeg
    }

    NumberAnimation {
        id: zoomWidthAnim
        target: timeline
        property: "zoomValue"
        easing.type: Easing.OutCubic
        duration: 300
    }

    NumberAnimation {
        id: zoomOffsetAnim
        target: flick
        property: "contentX"
        easing.type: Easing.OutCubic
        duration: 300
    }

    AsemanListModel {
        id: lmodel
        cachePath: {
            var path = AsemanApp.homePath + "/cache/timeline"
            Tools.mkDir(path)
            return path + "/" + instanceId + ".cache"
        }
    }

    Settings {
        id: lastStateSettings
        category: "General"
        source: {
            var path = AsemanApp.homePath + "/cache/state"
            Tools.mkDir(path)
            return path + "/" + instanceId + ".cache"
        }

        property real contentX: 0
        property real zoom: 1
        property bool inited: false

        Component.onCompleted: {
            if(inited) {
                flick.contentX = contentX
            }

            inited = true
        }
    }

    AsemanFlickable {
        id: flick
        anchors.fill: parent
        flickableDirection: Flickable.HorizontalFlick
        contentHeight: scene.height
        contentWidth: scene.width
        interactive: false
        onContentXChanged: lastStateSettings.contentX = contentX

        Item {
            id: scene
            width: {
                var res = itemsRow.width
                if(res < flick.width)
                    res = flick.width
                return res
            }
            height: flick.height

            MouseArea {
                id: marea
                width: scene.width
                height: parent.height
                hoverEnabled: true
                pressAndHoldInterval: 500
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onWheel: {
                    if(flick.contentX < 0)
                        return
                    if(wheel.modifiers & Qt.ControlModifier) {
                        var mMouseX = mouseX/zoomValue
                        var gMouseX = mouseX - flick.contentX
                        if(wheel.angleDelta.y > 0)
                            zoomValue = zoomValue * 2
                        else
                            zoomValue = zoomValue / 2
                        if(zoomValue > maximumZoom)
                            zoomValue = maximumZoom

                        var newContentX = mMouseX*zoomValue - gMouseX
                        if(newContentX < 0)
                            newContentX = 0

                        flick.contentX = newContentX
                    } else {
                        if(flick.contentX + flick.contentWidth > flick.width) {
                            var newX = flick.contentX - wheel.angleDelta.y
                            if(newX < 0)
                                newX = 0
                            if(newX > flick.contentWidth - flick.width)
                                newX = flick.contentWidth - flick.width
                            flick.contentX = newX
                        }
                    }
                }
                onPressed: {
                    if(mouse.buttons == Qt.RightButton) {
                        play = false
                        itemsRow.currentItem.openMenu()
                        return
                    }

                    pinX = mouseX
                    heldItem = null

                    var playState = play
                    if(!play) {
                        heldItem = itemsRow.currentItem
                        if(heldItem)
                            heldItem.held = true
                        return
                    }

                    if(itemsRow.currentItem != itemsRow.trueItem) {
                        play = false
                    }

                    itemsRow.refreshTrueItem()
                    if(!itemsRow.currentItem)
                        return

                    itemsRow.currentItem.move(itemsRow.currentItem.value)
                    itemsRow.trueActive = itemsRow.currentItem
                    play = playState
                }
                onReleased: {
                    if(heldItem) {
                        heldItem.held = false
                        if(itemsRow.currentItem && Math.abs(mouseX - pinX) < 2*Devices.density) {
                            itemsRow.currentItem.move(itemsRow.currentItem.value)
                            itemsRow.trueActive = itemsRow.currentItem
                        }
                    }
                    heldItem = null
                }
                onMouseXChanged: {
                    if(zoomWidthAnim.running)
                        return
                    if(heldItem) {
                        heldItem.held = true
                        heldItem.heldX = (marea.mouseX - marea.pinX)
                        var item = itemsRow.childAt(marea.mouseX, marea.height/2)
                        if(item) item = item.item

                        if(item && item != heldItem && (heldItem.parent.x + item.width < marea.mouseX || heldItem.parent.x > marea.mouseX)) {
                            if(item.index > heldItem.index)
                                pinX += item.width
                            else
                                pinX -= item.width
                            lmodel.move(heldItem.index, item.index, 1)
                        }
                        return
                    } else {
                        timeX = mouseX
                    }

                    if(!pressed || !itemsRow.currentItem || !itemsRow.currentItem.active)
                        return

                    itemsRow.currentItem.move(itemsRow.currentItem.value)
                }
                onContainsMouseChanged: {
                    if(!containsMouse && !play) {
                        if(itemsRow.trueActive) {
                            if(itemsRow.currentItem)
                                itemsRow.currentItem.active = false
                            itemsRow.trueActive.active = true
                            itemsRow.trueActive.move(itemsRow.trueActive.sliderValue)
                            itemsRow.trueItem = itemsRow.trueActive
                            return
                        }
                    }
                    itemsRow.refreshTrueItem()
                }

                property real pinX: 0
                property TimeLineVideoItem heldItem
                property real timeX
            }

            TimeRuler {
                id: ruler
                width: marea.width
                height: 50*Devices.density
                zoom: timeline.zoom
                minutesWidth: timeline.minutesWidth
                displayOffset: flick.contentX
                displayWidth: flick.width
            }

            Rectangle {
                width: marea.width
                height: 4*Devices.density
                anchors.top: ruler.bottom
                opacity: AsemanGlobals.darkMode? 1 : 0.5
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#000" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                width: marea.width
                height: 3*Devices.density
                opacity: AsemanGlobals.darkMode? 1 : 0.5
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#000" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Row {
                id: itemsRow
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10*Devices.density

                property TimeLineVideoItem currentItem: {
                    var item = childAt(marea.timeX, marea.height/2)
                    if(item)
                        return item.item
                    else
                        return null
                }
                property TimeLineVideoItem trueItem
                property TimeLineVideoItem trueActive

                onCurrentItemChanged: refreshTrueItem()
                onTrueItemChanged: if(play) trueActive = trueItem

                function refreshTrueItem() {
                    if(play && trueItem && !marea.pressed)
                        return
                    if(trueItem == currentItem)
                        return
                    if(!currentItem)
                        return
                    if(trueItem) {
                        trueItem.active = false
                        trueItem.mediaPlayer.pause()
                    }
                    trueItem = currentItem
                    if(trueItem)
                        trueItem.active = true
                    if(trueItem && play) {
                        trueItem.mediaPlayer.play()
                    }
                }

                Repeater {
                    id: itemsRepeater
                    model: lmodel
                    Item {
                        id: titem
                        width: item? item.width : 0
                        height: parent.height

                        property alias item: proxy.object

                        ProxyComponent {
                            id: proxy
                            source: timelineRow_component
                            onObjectChanged: {
                                if(!object)
                                    return

                                item.parent = titem
                                item.stopPositionChanged.connect( function(){ model.stopPosition = item.stopPosition } )
                                item.startPositionChanged.connect( function(){ model.startPosition = item.startPosition } )
                                item.sceneItem = titem
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: timePointer
                y: 10*Devices.density
                x: marea.timeX - width/2
                width: 2*Devices.density
                height: parent.height - 12*Devices.density
                radius: width/2
                color: AsemanGlobals.masterColor
                opacity: marea.containsMouse? (AsemanGlobals.darkMode? 0.4 : 0.8) : 0

                Behavior on opacity {
                    NumberAnimation { easing.type: Easing.OutCubic; duration: 350 }
                }

                Rectangle {
                    width: 50*Devices.density
                    height: 20*Devices.density
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    color: parent.color
                    radius: 3*Devices.density

                    Text {
                        anchors.centerIn: parent
                        color: "#fff"
                        font.pixelSize: 8*Devices.fontDensity
                        text: {
                            var minutes = (timePointer.x / minutesWidth)
                            var seconds = minutes * 60

                            var h = Math.floor(minutes/60)
                            var m = Math.floor(seconds/60)
                            var s = Math.floor(seconds) % 60
                            var ms = Math.round(seconds * 1000) % 1000
                            if(h < 10) h = "0" + h;
                            if(m < 10) m = "0" + m;
                            if(s < 10) s = "0" + s;
                            if(ms < 10) ms = ms + "00";
                            else if(ms < 100) ms = ms + "0";

                            if(h == "00")
                                return m + ":" + s + "." + ms
                            else
                                return h + ":" + m + ":" + s + "." + ms
                        }
                    }
                }
            }
        }

        QtControls.ScrollBar.horizontal: QtControls.ScrollBar {
            parent: flick.parent
            anchors.right: flick.right
            anchors.left: flick.left
            anchors.bottom: flick.bottom
            height: 10*Devices.density
            policy: QtControls.ScrollBar.AlwaysOn

            Material.theme: AsemanGlobals.darkMode? Material.Dark : Material.Light
        }
    }

    property int cache_newConstructedPosition: 0

    Component {
        id: timelineRow_component
        TimeLineVideoItem {
            id: item
            opacity: dragArea.containsDrag? 0.5 : 1
            parent: sceneItem
            height: parent.height
            zoom: timeline.zoom
            source: model.source
            scene: playerScene
            timeX: marea.timeX - (sceneItem? sceneItem.x : 0)
            mouseY: marea.mouseY
            isTrueActive: itemsRow.trueActive == item
            globalContainsMouse: marea.containsMouse
            playbackRate: {
                if(fastForward) return 8
                if(forward) return 2
                if(slowForward) return 0.2
                if(slowBackward) return -0.2
                if(backward) return -2
                if(fastBackward) return -8
                return 1
            }

            property int index: model.index
            property variant sceneItem

            function getGlobalPosition(position) {
                if(position == -1)
                    position = startPosition

                var pinTime = position - startPosition
                var allChilds = itemsRow.children
                for(var i=0; i<allChilds.length; i++) {
                    var child = allChilds[i]
                    if(!child.item || child.item.index >= index)
                        continue

                    pinTime += child.item.virtualDuration
                }
                return pinTime
            }

            function setStartPosition(pos) {
                model.startPosition = pos
                startPosition = pos
            }

            function setStopPosition(pos) {
                model.stopPosition = pos
                stopPosition = pos
            }

            onTimeXChanged: if(containsMouse) itemsRow.refreshTrueItem()
            onFinished: {
                var sub = itemsRepeater.itemAt(index+1)
                var item = (sub && sub.item? sub.item : null)
                if(item && play) {
                    active = false
                    item.active = true
                    item.mediaPlayer.play()
                    itemsRow.trueItem = item
                } else {
                    play = false
                }
            }
            onBackwardFinished: {
                var sub = itemsRepeater.itemAt(index-1)
                var item = (sub && sub.item? sub.item : null)
                if(item) {
                    active = false
                    item.move(item.duration<item.stopPosition? item.duration : item.stopPosition)
                    Tools.jsDelayCall(500, function(){
                        item.active = true
                        itemsRow.trueItem = item
                        itemsRow.trueActive = item
                    })
                }
            }
            onForwardFinished: {
                var sub = itemsRepeater.itemAt(index+1)
                var item = (sub && sub.item? sub.item : null)
                if(item) {
                    active = false
                    item.active = true
                    itemsRow.trueItem = item
                    itemsRow.trueActive = item
                }
            }

            onBookmark: {
                addBookmarkRequest(model.source, model.startPosition, model.stopPosition, Tools.urlToLocalPath(thumbPath))
            }
            onRenderRequest: {
                timeline.renderRequest({"source": model.source, "startPosition": model.startPosition, "stopPosition": model.stopPosition})
            }

            onDuplicate: {
                cache_newConstructedPosition = position
                lmodel.insert(index+1, {"source": model.source, "startPosition": model.startPosition, "stopPosition": model.stopPosition})
            }
            onDeleteRequest: {
                parent = timeline
                visible = false
                Tools.jsDelayCall(100, function(){ lmodel.remove(index) })
            }
            onSplit: {
                lmodel.insert(index+1, {"source": model.source, "startPosition": pinPosition, "stopPosition": stopPosition})
                model.stopPosition = pinPosition
                stopPosition = pinPosition
            }
            onProperties: propertiesRequest(model.source)

            DropArea {
                id: dragArea
                anchors.fill: parent
                onEntered: {
                    drag.accepted = drag.hasUrls
                }
                onDropped: {
                    if(drop.text.length) {
                        lmodel.insert(model.index, Tools.jsonToVariant(drop.text) )
                    }
                    for(var i in drop.urls) {
                        var source = drop.urls[i]
                        var mime = Tools.fileMime(source)
                        if(mime.slice(0, 6) != "video/")
                            continue

                        lmodel.insert(model.index, {"source": source, "startPosition": 0, "stopPosition": 0})
                    }
                }
            }

            Component.onCompleted: {
                if(model.startPosition) startPosition = model.startPosition
                if(model.stopPosition) stopPosition = model.stopPosition
                itemsRow.refreshTrueItem()
                if(itemsRow.trueItem != item)
                    active = false
                if(cache_newConstructedPosition) {
                    var pos = cache_newConstructedPosition
                    Tools.jsDelayCall(100, function(){ move(pos) })
                    cache_newConstructedPosition = 0
                }
            }
        }
    }

    Component {
        id: ffmpegComponent
        FfmpegTools {
            tempDirectory: AsemanApp.tempPath + "/" + AsemanApp.applicationName + "/" + Tools.dateToMSec(new Date)
        }
    }
}
