import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null

  property bool applied: false
  property bool applyPending: false
  property bool unloading: false
  readonly property string ownerToken: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`

  function clipboardHelpers() {
    return [
      'local function send_shortcut_once(mods, key) hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" })); hl.timer(function() hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" })) end, { timeout = 50, type = "oneshot" }) end',
      'local function uses_ctrl_shift_clipboard(window) if not window then return false end; local initial_title = window.initial_title or ""; return window.class == "com.lazycat.terminal" or initial_title:match("^cloud%.lazycat%.lightos") ~= nil end',
      'local function is_tagged_terminal(window) if not window then return false end; for _, tag in ipairs(window.tags or {}) do if tag:gsub("%*$", "") == "terminal" then return true end end; return false end',
      'local function clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key) return function() local window = hl.get_active_window(); if uses_ctrl_shift_clipboard(window) then send_shortcut_once("CTRL SHIFT", default_key) elseif is_tagged_terminal(window) then send_shortcut_once(terminal_mods, terminal_key) else send_shortcut_once(default_mods, default_key) end end end'
    ];
  }

  function removePluginBindings() {
    return [
      'for _, binding in ipairs(_G.omarchy_terminal_clipboard_bindings or {}) do pcall(function() binding:unbind() end) end',
      '_G.omarchy_terminal_clipboard_bindings = nil'
    ];
  }

  function applyScript() {
    const commands = root.removePluginBindings()
      .concat([
        'hl.unbind("SUPER + C")',
        'hl.unbind("SUPER + V")'
      ])
      .concat(root.clipboardHelpers());

    commands.push(`_G.omarchy_terminal_clipboard_owner = "${root.ownerToken}"`);
    commands.push('_G.omarchy_terminal_clipboard_bindings = { hl.bind("SUPER + C", clipboard_shortcut("CTRL", "C", "CTRL", "Insert"), { description = "Universal copy" }), hl.bind("SUPER + V", clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"), { description = "Universal paste" }) }');
    return commands.join('; ');
  }

  function restoreScript() {
    const commands = [
      `if _G.omarchy_terminal_clipboard_owner == "${root.ownerToken}" then`
    ].concat(root.removePluginBindings());

    commands.push('_G.omarchy_terminal_clipboard_owner = nil');
    commands.push('hl.unbind("SUPER + C")');
    commands.push('hl.unbind("SUPER + V")');
    for (const helper of root.clipboardHelpers())
      commands.push(helper);
    commands.push('hl.bind("SUPER + C", clipboard_shortcut("CTRL", "C", "CTRL", "Insert"), { description = "Universal copy" })');
    commands.push('hl.bind("SUPER + V", clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"), { description = "Universal paste" })');
    commands.push('end');
    return commands.join('; ');
  }

  function applyBindings() {
    if (root.unloading)
      return;

    if (applyProcess.running) {
      root.applyPending = true;
      return;
    }

    root.applyPending = false;
    applyGuard.restart();
    applyProcess.command = ["hyprctl", "eval", root.applyScript()];
    applyProcess.running = true;
  }

  function statusJson() {
    return JSON.stringify({
      applied: root.applied,
      lazycatTerminalClass: "com.lazycat.terminal",
      lightosInitialTitlePrefix: "cloud.lazycat.lightos"
    });
  }

  Process {
    id: applyProcess

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "" && text.trim() !== "ok")
          console.log("Omarchy Terminal Clipboard: " + text.trim());
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "")
          console.warn("Omarchy Terminal Clipboard: " + text.trim());
      }
    }

    onExited: function(exitCode) {
      root.applied = exitCode === 0;
      if (root.applyPending && !root.unloading)
        Qt.callLater(root.applyBindings);
    }
  }

  // Hyprland discards runtime bindings after a configuration reload.
  Timer {
    id: reapplyTimer
    interval: 250
    repeat: false
    onTriggered: root.applyBindings()
  }

  // Some Hyprland versions emit configreloaded while processing runtime Lua.
  Timer {
    id: applyGuard
    interval: 750
    repeat: false
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (String(event?.name ?? "").toLowerCase() !== "configreloaded")
        return;
      if (applyGuard.running || root.unloading)
        return;
      root.applied = false;
      reapplyTimer.restart();
    }
  }

  IpcHandler {
    target: "io.github.manateelazycat.terminal-clipboard"

    function status(): string { return root.statusJson(); }
  }

  Component.onCompleted: reapplyTimer.start()

  Component.onDestruction: {
    root.unloading = true;
    reapplyTimer.stop();
    applyGuard.stop();
    Quickshell.execDetached(["hyprctl", "eval", root.restoreScript()]);
  }
}
