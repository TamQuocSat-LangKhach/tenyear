local jiesi = fk.CreateSkill{
  name = "jiesi",
}

Fk:loadTranslationTable{
  ["jiesi"] = "捷思",
  [":jiesi"] = "出牌阶段，你可以弃置任意张牌，获得一张牌名字数与弃置牌数相等的牌，若本阶段已以此法获得过此牌名的牌，此技能本阶段失效。",

  ["#jiesi"] = "捷思：弃置任意张牌，获得一张牌名字数与弃牌数相等的牌",

  ["$jiesi1"] = "",
  ["$jiesi2"] = "",
}

jiesi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#jiesi",
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, jiesi.name, player, player)
    if player.dead then return end
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == #effect.cards
    end)
    if #cards == 0 then return end
    local card = Fk:getCardById(table.random(cards))
    if not room:addTableMarkIfNeed(player, "jiesi-phase", card.trueName) then
      room:invalidateSkill(player, jiesi.name, "-phase")
    end
    room:obtainCard(player, card, false, fk.ReasonJustMove, player, jiesi.name)
  end,
})

return jiesi
