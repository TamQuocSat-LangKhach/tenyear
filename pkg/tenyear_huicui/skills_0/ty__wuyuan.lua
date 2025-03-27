local ty__wuyuan = fk.CreateSkill {
  name = "ty__wuyuan"
}

Fk:loadTranslationTable{
  ['ty__wuyuan'] = '武缘',
  ['#ty__wuyuan'] = '武缘：将一张【杀】交给一名角色，你回复1点体力并与其各摸一张牌',
  [':ty__wuyuan'] = '出牌阶段限一次，你可以将一张【杀】交给一名其他角色，然后你回复1点体力并与其各摸一张牌；若此【杀】为：红色，其回复1点体力；属性【杀】，其多摸一张牌。',
  ['$ty__wuyuan1'] = '生为关氏之妇，虽死亦不悔。',
  ['$ty__wuyuan2'] = '我夫关长生，乃盖世之英雄。',
}

ty__wuyuan:addEffect('active', {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__wuyuan",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__wuyuan.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, ty__wuyuan.name, nil, true, player.id)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty__wuyuan.name
      })
    end
    if not player.dead then
      player:drawCards(1, ty__wuyuan.name)
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = ty__wuyuan.name
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, ty__wuyuan.name)
    end
  end,
})

return ty__wuyuan
