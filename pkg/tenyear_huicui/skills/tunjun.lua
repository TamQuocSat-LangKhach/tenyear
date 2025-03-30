local tunjun = fk.CreateSkill {
  name = "tunjun",
}

Fk:loadTranslationTable{
  ["tunjun"] = "屯军",
  [":tunjun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌（不替换原有装备，X为你发动〖掠命〗的次数）。",

  ["#tunjun"] = "屯军：选择一名角色，令其随机使用%arg张装备牌",

  ["$tunjun1"] = "得封侯爵，屯军弘农。",
  ["$tunjun2"] = "屯军弘农，养精蓄锐。",
}

tunjun:addEffect("active", {
  anim_type = "support",
  prompt = function (self, player)
    return "#tunjun:::"..player:usedSkillTimes("lueming", Player.HistoryGame)
  end,
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(tunjun.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lueming", Player.HistoryGame) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:hasEmptyEquipSlot()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = player:usedSkillTimes("lueming", Player.HistoryGame)
    for _ = 1, n, 1 do
      if target.dead then break end
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id, true)
        if card.type == Card.TypeEquip and target:hasEmptyEquipSlot(card.sub_type) and target:canUseTo(card, target) then
          table.insertIfNeed(cards, id)
        end
      end
      if #cards > 0 then
        room:useCard({
          from = target,
          tos = {target},
          card = Fk:getCardById(table.random(cards)),
        })
      else
        break
      end
    end
  end,
})

return tunjun
