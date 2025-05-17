import QtQuick
import org.kde.plasma.configuration 2.0
import org.kde.kirigami 2.20 as Kirigami

ConfigModel {
    ConfigCategory {
        name: i18n("Behavior")
        icon: "preferences-desktop"
        source: "config/BehaviorTab.qml"

        property bool expanded: true
        property int weight: 10
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-display-color"
        source: "config/AppearanceTab.qml"

        property bool expanded: false
        property int weight: 20
    }

    property bool immutable: false
    property bool isDefaults: true
}
