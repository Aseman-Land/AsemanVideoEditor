import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0

Item {
    property ProxyPlayer currentItem
    property ProxyPlayer lastItem

    onCurrentItemChanged: {
        if(currentItem) currentItem.player = player
        if(lastItem) lastItem.player = null
        lastItem = currentItem
    }

    Player {
        id: player
        anchors.fill: parent
        startPosition: currentItem? currentItem.startPosition : 0
        stopPosition: currentItem? currentItem.stopPosition : 2000000000
        playbackRate: currentItem? currentItem.playbackRate : 1
        source: currentItem? currentItem.source : ""
        active: true
        onPositionChanged: if(currentItem) currentItem.position = position
        onFinished: if(currentItem) currentItem.finished()
        onForwardFinished: if(currentItem) currentItem.forwardFinished()
        onBackwardFinished: if(currentItem) currentItem.backwardFinished()
    }

    function seek(position) {
        player.requestedValue = position
        tryToFixTimer.stop()
        tryToFixTimer.lastPosition = position
    }

    function play() {
        mainPlayer.play()
        playCheck.restart()
    }

    function pause() {
        mainPlayer.pause()
        playCheck.stop()
    }

    function refreshPlayrate() {
        if(playbackRate == 1 || !active) {
            autoSeekTimer.stop()
        } else {
            autoSeekTimer.position = position
            autoSeekTimer.restart()
        }
    }
}
