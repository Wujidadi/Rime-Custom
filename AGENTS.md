# Rime-Custom

自訂 Rime 設定檔的單一事實來源，並存放自建鼠鬚管（Squirrel，macOS）與小狼毫（Weasel，Windows）的操作手冊。

## 倉庫角色

- `Rime-macOS/`、`Rime-Windows/`：使用者層自訂檔（方案、詞典、symbols、Lua 模組），佈建至 `~/Library/Rime` 或 `%APPDATA%\Rime`。
- `Contents/SharedSupport/`、`data/`：app 層 overlay，覆蓋進安裝中的 Squirrel.app 或 weasel 安裝目錄。
- `MANUAL-SQUIRREL.md`、`MANUAL-WEASEL.md`：完整操作手冊，工作流、指令語義與疑難排解一律以手冊為準，不憑記憶。
- 機群：macOS 編譯機 A2780、A3434；Windows 編譯機 i9-10900。

## dotfiles 指令組

- 所有 Rime 機器都固定有 `~/dotfiles`，不必檢查存在與否。
- `rime-*`、`squirrel-*`、`weasel-*` 都是 dotfiles 定義的自訂指令，在 agent 的 shell 中已載入，看到即直接使用，不必再確認是否存在。
- macOS 實作：`~/dotfiles/zshrc/A2780/zsh/rime.zsh` 為載入器，子模組在 `~/dotfiles/zshrc/A2780/zsh/rime/`（core、build、install、userdb、user-files、cloud）；`~/.zsh/rime.zsh`、`~/.zsh_modules` 與 A3434 的同名檔案均為 symlink 指向 A2780 版，修改只改 A2780 那份。
- Windows 實作：`~/dotfiles/bash/i9-10900/bash/weasel.sh`（Git Bash）與 `~/dotfiles/pwsh/i9-10900/modules/weasel.ps1`（PowerShell 7），函式名與 macOS 對齊。
- 指令清單與環境變數見 `MANUAL-SQUIRREL.md` 的「指令一覽」節與 `MANUAL-WEASEL.md` 的「日常指令」節。
- 修改指令組時，須同步更新手冊對應的節。

## 工作慣例

- 部署與同步屬非同步動作，以 Rime 日誌驗證結果，不以猜測的等待時間空等。
- Windows 端的 `.bat` 為 CRLF，編修用逐段取代的編輯工具，不用 `sed -i`。
- 手冊只描述現況，不嵌入修訂歷史。
