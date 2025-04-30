
local lingse = fk.CreateSkill {
  name = "lingse",
}

Fk:loadTranslationTable{
  ["lingse"] = "令色",
  [":lingse"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，然后随机获得其两张此类别的牌，若不足两张，其视为对你使用一张【杀】，"..
  "若此【杀】造成伤害，此技能视为未发动过。",

  ["#lingse"] = "令色：交给一名角色一张牌，获得其两张同类别牌，若不足两张则视为对你使用【杀】",

  ["$lingse1"] = "陛下尚唤咱家一声阿耶，你怎得张不开嘴？",
  ["$lingse2"] = "这宫里的水深的很，你呀，把握不住！",
}

lingse:addEffect("active", {
  anim_type = "control",
  prompt = "#lingse",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lingse.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, lingse.name)
    if player.dead or target.dead then return end
    local cards = table.filter(target:getCardIds("he"), function (id)
      return Fk:getCardById(id).type == Fk:getCardById(effect.cards[1]).type
    end)
    if #cards > 0 then
      cards = table.random(cards, 2)
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, lingse.name)
      if player.dead or target.dead then return end
    end
    if #cards < 2 then
      local use = room:useVirtualCard("slash", nil, target, player, lingse.name)
      if use and use.damageDealt then
        player:setSkillUseHistory(lingse.name, 0, Player.HistoryPhase)
      end
    end
  end,
})

return lingse
