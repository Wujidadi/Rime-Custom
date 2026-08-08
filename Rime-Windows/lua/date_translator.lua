-- 日期時間快速輸入（掛載方式：lua_translator@*date_translator）
-- 觸發碼：/date（日期）、/time（時間）、/week（星期）、/dt（日期時間）、/ts（Unix 時間戳）
-- 三個方案的 recognizer 均已有「/ 開頭＋英文字母」的 punct 模式，故無須另加 pattern

local weekdays = { "日", "一", "二", "三", "四", "五", "六" }

local function translator(input, seg)
  if input:sub(1, 1) ~= "/" then return end
  local now = os.time()
  local d = os.date("*t", now)
  if input == "/date" then
    yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d", now), "〔日期〕"))
    yield(Candidate("date", seg.start, seg._end, string.format("%d年%d月%d日", d.year, d.month, d.day), "〔日期〕"))
    yield(Candidate("date", seg.start, seg._end, string.format("%d月%d日", d.month, d.day), "〔日期〕"))
    yield(Candidate("date", seg.start, seg._end, os.date("%Y%m%d", now), "〔日期〕"))
  elseif input == "/time" then
    yield(Candidate("time", seg.start, seg._end, os.date("%H:%M", now), "〔時間〕"))
    yield(Candidate("time", seg.start, seg._end, os.date("%H:%M:%S", now), "〔時間〕"))
  elseif input == "/week" then
    local w = weekdays[d.wday]
    yield(Candidate("week", seg.start, seg._end, "星期" .. w, "〔星期〕"))
    -- 星期日另有「天」的慣用說法，單獨補列
    if d.wday == 1 then
      yield(Candidate("week", seg.start, seg._end, "星期天", "〔星期〕"))
    end
    yield(Candidate("week", seg.start, seg._end, "週" .. w, "〔星期〕"))
    yield(Candidate("week", seg.start, seg._end, "禮拜" .. w, "〔星期〕"))
    if d.wday == 1 then
      yield(Candidate("week", seg.start, seg._end, "禮拜天", "〔星期〕"))
    end
  elseif input == "/dt" then
    yield(Candidate("datetime", seg.start, seg._end, os.date("%Y-%m-%d %H:%M:%S", now), "〔日期時間〕"))
    -- ISO 8601 格式，時區偏移由 %z 的 +0800 轉為 +08:00
    local tz = os.date("%z", now)
    yield(Candidate("datetime", seg.start, seg._end,
      os.date("%Y-%m-%dT%H:%M:%S", now) .. tz:sub(1, 3) .. ":" .. tz:sub(4, 5), "〔日期時間〕"))
  elseif input == "/ts" then
    yield(Candidate("timestamp", seg.start, seg._end, tostring(now), "〔時間戳（秒）〕"))
  end
end

return translator
