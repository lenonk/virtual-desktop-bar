import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "../common" as UICommon

Item {
    id: root

    // Config properties
    property bool cfg_DynamicDesktopsEnable
    property alias cfg_AnimationsEnable: animationsEnable.checked
    property alias cfg_TooltipsEnable: tooltipsEnable.checked
    property alias cfg_AddDesktopButtonShow: addDesktopButtonShow.checked

    // Desktop buttons config
    property alias cfg_DesktopButtonsVerticalMargin: desktopButtonsVerticalMargin.value
    property alias cfg_DesktopButtonsHorizontalMargin: desktopButtonsHorizontalMargin.value
    property alias cfg_DesktopButtonsSpacing: desktopButtonsSpacing.value
    property alias cfg_DesktopButtonsSetCommonSizeForAll: desktopButtonsSetCommonSize.checked
    property alias cfg_DesktopButtonsShowOnlyForCurrentDesktop: showOnlyCurrentDesktop.checked
    property alias cfg_DesktopButtonsShowOnlyForOccupiedDesktops: showOnlyOccupiedDesktops.checked

    // Desktop labels config
    property alias cfg_DesktopLabelsStyle: labelsStyle.currentIndex
    property string cfg_DesktopLabelsStyleCustomFormat
    property string cfg_DesktopLabelsCustomFont
    property int cfg_DesktopLabelsCustomFontSize
    property string cfg_DesktopLabelsCustomColor
    property alias cfg_DesktopLabelsDimForIdleDesktops: dimIdleDesktops.checked
    property alias cfg_DesktopLabelsBoldFontForCurrentDesktop: boldCurrentDesktop.checked
    property alias cfg_DesktopLabelsMaximumLength: maxLabelLength.value
    property alias cfg_DesktopLabelsDisplayAsUppercased: uppercaseLabels.checked

    // Desktop indicators config
    property alias cfg_DesktopIndicatorsStyle: indicatorsStyle.currentIndex
    property alias cfg_DesktopIndicatorsStyleBlockRadius: blockRadius.value
    property alias cfg_DesktopIndicatorsStyleLineThickness: lineThickness.value
    property alias cfg_DesktopIndicatorsInvertPosition: invertPosition.checked
    property string cfg_DesktopIndicatorsCustomColorForIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForCurrentDesktop
    property string cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention
    property alias cfg_DesktopIndicatorsDoNotOverrideOpacityOfCustomColors: preserveCustomColors.checked
    property alias cfg_DesktopIndicatorsDistinctForOccupiedIdleDesktops: distinctOccupied.checked
    property alias cfg_DesktopIndicatorsDistinctForDesktopsNeedingAttention: distinctAttention.checked

    ScrollView {
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // Animations Section
            Kirigami.FormLayout {
                PlasmaComponents3.CheckBox {
                    id: animationsEnable
                    Kirigami.FormData.label: i18n("Animations")
                    text: i18n("Enable animations")
                }
            }

            // Tooltips Section
            Kirigami.FormLayout {
                PlasmaComponents3.CheckBox {
                    id: tooltipsEnable
                    Kirigami.FormData.label: i18n("Tooltips")
                    text: i18n("Show tooltips on hover")
                }
            }

            // Add Desktop Button Section
            Kirigami.FormLayout {
                RowLayout {
                    Kirigami.FormData.label: i18n("Add Desktop Button")

                    PlasmaComponents3.CheckBox {
                        id: addDesktopButtonShow
                        enabled: !cfg_DynamicDesktopsEnable
                        text: i18n("Show add desktop button")
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "help-contextual"
                        visible: !addDesktopButtonShow.enabled
                        display: PlasmaComponents3.AbstractButton.IconOnly
                        PlasmaComponents3.ToolTip.text: i18n("Not available with dynamic desktops enabled")
                        PlasmaComponents3.ToolTip.visible: hovered
                    }
                }
            }

            // Desktop Buttons Section
            Kirigami.FormLayout {
                Layout.fillWidth: true

                PlasmaComponents3.SpinBox {
                    id: desktopButtonsVerticalMargin
                    Kirigami.FormData.label: i18n("Vertical margins:")
                    from: 0
                    to: 300
                    stepSize: 1
                    // suffix: " px"
                }

                PlasmaComponents3.SpinBox {
                    id: desktopButtonsHorizontalMargin
                    Kirigami.FormData.label: i18n("Horizontal margins:")
                    from: 0
                    to: 300
                    stepSize: 1
                    // suffix: " px"
                }

                PlasmaComponents3.SpinBox {
                    id: desktopButtonsSpacing
                    Kirigami.FormData.label: i18n("Button spacing:")
                    from: 0
                    to: 100
                    stepSize: 1
                    // suffix: " px"
                }

                PlasmaComponents3.CheckBox {
                    id: desktopButtonsSetCommonSize
                    Kirigami.FormData.label: i18n("Size:")
                    text: i18n("Use common size for all buttons")
                }

                PlasmaComponents3.CheckBox {
                    id: showOnlyCurrentDesktop
                    text: i18n("Show only current desktop")
                }

                PlasmaComponents3.CheckBox {
                    id: showOnlyOccupiedDesktops
                    text: i18n("Show only occupied desktops")
                }
            }

            // Desktop Labels Section
            Kirigami.FormLayout {
                Layout.fillWidth: true

                PlasmaComponents3.ComboBox {
                    id: labelsStyle
                    Kirigami.FormData.label: i18n("Label style:")
                    model: [
                        i18n("Name"),
                        i18n("Number"),
                        i18n("Number: Name"),
                        i18n("Active Window"),
                        i18n("Custom Format")
                    ]
                }

                UICommon.GrowingTextField {
                    id: customFormat
                    visible: labelsStyle.currentIndex === 4
                    Kirigami.FormData.label: visible ? i18n("Custom format:") : ""
                    placeholderText: "$X: $N"
                    text: cfg_DesktopLabelsStyleCustomFormat
                    onTextChanged: if (labelsStyle.currentIndex === 4) cfg_DesktopLabelsStyleCustomFormat = text
                }

                PlasmaComponents3.SpinBox {
                    id: maxLabelLength
                    Kirigami.FormData.label: i18n("Maximum length:")
                    from: 3
                    to: 100
                    stepSize: 1
                    // suffix: i18n(" chars")
                }

                FontDialog {
                    id: fontDialog
                    title: i18n("Choose Label Font")
                    onAccepted: {
                        cfg_DesktopLabelsCustomFont = selectedFont.family
                        cfg_DesktopLabelsCustomFontSize = selectedFont.pointSize
                    }
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Font:")
                    PlasmaComponents3.Button {
                        text: cfg_DesktopLabelsCustomFont || i18n("System Default")
                        onClicked: fontDialog.open()
                    }
                }

                ColorDialog {
                    id: labelColorDialog
                    title: i18n("Choose Label Color")
                    onAccepted: cfg_DesktopLabelsCustomColor = selectedColor
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Color:")
                    PlasmaComponents3.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        background: Rectangle {
                            color: cfg_DesktopLabelsCustomColor || Kirigami.Theme.textColor
                        }
                        onClicked: labelColorDialog.open()
                    }
                }

                PlasmaComponents3.CheckBox {
                    id: dimIdleDesktops
                    text: i18n("Dim labels for idle desktops")
                }

                PlasmaComponents3.CheckBox {
                    id: boldCurrentDesktop
                    text: i18n("Bold font for current desktop")
                }

                PlasmaComponents3.CheckBox {
                    id: uppercaseLabels
                    text: i18n("Display labels in uppercase")
                }
            }

            // Desktop Indicators Section
            Kirigami.FormLayout {
                Layout.fillWidth: true

                PlasmaComponents3.ComboBox {
                    id: indicatorsStyle
                    Kirigami.FormData.label: i18n("Indicator style:")
                    model: [
                        i18n("Edge Line"),
                        i18n("Side Line"),
                        i18n("Block"),
                        i18n("Rounded"),
                        i18n("Full Size"),
                        i18n("Use Labels")
                    ]
                }

                PlasmaComponents3.SpinBox {
                    id: blockRadius
                    visible: indicatorsStyle.currentIndex === 2
                    Kirigami.FormData.label: visible ? i18n("Corner radius:") : ""
                    from: 0
                    to: 300
                    stepSize: 1
                    // suffix: " px"
                }

                PlasmaComponents3.SpinBox {
                    id: lineThickness
                    visible: indicatorsStyle.currentIndex < 2
                    Kirigami.FormData.label: visible ? i18n("Line thickness:") : ""
                    from: 1
                    to: 10
                    stepSize: 1
                    // suffix: " px"
                }

                PlasmaComponents3.CheckBox {
                    id: invertPosition
                    enabled: indicatorsStyle.currentIndex < 2
                    text: i18n("Invert indicator position")
                }

                // Custom colors section for indicators
                ColorDialog {
                    id: idleColorDialog
                    title: i18n("Choose Color for Idle Desktops")
                    onAccepted: cfg_DesktopIndicatorsCustomColorForIdleDesktops = selectedColor
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Idle desktop color:")
                    PlasmaComponents3.Button {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        background: Rectangle {
                            color: cfg_DesktopIndicatorsCustomColorForIdleDesktops || Kirigami.Theme.textColor
                        }
                        onClicked: idleColorDialog.open()
                    }
                }

                // Add similar ColorDialog and button setups for other indicator colors...

                PlasmaComponents3.CheckBox {
                    id: preserveCustomColors
                    text: i18n("Preserve opacity of custom colors")
                }

                PlasmaComponents3.CheckBox {
                    id: distinctOccupied
                    text: i18n("Distinct indicators for occupied desktops")
                }

                PlasmaComponents3.CheckBox {
                    id: distinctAttention
                    text: i18n("Distinct indicators for desktops needing attention")
                }
            }
        }
    }
}
