local bazhan = fk.CreateSkill {
  name = "bazhan"
}

Fk:loadTranslationTable{
  ['bazhan'] = '把盏',
  ['#bazhan-Yang'] = '把盏（阳）：选择一至两张手牌，交给一名其他角色',
  ['#bazhan-Yin'] = '把盏（阴）：选择一名有手牌的其他角色，获得其一至两张手牌',
  ['#bazhan-support'] = '把盏：可以选择令 %dest 回复1点体力或复原武将牌',
  [':bazhan'] = '转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。然后若这些牌里包括【酒】或<font color=>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。',
  ['$bazhan1'] = '此酒，当配将军。',
  ['$bazhan2'] = '这杯酒，敬于将军。',
}

bazhan:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "bazhan",
  prompt = function (self, player)
    return player:getSwitchSkillState("bazhan", false) == fk.SwitchYang and "#bazhan-Yang" or "#bazhan-Yin"
  end,
  target_num = 1,
  max_card_num = function (self, player)
    return (player:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function (self, player)
    return (player:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(bazhan.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < self:getMaxCardNum(player) and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum(player) and #selected == 0 and to_select.id ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(bazhan.name, true) == fk.SwitchYang

    local to_check = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_check, effect.cards)
      room:obtainCard(target.id, to_check, false, fk.ReasonGive, player.id)
    elseif not isYang and not target:isKongcheng() then
      to_check = room:askToChooseCards(player, {
        min_num = 1,
        max_num = 2,
        targets = {target},
        pattern = "h",
        skill_name = bazhan.name
      })
      room:obtainCard(player, to_check, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_check, function (id)
      return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart
    end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = bazhan.name,
          prompt = "#bazhan-support::" .. target.id
        })
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = bazhan.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
})

return bazhan
