import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar presence for the ultrawide background pack: one glyph that reports which
// pack the focused monitor is using, and cycles packs on click. The renderer
// itself is the service plugin - this is only the control surface.
BarWidget {
  id: root
  moduleName: "io.github.johnsideserf.ultrawide-background"

  property string activeRatio: ""       // pack in use on the focused screen
  property string detected: ""          // what that screen's shape maps to
  property bool packMissing: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() { if (!statusProc.running) statusProc.running = true }

  Process {
    id: statusProc
    command: ["bash", "-lc",
      "omarchy-ultrawide packs 2>/dev/null | tr '\\n' ' '; echo; " +
      "hyprctl monitors -j 2>/dev/null | python3 -c \"import json,sys\nm=[x for x in json.load(sys.stdin) if x.get('focused')] or json.load(open('/dev/null')) if False else [x for x in json.load(sys.stdin) if x.get('focused')]\" 2>/dev/null || true"]
    stdout: StdioCollector { onStreamFinished: root.parseStatus(String(text || "")) }
  }

  // A single call is cheaper and less fragile than two: ask the helper.
  Process {
    id: infoProc
    command: ["bash", "-lc", "omarchy-ultrawide status 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        var out = String(text || "")
        var m = out.match(/^\s*\*\S+\s+\d+x\d+\s+(\S+)\s+(.*)$/m)
        if (m) {
          root.detected = m[1] === "-" ? "" : m[1]
          root.packMissing = /stock image/.test(m[2])
          root.activeRatio = root.packMissing ? "" : root.detected
        } else {
          root.detected = ""; root.activeRatio = ""; root.packMissing = true
        }
      }
    }
  }

  function parseStatus(_t) {}

  Process {
    id: cycleProc
    command: ["bash", "-lc", "true"]
    onExited: root.reload()
  }

  function reload() { infoProc.running = false; infoProc.running = true }

  function cycle() {
    // move to the next installed pack, wrapping round
    cycleProc.command = ["bash", "-lc",
      "cur=$(grep -s '^ratio=' ~/.config/omarchy/ultrawide-backgrounds/installed | cut -d= -f2); " +
      "packs=$(omarchy-ultrawide packs | tr '\\n' ' '); set -- $packs; " +
      "next=$1; found=0; for p in $packs; do if [ $found = 1 ]; then next=$p; break; fi; " +
      "[ \"$p\" = \"$cur\" ] && found=1; done; omarchy-ultrawide switch \"$next\" >/dev/null 2>&1 || true"]
    cycleProc.running = true
  }

  Timer { interval: 15000; running: true; repeat: true; onTriggered: root.reload() }
  Component.onCompleted: reload()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // 󰍹 monitor glyph; dimmed styling when no pack matches this screen
    text: "󰝹"
    tooltipText: root.activeRatio
      ? "Ultrawide background — " + root.activeRatio + " pack\nClick to switch pack, right-click for status"
      : "Ultrawide background — no pack for this screen (showing stock)\nRight-click for status"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton)
        root.bar.run("omarchy-launch-or-focus-tui \"zsh -c 'omarchy-ultrawide status; echo; read -k 1'\"")
      else root.cycle()
    }
  }
}
