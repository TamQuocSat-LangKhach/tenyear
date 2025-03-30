local jilei = fk.CreateSkill {
  name = "ty__jilei",
}

Fk:loadTranslationTable{
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",

  ["#ty__jilei-invoke"] = "鸡肋：声明一种类别，%dest 不能使用、打出、弃置该类别的手牌直到其下回合开始",
  ["@ty__jilei"] = "鸡肋",

  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
}

jilei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilei.name) and data.from and not data.from.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"basic", "trick", "equip", "Cancel"},
      skill_name = jilei.name,
      prompt = "#ty__jilei-invoke::"..data.from.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.from}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:addTableMarkIfNeed(data.from, "@ty__jilei", choice.."_char")
  end,
})

jilei:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "@ty__jilei", 0)
  end,
})

jilei:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char")
  end,
})

return jilei
