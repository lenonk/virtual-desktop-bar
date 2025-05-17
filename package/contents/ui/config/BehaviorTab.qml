import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "../common" as UICommon

Item {
    id: root

    // Config properties
    property string cfg_EmptyDesktopsRenameAs
    property alias cfg_AddingDesktopsSwitchTo: addingDesktopsSwitchTo.checked
    property alias cfg_AddingDesktopsPromptToRename: addingDesktopsPromptToRename.checked
    property string cfg_AddingDesktopsExecuteCommand
    property alias cfg_DynamicDesktopsEnable: dynamicDesktopsEnable.checked
    property alias cfg_MultipleScreensFilterOccupiedDesktops: multipleScreensFilter.checked
    property alias cfg_MouseWheelRemoveDesktopOnClick: mouseWheelRemoveDesktop.checked
    property alias cfg_MouseWheelSwitchDesktopOnScroll: mouseWheelSwitchDesktop.checked
    property alias cfg_MouseWheelInvertDesktopSwitchingDirection: mouseWheelInvertDirection.checked
    property alias cfg_MouseWheelWrapDesktopNavigationWhenScrolling: mouseWheelWrapNavigation.checked

    ScrollView {
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

                // Empty Desktops Section
                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: i18n("Empty Desktops")
                    level: 2
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Rename as:")

                    PlasmaComponents3.CheckBox {
                        id: emptyDesktopsRename
                        checked: cfg_EmptyDesktopsRenameAs
                        onCheckedChanged: cfg_EmptyDesktopsRenameAs = checked ?
                            emptyDesktopsRenameText.text : ""
                    }

                    UICommon.GrowingTextField {
                        id: emptyDesktopsRenameText
                        enabled: emptyDesktopsRename.checked
                        maximumLength: 20
                        text: cfg_EmptyDesktopsRenameAs || i18n("Desktop")
                        onTextChanged: {
                            if (cfg_EmptyDesktopsRenameAs && text) {
                                cfg_EmptyDesktopsRenameAs = text
                            }
                        }
                    }
                }

                // Adding Desktops Section
                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    text: i18n("Adding Desktops")
                    level: 2
                }

                RowLayout {
                    PlasmaComponents3.CheckBox {
                        id: addingDesktopsSwitchTo
                        enabled: !cfg_DynamicDesktopsEnable
                        text: i18n("Switch to newly added desktop")
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "help-contextual"
                        visible: !addingDesktopsSwitchTo.enabled
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        PlasmaComponents3.ToolTip {
                            text: i18n("Not available with dynamic desktops enabled")
                            visible: parent.hovered
                        }
                    }
                }

                RowLayout {
                    PlasmaComponents3.CheckBox {
                        id: addingDesktopsPromptToRename
                        enabled: !cfg_DynamicDesktopsEnable
                        text: i18n("Prompt to rename newly added desktop")
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "help-contextual"
                        visible: !addingDesktopsPromptToRename.enabled
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        PlasmaComponents3.ToolTip {
                            text: i18n("Not available with dynamic desktops enabled")
                            visible: parent.hovered
                        }
                    }
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Execute command:")

                    PlasmaComponents3.CheckBox {
                        id: executeCommandEnable
                        checked: cfg_AddingDesktopsExecuteCommand
                        onCheckedChanged: cfg_AddingDesktopsExecuteCommand = checked ?
                            executeCommandText.text : ""
                    }

                    UICommon.GrowingTextField {
                        id: executeCommandText
                        enabled: executeCommandEnable.checked
                        maximumLength: 255
                        text: cfg_AddingDesktopsExecuteCommand || "krunner"
                        onTextChanged: {
                            if (cfg_AddingDesktopsExecuteCommand && text) {
                                cfg_AddingDesktopsExecuteCommand = text
                            }
                        }
                    }
                }

                // Dynamic Desktops Section
                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    text: i18n("Dynamic Desktops")
                    level: 2
                }

                RowLayout {
                    PlasmaComponents3.CheckBox {
                        id: dynamicDesktopsEnable
                        text: i18n("Enable dynamic desktops")
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "help-contextual"
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        PlasmaComponents3.ToolTip {
                            text: i18n("Automatically adds and removes desktops")
                            visible: parent.hovered
                        }
                    }
                }

                // Multiple Screens Section
                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    text: i18n("Multiple Screens")
                    level: 2
                }

                PlasmaComponents3.CheckBox {
                    id: multipleScreensFilter
                    text: i18n("Filter occupied desktops by screen")
                }

                // Mouse Wheel Section
                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    text: i18n("Mouse Wheel")
                    level: 2
                }

                RowLayout {
                    PlasmaComponents3.CheckBox {
                        id: mouseWheelRemoveDesktop
                        enabled: !cfg_DynamicDesktopsEnable
                        text: i18n("Remove desktops on middle-click")
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "help-contextual"
                        visible: !mouseWheelRemoveDesktop.enabled
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        PlasmaComponents3.ToolTip {
                            text: i18n("Not available with dynamic desktops enabled")
                            visible: parent.hovered
                        }
                    }
                }

                PlasmaComponents3.CheckBox {
                    id: mouseWheelSwitchDesktop
                    text: i18n("Switch desktops by scrolling")
                }

                PlasmaComponents3.CheckBox {
                    id: mouseWheelInvertDirection
                    enabled: mouseWheelSwitchDesktop.checked
                    text: i18n("Invert scrolling direction")
                }

                PlasmaComponents3.CheckBox {
                    id: mouseWheelWrapNavigation
                    enabled: mouseWheelSwitchDesktop.checked
                    text: i18n("Wrap around at first and last desktop")
                }
            }
        }
    }
}
