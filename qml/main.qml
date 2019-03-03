import QtQuick 2.7
import AsemanQml.Base 2.0
import AsemanQml.Controls 2.0
import "globals"
import "."

AsemanApplication {
    id: app
    applicationAbout: "Aseman Video Editor"
    applicationDisplayName: "Aseman Video Editor"
    applicationId: "d77d937a-5630-4962-9548-afb6c602407d"
    organizationDomain: "aseman.io"
    source: "pages/MainWindow.qml"
    qpaNoTextHandles: Devices.isAndroid
    Component.onCompleted: {
        AsemanApp.globalFont.family = globalFont
    }

    property int closeRequestCommand: 0
    property string globalFont: AsemanGlobals.localeName == "fa"? iran_sans.name : ubuntu_font.name

    onGlobalFontChanged: AsemanApp.globalFont.family = globalFont

    FontLoader { id: iran_sans_light ;     source: "fonts/IRANSans_Light.ttf"}
    FontLoader { id: iran_sans;            source: "fonts/IRANSans_Regular.ttf"}
    FontLoader { id: ubuntu_font;          source: "fonts/Ubuntu-R.ttf" }

    TranslationManager {
        id: translationManager
        sourceDirectory: "translations"
        delimiters: "-"
        fileName: "lang"
        localeName: AsemanGlobals.localeName

        function refreshLayouts() {
            View.layoutDirection = textDirection
            if(localeName == "fa")
                CalendarConv.calendar = 1
            else
                CalendarConv.calendar = 0
        }
        Component.onCompleted: refreshLayouts()
        onLocaleNameChanged: refreshLayouts()
    }
}
