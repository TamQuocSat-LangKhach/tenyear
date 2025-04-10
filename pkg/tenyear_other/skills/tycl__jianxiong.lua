local jianxiong = fk.CreateSkill {
  name = "tycl__jianxiong",
}

Fk:loadTranslationTable{
  ["tycl__jianxiong"] = "奸雄",
  [":tycl__jianxiong"] = "当你受到伤害后，你可以摸一张牌，并获得造成伤害的牌。当你发动此技能后，摸牌数+1（至多为5）。",

  ["$tycl__jianxiong"] = "宁教我负天下人休教天下人负我！",
}

jianxiong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(jianxiong.name, Player.HistoryGame), 5)
    player:drawCards(n, jianxiong.name)
    if not player.dead and data.card and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, jianxiong.name)
    end
  end,
})

return jianxiong
