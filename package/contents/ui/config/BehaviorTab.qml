import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../common" as UICommon

pragma ComponentBehavior: Bound

KCM.SimpleKCM {
    id: root

    // Empty desktops
    property string cfg_EmptyDesktopName

    // Adding desktops
    property alias cfg_SwitchToNewDesktop: switchToNewDesktopCheckBox.checked
    property alias cfg_PromptRenameNew: promptRenameNewCheckBox.checked
    property string cfg_NewDesktopCommand

    // Dynamic desktops
    property alias cfg_DynamicDesktops: dynamicDesktopsCheckBox.checked

    // Multiple screens/monitors
    property alias cfg_FilterByScreen: filterByScreenCheckBox.checked

    // Mouse wheel handling
    property alias cfg_WheelClickRemoves: wheelClickRemovesCheckBox.checked
    property alias cfg_WheelScrollSwitches: wheelScrollSwitchesCheckBox.checked
    property alias cfg_WheelInvertDirection: wheelInvertDirectionCheckBox.checked
    property alias cfg_WheelWrapAround: wheelWrapAroundCheckBox.checked

    Kirigami.FormLayout {
        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Empty Desktops:")
            CheckBox {
                id: emptyDesktopNameCheckBox
                checked: cfg_EmptyDesktopName
                onCheckedChanged: cfg_EmptyDesktopName = checked ?
                    emptyDesktopNameTextField.text : ""
                text: "Rename as:"
            }

            UICommon.GrowingTextField {
                id: emptyDesktopNameTextField
                enabled: emptyDesktopNameCheckBox.checked
                maximumLength: 20
                text: cfg_EmptyDesktopName || "Desktop"
                onTextChanged: {
                    if (cfg_EmptyDesktopName && text) {
                        cfg_EmptyDesktopName = text;
                    }
                }
                onEditingFinished: cfg_EmptyDesktopName = text
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: i18n("Adding Desktops:")

            CheckBox {
                id: switchToNewDesktopCheckBox
                enabled: !dynamicDesktopsCheckBox.checked
                text: "Switch to an added desktop"
            }

            HintIcon {
                visible: !switchToNewDesktopCheckBox.enabled
                tooltipText: "Not available if dynamic desktops are enabled"
            }
        }

        RowLayout {
            CheckBox {
                id: promptRenameNewCheckBox
                enabled: !dynamicDesktopsCheckBox.checked
                text: "Prompt to rename an added desktop"
            }

            HintIcon {
                visible: !promptRenameNewCheckBox.enabled
                tooltipText: "Not available if dynamic desktops are enabled"
            }
        }

        RowLayout {
            CheckBox {
                id: newDesktopCommandCheckBox
                checked: cfg_NewDesktopCommand
                onCheckedChanged: cfg_NewDesktopCommand = checked ?
                    newDesktopCommandTextField.text : ""
                text: "Execute a command:"
            }

            UICommon.GrowingTextField {
                id: newDesktopCommandTextField
                enabled: newDesktopCommandCheckBox.enabled &&
                    newDesktopCommandCheckBox.checked
                maximumLength: 255
                text: cfg_NewDesktopCommand || "krunner"
                onTextChanged: {
                    if (cfg_NewDesktopCommand && text) {
                        cfg_NewDesktopCommand = text;
                    }
                }
                onEditingFinished: cfg_NewDesktopCommand = text
            }
        }


        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: i18n("Dynamic Desktops:")

            CheckBox {
                id: dynamicDesktopsCheckBox
                text: "Enable dynamic desktops"
            }

            HintIcon {
                tooltipText: "Automatically adds and removes desktops"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: i18n("Multiple Screens/Monitors:")

            CheckBox {
                id: filterByScreenCheckBox
                text: "Filter occupied desktops by screen/monitor"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: i18n("Mouse Wheel Handling:")

            CheckBox {
                id: wheelClickRemovesCheckBox
                enabled: !dynamicDesktopsCheckBox.checked
                text: "Remove desktops on the wheel click"
            }

            HintIcon {
                visible: !wheelClickRemovesCheckBox.enabled
                tooltipText: "Not available if dynamic desktops are enabled"
            }
        }

        CheckBox {
            id: wheelScrollSwitchesCheckBox
            text: "Switch desktops by scrolling the wheel"
        }

        CheckBox {
            id: wheelInvertDirectionCheckBox
            enabled: wheelScrollSwitchesCheckBox.checked
            text: "Invert wheel scrolling desktop switching direction"
        }

        CheckBox {
            id: wheelWrapAroundCheckBox
            enabled: wheelScrollSwitchesCheckBox.checked
            text: "Wrap desktop navigation after reaching first or last one"
        }
    }
}
