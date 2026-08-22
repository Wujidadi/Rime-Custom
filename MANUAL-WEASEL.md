# 自建小狼毫（Weasel）操作手冊 — i9-10900

> [!DATE] 時間：2026-08-22T18:10:10+08:00

本手冊記錄 i9-10900（Windows 11 Pro）上自建版小狼毫的組成、建置與部署方式。
macOS 端鼠鬚管的對應手冊見 `MANUAL-SQUIRREL.md`；兩者共用的慣例（fork 版號、FORK-CHANGELOG、上游 merge 規範）不重複詳述。

## 自建版組成

| 元件    | 版本                   | 倉庫                                             |
| ------- | ---------------------- | ------------------------------------------------ |
| weasel  | 0.17.4-wujidadi.3      | `D:\Workspaces\IME\Rime\weasel`                  |
| librime | 1.17.0-wujidadi        | `D:\Workspaces\IME\Rime\librime`                 |
| 外掛    | lua、octagram、predict | 隨 librime 以 BUILD_MERGED_PLUGINS 併入 rime.dll |
| Boost   | 1.84.0（兩倉共用）     | `weasel\deps\boost_1_84_0`（不入版控）           |

fork 相對上游的變動見各倉 `FORK-CHANGELOG.md`；開發規範見各倉 `FORK-POLICY.md`。

### 與官方版的行為差異

- librime 帶自訂 userdb 同步語義（刪除傳播、逐詞條 tick；詳見 librime 倉 FORK-CHANGELOG）。
- 更新頻道指向 fork 自控的 `update/appcast.xml`（raw.githubusercontent.com），「檢查新版本」恆得「已是最新版本」；官方新版以 git 上游追蹤。
  fork 版**不對外發布、不建 GitHub Release**：appcast 的 enclosure URL 僅為佔位，散佈一律走 `weasel-pack` 上雲＋`weasel-cloud-install`；進版推送後無需再問是否建 Release。
  WinSparkle 對連字號版號的比較語義不可靠，故不沿用 macOS「靠 Sparkle 比較器截斷後綴」的做法。
- `installation.yaml` 的 `distribution_version` 顯示 fork 版號（如 `0.17.4-wujidadi.3`）、`rime_version` 顯示 `1.17.0-wujidadi`，可直接分辨自建版。
- WeaselIPC 客戶端 IPC 為 fail-fast 帶兩級逾時（組字／按鍵 500ms、焦點／通知 25ms），宿主程式 UI 執行緒不再無限等待 WeaselServer（rime/weasel#1909）。
  上游 #1912（已合入，`d73f629`）把托盤刷新移到伺服器訊息執行緒、斷開與 explorer 工作列執行緒的死結環，屬伺服器端根因修補；兩者互補，fork 兩邊都有。
  殘餘風險：`FocusIn` → `_UpdateUI()` 仍在管線工作執行緒上跨執行緒呼叫候選視窗的 `ShowWindow`／`SetWindowPos`，若恰逢訊息執行緒卡在 `Shell_NotifyIcon`（`SMTO_BLOCK`），環仍可能短暫成立，由客戶端逾時兜底。

## 安裝位置與檔案對應

