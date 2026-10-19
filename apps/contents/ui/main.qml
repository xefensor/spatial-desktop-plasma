pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    Layout.minimumWidth: 220
    Layout.preferredWidth: 280
    Layout.minimumHeight: 260
    Layout.preferredHeight: 640
    Layout.fillHeight: true
    preferredRepresentation: fullRepresentation

    WindowModel {
        id: windows
        launchers: Plasmoid.configuration.launchers
    }
    fullRepresentation: AppsView {
        backend: windows
        previewsEnabled: Plasmoid.configuration.showPreviews
    }
}
