local saowei = fk.CreateSkill {
  name = "saowei",
}

Fk:loadTranslationTable{
  ["saowei"] = "扫围",
  [":saowei"] = "当其他角色使用【杀】结算后，若目标角色在你的攻击范围内，你可以将一张“隘”当【杀】对该目标角色使用。"..
  "若此【杀】造成伤害，你获得之。",

  ["@@aishou-inhand"] = "隘",
  ["#saowei-use"] = "扫围：你可以将一张“隘”当【杀】对目标角色使用",

  ["$saowei1"] = "今从王师猎虎，必擒吕布。",
  ["$saowei2"] = "七军围猎，虓虎插翅难逃。",
}

saowei:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(saowei.name) and target ~= player and data.card.trueName == "slash" and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@aishou-inhand") > 0
      end) and
      table.find(data.tos, function(p)
        return player:inMyAttackRange(p) and not p.dead and
          player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@aishou-inhand") > 0
    end)
    local targets = table.filter(data.tos, function(p)
      return player:inMyAttackRange(p) and not p.dead and
        player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
    end)
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = saowei.name,
      prompt = "#saowei-use",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = table.map(targets, Util.IdMapper),
      },
      card_filter = {
        n = 1,
        pattern = tostring(Exppattern{ id = cards }),
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    room:useCard(use)
    if use.damageDealt and not player.dead and room:getCardArea(use.card) == Card.DiscardPile then
      room:obtainCard(player, use.card, true, fk.ReasonJustMove, player, saowei.name)
    end
  end,
})

return saowei
