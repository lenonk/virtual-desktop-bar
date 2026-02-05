import QtQuick
import org.kde.plasma.configuration as PlasmaConfig
// import org.kde.kirigami 2.20 as Kirigami

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18n("Behavior")
        icon: "preferences-desktop"
        source: "config/BehaviorTab.qml"

        property bool expanded: false
        property int weight: 10
    }

    PlasmaConfig.ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-display-color"
        source: "config/AppearanceTab.qml"

        property bool expanded: false
        property int weight: 20
    }

    PlasmaConfig.ConfigCategory {
        name: i18n("Support")
        icon: "emblem-favorite"
        source: "config/SupportTab.qml"

        property bool expanded: false
        property int weight: 20
    }

    property bool immutable: false
    property bool isDefaults: true
}
