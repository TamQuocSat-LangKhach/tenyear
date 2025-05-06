local yuhua = fk.CreateSkill{
  name = "ty__yuhua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__yuhua"] = "羽化",
  [":ty__yuhua"] = "锁定技，你的非基本牌不计入手牌上限；结束阶段，若你的手牌数大于体力上限，你观看牌堆顶一张牌，置于牌堆顶或牌堆底。",

  ["$ty__yuhua1"] = "飘然若仙，翠羽明珠。",
  ["$ty__yuhua2"] = "仙姿玉质，翠羽明垱。",
}

yuhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuhua.name) and player.phase == Player.Finish and
      player:getHandcardNum() > player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, {
      cards = room:getNCards(1),
    })
  end,
})

yuhua:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(yuhua.name) and card.type ~= Card.TypeBasic
  end,
})

return yuhua
