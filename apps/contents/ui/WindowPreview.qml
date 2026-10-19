pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire

Item {
    id: root
    required property string windowId
    property var fallbackIcon: "application-x-executable"
    property bool previewEnabled: true
    property bool previewHidden: false
    readonly property bool streamActive: stream.active
    readonly property bool hasPreview: (stream.item as PipeWire.PipeWireSourceItem)?.ready ?? false

    Loader {
        id: stream
        anchors.fill: parent
        active: root.visible && root.previewEnabled && !root.previewHidden && root.windowId !== ""
            && Boolean(root.Window.window && root.Window.window.visible)
        sourceComponent: PipeWire.PipeWireSourceItem {
            nodeId: request.nodeId
            objectSerial: request.objectSerial
            TaskManager.ScreencastingRequest {
                id: request
                uuid: root.windowId
            }
        }
    }
    Column {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 24)
        spacing: 8
        visible: !root.hasPreview
        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40
            source: root.fallbackIcon
        }
        Label {
            width: parent.width
            color: Kirigami.Theme.textColor
            text: root.previewHidden || !root.previewEnabled ? qsTr("Preview hidden") : qsTr("Preview unavailable")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            opacity: 0.7
        }
    }
}
