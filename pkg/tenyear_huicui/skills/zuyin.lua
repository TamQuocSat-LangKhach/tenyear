local zuyin = fk.CreateSkill {
  name = "zuyin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zuyin"] = "祖荫",
  [":zuyin"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若“研作”牌中：没有同名牌，令〖研作〗出牌阶段可发动次数+1（至多为3），"..
  "然后你从牌堆或弃牌堆中将一张同名牌置为“研作”牌；有同名牌，令此牌无效并移去“研作”牌中全部同名牌。",

  ["$zuyin1"] = "蒙先祖之佑，未觉春秋之寒。",
  ["$zuyin2"] = "我本孺子，幸得父祖遮风挡雨。",
}

zuyin:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zuyin.name) and data.from ~= player and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getPile("yanzuo"), function(id)
      return Fk:getCardById(id).trueName == data.card.trueName
    end)
    if #cards > 0 then
      data.use.nullifiedTargets = table.simpleClone(room.alive_players)
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zuyin.name, nil, true, player)
    else
      if player:hasSkill("yanzuo", true) and player:getMark(zuyin.name) < 2 then
        room:addPlayerMark(player, zuyin.name, 1)
      end
      cards = room:getCardsFromPileByRule(data.card.trueName, 1, "allPiles")
      if #cards > 0 then
        player:addToPile("yanzuo", cards, true, zuyin.name, player)
      end
    end
  end,
})

return zuyin
