---
max-width: 1280px
---

# 自建鼠鬚管操作手冊

> [!DATE] 時間：2026-07-25T22:12:26+08:00

本手冊記載自建版鼠鬚管（Squirrel）與個人配套環境的全部非官方操作，
涵蓋自建版行為差異、dotfiles 指令組、同步工作流與疑難排解。
官方文件不會提到這裡的任何內容。

## 生態總覽

| 倉庫              | 位置（A2780）                            | 角色                                                 |
| ----------------- | ---------------------------------------- | ---------------------------------------------------- |
| Wujidadi/squirrel | ~/Documents/Workspaces/IME/rime/squirrel | 鼠鬚管 fork，master 為個人客製線                     |
| Wujidadi/librime  | ~/Documents/Workspaces/IME/rime/librime  | librime fork，squirrel 子模組指向此                  |
| Rime-Custom       | ~/Documents/Workspaces/Rime/Rime-Custom  | 自訂檔單一事實來源＋本手冊                           |
| dotfiles          | ~/dotfiles                               | 指令組（zshrc/A2780/zsh/rime.zsh，A2338 為 symlink） |

- 分支與語言規範見 squirrel 倉庫的 `FORK-POLICY.md`；master 永不合回上游，貢獻一律從 `upstream/master` 開英文分支。
- 版號慣例：官方版號前綴 `w`（wujidadi）加第四段流水號，如 `w1.1.2.1`；定義於 `project.pbxproj` 的 `CURRENT_PROJECT_VERSION`（兩處）。
- 已回報上游的修正：rime/squirrel#1160（add_data_files 錨點模板）、rime/squirrel#1161（appDir 路徑誤植）。

## 自建版與官方版的行為差異

### librime（Wujidadi/librime）

- **`rime_dict_manager -p|--purge <詞庫名>`**：硬刪除 userdb 中 c 為負值的墓碑詞條，並自動重建 sync 快照。官方無此功能，官方語義下墓碑永遠無法清除。
- **同步合併新語義**（刪詞傳播）：
  - 合併保留逐詞條事件 tick（官方會整批蓋成全庫最大值）；
  - c 的正負號由事件較新的一方決定——較新的刪除會跨裝置傳播、較新的使用會復活；tick 平手時刪除勝；
  - 絕對值取兩者較大，保留使用量歷史供復活延續；
  - dee（d 值）記帳為資訊保持變換，詞頻排序與官方無異。
  - 官方語義為「絕對值大者勝、平手本地勝」，刪除永不跨裝置傳播；與官方版機器混用時自動退化為近似官方行為。

### squirrel（Wujidadi/squirrel）

- `--register-input-source` 改為無條件重新註冊（官方在已啟用時直接跳過），bundle 更換後可強制 TIS 重新整理來源紀錄。
- 修正 `SquirrelApp.appDir` 路徑誤植（官方自 Swift 移轉起壞掉，顯式註冊靜默失效）。
- `package/add_data_files` 錨點模板修正並依副檔名分派檔案型別（官方版會靜默漏打包新資料檔）。
- OpenCC 打包清單同步至新版 librime 的字典檔名。
- librime 子模組指向自家 fork。

## 詞庫語義備忘

userdb 詞條形如 `a1 ba1 hai4 <TAB>阿巴亥<TAB>c=1 d=0.588605 t=1577323`：

- `c`：選字次數；Shift+Backspace 軟刪除使其變負（-4）；再次選字復活並續增。
- `d`：按 tick 衰減的近期使用權重，合併時取大——**想調小 d 只能改快照後重建**（purge 或 `-rm` 路徑），這是新語義刻意不動的範圍。
- `t`：該 userdb 的交易流水號（非時間戳）；跨裝置經同步合流後可比，是刪詞傳播的排序依據。

刪詞生命週期：刪詞 → 墓碑在本機 → 同步 → 墓碑在兩機（詞在兩邊消失）→ 再選字即復活，或 purge 徹底移除。
**墓碑常駐無害**（不影響候選與排序），purge 屬大掃除性質。

