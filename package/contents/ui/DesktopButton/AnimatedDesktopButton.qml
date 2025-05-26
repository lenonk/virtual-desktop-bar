import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../common" as Common

Item {
    id: buttonWrapper

    required property int number
    required property string name
    required property string uuid
    required property bool isCurrent

    readonly property int animationDuration: 850

    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

    // Forward properties to the actual button
    Layout.preferredWidth: button.Layout.preferredWidth
    Layout.preferredHeight: button.Layout.preferredHeight

    // States for animation
    state: "creating"
    states: [
        State {
            name: "creating"
            PropertyChanges { target: button; opacity: 0.0 }
        },
        State {
            name: "visible"
            PropertyChanges { target: button; opacity: 1.0 }
        },
        State {
            name: "removing"
            PropertyChanges { target: button; opacity: 0.0 }
        }
    ]

    transitions: [
        Transition {
            from: "creating"; to: "visible"
            NumberAnimation {
                target: button
                property: "opacity"
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        },
        Transition {
            from: "visible"; to: "removing"
            NumberAnimation {
                target: button
                property: "opacity"
                duration: animationDuration
                easing.type: Easing.InQuad
            }
            onRunningChanged: {
                if (!running && buttonWrapper.state === "removing") {
                    buttonRemoveAnimationCompleted(buttonWrapper.uuid);
                }
            }
        }
    ]

    Component.onCompleted: {
        state = "creating";
        createTimer.start();
    }

    Timer {
        id: createTimer
        interval: 10
        repeat: false
        onTriggered: buttonWrapper.state = "visible"
    }


    DesktopButton {
        id: button
        anchors.fill: parent

        number: buttonWrapper.number
        name: buttonWrapper.name
        uuid: buttonWrapper.uuid
        isCurrent: buttonWrapper.isCurrent

        Component.onCompleted: {
            console.log("Creating button for desktop: " + name);
            buttonCreateAnimationCompleted(this);
        }

        function startRemoveAnimation() {
            buttonWrapper.startRemoveAnimation();
        }
    }

    function startRemoveAnimation() {
        state = "removing";
        return;
    }

}