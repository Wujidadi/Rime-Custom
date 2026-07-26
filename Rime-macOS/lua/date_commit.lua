-- 讓日期時間觸發碼可用 Enter 上屏目前高亮的候選
-- 掛載方式：lua_processor@*date_commit，須置於編輯器（express_editor／fluency_editor）之前
-- 僅攔截 date_translator 的觸發碼，其餘情境維持 Enter 的預設行為（上屏原始編碼）

local codes = {
  ["/date"] = true,
  ["/time"] = true,
  ["/week"] = true,
  ["/dt"] = true,
  ["/ts"] = true,
}

local kRejected, kAccepted, kNoop = 0, 1, 2

local function processor(key_event, env)
  if key_event:release() or key_event:ctrl() or key_event:alt() or key_event:shift() then
    return kNoop
  end
  -- 0xff0d 為 Return，0xff8d 為數字鍵盤 Enter
  local keycode = key_event.keycode
  if keycode ~= 0xff0d and keycode ~= 0xff8d then
    return kNoop
  end
  local context = env.engine.context
  if not context:has_menu() or not codes[context.input] then
    return kNoop
  end
  context:confirm_current_selection()
  context:commit()
  return kAccepted
end

return processor
