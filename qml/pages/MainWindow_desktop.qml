import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import AsemanQml.Awesome 2.0
import QtAV 1.6 as QtAV
import "../globals"

AsemanPage {
    property bool backVisible: true

    footerItem.color: AsemanGlobals.masterColor

    MainPage {
        id: mainItem
        anchors.fill: parent
    }

    HeaderMenuButton {
        id:headerMenuButton
        buttonColor: mainWin.isFullscreen? "#fff" : AsemanGlobals.headerTextColor
        onClicked: AsemanGlobals.sidebar = !AsemanGlobals.sidebar
        ratio: AsemanGlobals.sidebar? 1 : 0

        Behavior on ratio {
            NumberAnimation{easing.type: Easing.OutCubic; duration: 300}
        }
    }

    Component {
        id: about_component
        Item {}
    }

    Component {
        id: settings_component
        Item {}
    }
}
