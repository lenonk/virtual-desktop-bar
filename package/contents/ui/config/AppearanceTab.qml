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
    property bool cfg_DynamicDesktops

    // Animations
    property alias cfg_AnimationsEnable: animationsCheckBox.checked

    // Tooltips
    property alias cfg_TooltipsEnable: tooltipsCheckBox.checked

    // Add desktop button
    property alias cfg_ShowAddButton: showAddButtonCheckBox.checked

    // Desktop buttons
    property alias cfg_ButtonMarginVertical: buttonMarginVerticalSpinBox.value
    property alias cfg_ButtonMarginHorizontal: buttonMarginHorizontalSpinBox.value
    property alias cfg_ButtonSpacing: buttonSpacingSpinBox.value
    property alias cfg_ButtonCommonSize: buttonCommonSizeCheckBox.checked
    property alias cfg_ShowOnlyCurrent: showOnlyCurrentCheckBox.checked
    property alias cfg_ShowOnlyOccupied: showOnlyOccupiedCheckBox.checked

    // Desktop labels
    property alias cfg_LabelStyle: labelStyleComboBox.currentIndex
    property string cfg_LabelCustomFormat
    property string cfg_LabelFont
    property int cfg_LabelFontSize
    property string cfg_LabelColor
    property alias cfg_LabelDimIdle: labelDimIdleCheckBox.checked
    property alias cfg_LabelBoldCurrent: labelBoldCurrentCheckBox.checked
    property alias cfg_LabelMaxLength: labelMaxLengthSpinBox.value
    property alias cfg_LabelUppercase: labelUppercaseCheckBox.checked

    // Desktop indicators
    property alias cfg_IndicatorStyle: indicatorStyleComboBox.currentIndex
    property alias cfg_IndicatorBlockRadius: indicatorBlockRadiusSpinBox.value
    property alias cfg_IndicatorLineThickness: indicatorLineThicknessSpinBox.value
    property alias cfg_IndicatorInvert: indicatorInvertCheckBox.checked
    property string cfg_IndicatorColorIdle
    property string cfg_IndicatorColorCurrent
    property string cfg_IndicatorColorOccupied
    property string cfg_IndicatorColorAttention
    property alias cfg_IndicatorKeepOpacity: indicatorKeepOpacityCheckBox.checked
    property alias cfg_IndicatorDistinctOccupied: indicatorDistinctOccupiedCheckBox.checked
    property alias cfg_IndicatorDistinctAttention: indicatorDistinctAttentionCheckBox.checked

    Kirigami.FormLayout {
        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: "Animations:"

            CheckBox {
                id: animationsCheckBox
                text: "Enable animations"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Tooltips:"

            CheckBox {
                id: tooltipsCheckBox
                text: "Enable hover tooltips"
            }
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Add Desktop Button:"
            CheckBox {
                id: showAddButtonCheckBox
                enabled: !cfg_DynamicDesktops
                text: "Show button for adding desktops"
            }

            HintIcon {
                visible: !showAddButtonCheckBox.enabled
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
                id: buttonMarginVerticalSpinBox
                value: cfg_ButtonMarginVertical

                editable:false
                enabled: plasmoid.formFactor == PlasmaCore.Types.Vertical ||
                    (cfg_IndicatorStyle != IndicatorStyles.EdgeLine &&
                        cfg_IndicatorStyle != IndicatorStyles.FullSize &&
                        cfg_IndicatorStyle != IndicatorStyles.UseLabels)

                from: 0
                to: 300
                suffix: " px"
            }

            HintIcon {
                visible: !buttonMarginVerticalSpinBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            Label {
                text: "Horizontal margins:"
            }

            PXSpinBox {
                id: buttonMarginHorizontalSpinBox
                value: cfg_ButtonMarginHorizontal

                editable:false
                enabled: plasmoid.formFactor != PlasmaCore.Types.Vertical ||
                    (cfg_IndicatorStyle != IndicatorStyles.SideLine &&
                        cfg_IndicatorStyle != IndicatorStyles.FullSize &&
                        cfg_IndicatorStyle != IndicatorStyles.UseLabels)

                from: 0
                to: 300
                suffix: " px"
            }

            HintIcon {
                visible: !buttonMarginHorizontalSpinBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            Label {
                enabled: buttonSpacingSpinBox.enabled
                text: "Spacing between buttons:"
            }

            PXSpinBox {
                id: buttonSpacingSpinBox
                value: cfg_ButtonSpacing

                editable: !cfg_ShowOnlyCurrent ||
                    cfg_ShowOnlyOccupied

                from: 0
                to: 100
                suffix: " px"
            }

            HintIcon {
                visible: !buttonSpacingSpinBox.enabled
                tooltipText: "Not available if only one button is shown"
            }
        }

        RowLayout {
            CheckBox {
                id: buttonCommonSizeCheckBox
                text: "Set common size for all buttons"
            }

            HintIcon {
                tooltipText: "The size is based on the largest button"
            }
        }

        CheckBox {
            id: showOnlyCurrentCheckBox
            text: "Show button only for current desktop"
        }

        CheckBox {
            id: showOnlyOccupiedCheckBox
            text: "Show button only for occupied desktops"
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Desktop Labels:"
            Label {
                text: "Style:"
            }

            ComboBox {
                id: labelStyleComboBox
                implicitWidth: 150
                model: [
                    "Name",
                    "Number",
                    "Number: name",
                    "Active window's name",
                    "Custom format"
                ]
                onCurrentIndexChanged: {
                    if (cfg_LabelStyle == 4) {
                        cfg_LabelCustomFormat = labelStyleTextField.text;
                    } else {
                        cfg_LabelCustomFormat = "";
                    }
                }

                Component.onCompleted: {
                    if (cfg_LabelStyle != 4 &&
                        cfg_LabelCustomFormat) {
                        cfg_LabelCustomFormat = "";
                    }
                }
            }

            UICommon.GrowingTextField {
                id: labelStyleTextField
                visible: cfg_LabelStyle == 4
                maximumLength: 50
                text: cfg_LabelCustomFormat || "$X: $N"
                onTextChanged: {
                    if (cfg_LabelStyle == 4 && text) {
                        cfg_LabelCustomFormat = text;
                    }
                }
                onEditingFinished: cfg_LabelCustomFormat = text
            }

            HintIcon {
                visible: labelStyleTextField.visible
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
                enabled: labelMaxLengthSpinBox.enabled
                text: "Maximum length:"
            }

            PXSpinBox {
                id: labelMaxLengthSpinBox
                editable: cfg_LabelStyle != 1
                from: 3
                to: 100
                suffix: " chars"
            }

            HintIcon {
                tooltipText: cfg_LabelStyle == 1 ?
                    "Not available for the selected label style" :
                    "Labels longer than the specified value will be ellipsized"
            }
        }

        RowLayout {
            CheckBox {
                id: labelCustomFontCheckBox
                checked: cfg_LabelFont
                onCheckedChanged: {
                    if (checked) {
                        var currentIndex = labelCustomFontComboBox.currentIndex;
                        var selectedFont = labelCustomFontComboBox.model[currentIndex].value;
                        cfg_LabelFont = selectedFont;
                    } else {
                        cfg_LabelFont = "";
                    }
                }
                text: "Custom font:"
            }

            ComboBox {
                id: labelCustomFontComboBox
                enabled: labelCustomFontCheckBox.checked
                implicitWidth: 130

                textRole: "text"
                valueRole: "value"
                popup.width: 300

                property bool _initDone: false

                Component.onCompleted: {
                    var array = [];
                    var fonts = Qt.fontFamilies()
                    for (var i = 0; i < fonts.length; i++) {
                        array.push({text: fonts[i], value: fonts[i]});
                    }
                    model = array;

                    var foundIndex = find(cfg_LabelFont);
                    if (foundIndex == -1) {
                        foundIndex = find(PlasmaCore.Theme.defaultFont.family);
                    }
                    if (foundIndex >= 0) {
                        currentIndex = foundIndex;
                    }

                    _initDone = true;
                }

                // Render each popup item in its own font
                delegate: ItemDelegate {
                    required property var modelData
                    required property int index

                    width: labelCustomFontComboBox.popup.width

                    implicitHeight: Kirigami.Units.gridUnit * 2

                    text: modelData.text
                    font.family: modelData.value
                    highlighted: labelCustomFontComboBox.highlightedIndex === index
                }

                // Reliable for user selection
                onActivated: (idx) => {
                    if (!_initDone) return;
                    if (enabled && idx >= 0) cfg_LabelFont = currentValue;
                    else cfg_LabelFont = "";
                }

                // Optional: keeps cfg in sync if something sets currentIndex programmatically later
                onCurrentValueChanged: {
                    if (!_initDone) return;
                    if (enabled && currentIndex >= 0) cfg_LabelFont = currentValue;
                }

                // If the checkbox disables it, clear the config immediately (optional, but matches your else-branch intent)
                onEnabledChanged: {
                    if (!_initDone) return;
                    if (!enabled) cfg_LabelFont = "";
                    else if (currentIndex >= 0) cfg_LabelFont = currentValue;
                }
                // onCurrentIndexChanged: {
                //     if (enabled && currentIndex >= 0) {
                //         cfg_LabelFont = currentValue;
                //     }
                //     else {
                //         cfg_LabelFont = "";
                //     }
                // }
            }
        }

        RowLayout {
            CheckBox {
                id: labelCustomFontSizeCheckBox
                checked: cfg_LabelFontSize > 0
                onCheckedChanged: cfg_LabelFontSize = checked ?
                    labelCustomFontSizeSpinBox.value : 0
                text: "Custom font size:"
            }

            PXSpinBox {
                id: labelCustomFontSizeSpinBox
                value: cfg_LabelFontSize || PlasmaCore.Theme.defaultFont.pixelSize

                editable: labelCustomFontSizeCheckBox.checked
                from: 5
                to: 100
                suffix: " px"
                onValueChanged: {
                    if (labelCustomFontSizeCheckBox.checked) {
                        cfg_LabelFontSize = value;
                    }
                }
            }
        }

        RowLayout {
            CheckBox {
                id: labelCustomColorCheckBox
                enabled: cfg_IndicatorStyle != IndicatorStyles.UseLabels
                checked: cfg_LabelColor
                onCheckedChanged: cfg_LabelColor = checked ?
                    labelCustomColorButton.color : ""
                text: "Custom text color:"
            }


            ColorButton {
                id: labelCustomColorButton
                enabled: labelCustomColorCheckBox.enabled && labelCustomColorCheckBox.checked
                color: cfg_LabelColor || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_LabelColor = color;
                }
            }

            Item {
                width: 8
            }

            HintIcon {
                tooltipText: cfg_IndicatorStyle != IndicatorStyles.UseLabels ?
                    "Click the colored box to choose a different color" :
                    "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            CheckBox {
                id: labelDimIdleCheckBox
                enabled: cfg_IndicatorStyle != IndicatorStyles.UseLabels
                text: "Dim labels for idle desktops"
            }

            HintIcon {
                visible: !labelDimIdleCheckBox.enabled
                tooltipText: "Not available if labels are used as indicators"
            }
        }

        RowLayout {
            CheckBox {
                id: labelUppercaseCheckBox
                enabled: cfg_LabelStyle != 1
                text: "Display labels as UPPERCASED"
            }

            HintIcon {
                visible: !labelUppercaseCheckBox.enabled
                tooltipText: "Not available for the selected label style"
            }
        }

        CheckBox {
            id: labelBoldCurrentCheckBox
            text: "Set bold font for current desktop"
        }

        Item { Kirigami.FormData.isSection: true }
        RowLayout {
            Kirigami.FormData.label: "Desktop Indicators:"
            Label {
                text: "Style:"
            }

            ComboBox {
                id: indicatorStyleComboBox
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
                    if (cfg_IndicatorStyle == IndicatorStyles.Block) {
                        cfg_IndicatorBlockRadius = indicatorBlockRadiusSpinBox.value;
                    } else {
                        cfg_IndicatorBlockRadius = 2;
                    }
                    if (cfg_IndicatorStyle < IndicatorStyles.Block) {
                        cfg_IndicatorLineThickness = indicatorLineThicknessSpinBox.value;
                    } else {
                        cfg_IndicatorLineThickness = 3;
                    }

                }

                Component.onCompleted: {
                    if (cfg_IndicatorStyle != IndicatorStyles.Block) {
                        cfg_IndicatorBlockRadius = 2;
                    }
                }
            }

            PXSpinBox {
                id: indicatorBlockRadiusSpinBox
                value: cfg_IndicatorBlockRadius
                visible: cfg_IndicatorStyle == IndicatorStyles.Block
                from: 0
                to: 300
                suffix: " px corner radius"
            }

            PXSpinBox {
                id: indicatorLineThicknessSpinBox
                value: cfg_IndicatorLineThickness
                visible: cfg_IndicatorStyle < IndicatorStyles.Block
                from: 1
                to: 10
                suffix: " px thickness"
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorInvertCheckBox
                enabled: cfg_IndicatorStyle < IndicatorStyles.Block
                text: "Invert indicator's position"
            }

            HintIcon {
                visible: !indicatorInvertCheckBox.enabled
                tooltipText: "Not available for the selected indicator style"
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorKeepOpacityCheckBox
                enabled: indicatorCustomColorCurrentCheckBox.checked ||
                    indicatorCustomColorIdleCheckBox.checked ||
                    indicatorCustomColorOccupiedCheckBox.checked ||
                    indicatorCustomColorAttentionCheckBox.checked
                text: "Do not override opacity of custom colors"
            }

            HintIcon {
                tooltipText: !indicatorKeepOpacityCheckBox.enabled ?
                    "Not available if custom colors are not used" :
                    "Alpha channel of custom colors will be applied without any modifications"
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorDistinctOccupiedCheckBox
                enabled: !cfg_IndicatorColorOccupied ||
                    !cfg_IndicatorKeepOpacity
                text: "Distinct indicators for occupied idle desktops"
            }

            HintIcon {
                visible: !indicatorDistinctOccupiedCheckBox.enabled
                tooltipText: "Not available if a custom color is used and overriding opacity of custom colors is blocked"
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorDistinctAttentionCheckBox
                enabled: !cfg_IndicatorColorAttention ||
                    !cfg_IndicatorKeepOpacity
                text: "Distinct indicators for desktops needing attention"
            }

            HintIcon {
                visible: !indicatorDistinctAttentionCheckBox.enabled
                tooltipText: "Not available if a custom color is used and overriding opacity of custom colors is blocked"
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorCustomColorIdleCheckBox
                checked: cfg_IndicatorColorIdle
                onCheckedChanged: cfg_IndicatorColorIdle = checked ?
                    indicatorCustomColorIdleButton.color : ""
                text: "Custom color for idle desktops:"
            }

            ColorButton {
                id: indicatorCustomColorIdleButton
                enabled: indicatorCustomColorIdleCheckBox.checked
                color: cfg_IndicatorColorIdle || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_IndicatorColorIdle = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorCustomColorCurrentCheckBox
                checked: cfg_IndicatorColorCurrent
                onCheckedChanged: cfg_IndicatorColorCurrent = checked ?
                    indicatorCustomColorCurrentButton.color : ""
                text: "Custom color for current desktop:"
            }

            ColorButton {
                id: indicatorCustomColorCurrentButton
                enabled: indicatorCustomColorCurrentCheckBox.checked
                color: cfg_IndicatorColorCurrent || PlasmaCore.Theme.buttonFocusColor

                colorAcceptedCallback: function (color) {
                    cfg_IndicatorColorCurrent = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorCustomColorOccupiedCheckBox
                checked: cfg_IndicatorColorOccupied
                onCheckedChanged: cfg_IndicatorColorOccupied = checked ?
                    indicatorCustomColorOccupiedButton.color : ""
                text: "Custom color for occupied idle desktops:"
            }

            ColorButton {
                id: indicatorCustomColorOccupiedButton
                enabled: indicatorCustomColorOccupiedCheckBox.checked
                color: cfg_IndicatorColorOccupied || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_IndicatorColorOccupied = color;
                }
            }
        }

        RowLayout {
            CheckBox {
                id: indicatorCustomColorAttentionCheckBox
                checked: cfg_IndicatorColorAttention
                onCheckedChanged: cfg_IndicatorColorAttention = checked ?
                    indicatorCustomColorAttentionButton.color : ""
                text: "Custom color for desktops needing attention:"
            }

            ColorButton {
                id: indicatorCustomColorAttentionButton
                enabled: indicatorCustomColorAttentionCheckBox.checked
                color: cfg_IndicatorColorAttention || PlasmaCore.Theme.textColor

                colorAcceptedCallback: function (color) {
                    cfg_IndicatorColorAttention = color;
                }
            }
        }
    }
}
