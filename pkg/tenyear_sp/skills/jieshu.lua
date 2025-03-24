local jieshu = fk.CreateSkill {
  name = "jieshu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jieshu"] = "解术",
  [":jieshu"] = "锁定技，非圆环内点数的牌不计入你的手牌上限。你使用或打出牌时，若满足圆环进度点数，你摸一张牌。",

  ["$jieshu1"] = "累乘除以成九数者，可以加减解之。",
  ["$jieshu2"] = "数有其理，见筹一可知沙数。",
}

--- 返回下一个能点亮圆环的点数
---@return integer[]
local function getCircleProceed(value)
  local all_points = value.all
  local ok_points = value.ok
  local all_len = #all_points
  -- 若没有点亮的就全部都满足
  if #ok_points == 0 then return all_points end
  -- 若全部点亮了返回空表
  if #ok_points == all_len then return Util.DummyTable end

  local function c(idx)
    if idx == 0 then idx = all_len end
    if idx == all_len + 1 then idx = 1 end
    return idx
  end

  -- 否则，显示相邻的，逻辑上要构成循环
  local ok_map = {}
  for _, v in ipairs(ok_points) do ok_map[v] = true end
  local start_idx, end_idx
  for i, v in ipairs(all_points) do
    -- 前一个不亮，这个是左端
    if ok_map[v] and not ok_map[all_points[c(i-1)]] then
      start_idx = i
    end
    -- 后一个不亮，这个是右端
    if ok_map[v] and not ok_map[all_points[c(i+1)]] then
      end_idx = i
    end
  end

  start_idx = c(start_idx - 1)
  end_idx = c(end_idx + 1)

  if start_idx == end_idx then
    return { all_points[start_idx] }
  else
    return { all_points[start_idx], all_points[end_idx] }
  end
end

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jieshu.name) and player:getMark("@[geyuan]") ~= 0 then
      return table.contains(getCircleProceed(player:getMark("@[geyuan]")), data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jieshu.name)
  end,
}

jieshu:addEffect(fk.CardUsing, spec)
jieshu:addEffect(fk.CardResponding, spec)

jieshu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    if player:hasSkill(jieshu.name) then
      local mark = player:getMark("@[geyuan]")
      local all = Util.DummyTable
      if type(mark) == "table" and mark.all then all = mark.all end
      return not table.contains(all, card.number)
    end
  end,
})

return jieshu
