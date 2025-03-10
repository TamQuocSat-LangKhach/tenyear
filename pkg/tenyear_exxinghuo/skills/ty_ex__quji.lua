local ty_ex__quji = fk.CreateSkill {
  name = "ty_ex__quji"
}

Fk:loadTranslationTable{
  ['ty_ex__quji'] = '去疾',
  [':ty_ex__quji'] = '出牌阶段限一次，若你已受伤，你可以弃置X张牌，令至多X名已受伤的角色各回复1点体力（X为你已损失的体力值），然后其中仍受伤的角色各摸一张牌。若弃置的牌中包含黑色牌，你失去1点体力。',
  ['$ty_ex__quji1'] = '待补充',
  ['$ty_ex__quji2'] = '待补充',
}

ty_ex__quji:addEffect('active', {
  anim_type = "support",
  card_num = function (player)
    return player:getLostHp()
  end,
  min_target_num = 1,
  can_use = function(self, player)
    return player:isWounded() and player:usedSkillTimes(ty_ex__quji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getLostHp() and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected < player:getLostHp() and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local loseHp = table.find(effect.cards, function(id) return Fk:getCardById(id).color == Card.Black end)
    room:throwCard(effect.cards, ty_ex__quji.name, player, player)
    local tos = effect.tos
    room:sortPlayersByAction(tos)
    for _, pid in ipairs(tos) do
      local to = room:getPlayerById(pid)
      if not to.dead and to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = ty_ex__quji.name
        })
      end
    end
    for _, pid in ipairs(tos) do
      local to = room:getPlayerById(pid)
      if not to.dead and to:isWounded() then
        to:drawCards(1, ty_ex__quji.name)
      end
    end
    if loseHp and not player.dead then
      room:loseHp(player, 1, ty_ex__quji.name)
    end
  end,
})

return ty_ex__quji
