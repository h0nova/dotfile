import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// =========================================================
// Dynamic Island Notifications - Apple-inspired notification system
// Standalone Dynamic Island notification component
// =========================================================

PanelWindow {
    id: islandWindow

    WlrLayershell.namespace: "qs-island-notifs"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    // Scaling
    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v); }

    implicitHeight: s(120)

    // --- Theme ---
    MatugenColors { id: mocha }

    // --- State ---
    property bool expanded: false
    property var currentNotification: null
    property int notificationQueue: 0

    // --- Notification Model ---
    ListModel {
        id: notificationStack
    }

    // --- Show next notification ---
    function displayNextNotification() {
        if (notificationStack.count === 0) {
            currentNotification = null;
            collapseIsland();
            return;
        }

        currentNotification = notificationStack.get(0);
        expandIsland();

        // Auto-close after 5 seconds
        autoHideTimer.restart();
    }

    // --- Remove current notification ---
    function dismissCurrent() {
        if (notificationStack.count > 0) {
            notificationStack.remove(0);
            notificationQueue = Math.max(0, notificationQueue - 1);
        }
        currentNotification = null;
        collapseIsland();

        // Show next after a short delay
        if (notificationStack.count > 0) {
            nextNotifTimer.start();
        }
    }

    // --- Timers ---
    Timer {
        id: autoHideTimer
        interval: 5000
        onTriggered: dismissCurrent()
    }

    Timer {
        id: nextNotifTimer
        interval: 300
        onTriggered: displayNextNotification()
    }

    // --- Island dimensions ---
    property real collapsedWidth: s(180)
    property real collapsedHeight: s(44)
    property real expandedWidth: s(420)
    property real expandedHeight: s(110)

    // --- Animated island container ---
    Item {
        id: islandShape
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: s(8)

        width: expanded ? expandedWidth : collapsedWidth
        height: expanded ? expandedHeight : collapsedHeight

        // Use animators instead of Behavior for better performance
        Behavior on width { enabled: false }
        Behavior on height { enabled: false }

        // Separate animators for dimensions
        NumberAnimation {
            id: widthAnim
            target: islandShape
            property: "width"
            duration: 380
            easing.type: Easing.Bezier; easing.bezierCurve: [0.16, 1, 0.3, 1]
        }

        NumberAnimation {
            id: heightAnim
            target: islandShape
            property: "height"
            duration: 380
            easing.type: Easing.Bezier; easing.bezierCurve: [0.16, 1, 0.3, 1]
        }

        // Listen for expanded change
        Connections {
            target: islandWindow
            function onExpandedChanged() {
                widthAnim.to = islandWindow.expanded ? islandWindow.expandedWidth : islandWindow.collapsedWidth;
                heightAnim.to = islandWindow.expanded ? islandWindow.expandedHeight : islandWindow.collapsedHeight;
                widthAnim.restart();
                heightAnim.restart();
            }
        }

        // --- Island background ---
        Rectangle {
            id: islandBg
            anchors.fill: parent
            radius: height / 2

            color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, expanded ? 0.95 : 0.88)

            // Border - fixed color without animation for performance
            border.width: 1
            border.color: expanded
                ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)
                : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)

            // Shadow - cached, opacity not changed during animation
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.3
                shadowBlur: 1.0
                shadowVerticalOffset: 6
            }

            // --- COLLAPSED STATE ---
            Item {
                id: collapsedContent
                anchors.fill: parent
                opacity: expanded ? 0 : 1
                visible: opacity > 0.01

                // Optimized fade
                NumberAnimation on opacity {
                    id: collapsedFade
                    duration: 200
                    easing.type: Easing.OutQuad
                    onStopped: {
                        if (islandWindow.expanded && collapsedContent.opacity === 0) collapsedContent.visible = false;
                    }
                }

                onVisibleChanged: {
                    if (!islandWindow.expanded && visible) opacity = 1;
                }

                // Notification queue indicator
                Row {
                    anchors.centerIn: parent
                    spacing: s(8)

                    // App icon (small)
                    Rectangle {
                        width: s(24)
                        height: s(24)
                        radius: s(6)
                        color: mocha.surface1
                        visible: currentNotification !== null

                        Image {
                            anchors.fill: parent
                            anchors.margins: s(2)
                            source: currentNotification ? currentNotification.icon : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        // Fallback icon
                        Text {
                            anchors.centerIn: parent
                            text: "󰵙"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: s(14)
                            color: mocha.mauve
                            visible: parent.children[0].status !== Image.Ready
                        }
                    }

                    // Activity indicator - optimized animation
                    Rectangle {
                        width: s(6)
                        height: s(6)
                        radius: s(3)
                        color: mocha.mauve
                        anchors.verticalCenter: parent.verticalCenter

                        ScaleAnimator on scale {
                            id: pulseAnim
                            from: 1.0
                            to: 1.3
                            duration: 600
                            easing.type: Easing.InOutSine
                            loops: Animation.Infinite
                            running: currentNotification !== null && !expanded
                        }
                    }

                    // Notification counter
                    Text {
                        text: notificationQueue > 1 ? notificationQueue.toString() : ""
                        font.family: "JetBrains Mono"
                        font.pixelSize: s(12)
                        font.weight: Font.Bold
                        color: mocha.text
                        visible: notificationQueue > 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // --- EXPANDED STATE ---
            Item {
                id: expandedContent
                anchors.fill: parent
                anchors.margins: s(12)
                opacity: expanded ? 1 : 0
                visible: opacity > 0.01

                NumberAnimation on opacity {
                    id: expandedFade
                    duration: 280
                    easing.type: Easing.OutQuad
                    onStopped: {
                        if (!islandWindow.expanded && expandedContent.opacity === 0) expandedContent.visible = false;
                    }
                }

                // Shift on appear via transform
                transform: Translate { id: contentTranslate; y: 0 }

                NumberAnimation {
                    id: slideAnim
                    target: contentTranslate
                    property: "y"
                    duration: 320
                    easing.type: Easing.OutBack; easing.overshoot: 1.2
                }

                onVisibleChanged: {
                    if (islandWindow.expanded && visible) opacity = 1;
                }

                // Fixed structure instead of RowLayout for performance
                Item {
                    anchors.fill: parent

                    // App icon
                    Rectangle {
                        id: iconContainer
                        width: s(48)
                        height: s(48)
                        radius: s(12)
                        color: mocha.surface0
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: appIcon
                            anchors.fill: parent
                            anchors.margins: s(4)
                            source: currentNotification ? currentNotification.icon : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        // Fallback
                        Text {
                            anchors.centerIn: parent
                            text: "󰵙"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: s(24)
                            color: mocha.mauve
                            visible: appIcon.status !== Image.Ready
                        }
                    }

                    // Notification content
                    Column {
                        anchors.left: iconContainer.right
                        anchors.leftMargin: s(12)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: s(3)

                        // App name
                        Text {
                            width: parent.width
                            text: currentNotification ? currentNotification.appName : ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: s(11)
                            font.weight: Font.Medium
                            color: mocha.overlay1
                            elide: Text.ElideRight
                        }

                        // Title
                        Text {
                            width: parent.width
                            text: currentNotification ? currentNotification.title : ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: s(14)
                            font.weight: Font.Bold
                            color: mocha.text
                            elide: Text.ElideRight
                        }

                        // Notification body
                        Text {
                            width: parent.width
                            text: currentNotification ? currentNotification.body : ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: s(12)
                            color: mocha.subtext0
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            visible: text !== ""
                        }
                    }
                }
            }
        }

        // --- Interaction area ---
        MouseArea {
            id: islandMouse
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if (expanded) {
                    dismissCurrent();
                } else if (currentNotification) {
                    expandIsland();
                    autoHideTimer.restart();
                }
            }
        }
    }

    // --- State management functions ---
    function expandIsland() {
        expanded = true;

        // Start fade animations
        collapsedFade.to = 0;
        collapsedFade.restart();

        expandedFade.to = 1;
        expandedFade.restart();

        slideAnim.from = islandWindow.s(8);
        slideAnim.to = 0;
        slideAnim.restart();
    }

    function collapseIsland() {
        expanded = false;

        // Start fade animations
        collapsedFade.to = 1;
        collapsedFade.restart();

        expandedFade.to = 0;
        expandedFade.restart();
    }

    // --- DND Support ---
    property bool dndEnabled: false

    Process {
        id: dndPoller
        command: ["bash", "-c", "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: islandWindow.dndEnabled = (this.text.trim() === "1")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: dndPoller.running = true
    }

    // Do not show notifications if DND is enabled
    function showNotification(appName, title, body, icon) {
        if (dndEnabled) return;

        let notif = {
            "uid": Date.now() + Math.random(),
            "appName": appName || "System",
            "title": title || "",
            "body": body || "",
            "icon": icon || "",
            "timestamp": new Date()
        };

        notificationStack.append(notif);
        notificationQueue++;

        if (!currentNotification) {
            displayNextNotification();
        }
    }

    // --- IPC: External command listener ---
    Process {
        id: ipcWatcher
        running: true
        command: ["bash", "-c",
            "inotifywait -qq -e close_write,moved_to --include 'qs_island_notif$' /tmp/ 2>/dev/null; " +
            "if [ -f /tmp/qs_island_notif ]; then cat /tmp/qs_island_notif; rm -f /tmp/qs_island_notif; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = this.text.trim();
                if (data) {
                    try {
                        let notif = JSON.parse(data);
                        showNotification(
                            notif.appName || "System",
                            notif.title || "",
                            notif.body || "",
                            notif.icon || ""
                        );
                    } catch(e) {
                        console.log("Failed to parse notification:", e);
                    }
                }
                ipcWatcher.running = false;
                ipcWatcher.running = true;
            }
        }
    }
}
