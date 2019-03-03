import QtQuick 2.9
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import AsemanQml.Modern 2.0
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Controls.Material 2.1
import "../globals"

Item {
    id: sidebar
    clip: true

    property alias tabIndex: tabbar.currentIndex

    function addBookmark(source, startPosition, stopPosition, image) {
        bookmark.append(source, startPosition, stopPosition, image)
        tabbar.currentIndex = 0
    }

    signal addToTimeline(variant item)
    signal renderRequest(variant item)
    signal addRequest(string path)

    QtControls.SwipeView {
        id: swipe
        interactive: false
        width: parent.width
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        currentIndex: AsemanGlobals.sidebarTabIndex

        LayoutMirroring.enabled: View.reverseLayout
        LayoutMirroring.childrenInherit: true

        Bookmarks {
            id: bookmark
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            onAddToTimeline: sidebar.addToTimeline(item)
            onRenderRequest: sidebar.renderRequest(item)
        }

        FileBrowser {
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            onAddRequest: sidebar.addRequest(path)
        }
    }

    FastRectengleShadow {
        anchors.fill: tabbar
        color: "#000"
        radius: 8*Devices.density
    }

    TabBar {
        id: tabbar
        width: parent.width
        minimumWidth: 80*Devices.density
        color: AsemanGlobals.darkMode? "#444" : "#f0f0f0"
        textColor: AsemanGlobals.darkMode? "#fff" : "#333"
        currentIndex: AsemanGlobals.sidebarTabIndex
        model: [qsTr("Bookmarks") + translationManager.refresher,
                qsTr("Files") + translationManager.refresher]
        fontSize: 9*Devices.fontDensity
        onCurrentIndexChanged: AsemanGlobals.sidebarTabIndex = currentIndex
    }
}
