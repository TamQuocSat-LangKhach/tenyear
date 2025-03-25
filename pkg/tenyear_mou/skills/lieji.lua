local lieji = fk.CreateSkill {
  name = "lieji",
}

Fk:loadTranslationTable{
  ["lieji"] = "烈计",
  [":lieji"] = "当你使用锦囊牌结算结束后，你可以令你当前手牌中的所有伤害牌的伤害基数+1直到回合结束。",

  ["#lieji-invoke"] = "烈计：令当前手牌中的伤害牌伤害+1直到回合结束！",
  ["@leiji-inhand-turn"] = "伤害+",

  ["$lieji1"] = "计烈如火，敌将休想逃脱！",
  ["$lieji2"] = "计如风，势如火，烧尽万千逆贼！"
}

lieji:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeTrick and player:hasSkill(lieji.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lieji.name,
      prompt = "#lieji-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.is_damage_card then
        room:addCardMark(card, "@leiji-inhand-turn")
      end
    end
  end,
})

lieji:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@leiji-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + data.card:getMark("@leiji-inhand-turn")
  end,
})

return lieji
