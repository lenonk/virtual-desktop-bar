// package/contents/ui/config/SupportTab.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    //
    // Plasma injects cfg_* (and sometimes cfg_*Default) into every config page root.
    // Declare them here so plasmashell doesn't spam the journal.
    //
    property string cfg_EmptyDesktopName
    property bool   cfg_SwitchToNewDesktop
    property bool   cfg_PromptRenameNew
    property string cfg_NewDesktopCommand
    property bool   cfg_DynamicDesktops
    property bool   cfg_FilterByScreen
    property bool   cfg_WheelClickRemoves
    property bool   cfg_WheelScrollSwitches
    property bool   cfg_WheelInvertDirection
    property bool   cfg_WheelWrapAround
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
    property bool   cfg_LabelBoldCurrent
    property bool   cfg_LabelUppercase
    property int    cfg_IndicatorStyle
    property int    cfg_IndicatorLineThickness
    property int    cfg_IndicatorBlockRadius
    property bool   cfg_IndicatorInvert
    property string cfg_IndicatorColorIdle
    property string cfg_IndicatorColorCurrent
    property string cfg_IndicatorColorOccupied
    property string cfg_IndicatorColorAttention
    property bool   cfg_IndicatorKeepOpacity
    property bool   cfg_IndicatorDistinctOccupied
    property bool   cfg_IndicatorDistinctAttention

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
    property bool   cfg_LabelBoldCurrentDefault
    property bool   cfg_LabelUppercaseDefault
    property int    cfg_IndicatorStyleDefault
    property int    cfg_IndicatorLineThicknessDefault
    property int    cfg_IndicatorBlockRadiusDefault
    property bool   cfg_IndicatorInvertDefault
    property string cfg_IndicatorColorIdleDefault
    property string cfg_IndicatorColorCurrentDefault
    property string cfg_IndicatorColorOccupiedDefault
    property string cfg_IndicatorColorAttentionDefault
    property bool   cfg_IndicatorKeepOpacityDefault
    property bool   cfg_IndicatorDistinctOccupiedDefault
    property bool   cfg_IndicatorDistinctAttentionDefault

    readonly property string kofiUrl: "https://ko-fi.com/K3K51TO6S1"

    Kirigami.FormLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Thank you!")
        }

        Label {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            Layout.preferredWidth: 0      // IMPORTANT: allow shrinking in layouts
            wrapMode: Text.Wrap
            text: i18n("If Virtual Desktop Bar makes your Plasma workflow nicer and you’d like to support ongoing maintenance and improvements, here’s the easiest way to do it.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("    ")
            spacing: Kirigami.Units.smallSpacing

            Button {
                text: i18n("Support me on Ko-fi")
                icon.name: "emblem-favorite"
                onClicked: Qt.openUrlExternally(root.kofiUrl)
            }

            // Optional: show the URL as clickable text too (easy copy/paste)
            Label {
                textFormat: Text.RichText
                text: "<a href='" + root.kofiUrl + "'>" + root.kofiUrl + "</a>"
                onLinkActivated: Qt.openUrlExternally(link)
                opacity: 0.8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Label {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            opacity: 0.8
            text: i18n("No pressure — using the widget is already appreciated.")
        }
    }
}
