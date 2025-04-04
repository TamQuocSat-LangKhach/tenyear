local bazhan = fk.CreateSkill {
  name = "bazhan",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "若其中包括【酒】或<font color='red'>♥</font>牌，你可以令获得牌的角色回复1点体力或复原武将牌。",

  ["#bazhan-yang"] = "把盏：交给一名其他角色至多两张手牌",
  ["#bazhan-yin"] = "把盏：获得一名其他角色至多两张手牌",
  ["#bazhan-support"] = "把盏：你可以令 %dest 回复1点体力或复原武将牌",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
}

bazhan:addEffect("active", {
  anim_type = "switch",
  prompt = function (self, player)
    return "#bazhan-"..player:getSwitchSkillState(bazhan.name, false, true)
  end,
  min_card_num = function (self, player)
    return (player:getSwitchSkillState(bazhan.name, false) == fk.SwitchYang) and 1 or 0
  end,
  max_card_num = function (self, player)
    return (player:getSwitchSkillState(bazhan.name, false) == fk.SwitchYang) and 2 or 0
  end,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(bazhan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < self:getMaxCardNum(player) and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum(player) and #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local isYang = player:getSwitchSkillState(bazhan.name, true) == fk.SwitchYang

    local cards = effect.cards
    if isYang then
      room:obtainCard(target, cards, false, fk.ReasonGive, player, bazhan.name)
    elseif not isYang and not target:isKongcheng() then
      cards = room:askToChooseCards(player, {
        skill_name = bazhan.name,
        min = 1,
        max = 2,
        target = target,
        flag = "h",
      })
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, bazhan.name)
      target = player
    end
    if not player.dead and not target.dead and
      table.find(cards, function (id)
        return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart
      end) then
      local choices = {"Cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = bazhan.name,
          prompt = "#bazhan-support::"..target.id,
        })
        if choice == "recover" then
          room:recover{
            who = target,
            num = 1,
            recoverBy = player,
            skillName = bazhan.name,
          }
        else
          if not target.faceup then
            target:turnOver()
          end
          if target.chained and not target.dead then
            target:setChainState(false)
          end
        end
      end
    end
  end,
})

return bazhan
