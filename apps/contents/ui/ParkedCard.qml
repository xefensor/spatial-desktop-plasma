import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Control {
    id: root
    required property string windowId
    required property string windowTitle
    property string applicationName: ""
    property var applicationIcon: "application-x-executable"
    property bool closable: true
    property bool previewsEnabled: true
    property bool previewHidden: false
    property bool inViewport: true
    signal restoreRequested(string id)
    signal closeRequested(string id)

    padding: 8
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    background: Rectangle {
        radius: 6
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.035)
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
    }
    contentItem: ColumnLayout {
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Icon {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                source: root.applicationIcon
            }
            Label {
                Layout.fillWidth: true
                text: root.windowTitle || root.applicationName
                maximumLineCount: 2
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }
            ToolButton {
                objectName: "closeWindow"
                icon.name: "window-close"
                enabled: root.closable
                Accessible.name: qsTr("Close %1").arg(root.windowTitle)
                ToolTip.text: Accessible.name
                ToolTip.visible: hovered
                onClicked: root.closeRequested(root.windowId)
            }
        }
        Button {
            id: restoreButton
            objectName: "restoreWindow"
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(96, width * 0.625)
            padding: 4
            Accessible.name: qsTr("Restore %1 onto this desktop").arg(root.windowTitle)
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered
            onClicked: root.restoreRequested(root.windowId)
            background: Rectangle {
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.12)
                border.width: restoreButton.activeFocus || restoreButton.hovered ? 2 : 0
                border.color: Kirigami.Theme.highlightColor
            }
            contentItem: WindowPreview {
                windowId: root.windowId
                fallbackIcon: root.applicationIcon
                previewEnabled: root.previewsEnabled && root.inViewport
                previewHidden: root.previewHidden
            }
        }
    }
}
