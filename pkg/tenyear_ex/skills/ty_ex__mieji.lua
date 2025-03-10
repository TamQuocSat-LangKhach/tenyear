local ty_ex__mieji = fk.CreateSkill {
  name = "ty_ex__mieji"
}

Fk:loadTranslationTable{
  ['ty_ex__mieji'] = '灭计',
  ['#ty_ex__mieji-discard1'] = '灭计：弃置一张锦囊牌或依次弃置两张非锦囊牌',
  ['#ty_ex__mieji-discard2'] = '灭计：再弃置一张非锦囊牌',
  [':ty_ex__mieji'] = '出牌阶段限一次，你可以将一张武器牌或黑色锦囊牌置于牌堆顶，令一名有手牌的其他角色弃置一张牌。若其弃置的牌不为锦囊牌，其弃置一张非锦囊牌（没有则不弃）。',
  ['$ty_ex__mieji1'] = '所谓智斗，便是以兑子入局取势，而后成杀。',
  ['$ty_ex__mieji2'] = '欲成大事，当弃则弃，怎可优柔寡断？',
}

ty_ex__mieji:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__mieji.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and ((card.type == Card.TypeTrick and card.color == Card.Black) or card.sub_type == Card.SubtypeWeapon)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = ty_ex__mieji.name,
      moveVisible = true,
    })
    local ids = room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".",
      prompt = "#ty_ex__mieji-discard1"
    })
    if #ids > 0 and Fk:getCardById(ids[1]).type ~= Card.TypeTrick then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        pattern = ".|.|.|.|.|basic,equip",
        prompt = "#ty_ex__mieji-discard2"
      })
    end
  end,
})

return ty_ex__mieji
