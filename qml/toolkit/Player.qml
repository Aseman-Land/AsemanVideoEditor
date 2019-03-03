import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import QtAV 1.6 as QtAV
import QtQuick.Window 2.2
import QtQuick.Controls 2.2 as QtControls
import "../globals"

Item {
    visible: true
    width: 640
    height: 480

    property alias mainPlayer: _player
    property int startPosition
    property int stopPosition
    property real playbackRate
    readonly property int position: mainPlayer? mainPlayer.newPosition : 0
    readonly property int duration: mainPlayer? mainPlayer.duration : 0
    property url source
    property bool active: false

    readonly property bool playing: mainPlayer && mainPlayer.playbackState == QtAV.MediaPlayer.PlayingState

    signal replaceRequest(int position)
    signal finished()
    signal pointerChangeRequest(int position)
    signal forwardFinished()
    signal backwardFinished()

    function seek(position) {
        if(mainPlayer.status < 5 || statusTimer.running)
            return
        if(position >= _player.duration)
            return
        if(position < 0)
            return
        if(source != _player.source)
            return

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

    onStartPositionChanged: sourceTimer.restart()
    onStopPositionChanged: sourceTimer.restart()
    onSourceChanged: sourceTimer.restart()
    onActiveChanged: refreshPlayrate()
    onPlayingChanged: playCheck.stop()
    onPlaybackRateChanged: {
        if(playing) pause()
        refreshPlayrate()
    }

    Timer {
        id: sourceTimer
        interval: 100
        repeat: false
        onTriggered: {
            _player.source = source
//            positionTimer.restart()
        }
    }

    Timer {
        id: positionTimer
        interval: sourceTimer.interval
        repeat: false
        onTriggered: {
            _player.startPosition = startPosition
            _player.stopPosition = stopPosition
        }
    }

    Timer {
        id: statusTimer
        interval: 200
        repeat: false
    }

    Timer {
        id: playCheck
        interval: 1000
        repeat: false
        onTriggered: {
            if(playing)
                return

            console.debug("Play error:\n -> Try restarting player...")
            replaceRequest(position)
        }
    }

    Timer {
        id: tryToFixTimer
        interval: 25
        repeat: true
        onTriggered: {
            if(counter == 10) {
                stop()
                return
            }

            counter++
        }

        function run() {
            if(mainPlayer.position == lastPosition) {
                stop()
                return
            }

            counter = 0
            restart()
        }

        property int counter
        property int lastPosition
    }

    Timer {
        id: autoSeekTimer
        interval: 10
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            position += (interval*playbackRate)
            if(position > stopPosition || position > duration) {
                forwardFinished()
                return
            } else if(position < 0 || position < startPosition) {
                backwardFinished()
                return
            }

            seek(position)
            pointerChangeRequest(position)
        }

        property int position
    }

    Rectangle {
        anchors.fill: parent
        color: "#000"
    }

    Item {
        id: player
        anchors.fill: parent

        property bool requested
        property int requestedValue

        onRequestedValueChanged: {
            if(requested)
                return
            if(!mainPlayer)
                return

            requested = true
            requestTimer.restart()
            mainPlayer.seek(requestedValue)
        }

        Timer {
            id: requestTimer
            interval: 1000
            repeat: false
            onTriggered: player.requested = false
        }


        QtAV.MediaPlayer {
            id: _player
            autoLoad: true
            autoPlay: true
            onStatusChanged: if(status < 5) statusTimer.restart()
            volume: 0
            readonly property int newPosition: position
            onStopped: {
                volume = 0
                inited = false
                Tools.jsDelayCall(10, play)
                finished()
            }
            onSeekFinished: {
                if(player.requested)
                    mainPlayer.seek(player.requestedValue)
                else
                    tryToFixTimer.run()

                player.requested = false
            }
            videoCodecPriority: {
                if(!AsemanGlobals.hardwareAccelaration)
                    return ["FFmpeg"]
                if(Devices.isLinux)
                    return ["VAAPI", "FFmpeg"]
                else
                if(Devices.isMacX)
                    return ["VideoToolbox", "FFmpeg"]
                else
                    return ["DXVA", "D3D11", "FFmpeg"]
            }
            onSourceChanged: {
                volume = 0
                inited = false
            }
            onPlaybackStateChanged: {
                if(inited)
                    return
                if(playbackState != QtAV.MediaPlayer.PlayingState)
                    return

                inited = true
                volume = 1
                Tools.jsDelayCall(1, pause)
            }

            property bool inited: false
        }

        QtAV.VideoOutput2 {
            anchors.fill: parent
            source: mainPlayer
        }
    }
}
