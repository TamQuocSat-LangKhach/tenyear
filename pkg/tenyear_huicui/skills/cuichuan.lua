local cuichuan = fk.CreateSkill {
  name = "cuichuan",
}

Fk:loadTranslationTable{
  ["cuichuan"] = "榱椽",
  [":cuichuan"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，从牌堆中将一张随机装备牌置入其装备区空位，你摸X张牌（X为其装备区牌数）。"..
  "若其装备区内的牌因此达到4张或以上，你失去〖榱椽〗并获得〖佐谏〗，然后令其在此回合结束后获得一个额外回合。",

  ["#cuichuan"] = "榱椽：弃一张手牌，将随机装备置入一名角色的装备区",

  ["$cuichuan1"] = "老臣在，必不使吴垒倾颓。",
  ["$cuichuan2"] = "舍老朽之躯，擎广厦之柱。",
}

cuichuan:addEffect("active", {
  anim_type = "support",
  prompt = "#cuichuan",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(cuichuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select:hasEmptyEquipSlot()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, cuichuan.name, player, player)
    if target.dead or not target:hasEmptyEquipSlot() then return end
    local types = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure,
    }
    local cards = {}
    for i = 1, #room.draw_pile do
      local card = Fk:getCardById(room.draw_pile[i])
      for _, type in ipairs(types) do
        if card.sub_type == type and target:hasEmptyEquipSlot(type) then
          table.insert(cards, room.draw_pile[i])
        end
      end
    end
    if #cards > 0 then
      room:moveCardIntoEquip(target, {table.random(cards)}, cuichuan.name, false, player)
    end
    if player.dead then return end
    local n = #target:getCardIds("e")
    if n > 0 then
      player:drawCards(n, cuichuan.name)
    end
    if #cards > 0 and n > 3 then
      room:handleAddLoseSkills(player, "-cuichuan|zuojian")
      target:gainAnExtraTurn(true)
    end
  end,
})

return cuichuan
