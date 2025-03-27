local aichen = fk.CreateSkill {
  name = "ty__aichen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__aichen"] = "哀尘",
  [":ty__aichen"] = "锁定技，若剩余牌堆牌数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；若剩余牌堆数大于40，你跳过弃牌阶段；"..
  "若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。",

  ["$ty__aichen1"] = "君可负妾，然妾不负君。",
  ["$ty__aichen2"] = "所思所想，皆系陛下。",
}

aichen:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(aichen.name) and #player.room.draw_pile > 80 then
      for _, move in ipairs(data) do
        if move.skillName == "ty__luochong" and move.from == player then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, aichen.name)
  end,
})

aichen:addEffect(fk.EventPhaseChanging, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aichen.name) and #player.room.draw_pile > 40 and
      data.phase == Player.Discard and not data.skipped
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

aichen:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aichen.name) and #player.room.draw_pile < 40 and
      data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
  end,
  on_use = function(self, event, target, player, data)
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    table.insertIfNeed(data.use.disresponsiveList, player)
  end,
})

return aichen
