local liangxiu = fk.CreateSkill {
  name = "liangxiu",
}

Fk:loadTranslationTable{
  ["liangxiu"] = "良秀",
  [":liangxiu"] = "出牌阶段，你可以弃置两张不同类型的牌，然后将两张与你弃置牌类别均不同的牌交给任意角色（每种类别每阶段限一次）。",

  ["#liangxiu"] = "良秀：弃置两张类别不同的牌，分配两张另一类别的牌",

  ["$liangxiu1"] = "君子性谦，不夺人之爱。",
  ["$liangxiu2"] = "蒯门多隽秀，吾居其末。",
}

liangxiu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#liangxiu",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return #player:getTableMark("liangxiu-phase") < 3
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 and not player:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      else
        if Fk:getCardById(to_select).type ~= Fk:getCardById(selected[1]).type then
          local types = {"basic", "trick", "equip"}
          table.removeOne(types, Fk:getCardById(to_select):getTypeString())
          table.removeOne(types, Fk:getCardById(selected[1]):getTypeString())
          return not table.contains(player:getTableMark("liangxiu-phase"), types[1])
        end
      end
    end
  end,

  on_use = function(self, room, effect)
    local player = effect.from
    local types = {"basic", "trick", "equip"}
    for i = 1, 2, 1 do
      table.removeOne(types, Fk:getCardById(effect.cards[i]):getTypeString())
    end
    room:throwCard(effect.cards, liangxiu.name, player, player)
    if not player.dead then
      room:addTableMark(player, "liangxiu-phase", types[1])
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. types[1], 2)
      if #cards > 0 then
        room:askToYiji(player, {
          cards = cards,
          targets = nil,
          skill_name = liangxiu.name,
          min_num = #cards,
          max_num = #cards,
          expand_pile = cards,
        })
      end
    end
  end,
})

return liangxiu
