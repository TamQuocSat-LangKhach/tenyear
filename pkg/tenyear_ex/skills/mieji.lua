local mieji = fk.CreateSkill {
  name = "ty_ex__mieji",
}

Fk:loadTranslationTable{
  ["ty_ex__mieji"] = "灭计",
  [":ty_ex__mieji"] = "出牌阶段限一次，你可以将一张武器牌或黑色锦囊牌置于牌堆顶，令一名有手牌的其他角色选择一项：弃置一张锦囊牌；或依次"..
  "弃置两张非锦囊牌。",

  ["#ty_ex__mieji"] = "灭计：将一张武器或黑色锦囊牌置于牌堆顶，令一名角色选择弃一张锦囊牌或弃两张非锦囊牌",
  ["#ty_ex__mieji-discard1"] = "灭计：弃置一张锦囊牌或依次弃置两张非锦囊牌",
  ["#ty_ex__mieji-discard2"] = "灭计：再弃置一张非锦囊牌",

  ["$ty_ex__mieji1"] = "所谓智斗，便是以兑子入局取势，而后成杀。",
  ["$ty_ex__mieji2"] = "欲成大事，当弃则弃，怎可优柔寡断？",
}

mieji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__mieji",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mieji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local card = Fk:getCardById(to_select)
      return (card.type == Card.TypeTrick and card.color == Card.Black) or card.sub_type == Card.SubtypeWeapon
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not to_select:isNude() and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCards({
      ids = effect.cards,
      from = player,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = mieji.name,
    })
    if target.dead then return end
    local card = room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = mieji.name,
      cancelable = false,
      prompt = "#ty_ex__mieji-discard1"
    })
    if Fk:getCardById(card[1]).type ~= Card.TypeTrick and not target.dead then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = mieji.name,
        cancelable = false,
        pattern = ".|.|.|.|.|^trick",
        prompt = "#ty_ex__mieji-discard2",
      })
    end
  end,
})

return mieji
