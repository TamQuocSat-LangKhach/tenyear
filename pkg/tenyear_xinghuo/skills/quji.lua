local quji = fk.CreateSkill {
  name = "ty_ex__quji",
}

Fk:loadTranslationTable{
  ["ty_ex__quji"] = "去疾",
  [":ty_ex__quji"] = "出牌阶段限一次，若你已受伤，你可以弃置X张牌，令至多X名已受伤的角色各回复1点体力（X为你已损失的体力值），"..
  "然后其中仍受伤的角色各摸一张牌。若弃置的牌中包含黑色牌，你失去1点体力。",

  ["#ty_ex__quji"] = "去疾：弃%arg张牌，令至多等量角色回复体力，仍受伤的角色各摸一张牌，若弃置黑色牌你失去1点体力",

  ["$ty_ex__quji1"] = "",
  ["$ty_ex__quji2"] = "",
}

quji:addEffect("active", {
  anim_type = "support",
  card_num = function(self, player)
    return player:getLostHp()
  end,
  min_target_num = 1,
  prompt = function(self, player)
    return "#ty_ex__quji:::"..player:getLostHp()
  end,
  can_use = function(self, player)
    return player:isWounded() and player:usedSkillTimes(quji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getLostHp() and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected < player:getLostHp() and to_select:isWounded()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local loseHp = table.find(effect.cards, function(id)
      return Fk:getCardById(id).color == Card.Black
    end)
    room:throwCard(effect.cards, quji.name, player, player)
    local tos = effect.tos
    room:sortByAction(tos)
    for _, to in ipairs(tos) do
      if not to.dead and to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = quji.name,
        }
      end
    end
    for _, to in ipairs(tos) do
      if not to.dead and to:isWounded() then
        to:drawCards(1, quji.name)
      end
    end
    if loseHp and not player.dead then
      room:loseHp(player, 1, quji.name)
    end
  end,
})

return quji
