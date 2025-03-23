local zhuning = fk.CreateSkill {
  name = "zhuning"
}

Fk:loadTranslationTable{
  ['zhuning'] = '诛佞',
  ['#zhuning'] = '诛佞：交给一名角色任意张牌（标记为“隙”），然后视为使用一张伤害牌',
  ['@@zhuning-inhand'] = '隙',
  ['#zhuning-use'] = '诛佞：你可以视为使用一张不计次数的伤害牌',
  [':zhuning'] = '出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。',
  ['$zhuning1'] = '此剑半丈，当斩奸佞人头！',
  ['$zhuning2'] = '此身八尺，甘为柱国之石。',
}

zhuning:addEffect('active', {
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = "#zhuning",
  can_use = function(self, player)
    if not player:isNude() then
      if player:usedSkillTimes(zhuning.name, Player.HistoryPhase) == 0 then
        return true
      elseif player:usedSkillTimes(zhuning.name, Player.HistoryPhase) == 1 then
        return player:getMark("zhuning-phase") > 0
      end
    end
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, zhuning.name, "", false, player.id, "@@zhuning-inhand")
    if not player.dead then
      local cards = table.filter(U.getUniversalCards(room, "bt", false), function (id)
        return Fk:getCardById(id).is_damage_card
      end)
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = zhuning.name,
        prompt = "#zhuning-use",
        expand_pile = cards,
        bypass_times = true,
        skip = true,
      })
      if use then
        local use = {
          card = Fk:cloneCard(use.card.name),
          from = player.id,
          tos = use.tos,
          extraUse = true,
        }
        use.card.skillName = zhuning.name
        room:useCard(use)
        if not player.dead and not use.damageDealt then
          room:setPlayerMark(player, "zhuning-phase", 1)
        end
      end
    end
  end,
})

return zhuning
