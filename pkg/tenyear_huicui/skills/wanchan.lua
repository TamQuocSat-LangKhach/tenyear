local wanchan = fk.CreateSkill {
  name = "wanchan",
}

Fk:loadTranslationTable{
  ["wanchan"] = "宛蝉",
  [":wanchan"] = "出牌阶段限一次，你可以选择一名角色，令其摸X张牌（X为你与其距离且最多为3），然后其可以使用一张基本牌或普通锦囊牌"..
  "（无距离次数限制），且目标相邻的角色也成为此牌的目标。",

  ["#wanchan"] = "宛蝉：选择一名角色，令其摸牌并可以使用一张基本牌或普通锦囊牌",
  ["#wanchan-use"] = "宛蝉：你可以使用一张基本牌或普通锦囊牌（无距离次数限制且额外指定目标相邻角色）",

  ["$wanchan1"] = "发如蝉翼轻扬，君王如何不偏爱？",
  ["$wanchan2"] = "轻挽云鬓，可栖玉蝉。",
}

wanchan:addEffect("active", {
  anim_type = "support",
  prompt = "#wanchan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(wanchan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local x = player:distanceTo(target)
    if x > 0 then
      room:drawCards(target, math.min(3, x), wanchan.name)
      if target.dead then return end
    end
    local use = room:askToPlayCard(target, {
      pattern = ".|.|.|.|.|basic,normal_trick",
      skill_name = wanchan.name,
      prompt = "#wanchan-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        bypass_distances = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      use.extra_data = use.extra_data or {}
      use.extra_data.wanchan = true
      room:useCard(use)
    end
  end,
})

wanchan:addEffect(fk.AfterCardTargetDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.wanchan
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({bypass_distances = true, bypass_times = true}), function (p)
      return table.find(data.tos, function (q)
        return p:getNextAlive() == q or q:getNextAlive() == p
      end) ~= nil
    end)
    for _, p in ipairs(targets) do
      room:doIndicate(player, {p})
      data:addTarget(p)
    end
  end,
})

return wanchan
