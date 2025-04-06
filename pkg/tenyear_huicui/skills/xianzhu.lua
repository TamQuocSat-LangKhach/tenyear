local xianzhu = fk.CreateSkill {
  name = "xianzhu",
}

Fk:loadTranslationTable{
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级<a href=':siege_engine'>【大攻车】</a>（每个【大攻车】最多升级5次）。",

  ["xianzhu1"] = "无视距离和防具",
  ["xianzhu2"] = "可指定目标+1",
  ["xianzhu3"] = "造成伤害后弃牌数+1",
  ["#xianzhu-choice"] = "陷筑：选择【大攻车】使用【杀】的增益效果",

  ["$xianzhu1"] = "敌垒已陷，当长驱直入！",
  ["$xianzhu2"] = "舍命陷登，击蛟蟒于狂澜！",
}

xianzhu:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianzhu.name) and
      data.card and data.card.trueName == "slash" and
      table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        local card = Fk:getCardById(id)
        return card.name == "siege_engine" and
          (card:getMark("xianzhu1") + card:getMark("xianzhu2") + card:getMark("xianzhu3")) < 5
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getEquipments(Card.SubtypeTreasure)) do
      local card = Fk:getCardById(id)
      if card.name == "siege_engine" then
        local choices = {"xianzhu2", "xianzhu3"}
        if card:getMark("xianzhu1") == 0 then
          table.insert(choices, 1, "xianzhu1")
        end
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = xianzhu.name,
          prompt = "#xianzhu-choice",
          all_choices = {"xianzhu1", "xianzhu2", "xianzhu3"},
        })
        room:sendLog{
          type = "#Choice",
          from = player.id,
          arg = choice,
          toast = true,
        }
        room:addCardMark(card, choice, 1)
      end
    end
  end,
})

return xianzhu
