local dehua = fk.CreateSkill {
  name = "dehua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['dehua'] = '德化',
  ['@$dehua'] = '德化',
  ['#dehua-use'] = '德化：请选择一种伤害牌使用，然后你不能再使用同名手牌',
  ['#dehua_prohibited'] = '德化',
  [':dehua'] = '锁定技，每轮开始时，你选择一种你可使用的伤害牌牌名，视为使用此牌，然后若所有伤害牌均被选择过，则你失去本技能，且本局游戏内伤害牌不计入你的手牌上限；你不能使用与以此法选择过的牌名相同的手牌，且你的手牌上限增加以此法选择过的牌名数量。',
  ['$dehua1'] = '君子怀德，可驱怀土之小人。',
  ['$dehua2'] = '以德与人，福虽未至，祸已远离。',
}

dehua:addEffect(fk.RoundStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(dehua) then
      return false
    end

    local availableNames = player:getTableMark("@$dehua")
    if #availableNames < 1 then
      return false
    end

    local realNames = player.tag["dehuaRealNames"]
    for _, name in ipairs(availableNames) do
      if type(realNames[name]) == "table" then
        table.insertTable(availableNames, realNames[name])
      end
    end

    return table.find(availableNames, function(cardName)
      local card = Fk:cloneCard(cardName)
      card.skillName = dehua.name
      return card.skill:canUse(player, card) and not player:prohibitUse(card)
        and table.find(player.room.alive_players, function (p)
          return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, false)
        end)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local availableNames = player:getTableMark("@$dehua")
    local realNames = player.tag["dehuaRealNames"]
    for i = 1, #availableNames do
      local name = availableNames[i]
      local curRealNames = realNames[name]
      if type(curRealNames) == "table" then
        for j = 1, #curRealNames do
          table.insert(availableNames, j + 1, curRealNames[j])
        end
      end
    end

    local use = room:askToUseVirtualCard(player, {
      pattern = availableNames,
      skill_name = dehua.name,
      prompt = "#dehua-use",
      cancelable = false,
      skip = true,
    })
    if (use or {}).card then
      local names = player:getTableMark("@$dehua")
      table.removeOne(names, use.card.trueName)
      room:setPlayerMark(player, "@$dehua", #names > 0 and names or 0)

      if #player:getTableMark("@$dehua") == 0 then
        room:handleAddLoseSkills(player, "-" .. dehua.name)
        room:setPlayerMark(player, "dehua_keep_damage", 1)
      else
        room:addTableMarkIfNeed(player, "dehuaChosen", use.card.trueName)
      end
    end
  end,
})

dehua:addEffect(fk.EventAcquireSkill, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    return target == player and data == dehua and not player.tag["dehuaRealNames"]
  end,
  on_refresh = function(self, event, target, player, data)
    local names = {}
    local realNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card.is_damage_card and not card.is_derived then
        table.insertIfNeed(names, card.trueName)
        if card.trueName ~= card.name then
          realNames[card.trueName] = realNames[card.trueName] or {}
          table.insertIfNeed(realNames[card.trueName], card.name)
        end
      end
    end

    local room = player.room
    room:setPlayerMark(player, "@$dehua", names)
    player.tag["dehuaRealNames"] = realNames
  end,
})

local dehuaBuff = fk.CreateSkill {
  name = "#dehua_buff"
}
dehuaBuff:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:hasSkill(dehua) and #player:getTableMark("dehuaChosen") or 0
  end,
  exclude_from = function(self, player, card)
    return player:getMark("dehua_keep_damage") > 0 and card.is_damage_card
  end,
})

local dehuaProhibited = fk.CreateSkill {
  name = "#dehua_prohibited"
}
dehuaProhibited:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not player:hasSkill(dehua) then
      return false
    end

    local namesChosen = player:getTableMark("dehuaChosen")
    if type(namesChosen) == "table" and table.contains(namesChosen, card.trueName) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
})

return dehua
