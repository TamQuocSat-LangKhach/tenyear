local guanchao = fk.CreateSkill {
  name = "guanchao"
}

Fk:loadTranslationTable{
  ['guanchao'] = '观潮',
  ['@@guanchao_ascending-turn'] = '观潮：递增',
  ['@@guanchao_decending-turn'] = '观潮：递减',
  ['@guanchao_ascending-turn'] = '观潮：递增',
  ['@guanchao_decending-turn'] = '观潮：递减',
  [':guanchao'] = '出牌阶段开始时，你可以选择一项直到回合结束：1.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递增，你摸一张牌；2.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递减，你摸一张牌。',
  ['$guanchao1'] = '朝夕之间，可知所进退。',
  ['$guanchao2'] = '月盈，潮起晨暮也；月亏，潮起日半也。',
}

guanchao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(guanchao.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"@@guanchao_ascending-turn", "@@guanchao_decending-turn"},
      skill_name = guanchao.name
    })
    room:setPlayerMark(player, choice, 1)
  end,
})

guanchao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player)
    return target == player and player:usedSkillTimes(guanchao.name, Player.HistoryTurn) > 0 and
      (player:getMark("@@guanchao_ascending-turn") > 0 or 
      player:getMark("@@guanchao_decending-turn") > 0 or
      player:getMark("@guanchao_ascending-turn") > 0 or 
      player:getMark("@guanchao_decending-turn") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@guanchao_ascending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_ascending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
      end
    elseif player:getMark("@@guanchao_decending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_decending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
      end
    elseif player:getMark("@guanchao_ascending-turn") > 0 then
      if data.card.number and data.card.number > player:getMark("@guanchao_ascending-turn") then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
        player:drawCards(1, guanchao.name)
      else
        room:setPlayerMark(player, "@guanchao_ascending-turn", 0)
      end
    elseif player:getMark("@guanchao_decending-turn") > 0 then
      if data.card.number and data.card.number < player:getMark("@guanchao_decending-turn") then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
        player:drawCards(1, guanchao.name)
      else
        room:setPlayerMark(player, "@guanchao_decending-turn", 0)
      end
    end
  end,
})

return guanchao
