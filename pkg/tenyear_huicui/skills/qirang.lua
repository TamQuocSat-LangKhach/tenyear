local qirang = fk.CreateSkill{
  name = "ty__qirang",
}

Fk:loadTranslationTable{
  ["ty__qirang"] = "祈禳",
  [":ty__qirang"] = "当你使用装备牌时，你可以从牌堆获得一张锦囊牌，本回合使用此牌可以额外指定一个目标。",

  ["@@ty__qirang-inhand-turn"] = "祈禳",
  ["#ty__qirang-choose"] = "祈禳：你可以为%arg额外指定一个目标",

  ["$ty__qirang1"] = "禳除煞星，祈愿皎月。",
  ["$ty__qirang2"] = "禳灾消祸，祈运绵久。",
}

qirang:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qirang.name) and data.card.type == Card.TypeEquip
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qirang.name, nil, false, player,
        Fk:getCardById(cards[1]):isCommonTrick() and "@@ty__qirang-inhand-turn" or "")
    end
  end,
})

qirang:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@ty__qirang-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__qirang = player
  end,
})

qirang:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.ty__qirang == player and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = qirang.name,
      prompt = "#ty__qirang-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return qirang