- 安裝目錄（x64／Win11）：`C:\Program Files\Rime\weasel-0.17.4\`（NSIS 以 `WEASEL_VERSION` 純數字命名目錄）
- 使用者資料夾：`%APPDATA%\Rime`（`C:\Users\wujidadi\AppData\Roaming\Rime`）
- 使用者層鏡像：本倉 `Rime-Windows/`；應用程式層（data）鏡像：本倉 `data/`
- 2026-08-09 起 `Rime-Windows/` 與 `data/` 一律 LF 入庫（`.gitattributes` 鎖定）；部署腳本化後不再需要 CRLF 手動搬運慣例
- `installation.yaml`、`user.yaml` 為機器私有，不入鏡像；`installation_id` 統一為 `"rime-wujidadi"`
- **自訂方案檔必須同時放應用程式層**（`data/`）：librime 的 SchemaUpdate 會把「版本號低於共用層」的使用者層方案副本移進 `%APPDATA%\Rime\trash\`（README 舊記載「terra_pinyin.schema.yaml 會被刪、原因未查明」的真正機制，適用所有與共用層同名的方案檔——bopomofo、cangjie5、terra_pinyin 皆然）。
  自訂版覆蓋 app 層後兩層版本相等，使用者層副本即可存活，雙層架構與 macOS 的 SharedSupport overlay 對齊

## 建置環境

- VS 2022 Build Tools（C++ 工作負載＋ATL＋MFC；不需 ARM64 元件）、CMake、aria2c、7z、NSIS ≥ 3.09（`install_nsis.bat` 的 3.08 過舊，`${AtLeastWin11}` 會炸；本機以 winget 裝 3.12）
- 兩倉皆用 `env.bat`（自 `env.vs2022.bat` 複製修改，不入版控）：librime 的 `ARCH` 依輪次設 `x64`／`Win32`、`BOOST_ROOT` 指向 weasel 的 boost；weasel 端補 `SDKVER`
- Boost 只需下載解壓一份：weasel 用 `build.bat boost` 編 x86＋x64 靜態庫（不跑 arm64），librime 端 header-only 共用同一份

## 建置流程

### librime（先 x64 後 Win32）

1. `git submodule update --init --recursive`
2. 外掛：`set RIME_PLUGINS=hchunhui/librime-lua lotem/librime-octagram rime/librime-predict` → `action-install-plugins-windows.bat`（librime-lua 的 Lua 原始碼由其自帶腳本抓取；建置須同一 cmd session）
3. `build.bat deps` → `build.bat test`（x64；含 `RimeUserDbMergeTest` 五項）→ 保存 `dist` 為 `dist_x64`
4. 換架構前**必須**清 `lib\`、`bin\`、`include\`、`share\` 與 `deps\*\build`（deps 產物不分架構，不清會 LNK1112），再 `git checkout -- bin include lib share` 還原版控檔
5. `ARCH=Win32` 重跑 deps＋librime → 保存 `dist` 為 `dist_Win32`

### weasel

1. librime 產物手動接入（INSTALL.md 只寫 `weasel\lib`，不完整）：
   - `dist_x64\include\rime_*.h` → `include\`
   - `dist_x64\lib\rime.lib` → `lib64\`；`rime.dll`／`rime.pdb` → `output\`
   - `dist_Win32\lib\rime.lib` → `lib\`；`rime.dll`／`rime.pdb` → `output\Win32\`
   - librime `share\opencc\*` → `output\data\opencc\`
2. octagram 語言模型（方案目前註解未用，為與 macOS 對等而打包）：`plum_dir=plum rime_dir=output/data bash plum/rime-install lotem/rime-octagram-data lotem/rime-octagram-data@hant`
3. `set RELEASE_BUILD=1` → `build.bat data weasel installer` → 產出 `output\archives\weasel-<PRODUCT_VERSION>-installer.exe`（如 `weasel-0.17.4-wujidadi.3-installer.exe`）
4. **不要**走 `build.bat rime`（會 `rd /s /q` 清掉 librime 的建置快取）；**不要**用 `output\install.bat`（x64 機器上呼叫不存在的 `WeaselSetupx64.exe`、靜默失敗）

### 安裝

`weasel-<PRODUCT_VERSION>-installer.exe /S /T`：靜默＋註冊中文（台灣）鍵盤配置＋自動關閉更新檢查（`HKCU\Software\Rime\Weasel\Updates\CheckForUpdates=0`）。

## 日常指令（dotfiles 的 weasel 模組，pwsh 與 Git Bash 皆有）

- `weasel-dev-install`：建置（`scripts/weasel-build.bat`）→ 漂移偵測 → 靜默安裝 → app 層 overlay → 重新部署 → 版本驗證，一鍵到位
- `rime-user-deploy`：Rime-Windows/ 佈建使用者層＋data/ overlay app 層（雙層鐵律一次處理）；`rime-user-collect` 反向回收
- `weasel-version`：交叉驗證安裝、部署記錄與行程三訊號（fork 後綴資源字串需用 pwsh 端）
- `weasel-pack`／`weasel-cloud-install`：安裝檔上雲與自雲端安裝（無建置環境機器用）
- `rime-deploy`／`rime-sync`／`rime-sync-rm`／`rime-purge-deleted` 與 `rime-cloud*`／`rime-google-*` 雲端搬運：語義同 macOS 端，詳見 MANUAL-SQUIRREL.md
- `rime-sync-rm`／`rime-purge-deleted` 的離線窗口由 `rime-hold-quit`／`rime-release-quit` 守住：WeaselServer 結束後，任何應用程式的 TSF 用戶端連線失敗或 WER 自動重啟都會重新拉起伺服器（在終端機按任何鍵即可能觸發），與離線重建競逐同一 LevelDB。主防線是維護旗標 `%APPDATA%\Rime\.maintenance-hold`——fork 的 WeaselServer.cpp 見旗標即退場（逾 10 分鐘自動失效，`/q` 等指令動詞不受約束）；背景看門狗（輪詢、一出現即強制結束，約兩分鐘保險絲）作為未更新建置時的備援

## 部署使用者自訂檔

1. 使用者層：`Rime-Windows/` 的 11 個 yaml＋`lua/` 複製到 `%APPDATA%\Rime`（排除 `installation.yaml`、`user.yaml`）
2. 應用程式層：本倉 `data/` 為 Windows 版的 SharedSupport 鏡像（納管清單與 macOS 的 `Contents/SharedSupport/` 完全對齊——三方案 schema、cangjie5.custom、四個字典檔、opencc 五檔），整包複製到安裝目錄 `data\` 覆蓋 plum 原版；`essay.txt` 僅留底、沿用官方版
3. 複製一律**不保留來源 mtime**（`cp` 不加 `-p`）：mtime 早於 build 時間會使部署靜默跳過
4. 首次安裝後將 `installation.yaml` 的 `installation_id` 改為 `"rime-wujidadi"`
5. 重新部署：`WeaselDeployer.exe /deploy`；以日誌驗證（`%TEMP%\rime.weasel\rime.weasel.*.INFO.*`，找「finished updating schemas: N success, 0 failure」），勿以猜測空等

### userdb 還原（新機）

新機無本機 userdb 時走 restore 路徑（同 A3434 經驗）：

1. 退出 WeaselServer
2. 於 `%APPDATA%\Rime` 執行 `rime_dict_manager.exe --restore <terra_pinyin.userdb.txt 快照路徑>`（工具在 librime `dist_x64\bin`，需將 `rime.dll` 放在 exe 旁）
3. 快照來源：`G:\我的雲端硬碟\Rime\terra_pinyin.userdb.txt`
4. 重啟 WeaselServer

## 疑難排解

- **MSVC 中文註解吞行**：台灣系統字碼頁 CP950 下，MSVC 預設以系統字碼頁讀 UTF-8 原始碼，中文註解尾位元組會與換行符組成假雙位元組字元而吞掉下一行程式碼，產生大量詭異編譯錯誤（C2039、C3927 等）；解法為 `/utf-8` 旗標（librime fork 已修入 CMakeLists，weasel 上游本就有）。上游英文單位元組字碼頁 CI 不會暴露此問題。
- **`NoDefaultCurrentDirectoryInExePath=1`**：Claude Code 等自動化環境會設此變數，cmd 因此不搜尋目前目錄的執行檔，`call build.bat` 等裸名呼叫全數失敗且訊息誤導（「不是內部或外部命令」）；批次腳本開頭 `set NoDefaultCurrentDirectoryInExePath=` 清掉即可。
- **Git Bash 的 MSYS 參數轉換**：`/deploy`、`/q` 等斜線開關會被改寫成路徑（`WeaselDeployer /deploy` 變成開設定視窗、`WeaselServer /q` 變成再開一個伺服器）；改用 `//deploy` 雙斜線或改由 cmd 批次檔呼叫。傳給 cmd 的字串含雙引號時會被轉義成 `\"` 而失效，一律改走批次檔。
- **b2（Boost.Build）找不到 vcvarsall**：Build Tools 版型下 b2 自動偵測失敗（推導出錯誤路徑）；於 `project-config.jam` 明確指定 `using msvc : 14.3 : : <setup>"C:/Program Files (x86)/.../VC/Auxiliary/Build/vcvarsall.bat" ;`——**jam 引號字串內反斜線是跳脫字元，路徑必須用正斜線**。組態探測結果會被快取，修正後要清 `bin.v2` 重跑。
- **勿從 `output\` 直接執行 `WeaselSetup.exe /t`**：它會把登錄 `HKLM\SOFTWARE\Rime\Weasel\WeaselRoot` 註冊為其所在目錄；之後執行 NSIS 安裝檔時，`install.nsi` 的舊版清除段會把 `WeaselRoot` 所指目錄的頂層檔案與 `data\` 全部刪除（不遞迴，`Win32\`、`archives\` 倖存），repo 的 `output\` 即被當舊安裝目錄清空。驗證修補一律改用安裝檔靜默安裝（`/S /T`）；若懷疑登錄已被污染，安裝前先確認 `WeaselRoot` 指向 `C:\Program Files\Rime\weasel-<版本>`。誤中後的復原：`git checkout -- output` 還原版控檔、以 7-Zip 自安裝檔解出 payload 補回 `data\` 等未版控內容（注意解壓會攤平 x64／Win32 同名檔，`rime.dll`、`WinSparkle.dll` 需按架構自 librime dist 與版控重新接入）、重跑 `weasel-build weasel` 補回 PDB。
- **合併上游後 `weasel.props.template` 的版本巨集**：上游 `c681ea8` 已在 `ClCompile` 加入 `VERSION_*`／`PRODUCT_VERSION`／`FILE_VERSION` 定義（與 fork `9ddbb35` 的補丁等價），合併後保留上游那行即可；`ResourceCompile` 區塊的同名定義行必須留著，少了它 RC 會報 `RC2104: undefined keyword or key name: VERSION_MAJOR`。
- **`weasel-drift-check` 對上游資料包變更誤報**：合併上游後若 `output\data\*.yaml` 有變（如 2026-08-22 合入的 `weasel.yaml` 升 `config_version 0.23`、移除 `firefox.exe: inline_preedit` 繞道），安裝前偵測會把現場的舊版當成未納管修改並備份到 `WeaselData-drift-<時間>`；與 `git log -- output/data` 比對確認是上游變更即可刪除備份。
- **`missing input schema: quick5`**：plum preset 的共用 `default.yaml` 列了未打包的 quick5，屬上游資料包不一致，與自訂方案無關，無害。
- **GUI 會改寫 custom 檔**：在小狼毫的「輸入法設定」／「界面風格」按確認後，`default.custom.yaml`／`weasel.custom.yaml` 會被以 `customization:` 區塊格式重寫；現場檔如此屬正常，鏡像維持乾淨版即可。
- **rime_api_console 在無終端機環境掛住**：管線 stdin 的 EOF 送不到，會永久等待輸入；引擎驗證以 `build.bat test` 為準。
- **Google Drive 會給無副檔名的純文字檔補 `.txt`**：本地同步（macOS 與 Windows 客戶端皆然）會把 `留言` 這類無副檔名文字檔自動改成 `留言.txt`，兩平台的留言別名因此指空。發現留言指令讀不到檔案時，先檢查雲端是否又多了 `.txt`，改回無副檔名即可（改名會同步回雲端）。