## 指令一覽（dotfiles rime.zsh）

### 環境變數

| 變數              | 預設值                                   | 用途                           |
| ----------------- | ---------------------------------------- | ------------------------------ |
| SQUIRREL_APP      | /Library/Input Methods/Squirrel.app      | app 路徑                       |
| SQUIRREL          | $SQUIRREL_APP/Contents/MacOS/Squirrel    | 主程式                         |
| RIMED             | ~/Library/Rime                           | 使用者資料目錄                 |
| SQUIRREL_REPO     | ~/Documents/Workspaces/IME/rime/squirrel | 建置倉庫                       |
| SQUIRREL_OVERLAY  | Rime-Custom/Contents/SharedSupport       | 自訂檔 overlay 來源            |
| RIME_DICT_MANAGER | app 內建 rime_dict_manager               | purge 工具路徑                 |
| RIME_PURGE_LEGACY | （未設）                                 | 設 1 強制 purge 走傳統重建機制 |

（`$CLOUD`、`$DRIVE`、`$D` 分別定義於 icloud.zsh、drive.zsh、favorite.zsh。）

### 建置與安裝（編譯機 A2780）

- `squirrel-dev-install`：一鍵重編譯＋就地安裝——建置 → `--quit` → rsync 就地更新（保住 bundle inode）→ overlay 還原自訂檔 → 重新註冊 → `--build` 部署 → 拉起 → nudge。免登出、免動系統設定。
- `squirrel-drift-check`：偵測 SharedSupport 中「內容既不同於建置產出、也不同於 overlay」的未納管現場修改，自動備份到帶時戳 drift 目錄並警告；dev-install 每次自動執行，也可單獨跑。上游資料檔改版可能誤報，人工判讀。
- `squirrel-pack [目的資料夾]`：把建置產出打成 `Squirrel-<版號>.tar.gz`＋sha256 放上雲端（預設 `$CLOUD/Rime`）。必須走 tar：`.app` 裸奔上雲端同步會毀掉符號連結與執行權限。

### 安裝（無建置環境機 A2338）

- `squirrel-cloud-install [來源資料夾]`：取最新雲端 tar 包 → sha256 校驗 → 解包 → 去除隔離屬性 → 就地 rsync → overlay 還原 → 部署拉起。
- 首次安裝前置：`sudo chown -R $USER "/Library/Input Methods"`；首次取代官方版若選單失靈，見疑難排解。

### 同步與詞庫維護

- `rime-sync`：（如 `$D` 有 userdb.txt 先收進 sync 目錄）確保實例存在後發同步通知。
- `rime-deploy`：（如 `$D` 有字典檔先收進 RIMED）有實例走 `--reload`，無實例改於 SharedSupport 執行 `--build` 再拉起。
- `rime-purge-deleted [詞庫名]`：硬刪墓碑。偵測到自建版 `--purge` 即走官方管道（原地清除＋自動重建快照）；否則退回傳統機制（濾快照＋刪 LevelDB 重建）。預設 terra_pinyin。
- `rime-sync-rm`：核選項——刪整個 userdb 令其自快照重建，用於權威重置（含手動調低 c、d 值後落地）。重建以 `rime_dict_manager --restore` 在輸入法重啟前離線完成，**一次到位**，不再需要事後補跑 `rime-sync`。重置前記得先把本機新詞 sync 出去。
- `rime-cloud` / `rime-cloud-ground` / `rime-cloud-ground-rm`：iCloud 上傳快照／下載合併／下載重建。
- `rime-google-*`：Google Drive 對應版本。
- `rime-sync-see-message` 等：裝置間同步留言。
- 內部輔助：`rime-ensure-running`（拉起實例）、`rime-wait-quit`（等待結束）、`rime-nudge-input-sources`（觸發 TIS 重新整理）。

## 標準工作流

### 日常雙向同步（兩台皆自建版）

