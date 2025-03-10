local panshi = fk.CreateSkill {
  name = "panshi"
}

Fk:loadTranslationTable{
  ['panshi'] = '叛弑',
  ['#panshi-give-to'] = '叛弑：必须选择一张手牌交给%src',
  ['#panshi-give'] = '叛弑：必须选择一张手牌交给一名拥有〖慈孝〗的角色',
  ['@@panshi_son'] = '义子',
  [':panshi'] = '锁定技，准备阶段，你将一张手牌交给拥有技能〖慈孝〗的角色；你于出牌阶段使用的【杀】对其造成伤害时，此伤害+1且你于造成伤害后结束出牌阶段。',
}

panshi:addEffect({fk.EventPhaseStart, fk.DamageCaused, fk.Damage}, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(panshi) and player == target then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start and table.find(player.room.alive_players, function (p)
          return p ~= player and p:hasSkill(cixiao, true) end)
      elseif event == fk.DamageCaused or event == fk.Damage then
        return player.phase == Player.Play and data.to:hasSkill(cixiao, true) and
          data.card and data.card.trueName =="slash" and not data.chain
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, panshi.name, "negative")
      player:broadcastSkillInvoke(panshi.name)
      local fathers = table.filter(room.alive_players, function (p) return p ~= player and p:hasSkill(cixiao, true) end)
      if #fathers == 1 then
        room:doIndicate(player.id, {fathers[1].id})
        if player:isKongcheng() then return false end
        local card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          pattern = ".|.|.|hand",
          prompt = "#panshi-give-to:"..fathers[1].id,
          skill_name = panshi.name
        })
        if #card > 0 then
          room:obtainCard(fathers[1].id, card[1], false, fk.ReasonGive)
        end
      else
        local tos, id = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 1,
          max_card_num = 1,
          targets = table.map(fathers, Util.IdMapper),
          min_target_num = 1,
          max_target_num = 1,
          pattern = ".|.|.|hand",
          prompt = "#panshi-give",
          skill_name = panshi.name
        })
        if #tos > 0 and id then
          room:obtainCard(tos[1], id, false, fk.ReasonGive)
        end
      end
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, panshi.name, "offensive")
      player:broadcastSkillInvoke(panshi.name)
      data.damage = data.damage + 1
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, panshi.name, "negative")
      player:broadcastSkillInvoke(panshi.name)
      player:endPlayPhase()
    end
  end,
})

panshi:addEffect({fk.EventLoseSkill, fk.EventAcquireSkill}, {
  can_refresh = function(self, event, target, player, data)
    return player == target and data == panshi
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@panshi_son", event == fk.EventAcquireSkill and 1 or 0)
  end,
})

return panshi
