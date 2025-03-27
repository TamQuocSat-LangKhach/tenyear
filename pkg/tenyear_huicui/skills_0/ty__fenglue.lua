local ty__fenglue = fk.CreateSkill {
  name = "ty__fenglue"
}

Fk:loadTranslationTable{
  ['ty__fenglue'] = '锋略',
  [':ty__fenglue'] = '出牌阶段限一次，你可以和一名角色拼点。若：你赢，你获得其区域里的两张牌；你与其均没赢，你获得你的拼点牌且此技能视为未发动过；其赢，其获得你拼点的牌。',
  ['$ty__fenglue1'] = '当今敢称贤者，唯袁氏本初一人！',
  ['$ty__fenglue2'] = '冀州宝地，本当贤者居之！',
}

ty__fenglue:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty__fenglue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, ty__fenglue.name)
    local winner = pindian.results[to.id].winner
    if winner == player then
      if to:isAllNude() or player.dead then return end
      local cards = to:getCardIds("hej")
      if #cards > 2 then
        cards = room:askToChooseCards(player, {
          min = 2,
          max = 2,
          target = to,
          flag = "hej",
          skill_name = ty__fenglue.name
        })
      end
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    elseif winner == to then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile and not to.dead then
        room:obtainCard(to, pindian.fromCard, true, fk.ReasonPrey)
      end
    elseif not player.dead then
      if room:getCardArea(pindian.fromCard) == Card.DiscardPile then
        room:obtainCard(player, pindian.fromCard, true, fk.ReasonPrey)
      end
      player:setSkillUseHistory(ty__fenglue.name, 0, Player.HistoryPhase)
    end
  end,
})

return ty__fenglue