```
早：A2780 rime-cloud → A2338 rime-cloud-ground
晚：A2338 rime-cloud → A2780 rime-cloud-ground
```

刪詞（Shift+Backspace）經一輪雙向同步自動傳播，無需其他操作。
注意 `rime-cloud` 上傳的是快照檔：傍晚上傳前先 `rime-sync` 才含當日新詞。

### 墓碑大掃除（六步時間線，已驗證）

1. 早：A2780 `rime-cloud` → A2338 `rime-cloud-ground`
2. 晚：A2338 `rime-cloud` → A2780 `rime-cloud-ground`（至此墓碑跑完一圈）
3. 夜：A2780 `rime-purge-deleted`（purge 自帶 Backup，順便匯出當日新詞）
4. 翌早：A2780 `rime-cloud`
5. 翌早：A2338 先 `rime-purge-deleted` 再 `rime-cloud-ground`
6. 兩機詞庫同步且墓碑全消

不變式：**墓碑跑完一圈之後，從上傳端開始 purge；接收端在收到乾淨快照的前後 purge 皆可**。
刪詞後未滿一輪同步就 purge，會令對方的活詞條回流復活。

### 更新自建版

- A2780：`squirrel-dev-install`；要發布給其他機器再 `squirrel-pack`。
- A2338：等 iCloud 同步完成後 `squirrel-cloud-install`。

## 疑難排解

- **狀態列圖標／選單失靈**（bundle 整包替換後）：於系統設定 → 鍵盤加減任一輸入法即救活（觸發 TIS 重新枚舉）。**切勿 `killall TextInputMenuAgent`**——實測會造成圖標空白、選單失聯的半殘狀態。就地 rsync 更新（dev-install／cloud-install 內建）可從根本避免。
- **「中／Ａ」獨立狀態列圖標**點擊無反應屬正常：純顯示元件，無點擊動作。
- **macOS 26 陷阱**：終端行程呼叫 `TISDisableInputSource` 回報成功但靜默失效（enable 有效、disable 無效）；`defaults read com.apple.HIToolbox AppleEnabledInputSources` 是過時鏡像，判斷輸入法即時狀態要用 TIS API。
- **殘留的簡體模式（Squirrel.Hans）**：終端清不掉，要移除只能走系統設定 UI；不出現在狀態列選單、不可選，放著無實害。
- **詞頻全歸零、候選呈字典編碼序（部首靠前的罕見字排最前）**：userdb 是空的——歷史成因是舊版 `rime-sync-rm` 在實例執行中刪 LevelDB（幽靈檔案），或重啟後空庫空窗，過去須再跑一次 `rime-sync` 救回。現版 `rime-sync-rm` 已改為離線重建、一次到位；若仍遇到，跑 `rime-sync` 即可恢復。
- **librime 全套測試**：必須在 `librime/build/test/` 目錄下執行 `rime_test`，否則字典類測試因測試資料路徑誤報失敗。
- **搬移倉庫後建置失敗**（CMake 快取記舊路徑）：`rm -rf librime/build` 再重建。
- **新 Xcode 首次建置 Sparkle 報 plug-in 錯誤**：跑 `xcodebuild -runFirstLaunch`。

## 自訂檔案體系

- 單一事實來源：本倉庫 `Contents/SharedSupport/`（8 個 yaml＋opencc 自訂檔），dev-install／cloud-install 自動 overlay 進 app。
- `essay.txt` 僅留底參考，部署時排除、一律沿用官方版。
- opencc 自訂 txt 只有 `JPVariants.txt` 有效（JPCharacters.txt／JPPhrases.txt 已於 2023-02-02 失效並移除）。
- `t2jp.json` 分詞字典用 `JPShinjitaiCharacters.ocd2`（新版 OpenCC 檔名，原 JPVariants.ocd2 已更名）。
- 直接在 app 內改自訂檔不會遺失（drift 偵測會備份並警告），但正規流程是改本倉庫後重跑 dev-install（或手動同步進 app）。
