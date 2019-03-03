import QtQuick 2.0

Item {

    property Player player

    property int startPosition
    property int stopPosition: 2000000000
    property real playbackRate
    property int position
    property int duration
    property url source
    property bool active

    readonly property bool playing: player? player.playing : false

    signal replaceRequest(int position)
    signal finished()
    signal pointerChangeRequest(int position)
    signal forwardFinished()
    signal backwardFinished()

    function seek(position) {
        player.seek(position)
    }

    function play() {
        player.play()
    }

    function pause() {
        player.pause()
    }
}
