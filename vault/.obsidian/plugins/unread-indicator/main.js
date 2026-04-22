var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/main.ts
var main_exports = {};
__export(main_exports, {
  default: () => UnreadIndicatorPlugin
});
module.exports = __toCommonJS(main_exports);
var import_obsidian = require("obsidian");
var UnreadIndicatorPlugin = class extends import_obsidian.Plugin {
  constructor() {
    super(...arguments);
    this.unreadPaths = /* @__PURE__ */ new Set();
  }
  async onload() {
    const data = await this.loadData();
    if (data?.unread) {
      this.unreadPaths = new Set(data.unread);
    }
    this.registerEvent(
      this.app.vault.on("modify", (file) => {
        if (file instanceof import_obsidian.TFile && file.extension === "md") {
          this.unreadPaths.add(file.path);
          this.saveUnread();
          this.refreshFileExplorer();
        }
      })
    );
    this.registerEvent(
      this.app.workspace.on("file-open", (file) => {
        if (file instanceof import_obsidian.TFile && file.extension === "md") {
          if (this.unreadPaths.has(file.path)) {
            this.unreadPaths.delete(file.path);
            this.saveUnread();
            this.refreshFileExplorer();
          }
        }
      })
    );
    this.registerEvent(
      this.app.workspace.on("layout-change", () => {
        this.refreshFileExplorer();
      })
    );
    this.refreshFileExplorer();
  }
  onunload() {
    document.querySelectorAll(".unread-dot").forEach((el) => el.remove());
  }
  async saveUnread() {
    await this.saveData({ unread: Array.from(this.unreadPaths) });
  }
  refreshFileExplorer() {
    document.querySelectorAll(".unread-dot").forEach((el) => el.remove());
    this.unreadPaths.forEach((filePath) => {
      const container = document.querySelector(
        `.nav-files-container [data-path="${CSS.escape(filePath)}"]`
      );
      if (!container) return;
      const titleEl = container.querySelector(".nav-file-title");
      if (!titleEl) return;
      const dot = document.createElement("span");
      dot.className = "unread-dot";
      titleEl.appendChild(dot);
    });
  }
};
