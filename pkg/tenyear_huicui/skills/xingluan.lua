local xingluan = fk.CreateSkill {
  name = "xingluan",
}

Fk:loadTranslationTable{
  ["xingluan"] = "兴乱",
  [":xingluan"] = "每阶段限一次，当你于你出牌阶段使用一张仅指定一名目标角色的牌结算结束后，你可以从牌堆中获得一张点数为6的牌"..
  "（若牌堆中没有点数为6的牌，改为摸6张牌）。",

  ["$xingluan1"] = "大兴兵争，长安当乱。",
  ["$xingluan2"] = "勇猛兴军，乱世当立。",
}

xingluan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingluan.name) and player.phase == Player.Play and
      #data.tos == 1 and player:usedSkillTimes(xingluan.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|6")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, xingluan.name, nil, false, player)
    else
      player:drawCards(6, xingluan.name)
    end
  end,
})

return xingluan
