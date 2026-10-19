pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Control {
    id: root
    palette.window: Kirigami.Theme.backgroundColor
    palette.windowText: Kirigami.Theme.textColor
    palette.text: Kirigami.Theme.textColor
    palette.buttonText: Kirigami.Theme.textColor
    palette.highlight: Kirigami.Theme.highlightColor
    palette.highlightedText: Kirigami.Theme.highlightedTextColor
    required property var backend
    property bool previewsEnabled: true
    readonly property alias parkedList: parkedList
    readonly property alias quickLaunch: quickLaunch
    implicitWidth: 280
    implicitHeight: 640

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        Label {
            text: qsTr("Quick launch")
            font.bold: true
            Layout.fillWidth: true
        }
        Flow {
            id: quickLaunch
            objectName: "quickLaunch"
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 6
            readonly property int columns: Math.max(1, Math.floor((width + spacing) / 72))
            Repeater {
                model: root.backend.launcherEntries
                delegate: ToolButton {
                    id: launcherButton
                    objectName: "launcherButton"
                    required property var modelData
                    width: Math.floor((root.quickLaunch.width - (root.quickLaunch.columns - 1) * root.quickLaunch.spacing) / root.quickLaunch.columns)
                    height: 66
                    Accessible.name: qsTr("Open %1 in a new window").arg(modelData.title)
                    ToolTip.text: Accessible.name
                    ToolTip.visible: hovered
                    onClicked: root.backend.launch(modelData.url)
                    contentItem: ColumnLayout {
                        spacing: 3
                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            source: launcherButton.modelData.icon
                        }
                        Label {
                            Layout.fillWidth: true
                            text: launcherButton.modelData.title
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
        Label {
            Layout.fillWidth: true
            visible: root.backend.launcherEntries.length === 0
            text: qsTr("Add applications in the widget settings.")
            wrapMode: Text.WordWrap
            opacity: 0.7
        }
        Kirigami.Separator { Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            Label { text: qsTr("Parked"); font.bold: true; Layout.fillWidth: true }
            Label { text: parkedList.count; opacity: 0.65 }
        }
        Label {
            Layout.fillWidth: true
            text: qsTr("Available across desktops")
            opacity: 0.65
            wrapMode: Text.WordWrap
        }
        ListView {
            id: parkedList
            objectName: "parkedList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 90
            model: root.backend.parked
            clip: true
            spacing: 10
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            delegate: ParkedCard {
                required property var model
                width: root.parkedList.width
                windowId: model.WinIdList.length ? String(model.WinIdList[0]) : ""
                windowTitle: model.display || model.AppName || ""
                applicationName: model.AppName || ""
                applicationIcon: model.decoration || "application-x-executable"
                closable: model.IsClosable
                previewHidden: Boolean(model.IsExcludedFromCapture)
                previewsEnabled: root.previewsEnabled
                property bool pooled: false
                inViewport: !pooled && y + height > root.parkedList.contentY
                    && y < root.parkedList.contentY + root.parkedList.height
                ListView.onPooled: pooled = true
                ListView.onReused: pooled = false
                onRestoreRequested: id => root.backend.restore(id)
                onCloseRequested: id => root.backend.closeWindow(id)
            }
            Label {
                anchors.fill: parent
                anchors.margins: 8
                visible: parkedList.count === 0
                text: qsTr("Park a window using its minimize button. Its preview will appear here.")
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.65
            }
        }
        Label {
            id: errorLabel
            Layout.fillWidth: true
            visible: text !== ""
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Connections {
                target: root.backend
                function onOperationFailed(message) { errorLabel.text = message; clearError.restart() }
            }
            Timer { id: clearError; interval: 6000; onTriggered: errorLabel.text = "" }
        }
    }
}
