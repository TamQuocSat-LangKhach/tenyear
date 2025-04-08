local tianjiang = fk.CreateSkill {
  name = "tianjiang",
}

Fk:loadTranslationTable{
  ["tianjiang"] = "天匠",
  [":tianjiang"] = "游戏开始时，将牌堆中随机两张不同副类别的装备牌置入你的装备区。出牌阶段，你可以将装备区里的一张牌移动至"..
  "其他角色的装备区（可替换原装备），若你移动的是〖铸刃〗打造的装备，你摸两张牌。",

  ["#tianjiang"] = "天匠：将一张装备移给其他角色（替换原装备），若移动“铸刃”装备，你摸两张牌",

  ["$tianjiang1"] = "巧夺天工，超凡脱俗。",
  ["$tianjiang2"] = "天赐匠法，精心锤炼。",
}

tianjiang:addEffect("active", {
  anim_type = "support",
  prompt = "#tianjiang",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player:getCardIds("e") > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("e"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and #selected_cards == 1 and to_select:canMoveCardIntoEquip(selected_cards[1])
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardIntoEquip(target, effect.cards, tianjiang.name, true, player)
    if not player.dead and table.contains({
      "red_spear",
      "quenched_blade",
      "poisonous_dagger",
      "water_sword",
      "thunder_blade",
    }, card.name) then
      player:drawCards(2, tianjiang.name)
    end
  end,
})

tianjiang:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianjiang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local equipMap = {}
    for _, id in ipairs(room.draw_pile) do
      local sub_type = Fk:getCardById(id).sub_type
      if Fk:getCardById(id).type == Card.TypeEquip and player:canMoveCardIntoEquip(id, false) then
        local list = equipMap[tostring(sub_type)] or {}
        table.insert(list, id)
        equipMap[tostring(sub_type)] = list
      end
    end
    local sub_types = {}
    for k, _ in pairs(equipMap) do
      table.insert(sub_types, k)
    end
    sub_types = table.random(sub_types, 2)
    local cards = {}
    for _, sub_type in ipairs(sub_types) do
      table.insert(cards, table.random(equipMap[sub_type]))
    end
    if #cards > 0 then
      room:moveCardIntoEquip(player, cards, tianjiang.name, false, player)
    end
  end,
})

return tianjiang
