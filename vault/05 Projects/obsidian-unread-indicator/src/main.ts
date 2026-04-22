import { Plugin, TFile } from 'obsidian';

interface UnreadData {
  unread: string[];
}

export default class UnreadIndicatorPlugin extends Plugin {
  private unreadPaths: Set<string> = new Set();

  async onload() {
    const data = (await this.loadData()) as UnreadData | null;
    if (data?.unread) {
      this.unreadPaths = new Set(data.unread);
    }

    // Mark as unread when vault modifies a note
    this.registerEvent(
      this.app.vault.on('modify', (file) => {
        if (file instanceof TFile && file.extension === 'md') {
          this.unreadPaths.add(file.path);
          this.saveUnread();
          this.refreshFileExplorer();
        }
      })
    );

    // Mark as read when note is opened
    this.registerEvent(
      this.app.workspace.on('file-open', (file) => {
        if (file instanceof TFile && file.extension === 'md') {
          if (this.unreadPaths.has(file.path)) {
            this.unreadPaths.delete(file.path);
            this.saveUnread();
            this.refreshFileExplorer();
          }
        }
      })
    );

    // Re-render dots when sidebar is toggled or layout changes
    this.registerEvent(
      this.app.workspace.on('layout-change', () => {
        this.refreshFileExplorer();
      })
    );

    this.refreshFileExplorer();
  }

  onunload() {
    document.querySelectorAll('.unread-dot').forEach((el) => el.remove());
  }

  private async saveUnread() {
    await this.saveData({ unread: Array.from(this.unreadPaths) });
  }

  private refreshFileExplorer() {
    // Remove all existing dots to avoid duplicates
    document.querySelectorAll('.unread-dot').forEach((el) => el.remove());

    this.unreadPaths.forEach((filePath) => {
      // Obsidian renders: .nav-files-container [data-path="some/path.md"] .nav-file-title
      const container = document.querySelector(
        `.nav-files-container [data-path="${CSS.escape(filePath)}"]`
      );
      if (!container) return;

      const titleEl = container.querySelector('.nav-file-title');
      if (!titleEl) return;

      const dot = document.createElement('span');
      dot.className = 'unread-dot';
      titleEl.appendChild(dot);
    });
  }
}
