import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "../common" as UICommon

KCM.SimpleKCM {
    id: root

    // Behavior - Dynamic desktops
    property bool cfg_DynamicDesktopsEnable

    // Animations
    property bool cfg_AnimationsEnable: animationsEnableCheckBox.checked

    // Tooltips
    property bool cfg_TooltipsEnable: tooltipsEnableCheckBox.checked

    // Add desktop button
    property bool cfg_AddDesktopButtonShow: addDesktopButtonShowCheckBox.checked

    // Desktop buttons
    property int cfg_DesktopButtonsVerticalMargin: desktopButtonsVerticalMarginSpinBox.value
    property int cfg_DesktopButtonsHorizontalMargin: desktopButtonsHorizontalMarginSpinBox.value
    property int cfg_DesktopButtonsSpacing: desktopButtonsSpacingSpinBox.value
    property bool cfg_DesktopButtonsSetCommonSizeForAll: desktopButtonsSetCommonSizeForAllCheckBox.checked
    property bool cfg_DesktopButtonsShowOnlyForCurrentDesktop: desktopButtonsShowOnlyForCurrentDesktopCheckBox.checked
    property bool cfg_DesktopButtonsShowOnlyForOccupiedDesktops: desktopButtonsShowOnlyForOccupiedDesktopsCheckBox.checked

    // Desktop labels
    property int cfg_DesktopLabelsStyle: desktopLabelsStyleComboBox.currentIndex
    property string cfg_DesktopLabelsStyleCustomFormat
    property string cfg_DesktopLabelsCustomFont
    property int cfg_DesktopLabelsCustomFontSize
    property string cfg_DesktopLabelsCustomColor
    property bool cfg_DesktopLabelsDimForIdleDesktops: desktopLabelsDimForIdleDesktopsCheckBox.checked
    property bool cfg_DesktopLabelsBoldFontForCurrentDesktop: desktopLabelsBoldFontForCurrentDesktopCheckBox.checked
    property int cfg_DesktopLabelsMaximumLength: desktopLabelsMaximumLengthSpinBox.value
    property bool cfg_DesktopLabelsDisplayAsUppercased: desktopLabelsDisplayAsUppercasedCheckBox.checked

    // Desktop indicators
    property int cfg_DesktopIndicatorsStyle: desktopIndicatorsStyleComboBox.currentIndex
    property int cfg_DesktopIndicatorsStyleBlockRadius: desktopIndicatorsStyleBlockRadiusSpinBox.value
    property int cfg_DesktopIndicatorsStyleLineThickness: desktopIndicatorsStyleLineThicknessSpinBox.value
    property bool cfg_DesktopIndicatorsInvertPosition: desktopIndicatorsInvertPositionCheckBox.checked
    property string cfg_DesktopIndicatorsCustomColorForIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForCurrentDesktop
    property string cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops
    property string cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention
    property bool cfg_DesktopIndicatorsDoNotOverrideOpacityOfCustomColors: desktopIndicatorsDoNotOverrideOpacityOfCustomColorsCheckBox.checked
    property bool cfg_DesktopIndicatorsDistinctForOccupiedIdleDesktops: desktopIndicatorsDistinctForOccupiedIdleDesktopsCheckBox.checked
    property bool cfg_DesktopIndicatorsDistinctForDesktopsNeedingAttention: desktopIndicatorsDistinctForDesktopsNeedingAttentionCheckBox.checked

    Kirigami.FormLayout {
        SectionHeader {
            text: "Animations"
        }

        CheckBox {
            id: animationsEnableCheckBox
            text: "Enable animations"
        }

        SectionHeader {
            text: "Tooltips"
        }

        CheckBox {
            id: tooltipsEnableCheckBox
            text: "Enable hover tooltips"
        }

        SectionHeader {
            text: "Add desktop button"
        }

        RowLayout {
            spacing: 0

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

        SectionHeader {
            text: "Desktop buttons"
        }

        RowLayout {
            Label {
                text: "Vertical margins:"
            }

            SpinBox {
                id: desktopButtonsVerticalMarginSpinBox

                enabled: plasmoid.formFactor == PlasmaCore.Types.Vertical ||
                         (cfg_DesktopIndicatorsStyle != 0 &&
                          cfg_DesktopIndicatorsStyle != 4 &&
                          cfg_DesktopIndicatorsStyle != 5)

                value: cfg_DesktopButtonsVerticalMargin
                from: 0
                to: 300
                // #FIX Gone in QT6
                // suffix: " px"
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

            SpinBox {
                id: desktopButtonsHorizontalMarginSpinBox

                enabled: plasmoid.formFactor != PlasmaCore.Types.Vertical ||
                         (cfg_DesktopIndicatorsStyle != 1 &&
                          cfg_DesktopIndicatorsStyle != 4 &&
                          cfg_DesktopIndicatorsStyle != 5)

                value: cfg_DesktopButtonsHorizontalMargin
                from: 0
                to: 300
                // suffix: " px"
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

            SpinBox {
                id: desktopButtonsSpacingSpinBox
                enabled: !cfg_DesktopButtonsShowOnlyForCurrentDesktop ||
                         cfg_DesktopButtonsShowOnlyForOccupiedDesktops
                value: cfg_DesktopButtonsSpacing
                from: 0
                to: 100
                // suffix: " px"
            }

            HintIcon {
                visible: !desktopButtonsSpacingSpinBox.enabled
                tooltipText: "Not available if only one button is shown"
            }
        }

        RowLayout {
            spacing: 0

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

        SectionHeader {
            text: "Desktop labels"
        }

        RowLayout {
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

            SpinBox {
                id: desktopLabelsMaximumLengthSpinBox
                enabled: cfg_DesktopLabelsStyle != 1
                from: 3
                to: 100
                // suffix: " chars"
            }

            HintIcon {
                tooltipText: cfg_DesktopLabelsStyle == 1 ?
                             "Not available for the selected label style" :
                             "Labels longer than the specified value will be ellipsized"
            }
        }

        RowLayout {
            spacing: 0

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
                        foundIndex = find(Kirigami.Theme.defaultFont.family);
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
            spacing: 0

            CheckBox {
                id: desktopLabelsCustomFontSizeCheckBox
                checked: cfg_DesktopLabelsCustomFontSize > 0
                onCheckedChanged: cfg_DesktopLabelsCustomFontSize = checked ?
                                  desktopLabelsCustomFontSizeSpinBox.value : 0
                text: "Custom font size:"
            }

            SpinBox {
                id: desktopLabelsCustomFontSizeSpinBox
                enabled: desktopLabelsCustomFontSizeCheckBox.checked
                value: cfg_DesktopLabelsCustomFontSize || Kirigami.Theme.defaultFont.pixelSize
                from: 5
                to: 100
                // suffix: " px"
                onValueChanged: {
                    if (desktopLabelsCustomFontSizeCheckBox.checked) {
                        cfg_DesktopLabelsCustomFontSize = value;
                    }
                }
            }
        }

        RowLayout {
            spacing: 0

            CheckBox {
                id: desktopLabelsCustomColorCheckBox
                enabled: cfg_DesktopIndicatorsStyle != 5
                checked: cfg_DesktopLabelsCustomColor
                onCheckedChanged: cfg_DesktopLabelsCustomColor = checked ?
                                  desktopLabelsCustomColorButton.color : ""
                text: "Custom text color:"
            }

            ColorButton {
                id: desktopLabelsCustomColorButton
                enabled: desktopLabelsCustomColorCheckBox.enabled &&
                         desktopLabelsCustomColorCheckBox.checked
                color: cfg_DesktopLabelsCustomColor || Kirigami.Theme.textColor

                colorAcceptedCallback: function(color) {
                    cfg_DesktopLabelsCustomColor = color;
                }
            }

            Item {
                width: 8
            }

            HintIcon {
                visible: desktopLabelsCustomColorCheckBox.checked ||
                         !desktopLabelsCustomColorCheckBox.enabled
                tooltipText: cfg_DesktopIndicatorsStyle != 5 ?
                             "Click the colored box to choose a different color" :
                             "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            spacing: 0

            CheckBox {
                id: desktopLabelsDimForIdleDesktopsCheckBox
                enabled: cfg_DesktopIndicatorsStyle != 5
                text: "Dim labels for idle desktops"
            }

            HintIcon {
                visible: !desktopLabelsDimForIdleDesktopsCheckBox.enabled
                tooltipText: "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            spacing: 0

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

        SectionHeader {
            text: "Desktop indicators"
        }

        RowLayout {
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
                    if (cfg_DesktopIndicatorsStyle == 2) {
                        cfg_DesktopIndicatorsStyleBlockRadius = desktopIndicatorsStyleBlockRadiusSpinBox.value;
                    } else {
                        cfg_DesktopIndicatorsStyleBlockRadius = 2;
                    }
                    if (cfg_DesktopIndicatorsStyle < 2) {
                        cfg_DesktopIndicatorsStyleLineThickness = desktopIndicatorsStyleLineThicknessSpinBox.value;
                    } else {
                        cfg_DesktopIndicatorsStyleLineThickness = 3;
                    }

                }

                Component.onCompleted: {
                    if (cfg_DesktopIndicatorsStyle != 2) {
                        cfg_DesktopIndicatorsStyleBlockRadius = 2;
                    }
                }
            }

            SpinBox {
                id: desktopIndicatorsStyleBlockRadiusSpinBox
                visible: cfg_DesktopIndicatorsStyle == 2
                value: cfg_DesktopIndicatorsStyleBlockRadius
                from: 0
                to: 300
                // suffix: " px corner radius"
            }

            SpinBox {
                id: desktopIndicatorsStyleLineThicknessSpinBox
                visible: cfg_DesktopIndicatorsStyle < 2
                value: cfg_DesktopIndicatorsStyleLineThickness
                from: 1
                to: 10
                // suffix: " px thickness"
            }
        }

        RowLayout {
            spacing: 0

            CheckBox {
                id: desktopIndicatorsInvertPositionCheckBox
                enabled: cfg_DesktopIndicatorsStyle < 2
                text: "Invert indicator's position"
            }

            HintIcon {
                visible: !desktopIndicatorsInvertPositionCheckBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            spacing: 0

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
                color: cfg_DesktopIndicatorsCustomColorForIdleDesktops || Kirigami.Theme.textColor

                colorAcceptedCallback: function(color) {
                    cfg_DesktopIndicatorsCustomColorForIdleDesktops = color;
                }
            }
        }

        RowLayout {
            spacing: 0

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
                color: cfg_DesktopIndicatorsCustomColorForCurrentDesktop || Kirigami.Theme.buttonFocusColor

                colorAcceptedCallback: function(color) {
                    cfg_DesktopIndicatorsCustomColorForCurrentDesktop = color;
                }
            }
        }

        RowLayout {
            spacing: 0

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
                color: cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops || Kirigami.Theme.textColor

                colorAcceptedCallback: function(color) {
                    cfg_DesktopIndicatorsCustomColorForOccupiedIdleDesktops = color;
                }
            }
        }

        RowLayout {
            spacing: 0

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
                color: cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention || Kirigami.Theme.textColor

                colorAcceptedCallback: function(color) {
                    cfg_DesktopIndicatorsCustomColorForDesktopsNeedingAttention = color;
                }
            }
        }

        RowLayout {
            spacing: 0

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
            spacing: 0

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
            spacing: 0

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
    }
}
