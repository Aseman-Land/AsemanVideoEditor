import QtQuick 2.0
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import "../globals"

Item {
    id: ruler

    property real zoom
    property real minutesWidth: 100
    property real displayOffset
    property real displayWidth: 600
    readonly property real stepsWidth: (zoom > 2? zoom / 2 : 1) * 120*Devices.density / 6
    readonly property int stepsCount: Math.floor(ruler.width / stepsWidth) + 1

    onStepsCountChanged: refresh()
    onDisplayWidthChanged: refresh()
    onDisplayOffsetChanged: refresh()

    function refresh() {
        var startIndex = Math.floor(displayOffset/stepsWidth)
        var endIndex = Math.floor((displayOffset + displayWidth)/stepsWidth)

        var hashKeys = hash.keys()
        for(var key in hashKeys)
            hash.value(hashKeys[key]).destroy()

        hash.clear()
        for(var i=startIndex; i<=endIndex+1; i++) {
            var obj = linesComponent.createObject(scene, {"index": i})
            hash.insert(i, obj)
        }
    }

    HashObject {
        id: hash
    }

    Rectangle {
        anchors.fill: parent
        color: AsemanGlobals.darkMode? "#333" : "#fafafa"
    }

    Item {
        id: scene
        anchors.fill: parent
    }

    Component {
        id: linesComponent
        Item {
            id: item
            x: index * sw
            width: sw
            height: ruler.height

            property real sw: stepsWidth
            property real mw: minutesWidth
            property int index

            Behavior on opacity {
                NumberAnimation { easing.type: Easing.OutCubic; duration: 300 }
            }

            Rectangle {
                id: line
                y: 2*Devices.density
                anchors.bottom: parent.bottom
                width: 1*Devices.density
                height: 20*Devices.densit
                color: "#666"
            }

            Text {
                anchors.horizontalCenter: line.horizontalCenter
                anchors.bottom: line.top
                anchors.bottomMargin: 4*Devices.density
                color: line.color
                visible: item.index % 2 == 0
                font.pixelSize: 8*Devices.fontDensity

                text: {
                    var minutes = item.index * (item.sw / item.mw)
                    var seconds = minutes * 60
                    var ms = seconds * 1000

                    var h = Math.floor(minutes/60)
                    var m = Math.floor(seconds/60)
                    var s = Math.floor(seconds) % 60
                    if(h < 10) h = "0" + h;
                    if(m < 10) m = "0" + m;
                    if(s < 10) s = "0" + s;

                    var text = ""
                    if(s == "00" && m == "00") {
                        text = h + ":" + m + ":" + s
                        line.height = 30*Devices.density
                    }
                    else
                    if(s == "00") {
                        text = m + ":" + s
                        line.height = 20*Devices.density
                    } else {
                        text = s
                        line.height = 10*Devices.density
                    }
                    return text
                }
            }
        }
    }
}
