# Rime Custom

自訂 Rime 設定、詞庫及相關檔案等。

## VSCode 專案路徑
* `~/Documents/Workspaces/Rime/`
* Workspace 路徑：`~/Documents/Workspaces/VSCode/Rime/Rime-Custom.code-workspace`

## 檔案對應路徑
* **Rime** 資料夾：`~/Library/Rime/`
* **Contents 資料夾（macOS）**：`/Library/Input Methods/Squirrel.app/Contents/`
* **data 資料夾（Windows）**：`C:/Program Files (x86)/Rime/weasel-{版本號}/data/`

## 注意事項
* **Mac:** Rime 0.16（2023-01-30）起不知為何日文漢字轉換的字典無法使用 `group`，故將 `JPCharacters.txt` 和 `JPPhrases.txt` 合併於 `JPVariants.txt`（見 `t2jp.json`）  
  **Windows:** 從 Weasel 0.15（2023-06-06）起也有上述問題，必須使用單一的 `JPVariants.txt` 檔案
* Rime 0.16 版新增了命令行同步功能，可在 `.zshrc` 加入以下指令，即可用 `Squirrel --sync` 或 `squirrel --sync` 指令執行同步：
  ```bash
  ## Rime
  alias Squirrel='/Library/Input\ Methods/Squirrel.app/Contents/MacOS/Squirrel'
  alias squirrel='/Library/Input\ Methods/Squirrel.app/Contents/MacOS/Squirrel'
  ```
* 小狼毫 0.16.1.0 起：
  - 用戶資料夾下的 `terra_pinyin.schema.yaml` 每次重新部署後都會被刪除（原因未查明），須直接修改應用程式資料夾下的 `terra_pinyin.schema.yaml` 檔案
  - OpenCC `segmentation` 現在只吃 ocd2
  - 日文漢字轉換只吃單檔（原因未查明），直接用 JPVariants.txt 就好，`JPCharacters.txt` 和 `JPPhrases.txt` 留存
