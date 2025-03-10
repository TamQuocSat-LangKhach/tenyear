local wanchan = fk.CreateSkill {
  name = "wanchan"
}

Fk:loadTranslationTable{
  ['wanchan'] = '宛蝉',
  ['#wanchan-active'] = '发动 宛蝉，选择一名角色，令其摸牌并可以使用牌',
  ['#wanchan-use'] = '宛蝉：你可以使用手牌中的一张基本牌或普通锦囊牌',
  ['#wanchan_trigger'] = '宛蝉',
  [':wanchan'] = '出牌阶段限一次，你可以选择一名角色，令其摸X张牌（X为你与其距离且最多为3），然后其可以使用一张基本牌或普通锦囊牌（无距离和次数限制），且你令与此牌的目标相邻的角色也成为此牌的目标。',
  ['$wanchan1'] = '发如蝉翼轻扬，君王如何不偏爱？',
  ['$wanchan2'] = '轻挽云鬓，可栖玉蝉。',
}

-- 主动技能
wanchan:addEffect('active', {
  anim_type = "support",
  prompt = "#wanchan-active",
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
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local x = player:distanceTo(target)
    if x > 0 then
      room:drawCards(target, math.min(3, x), wanchan.name)
      if target.dead then return false end
    end
    local use = room:askToUseCard(target, {
      pattern = ".|.|.|.|.|basic,normal_trick",
      skill_name = wanchan.name,
      prompt = "#wanchan-use",
      cancelable = true,
      extra_data = { bypass_times = true, bypass_distances = true }
    })
    if use then
      use.extra_data.wanchan_source = player.id
      room:useCard(use)
    end
  end,
})

-- 触发技能
wanchan:addEffect(fk.AfterCardTargetDeclared, {
  main_skill = wanchan,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wanchan.name) and data.extra_data and data.extra_data.wanchan_source == player.id then
      local room = player.room
      local tos = table.map(TargetGroup:getRealTargets(data.tos), Util.Id2PlayerMapper)
      local targets = room:getUseExtraTargets(data, true)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        for _, p in ipairs(tos) do
          if p:getNextAlive() == to or to:getNextAlive() == p then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(TargetGroup:getRealTargets(data.tos), Util.Id2PlayerMapper)
    local targets = room:getUseExtraTargets(data, true)
    targets = table.filter(targets, function (pid)
      local to = room:getPlayerById(pid)
      for _, p in ipairs(tos) do
        if p:getNextAlive() == to or to:getNextAlive() == p then
          return true
        end
      end
    end)
    if #targets > 0 then
      room:doIndicate(player.id, targets)
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    room:sendLog{
      type = "#AddTargetsBySkill",
      from = data.from,
      to = targets,
      arg = wanchan.name,
      arg2 = data.card:toLogString()
    }
    for _, pid in ipairs(targets) do
      table.insert(data.tos, {pid})
    end
  end,
})

return wanchan
