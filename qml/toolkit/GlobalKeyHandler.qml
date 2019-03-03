import QtQuick 2.0
import AsemanQml.Base 2.0

KeyHandler {
    window: mainWin

    property bool active: true

    readonly property bool controlShift: active && modifiers == (Qt.ControlModifier | Qt.ShiftModifier)
    readonly property bool left: active && modifiers == 0 && key == Qt.Key_Left
    readonly property bool controlLeft: active && modifiers == Qt.ControlModifier && key == Qt.Key_Left
    readonly property bool altLeft: active && modifiers == Qt.AltModifier && key == Qt.Key_Left
    readonly property bool right: active && modifiers == 0 && key == Qt.Key_Right
    readonly property bool controlRight: active && modifiers == Qt.ControlModifier && key == Qt.Key_Right
    readonly property bool altRight: active && modifiers == Qt.AltModifier && key == Qt.Key_Right

    signal spacePressed()
    signal sPressed()
    signal dPressed()
    signal xPressed()
    signal nPressed()
    signal mPressed()
    signal controlN()
    signal controlR()
    signal controlS()
    signal controlB()
    signal controlP()
    signal deletePressed()
    signal esc()

    onKeyChanged: {
        switch(key) {
        case Qt.Key_Escape:
            esc();
            break;
        }
        if(!active) return

        switch(key) {
        case Qt.Key_Space:
            spacePressed()
            break;

        case Qt.Key_R:
            if(modifiers == Qt.ControlModifier)
                controlR()
            break;

        case Qt.Key_S:
            if(modifiers == Qt.ControlModifier)
                controlS()
            else
                sPressed()
            break;

        case Qt.Key_B:
            if(modifiers == Qt.ControlModifier)
                controlB()
            break;

        case Qt.Key_P:
            if(modifiers == Qt.ControlModifier)
                controlP()
            break;

        case Qt.Key_D:
            dPressed()
            break;

        case Qt.Key_X:
            xPressed()
            break;

        case Qt.Key_N:
            if(modifiers == Qt.ControlModifier)
                controlN()
            else
                nPressed()
            break;

        case Qt.Key_M:
            mPressed()
            break;

        case Qt.Key_Delete:
            deletePressed()
            break;
        }
    }
}
