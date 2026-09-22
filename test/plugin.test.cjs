const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const root = path.resolve(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const service = fs.readFileSync(path.join(root, "Service.qml"), "utf8");

test("manifest exposes a persistent service", () => {
  assert.equal(manifest.id, "io.github.manateelazycat.terminal-clipboard");
  assert.deepEqual(manifest.kinds, ["service"]);
  assert.equal(manifest.keepLoaded, true);
  assert.equal(manifest.entryPoints.service, "Service.qml");
});

test("Lazycat Terminal and every LightOS user domain use Ctrl+Shift+C/V", () => {
  assert.equal(service.includes('window.class == "com.lazycat.terminal"'), true);
  assert.equal(service.includes('initial_title:match("^cloud%.lazycat%.lightos")'), true);
  assert.equal(service.includes('send_shortcut_once("CTRL SHIFT", default_key)'), true);
});

test("ordinary terminals retain Omarchy's Insert-based shortcuts", () => {
  assert.equal(service.includes('tag:gsub("%*$", "") == "terminal"'), true);
  assert.equal(service.includes('clipboard_shortcut("CTRL", "C", "CTRL", "Insert")'), true);
  assert.equal(service.includes('clipboard_shortcut("CTRL", "V", "SHIFT", "Insert")'), true);
});

test("runtime bindings are reapplied after config reload", () => {
  assert.match(service, /configreloaded/);
  assert.match(service, /reapplyTimer\.restart\(\)/);
  assert.match(service, /hyprctl", "eval", root\.applyScript\(\)/);
});

test("unloading restores Omarchy's default clipboard behavior", () => {
  assert.match(service, /Component\.onDestruction/);
  assert.match(service, /root\.restoreScript\(\)/);
  assert.match(service, /omarchy_terminal_clipboard_owner/);
});

test("the plugin never reloads Hyprland from its lifecycle", () => {
  assert.doesNotMatch(service, /hyprctl[^\n]*reload|reload[^\n]*hyprctl/);
});
