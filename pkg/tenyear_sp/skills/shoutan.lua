local shoutan = fk.CreateSkill {
  name = "shoutan",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["shoutan"] = "手谈",
  [":shoutan"] = "转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。",

  ["#shoutan-yang"] = "手谈：弃置一张非黑色手牌",
  ["#shoutan-yin"] = "手谈：弃置一张黑色手牌",
  ["#shoutan_yaoyi-yang"] = "手谈：转换至阴状态",
  ["#shoutan_yaoyi-yin"] = "手谈：转换至阳状态",

  ["$shoutan1"] = "对弈博雅，落子珠玑胜无声。",
  ["$shoutan2"] = "弈者无言，手执黑白谈古今。",
}

shoutan:addEffect("active", {
  anim_type = "switch",
  prompt = function(self, player)
    if player:hasSkill("yaoyi") then
      return "#shoutan_yaoyi-"..player:getSwitchSkillState(shoutan.name, false, true)
    else
      return "#shoutan-"..player:getSwitchSkillState(shoutan.name, false, true)
    end
  end,
  card_num = function(self, player)
    if player:hasSkill("yaoyi") then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill("yaoyi") then
      return player:getMark("shoutan_prohibit-phase") == 0
    else
      return player:usedSkillTimes(shoutan.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if player:hasSkill("yaoyi") then
      return false
    elseif #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) then
      if player:getSwitchSkillState(shoutan.name, false) == fk.SwitchYang then
        return Fk:getCardById(to_select).color ~= Card.Black
      else
        return Fk:getCardById(to_select).color == Card.Black
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if not player:hasSkill("yaoyi") then
      room:throwCard(effect.cards, shoutan.name, player, player)
    end
  end,
})

shoutan:addEffect(fk.StartPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("shoutan-phase") < player:usedSkillTimes(shoutan.name, Player.HistoryPhase) then
      room:setPlayerMark(player, "shoutan-phase", player:usedSkillTimes(shoutan.name, Player.HistoryPhase))
      room:setPlayerMark(player, "shoutan_prohibit-phase", 1)
    else
      room:setPlayerMark(player, "shoutan_prohibit-phase", 0)
    end
  end,
})

return shoutan
