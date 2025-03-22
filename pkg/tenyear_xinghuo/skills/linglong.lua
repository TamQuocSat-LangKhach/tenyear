local linglong = fk.CreateSkill {
  name = "ty__linglong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__linglong"] = "玲珑",
  [":ty__linglong"] = "锁定技，若你的装备区里没有防具牌，你视为装备【八卦阵】；若你的装备区里没有坐骑牌，你的手牌上限+2；"..
  "若你的装备区里没有宝物牌，你视为拥有〖奇才〗。若均满足，你使用的【杀】和普通锦囊牌不能被响应。",

  ["$ty__linglong1"] = "我夫所赠之玫，遗香自长存。",
  ["$ty__linglong2"] = "心有玲珑罩，不殇春与秋。",
}

linglong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linglong.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({4, 5, 6, 7}, function(type)
        return #player:getEquipments(type) == 0 and #player:getAvailableEquipSlots(type) > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

local linglong_on_use = function (self, event, target, player, data)
  local room = player.room
  room:broadcastPlaySound("./packages/standard_cards/audio/card/eight_diagram")
  room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
  local skill = Fk.skills["#eight_diagram_skill"]
  skill:use(event, target, player, data)
end
linglong:addEffect(fk.AskForCardUse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linglong.name) and not player:isFakeSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = linglong.name,
    })
  end,
  on_use = linglong_on_use,
})
linglong:addEffect(fk.AskForCardResponse, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(linglong.name) and not player:isFakeSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = linglong.name,
    })
  end,
  on_use = linglong_on_use,
})

linglong:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(linglong.name) and
      #player:getEquipments(Card.SubtypeOffensiveRide) + #player:getEquipments(Card.SubtypeDefensiveRide) == 0 then
      return 2
    end
  end,
})

linglong:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(linglong.name) and #player:getEquipments(Card.SubtypeTreasure) == 0 and
      card and card.type == Card.TypeTrick
  end,
})

return linglong
