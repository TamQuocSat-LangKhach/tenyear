local ty__linglong = fk.CreateSkill {
  name = "ty__linglong"
}

Fk:loadTranslationTable{
  ['ty__linglong'] = '玲珑',
  [':ty__linglong'] = '锁定技，若你的装备区里没有防具牌，你视为装备【八卦阵】；若你的装备区里没有坐骑牌，你的手牌上限+2；若你的装备区里没有宝物牌，你视为拥有〖奇才〗。若均满足，你使用的【杀】和普通锦囊牌不能被响应。',
  ['$ty__linglong1'] = '我夫所赠之玫，遗香自长存。',
  ['$ty__linglong2'] = '心有玲珑罩，不殇春与秋。',
}

-- Trigger Skill Effects
ty__linglong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__linglong) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}, function(type)
        return #player:getEquipments(type) == 0 and #player:getAvailableEquipSlots(type) > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
  end,
})

ty__linglong:addEffect(fk.BeforeCardsMove, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__linglong) and player:getEquipment(Card.SubtypeArmor) and not player:getEquipment(Card.SubtypeTreasure) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.proposer ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.proposer ~= player.id then
        local move_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor then
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = move_info
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = ty__linglong.name,
      }
    end
  end,
})

ty__linglong:addEffect(fk.AskForCardUse, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__linglong) and not player:isFakeSkill(ty__linglong) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and #player:getAvailableEquipSlots(Card.SubtypeArmor) > 0 and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, { skill_name = "#eight_diagram_skill", prompt = data.prompt }) then return false end
    room:broadcastPlaySound("./packages/standard_cards/audio/card/eight_diagram")
    room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
    local judgeData = {
      who = player,
      reason = "eight_diagram",
      pattern = ".|.|heart,diamond",
    }
    room:judge(judgeData)
    if judgeData.card.color == Card.Red then
      data.result = {
        from = player.id,
        card = Fk:cloneCard('jink'),
      }
      data.result.card.skillName = "eight_diagram"
      data.result.card.skillName = ty__linglong.name

      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
    end
  end,
})

-- Max Cards Skill Effect
ty__linglong:addEffect('maxcards', {
  name = "#ty__linglong_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ty__linglong) and
      player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 2
    end
    return 0
  end,
})

-- Target Mod Skill Effect
ty__linglong:addEffect('targetmod', {
  name = "#ty__linglong_targetmod",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(ty__linglong) and player:getEquipment(Card.SubtypeTreasure) == nil
      and card and card.type == Card.TypeTrick
  end,
})

return ty__linglong
