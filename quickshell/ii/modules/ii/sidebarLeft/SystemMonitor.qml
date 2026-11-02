pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var temps: ({})       // { CPU: 55, GPU: 48, SSD: 40 }
    property var fans: []          // [rpm, rpm]
    property var procs: []         // [{pid, cpu, mem, name}]
    property real gpuUsage: -1     // 0..1, -1 = unknown
    property real diskTotal: 0
    property real diskUsed: 0
    property int batteryLevel: -1
    property string batteryStatus: ""
    property real batteryWatts: 0
    property real uptimeSecs: 0
    property real netDown: 0       // bytes/s
    property real netUp: 0
    property var lastNet: null

    function fmtBytes(b) {
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return `${b.toFixed(b < 10 && i > 0 ? 1 : 0)} ${u[i]}`;
    }
    function fmtUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
    function tempColor(t) {
        return t >= 85 ? Appearance.m3colors.m3error : t >= 70 ? Appearance.m3colors.m3tertiary : Appearance.colors.colSubtext;
    }

    function parse(text) {
        const sec = {};
        let cur = null;
        for (const line of text.split("\n")) {
            const m = line.match(/^@@(\w+)$/);
            if (m) { cur = m[1]; sec[cur] = []; continue; }
            if (cur) sec[cur].push(line);
        }
        // Sensors
        try {
            const s = JSON.parse((sec.sensors ?? []).join("\n"));
            const t = {}, f = [];
            const first = (chip, suffix) => {
                for (const k in chip) {
                    const v = chip[k];
                    if (typeof v !== "object") continue;
                    for (const kk in v) if (kk.endsWith(suffix)) return v[kk];
                }
                return undefined;
            };
            for (const name in s) {
                const chip = s[name];
                if (/^(k10temp|coretemp|zenpower)/.test(name) && t.CPU === undefined)
                    t.CPU = chip.Tctl?.temp1_input ?? chip["Package id 0"]?.temp1_input ?? first(chip, "_input");
                else if (/^(amdgpu|nouveau|nvidia)/.test(name) && t.GPU === undefined)
                    t.GPU = chip.edge?.temp1_input ?? first(chip, "temp1_input");
                else if (/^nvme/.test(name) && t.SSD === undefined)
                    t.SSD = chip.Composite?.temp1_input ?? first(chip, "temp1_input");
                for (const k in chip) {
                    if (/^fan\d+$/.test(k) && chip[k][`${k}_input`] !== undefined) f.push(chip[k][`${k}_input`]);
                }
            }
            root.temps = t;
            root.fans = f;
        } catch (e) {}
        // GPU usage
        const g = parseFloat((sec.gpu ?? [])[0]);
        root.gpuUsage = isNaN(g) ? -1 : g / 100;
        // Disk
        const d = ((sec.disk ?? [])[0] ?? "").trim().split(/\s+/);
        if (d.length >= 2) { root.diskTotal = Number(d[0]); root.diskUsed = Number(d[1]); }
        // Battery
        const b = sec.battery ?? [];
        root.batteryLevel = b[0] ? parseInt(b[0]) : -1;
        root.batteryStatus = b[1] ?? "";
        root.batteryWatts = b[2] ? Number(b[2]) / 1e6 : 0;
        // Uptime
        root.uptimeSecs = parseFloat((sec.uptime ?? ["0"])[0]);
        // Network
        const n = ((sec.net ?? [])[0] ?? "").trim().split(/\s+/).map(Number);
        if (n.length === 2 && !isNaN(n[0])) {
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.t) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, (n[0] - root.lastNet.rx) / dt);
                    root.netUp = Math.max(0, (n[1] - root.lastNet.tx) / dt);
                }
            }
            root.lastNet = { t: now, rx: n[0], tx: n[1] };
        }
        // Processes (top output)
        root.procs = (sec.top ?? []).filter(l => /^\s*\d+/.test(l)).slice(0, 12).map(l => {
            const c = l.trim().split(/\s+/);
            return { pid: c[0], cpu: parseFloat(c[8]), mem: parseFloat(c[9]), name: c.slice(11).join(" ") };
        });
    }

    Process {
        id: poller
        command: ["bash", "-c", `
            echo @@sensors; sensors -j 2>/dev/null
            echo @@gpu; cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1
            echo @@disk; df -B1 --output=size,used / | tail -1
            echo @@battery; b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
            [ -n "$b" ] && { cat $b/capacity; cat $b/status; cat $b/power_now 2>/dev/null || echo 0; }
            echo @@uptime; cut -d' ' -f1 /proc/uptime
            echo @@net; i=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
            [ -n "$i" ] && echo "$(cat /sys/class/net/$i/statistics/rx_bytes) $(cat /sys/class/net/$i/statistics/tx_bytes)"
            echo @@top; top -b -n2 -d0.5 -w 256 | awk '/^top -/{n++} n==2' | sed -n '8,24p'
        `]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }
    Timer {
        running: root.visible
        triggeredOnStart: true
        interval: 2000
        repeat: true
        onTriggered: if (!poller.running) poller.running = true
    }

    // ---------- components ----------
    component Card: Rectangle {
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
        Layout.fillWidth: true
    }

    component Gauge: Card {
        id: gauge
        property string label
        property real value: 0
        property bool known: true
        property string sub: ""
        property color subColor: Appearance.colors.colSubtext
        property color accent: Appearance.colors.colPrimary
        implicitHeight: 128
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 68
                implicitHeight: 68
                CircularProgress {
                    anchors.centerIn: parent
                    implicitSize: 68
                    lineWidth: 6
                    value: gauge.known ? gauge.value : 0
                    colPrimary: gauge.accent
                }
                StyledText {
                    anchors.centerIn: parent
                    text: gauge.known ? `${Math.round(gauge.value * 100)}%` : "–"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer2
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gauge.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: gauge.sub.length > 0
                text: gauge.sub
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: gauge.subColor
            }
        }
    }

    component InfoTile: Card {
        id: tile
        property string icon
        property string title
        property string value
        property string detail: ""
        property real bar: -1   // 0..1 shows a progress bar
        implicitHeight: 72
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2
            RowLayout {
                spacing: 6
                MaterialSymbol { text: tile.icon; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colPrimary; fill: 1 }
                StyledText { text: tile.title; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: tile.value
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
            }
            StyledProgressBar {
                Layout.fillWidth: true
                visible: tile.bar >= 0
                value: Math.max(0, tile.bar)
                valueBarHeight: 4
            }
            StyledText {
                Layout.fillWidth: true
                visible: tile.bar < 0 && tile.detail.length > 0
                elide: Text.ElideRight
                text: tile.detail
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ---------- layout ----------
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Gauges
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Gauge {
                label: "CPU"
                value: ResourceUsage.cpuUsage
                sub: root.temps.CPU !== undefined ? `${Math.round(root.temps.CPU)}°C` : ""
                subColor: root.tempColor(root.temps.CPU ?? 0)
            }
            Gauge {
                label: Translation.tr("Memory")
                value: ResourceUsage.memoryUsedPercentage
                sub: `${ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)} / ${ResourceUsage.maxAvailableMemoryString}`.replace(/ GB \//, " /")
                accent: Appearance.m3colors.m3tertiary
            }
            Gauge {
                label: "GPU"
                known: root.gpuUsage >= 0
                value: Math.max(0, root.gpuUsage)
                sub: root.temps.GPU !== undefined ? `${Math.round(root.temps.GPU)}°C` : ""
                subColor: root.tempColor(root.temps.GPU ?? 0)
                accent: Appearance.m3colors.m3secondary
            }
        }

        // History graph (grows with the sidebar)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 110
            Layout.preferredHeight: 160
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2
            clip: true
            Graph {
                anchors.fill: parent
                anchors.topMargin: 34
                values: ResourceUsage.memoryUsageHistory
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
                color: Appearance.m3colors.m3tertiary
                fillOpacity: 0.15
            }
            Graph {
                anchors.fill: parent
                anchors.topMargin: 34
                values: ResourceUsage.cpuUsageHistory
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
                color: Appearance.colors.colPrimary
                fillOpacity: 0.25
            }
            RowLayout {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                spacing: 12
                StyledText { text: Translation.tr("History"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer2 }
                Item { Layout.fillWidth: true }
                Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: Appearance.colors.colPrimary }
                StyledText { text: "CPU"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: Appearance.m3colors.m3tertiary }
                StyledText { text: Translation.tr("Memory"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }
        }

        // Info tiles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            InfoTile {
                icon: "hard_drive"
                title: Translation.tr("Disk")
                value: `${root.fmtBytes(root.diskUsed)} / ${root.fmtBytes(root.diskTotal)}`
                bar: root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0
            }
            InfoTile {
                icon: root.batteryStatus === "Charging" ? "battery_charging_full" : "battery_full"
                title: Translation.tr("Battery")
                value: root.batteryLevel >= 0 ? `${root.batteryLevel}% · ${root.batteryStatus}` : "–"
                bar: root.batteryLevel >= 0 ? root.batteryLevel / 100 : -1
            }
            InfoTile {
                icon: "swap_vert"
                title: Translation.tr("Network")
                value: `↓ ${root.fmtBytes(root.netDown)}/s`
                detail: `↑ ${root.fmtBytes(root.netUp)}/s`
            }
            InfoTile {
                icon: "schedule"
                title: Translation.tr("Uptime")
                value: root.fmtUptime(root.uptimeSecs)
                detail: root.fans.length > 0 ? `${Translation.tr("Fans")} ${root.fans.map(f => Math.round(f)).join(" · ")} rpm`
                      : (root.temps.SSD !== undefined ? `SSD ${Math.round(root.temps.SSD)}°C` : "")
            }
        }

        // Top processes (fills the rest)
        Card {
            Layout.fillHeight: true
            Layout.minimumHeight: 140
            Layout.preferredHeight: 260
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.fillWidth: true; text: Translation.tr("Top processes"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer2 }
                    StyledText { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: "CPU"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                    StyledText { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: "MEM"; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                }
                ListView {
                    id: procList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    interactive: false
                    spacing: 2
                    model: root.procs
                    delegate: Item {
                        id: procRow
                        required property var modelData
                        width: procList.width
                        height: 26
                        Rectangle { // CPU share bar
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: parent.width * Math.min(1, procRow.modelData.cpu / 100)
                            radius: 4
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            StyledText { Layout.fillWidth: true; elide: Text.ElideRight; text: procRow.modelData.name; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer2 }
                            StyledText { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: `${procRow.modelData.cpu.toFixed(1)}%`; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer2 }
                            StyledText { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: `${procRow.modelData.mem.toFixed(1)}%`; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                        }
                    }
                }
            }
        }
    }
}
