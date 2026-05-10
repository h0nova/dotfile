import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Explicitly typed as 'color' for strict QML binding
    property color base: "#0b0f0b"
    property color mantle: "#181d18"
    property color crust: "#101510"
    property color text: "#dfe4dc"
    property color subtext0: "#c1c9be"
    property color subtext1: "#8b9389"
    property color surface0: "#1c211c"
    property color surface1: "#262b26"
    property color surface2: "#313631"
    property color overlay0: "#dfe4dc"
    property color overlay1: "#dfe4dc"
    property color overlay2: "#dfe4dc"
    property color blue: "#99d4a2"
    property color sapphire: "#18512b"
    property color peach: "#a2ced8"
    property color green: "#b7ccb7"
    property color red: "#ffb4ab"
    property color mauve: "#99d4a2"
    property color pink: "#204d55"
    property color yellow: "#394b3b"
    property color maroon: "#93000a"
    property color teal: "#b7ccb7"

    property string rawJson: ""

    Process {
        id: themeReader
	command: ["cat", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/qs_colors.json"]
	stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt !== root.rawJson) {
                    root.rawJson = txt;
                    try {
                        let c = JSON.parse(txt);
                        if (c.base) root.base = c.base;
                        if (c.mantle) root.mantle = c.mantle;
                        if (c.crust) root.crust = c.crust;
                        if (c.text) root.text = c.text;
                        if (c.subtext0) root.subtext0 = c.subtext0;
                        if (c.subtext1) root.subtext1 = c.subtext1;
                        if (c.surface0) root.surface0 = c.surface0;
                        if (c.surface1) root.surface1 = c.surface1;
                        if (c.surface2) root.surface2 = c.surface2;
                        if (c.overlay0) root.overlay0 = c.overlay0;
                        if (c.overlay1) root.overlay1 = c.overlay1;
                        if (c.overlay2) root.overlay2 = c.overlay2;
                        if (c.blue) root.blue = c.blue;
                        if (c.sapphire) root.sapphire = c.sapphire;
                        if (c.peach) root.peach = c.peach;
                        if (c.green) root.green = c.green;
                        if (c.red) root.red = c.red;
                        if (c.mauve) root.mauve = c.mauve;
                        if (c.pink) root.pink = c.pink;
                        if (c.yellow) root.yellow = c.yellow;
                        if (c.maroon) root.maroon = c.maroon;
                        if (c.teal) root.teal = c.teal;
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 1000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: themeReader.running = true
    }
}
