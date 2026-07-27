# 注音方案改良待辦

> [!DATE] 時間：2026-07-27T16:53:35+08:00

- 從底層重做獨立的注音輸入法方案（脫離 terra_pinyin 基底），目標是可推廣給社群的完整方案——大工程，另案處理。
- librime fork 層的簡拼排序工程：讓多音節簡拼解不被少音節解整批壓後。
  - 現況：`abbrev` 的信度懲罰是 librime 寫死的 log(0.5)（`calculus.cc` 的 `kAbbreviationPenalty`），
    候選以「信度＋詞頻」排序（`dictionary.cc` 的 `compare_chunk_by_head_element`）；
    「ㄒㄧㄧ」的「ㄒㄧ|ㄧ」兩音節解先天比「ㄒ|ㄧ|ㄧ」三音節解少吃一次懲罰，
    三字詞（下一頁、消炎藥等）整批沉到約第 31 名（預設頁距下第 4 頁）之後。
  - 可能方向：懲罰值可設定化，或對「符號數等於音節數」的切分加權。
  - 方案層無解：把省調或簡拼改成其他拼寫型別（fuzz、derive）會觸發 syllabifier 的路徑裁剪，
    將其中一種切分整邊砍掉，已驗證並否決。
  - 即時緩解（毋須改碼）：輸入分隔符 `'` 強制切分（三字詞登頂）、翻頁、為字加聲調。

## 既有方案調查（2026-07-27）

Rime 官方及主要社群的注音方案現況，作為獨立方案立案時的參考基準：

- 官方 [rime/rime-bopomofo](https://github.com/rime/rime-bopomofo)（51 星）：
  與本機現行方案同構——表面注音、內部經拼寫演算轉為拼音、共用朙月拼音詞庫；
  按鍵內外不一致、簡拼規則殘缺（即本檔所修諸問題的上游根源），維護基本停滯。
- [oniondelta/Onion_Rime_Files](https://github.com/oniondelta/Onion_Rime_Files)（洋蔥方案，319 星、685 commits）：
  目前最成熟活躍的台灣社群注音，持續更新六年以上，
  含純注音、Plus（詞庫多 70 萬條）、mixin、雙拼等變體，輸入邏輯接近手機注音；
  代價是重度依賴 librime-lua 且鎖定特定 librime 版本（建議 1.11.2 Nightly＋librime-lua #200），
  與自建 librime 1.17.0 fork 整合需另做相容性功課；
  另有社群衍生的 [Onion-Rime-Bopomo-Revised](https://github.com/sunsun8170/Onion-Rime-Bopomo-Revised)。
- [andy0130tw/iridium-bpmf](https://github.com/andy0130tw/iridium-bpmf)（銥注音，60 星）：
  小而美，2023 年起改用小麥注音（McBopomofo）詞庫，
  支援亂序輸入自動修正（如「ㄋㄠㄧˇ」→「ㄋㄧㄠˇ」）、聲調可省略，設計想法與本計畫目標最接近。
- [imper0502/rime-double-bopomo](https://github.com/imper0502/rime-double-bopomo)（雙碼注音，97 星）：
  雙拼式方案，不需學漢語拼音，屬另一路線。
- [davix/rime-bopomofo-native](https://github.com/davix/rime-bopomofo-native)（1 星）：
  「原生注音碼表、不經拼音轉換」的概念驗證，碼表由地球拼音轉化而來，無人採用。

結論：「原生設計（不經拼音內轉）、詞庫紮實、簡拼與排序行為完善」的標準化注音方案仍是空缺；
立案時可借鑑洋蔥的 Lua 功能設計，與銥的 McBopomofo 詞庫及亂序修正。
