import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kquickcontrols as KQControls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../common" as UICommon
import "../common/IndicatorStyles.js" as IndicatorStyles
import "."

pragma ComponentBehavior: Bound

KCM.SimpleKCM {
    id: root
    // Behavior - Dynamic desktops
    property bool cfg_DynamicDesktopsEnable

    // Animations
    property alias cfg_AnimationsEnable: animationsEnableCheckBox.checked

    // Tooltips
    property alias cfg_TooltipsEnable: tooltipsEnableCheckBox.checked

    // Add desktop button
    property alias cfg_AddDesktopButtonShow: addDesktopButtonShowCheckBox.checked

    // Desktop buttons
    property alias cfg_DesktopButtonsVerticalMargin: desktopButtonsVerticalMarginSpinBox.value
    property alias cfg_DesktopButtonsHorizontalMargin: desktopButtonsHorizontalMarginSpinBox.value
    property alias cfg_DesktopButtonsSpacing: desktopButtonsSpacingSpinBox.value
    property alias cfg_DesktopButtonsSetCommonSizeForAll: desktopButtonsSetCommonSizeForAllCheckBox.checked
    property alias cfg_DesktopButtonsShowOnlyForCurrentDesktop: desktopButtonsShowOnlyForCurrentDesktopCheckBox.checked
    property alias cfg_DesktopButtonsShowOnlyForOccupiedDesktops: desktopButtonsShowOnlyForOccupiedDesktopsCheckBox.checked

    // Desktop labels
    property alias cfg_DesktopLabelsStyle: desktopLabelsStyleComboBox.currentIndex
    property string cfg_DesktopLabelsStyleCustomFormat
    property string cfg_DesktopLabelsCustomFont
    property int cfg_DesktopLabelsCustomFontSize
    property string cfg_DesktopLabelsCustomColor
    property alias cfg_DesktopLabelsDimForIdleDesktops: desktopLabelsDimForIdleDesktopsCheckBox.checked
    property alias cfg_DesktopLabelsBoldFontForCurrentDesktop: desktopLabelsBoldFontForCurrentDesktopCheckBox.checked
    property alias cfg_DesktopLabelsMaximumLength: desktopLabelsMaximumLengthSpinBox.value
    property alias cfg_DesktopLabelsDisplayAsUppercased: desktopLabelsDisplayAsUppercasedCheckBox.checked

    // Desktop indicators
    property alias cfg_DesktopIndicatorsStyle: desktopIndicatorsStyleComboBox.currentIndex
    property alias cfg_DesktopIndicatorsStyleBlockRadius: desktopIndicatorsStyleBlockRadiusSpinBox.value
    property alias cfg_DesktopIndicatorsStyleLineThickness: desktopIndicatorsStyleLineThicknessSpinBox.value
    property alias cfg_DesktopIndicatorsInvertPosition: desktopIndicatorsInvertPositionCheckBox.checked
    property string cfg_DesktopIndicatorsCustomColorForIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForCurrentDesktop
    property string cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention
    property alias cfg_DesktopIndicatorsDoNotOverrideOpacityOfCustomColors: desktopIndicatorsDoNotOverrideOpacityOfCustomColorsCheckBox.checked
    property alias cfg_DesktopIndicatorsDistinctForOccupiedIdleDesktops: desktopIndicatorsDistinctForOccupiedIdleDesktopsCheckBox.checked
    property alias cfg_DesktopIndicatorsDistinctForDesktopsNeedingAttention: desktopIndicatorsDistinctForDesktopsNeedingAttentionCheckBox.checked

    Kirigami.FormLayout {
        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: "Animations:"

            CheckBox {
                id: animationsEnableCheckBox
                text: "Enable animations"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Tooltips:"

            CheckBox {
                id: tooltipsEnableCheckBox
                text: "Enable hover tooltips"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Add Desktop Button:"
            CheckBox {
                id: addDesktopButtonShowCheckBox
                enabled: !cfg_DynamicDesktopsEnable
                text: "Show button for adding desktops"
            }

            HintIcon {
                visible: !addDesktopButtonShowCheckBox.enabled
                tooltipText: "Not available if dynamic desktops are enabled"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Desktop Buttons:"
            Label {
                text: "Vertical margins:"
            }

            PXSpinBox {
                id: desktopButtonsVerticalMarginSpinBox
                value: cfg_DesktopButtonsVerticalMargin

                editable: plasmoid.formFactor == PlasmaCore.Types.Vertical ||
                    (cfg_DesktopIndicatorsStyle != IndicatorStyles.EdgeLine &&
                        cfg_DesktopIndicatorsStyle != IndicatorStyles.FullSize &&
                        cfg_DesktopIndicatorsStyle != IndicatorStyles.UseLabels)

                from: 0
                to: 300
                suffix: " px"
            }

            HintIcon {
                visible: !desktopButtonsVerticalMarginSpinBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            Label {
                text: "Horizontal margins:"
            }

            PXSpinBox {
                id: desktopButtonsHorizontalMarginSpinBox
                value: cfg_DesktopButtonsHorizontalMargin

                editable: plasmoid.formFactor != PlasmaCore.Types.Vertical ||
                    (cfg_DesktopIndicatorsStyle != IndicatorStyles.SideLine &&
                        cfg_DesktopIndicatorsStyle != IndicatorStyles.FullSize &&
                        cfg_DesktopIndicatorsStyle != IndicatorStyles.UseLabels)

                from: 0
                to: 300
                suffix: " px"
            }

            HintIcon {
                visible: !desktopButtonsHorizontalMarginSpinBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            Label {
                enabled: desktopButtonsSpacingSpinBox.enabled
                text: "Spacing between buttons:"
            }

            PXSpinBox {
                id: desktopButtonsSpacingSpinBox
                value: cfg_DesktopButtonsSpacing

                editable: !cfg_DesktopButtonsShowOnlyForCurrentDesktop ||
                    cfg_DesktopButtonsShowOnlyForOccupiedDesktops

                from: 0
                to: 100
                suffix: " px"
            }

            HintIcon {
                visible: !desktopButtonsSpacingSpinBox.enabled
                tooltipText: "Not available if only one button is shown"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopButtonsSetCommonSizeForAllCheckBox
                text: "Set common size for all buttons"
            }

            HintIcon {
                tooltipText: "The size is based on the largest button"
            }
        }

        CheckBox {
            id: desktopButtonsShowOnlyForCurrentDesktopCheckBox
            text: "Show button only for current desktop"
        }

        CheckBox {
            id: desktopButtonsShowOnlyForOccupiedDesktopsCheckBox
            text: "Show button only for occupied desktops"
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Desktop Labels:"
            Label {
                text: "Style:"
            }

            ComboBox {
                id: desktopLabelsStyleComboBox
                implicitWidth: 150
                model: [
                    "Name",
                    "Number",
                    "Number: name",
                    "Active window's name",
                    "Custom format"
                ]
                onCurrentIndexChanged: {
                    if (cfg_DesktopLabelsStyle == 4) {
                        cfg_DesktopLabelsStyleCustomFormat = desktopLabelsStyleTextField.text;
                    } else {
                        cfg_DesktopLabelsStyleCustomFormat = "";
                    }
                }

                Component.onCompleted: {
                    if (cfg_DesktopLabelsStyle != 4 &&
                        cfg_DesktopLabelsStyleCustomFormat) {
                        cfg_DesktopLabelsStyleCustomFormat = "";
                    }
                }
            }

            UICommon.GrowingTextField {
                id: desktopLabelsStyleTextField
                visible: cfg_DesktopLabelsStyle == 4
                maximumLength: 50
                text: cfg_DesktopLabelsStyleCustomFormat || "$X: $N"
                onTextChanged: {
                    if (cfg_DesktopLabelsStyle == 4 && text) {
                        cfg_DesktopLabelsStyleCustomFormat = text;
                    }
                }
                onEditingFinished: cfg_DesktopLabelsStyleCustomFormat = text
            }

            HintIcon {
                visible: desktopLabelsStyleTextField.visible
                tooltipText: "Available variables:<br><br>
                          <tt>$X</tt> = desktop's number<br>
                          <tt>$R</tt> = desktop's number (Roman)<br>
                          <tt>$N</tt> = desktop's name<br>
                          <tt>$W</tt> = active window's name<br>
                          <tt>$WX</tt> = <tt>$W</tt>, or <tt>$X</tt> if there are no windows<br>
                          <tt>$WR</tt> = <tt>$W</tt>, or <tt>$R</tt> if there are no windows<br>
                          <tt>$WN</tt> = <tt>$W</tt>, or <tt>$N</tt> if there are no windows"
            }
        }

        RowLayout {
            Label {
                enabled: desktopLabelsMaximumLengthSpinBox.enabled
                text: "Maximum length:"
            }

            PXSpinBox {
                id: desktopLabelsMaximumLengthSpinBox
                editable: cfg_DesktopLabelsStyle != 1
                from: 3
                to: 100
                suffix: " chars"
            }

            HintIcon {
                tooltipText: cfg_DesktopLabelsStyle == 1 ?
                    "Not available for the selected label style" :
                    "Labels longer than the specified value will be ellipsized"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopLabelsCustomFontCheckBox
                checked: cfg_DesktopLabelsCustomFont
                onCheckedChanged: {
                    if (checked) {
                        var currentIndex = desktopLabelsCustomFontComboBox.currentIndex;
                        var selectedFont = desktopLabelsCustomFontComboBox.model[currentIndex].value;
                        cfg_DesktopLabelsCustomFont = selectedFont;
                    } else {
                        cfg_DesktopLabelsCustomFont = "";
                    }
                }
                text: "Custom font:"
            }

            ComboBox {
                id: desktopLabelsCustomFontComboBox
                enabled: desktopLabelsCustomFontCheckBox.checked
                implicitWidth: 130

                Component.onCompleted: {
                    var array = [];
                    var fonts = Qt.fontFamilies()
                    for (var i = 0; i < fonts.length; i++) {
                        array.push({text: fonts[i], value: fonts[i]});
                    }
                    model = array;

                    var foundIndex = find(cfg_DesktopLabelsCustomFont);
                    if (foundIndex == -1) {
                        foundIndex = find(PlasmaCore.Theme.defaultFont.family);
                    }
                    if (foundIndex >= 0) {
                        currentIndex = foundIndex;
                    }
                }

                onCurrentIndexChanged: {
                    if (enabled && currentIndex) {
                        var selectedItem = model[currentIndex];
                        if (selectedItem) {
                            var selectedFont = selectedItem.value;
                            cfg_DesktopLabelsCustomFont = selectedFont;
                        }
                    }
                }
            }
        }

        RowLayout {
            CheckBox {
                id: desktopLabelsCustomFontSizeCheckBox
                checked: cfg_DesktopLabelsCustomFontSize > 0
                onCheckedChanged: cfg_DesktopLabelsCustomFontSize = checked ?
                    desktopLabelsCustomFontSizeSpinBox.value : 0
                text: "Custom font size:"
            }

            PXSpinBox {
                id: desktopLabelsCustomFontSizeSpinBox
                value: cfg_DesktopLabelsCustomFontSize || PlasmaCore.Theme.defaultFont.pixelSize

                editable: desktopLabelsCustomFontSizeCheckBox.checked
                from: 5
                to: 100
                suffix: " px"
                onValueChanged: {
                    if (desktopLabelsCustomFontSizeCheckBox.checked) {
                        cfg_DesktopLabelsCustomFontSize = value;
                    }
                }
            }
        }

        RowLayout {
            CheckBox {
                id: desktopLabelsCustomColorCheckBox
                enabled: cfg_DesktopIndicatorsStyle != IndicatorStyles.UseLabels
                checked: cfg_DesktopLabelsCustomColor
                onCheckedChanged: cfg_DesktopLabelsCustomColor = checked ?
                    desktopLabelsCustomColorButton.color : ""
                text: "Custom text color:"
            }

            ColorButton {
                id: desktopLabelsCustomColorButton
                enabled: desktopLabelsCustomColorCheckBox.enabled &&
                    desktopLabelsCustomColorCheckBox.checked
                color: cfg_DesktopLabelsCustomColor || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_DesktopLabelsCustomColor = color;
                }
            }

            Item {
                width: 8
            }

            HintIcon {
                visible: desktopLabelsCustomColorCheckBox.checked ||
                    !desktopLabelsCustomColorCheckBox.enabled
                tooltipText: cfg_DesktopIndicatorsStyle != IndicatorStyles.UseLabels ?
                    "Click the colored box to choose a different color" :
                    "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopLabelsDimForIdleDesktopsCheckBox
                enabled: cfg_DesktopIndicatorsStyle != IndicatorStyles.UseLabels
                text: "Dim labels for idle desktops"
            }

            HintIcon {
                visible: !desktopLabelsDimForIdleDesktopsCheckBox.enabled
                tooltipText: "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopLabelsDisplayAsUppercasedCheckBox
                enabled: cfg_DesktopLabelsStyle != 1
                text: "Display labels as UPPERCASED"
            }

            HintIcon {
                visible: !desktopLabelsDisplayAsUppercasedCheckBox.enabled
                tooltipText: "Not available for the selected label style"
            }
        }

        CheckBox {
            id: desktopLabelsBoldFontForCurrentDesktopCheckBox
            text: "Set bold font for current desktop"
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Desktop Indicators:"
            Label {
                text: "Style:"
            }

            ComboBox {
                id: desktopIndicatorsStyleComboBox
                implicitWidth: 100
                model: [
                    "Edge line",
                    "Side line",
                    "Block",
                    "Rounded",
                    "Full size",
                    "Use labels"
                ]

                onCurrentIndexChanged: {
                    if (cfg_DesktopIndicatorsStyle == IndicatorStyles.Block) {
                        cfg_DesktopIndicatorsStyleBlockRadius = desktopIndicatorsStyleBlockRadiusSpinBox.value;
                    } else {
                        cfg_DesktopIndicatorsStyleBlockRadius = 2;
                    }
                    if (cfg_DesktopIndicatorsStyle < IndicatorStyles.Block) {
                        cfg_DesktopIndicatorsStyleLineThickness = desktopIndicatorsStyleLineThicknessSpinBox.value;
                    } else {
                        cfg_DesktopIndicatorsStyleLineThickness = 3;
                    }

                }

                Component.onCompleted: {
                    if (cfg_DesktopIndicatorsStyle != IndicatorStyles.Block) {
                        cfg_DesktopIndicatorsStyleBlockRadius = 2;
                    }
                }
            }

            PXSpinBox {
                id: desktopIndicatorsStyleBlockRadiusSpinBox
                value: cfg_DesktopIndicatorsStyleBlockRadius
                visible: cfg_DesktopIndicatorsStyle == IndicatorStyles.Block
                from: 0
                to: 300
                suffix: " px corner radius"
            }

            PXSpinBox {
                id: desktopIndicatorsStyleLineThicknessSpinBox
                value: cfg_DesktopIndicatorsStyleLineThickness
                visible: cfg_DesktopIndicatorsStyle < IndicatorStyles.Block
                from: 1
                to: 10
                suffix: " px thickness"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsInvertPositionCheckBox
                enabled: cfg_DesktopIndicatorsStyle < IndicatorStyles.Block
                text: "Invert indicator's position"
            }

            HintIcon {
                visible: !desktopIndicatorsInvertPositionCheckBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsDoNotOverrideOpacityOfCustomColorsCheckBox
                enabled: desktopIndicatorsCustomColorForCurrentDesktopCheckBox.checked ||
                    desktopIndicatorsCustomColorForIdleDesktopsCheckBox.checked ||
                    desktopIndicatorsCustomColorForOccupiedIdleDesktopsCheckBox.checked ||
                    desktopIndicatorsCustomColorForDesktopsNeedingAttentionCheckBox.checked
                text: "Do not override opacity of custom colors"
            }

            HintIcon {
                tooltipText: !desktopIndicatorsDoNotOverrideOpacityOfCustomColorsCheckBox.enabled ?
                    "Not available if custom colors are not used" :
                    "Alpha channel of custom colors will be applied without any modifications"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsDistinctForOccupiedIdleDesktopsCheckBox
                enabled: !cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops ||
                    !cfg_DesktopIndicatorsDoNotOverrideOpacityOfCustomColors
                text: "Distinct indicators for occupied idle desktops"
            }

            HintIcon {
                visible: !desktopIndicatorsDistinctForOccupiedIdleDesktopsCheckBox.enabled
                tooltipText: "Not available if a custom color is used and overriding opacity of custom colors is blocked"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsDistinctForDesktopsNeedingAttentionCheckBox
                enabled: !cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention ||
                    !cfg_DesktopIndicatorsDoNotOverrideOpacityOfCustomColors
                text: "Distinct indicators for desktops needing attention"
            }

            HintIcon {
                visible: !desktopIndicatorsDistinctForDesktopsNeedingAttentionCheckBox.enabled
                tooltipText: "Not available if a custom color is used and overriding opacity of custom colors is blocked"
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsCustomColorForIdleDesktopsCheckBox
                checked: cfg_DesktopIndicatorsCustomColorForIdleDesktops
                onCheckedChanged: cfg_DesktopIndicatorsCustomColorForIdleDesktops = checked ?
                    desktopIndicatorsCustomColorForIdleDesktopsButton.color : ""
                text: "Custom color for idle desktops:"
            }

            ColorButton {
                id: desktopIndicatorsCustomColorForIdleDesktopsButton
                enabled: desktopIndicatorsCustomColorForIdleDesktopsCheckBox.checked
                color: cfg_DesktopIndicatorsCustomColorForIdleDesktops || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_DesktopIndicatorsCustomColorForIdleDesktops = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsCustomColorForCurrentDesktopCheckBox
                checked: cfg_DesktopIndicatorsCustomColorForCurrentDesktop
                onCheckedChanged: cfg_DesktopIndicatorsCustomColorForCurrentDesktop = checked ?
                    desktopIndicatorsCustomColorForCurrentDesktopButton.color : ""
                text: "Custom color for current desktop:"
            }

            ColorButton {
                id: desktopIndicatorsCustomColorForCurrentDesktopButton
                enabled: desktopIndicatorsCustomColorForCurrentDesktopCheckBox.checked
                color: cfg_DesktopIndicatorsCustomColorForCurrentDesktop || PlasmaCore.Theme.buttonFocusColor

                colorAcceptedCallback: function (color) {
                    cfg_DesktopIndicatorsCustomColorForCurrentDesktop = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsCustomColorForOccupiedIdleDesktopsCheckBox
                checked: cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops
                onCheckedChanged: cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops = checked ?
                    desktopIndicatorsCustomColorForOccupiedIdleDesktopsButton.color : ""
                text: "Custom color for occupied idle desktops:"
            }

            ColorButton {
                id: desktopIndicatorsCustomColorForOccupiedIdleDesktopsButton
                enabled: desktopIndicatorsCustomColorForOccupiedIdleDesktopsCheckBox.checked
                color: cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: desktopIndicatorsCustomColorForDesktopsNeedingAttentionCheckBox
                checked: cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention
                onCheckedChanged: cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention = checked ?
                    desktopIndicatorsCustomColorForDesktopsNeedingAttentionButton.color : ""
                text: "Custom color for desktops needing attention:"
            }

            ColorButton {
                id: desktopIndicatorsCustomColorForDesktopsNeedingAttentionButton
                enabled: desktopIndicatorsCustomColorForDesktopsNeedingAttentionCheckBox.checked
                color: cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention = color;
                }
            }
        }
    }
}
