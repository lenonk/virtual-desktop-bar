import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../common" as UICommon

pragma ComponentBehavior: Bound

KCM.SimpleKCM {
    id: root

    // Add config keys used on other tabs (Plasma injects all cfg_* into every tab)
    property bool   cfg_AnimationsEnable
    property bool   cfg_TooltipsEnable
    property bool   cfg_ShowAddButton
    property int    cfg_AddDesktopButtonSize
    property int    cfg_ButtonMarginVertical
    property int    cfg_ButtonMarginHorizontal
    property int    cfg_ButtonSpacing
    property bool   cfg_ButtonCommonSize
    property bool   cfg_ShowOnlyCurrent
    property bool   cfg_ShowOnlyOccupied
    property int    cfg_LabelStyle
    property string cfg_LabelCustomFormat
    property int    cfg_LabelMaxLength
    property string cfg_LabelFont
    property int    cfg_LabelFontSize
    property string cfg_LabelColor
    property bool   cfg_LabelDimIdle
    property bool   cfg_LabelUppercase
    property bool   cfg_LabelBoldCurrent
    property int    cfg_IndicatorStyle
    property int    cfg_IndicatorBlockRadius
    property int    cfg_IndicatorLineThickness
    property bool   cfg_IndicatorInvert
    property string cfg_IndicatorColorIdle
    property string cfg_IndicatorColorCurrent
    property string cfg_IndicatorColorOccupied
    property string cfg_IndicatorColorAttention
    property bool   cfg_IndicatorKeepOpacity
    property bool   cfg_IndicatorDistinctOccupied
    property bool   cfg_IndicatorDistinctAttention

    // Add defaults (Plasma may inject cfg_*Default too)
    property string cfg_EmptyDesktopNameDefault
    property bool   cfg_SwitchToNewDesktopDefault
    property bool   cfg_PromptRenameNewDefault
    property string cfg_NewDesktopCommandDefault
    property bool   cfg_DynamicDesktopsDefault
    property bool   cfg_FilterByScreenDefault
    property bool   cfg_WheelClickRemovesDefault
    property bool   cfg_WheelScrollSwitchesDefault
    property bool   cfg_WheelInvertDirectionDefault
    property bool   cfg_WheelWrapAroundDefault
    property bool   cfg_AnimationsEnableDefault
    property bool   cfg_TooltipsEnableDefault
    property bool   cfg_ShowAddButtonDefault
    property int    cfg_AddDesktopButtonSizeDefault
    property int    cfg_ButtonMarginVerticalDefault
    property int    cfg_ButtonMarginHorizontalDefault
    property int    cfg_ButtonSpacingDefault
    property bool   cfg_ButtonCommonSizeDefault
    property bool   cfg_ShowOnlyCurrentDefault
    property bool   cfg_ShowOnlyOccupiedDefault
    property int    cfg_LabelStyleDefault
    property string cfg_LabelCustomFormatDefault
    property int    cfg_LabelMaxLengthDefault
    property string cfg_LabelFontDefault
    property int    cfg_LabelFontSizeDefault
    property string cfg_LabelColorDefault
    property bool   cfg_LabelDimIdleDefault
    property bool   cfg_LabelUppercaseDefault
    property bool   cfg_LabelBoldCurrentDefault
    property int    cfg_IndicatorStyleDefault
    property int    cfg_IndicatorBlockRadiusDefault
    property int    cfg_IndicatorLineThicknessDefault
    property bool   cfg_IndicatorInvertDefault
    property string cfg_IndicatorColorIdleDefault
    property string cfg_IndicatorColorCurrentDefault
    property string cfg_IndicatorColorOccupiedDefault
    property string cfg_IndicatorColorAttentionDefault
    property bool   cfg_IndicatorKeepOpacityDefault
    property bool   cfg_IndicatorDistinctOccupiedDefault
    property bool   cfg_IndicatorDistinctAttentionDefault

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
