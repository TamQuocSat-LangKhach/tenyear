local jinjing = fk.CreateSkill {
  name = "jinjing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jinjing"] = "金睛",
  [":jinjing"] = "锁定技，其他角色的手牌对你可见。",
}

jinjing:addEffect("visibility", {
  card_visible = function(self, player, card)
    if player:hasSkill(jinjing.name) and Fk:currentRoom():getCardArea(card) == Card.PlayerHand then
      return true
    end
  end
})

return jinjing
