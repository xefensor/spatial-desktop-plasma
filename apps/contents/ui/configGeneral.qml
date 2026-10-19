import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    property var cfg_launchers: []
    property alias cfg_showPreviews: previews.checked

    TextArea {
        id: launchers
        Kirigami.FormData.label: qsTr("Quick launch:")
        Layout.preferredWidth: 340
        Layout.preferredHeight: 140
        text: root.cfg_launchers.join("\n")
        wrapMode: TextEdit.NoWrap
        onTextChanged: {
            const values = text.split(/\r?\n/).map(line => line.trim()).filter(Boolean)
            if (JSON.stringify(values) !== JSON.stringify(root.cfg_launchers))
                root.cfg_launchers = values
        }
        Accessible.name: qsTr("Application launcher addresses, one per line")
    }
    Label {
        Layout.preferredWidth: 340
        wrapMode: Text.WordWrap
        text: qsTr("One launcher per line, in display order. Use preferred://browser, preferred://filemanager, or applications: followed by a .desktop file name.")
    }
    CheckBox {
        id: previews
        text: qsTr("Show window previews")
    }
}
