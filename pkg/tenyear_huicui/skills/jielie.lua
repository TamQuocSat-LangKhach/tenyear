local jielie = fk.CreateSkill {
  name = "jielie",
}

Fk:loadTranslationTable{
  ["jielie"] = "节烈",
  [":jielie"] = "当你受到除你或〖抗歌〗角色以外的角色造成的伤害时，你可以防止此伤害并选择一种花色，失去X点体力，令〖抗歌〗角色从弃牌堆中"..
  "随机获得X张此花色的牌（X为伤害值）。",

  ["#jielie-choice"] = "节烈：是否选择一种花色，失去体力防止你受到的伤害？",
  ["#jielie-invoke"] = "节烈：是否失去体力防止你受到的伤害，令 %dest 获得你选择花色的牌？",

  ["$jielie1"] = "节烈之妇，从一而终也！",
  ["$jielie2"] = "清闲贞静，守节整齐。",
}

jielie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jielie.name) and data.from and
      data.from ~= player and data.from.id ~= player:getMark("kangge")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#jielie-choice"
    if player:getMark("kangge") ~= 0 and not room:getPlayerById(player:getMark("kangge")).dead then
      prompt = "#jielie-invoke::"..player:getMark("kangge")
    end
    local choice = room:askToChoice(player, {
      choices = {"log_spade", "log_heart", "log_club", "log_diamond", "Cancel"},
      skill_name = jielie.name,
      prompt = prompt,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = prompt == "#jielie-choice" and {} or {player:getMark("kangge")}, choice = string.sub(choice, 5)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = event:getCostData(self).choice
    local to
    if player:getMark("kangge") ~= 0 then
      to = room:getPlayerById(player:getMark("kangge"))
    end
    local n = data.damage
    data:preventDamage()
    room:loseHp(player, n, jielie.name)
    if to and not to.dead then
      room:setPlayerMark(player, "@kangge", to.general)
      local cards = room:getCardsFromPileByRule(".|.|"..suit, n, "discardPile")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, jielie.name, nil, false, player)
      end
    end
  end,
})

return jielie
