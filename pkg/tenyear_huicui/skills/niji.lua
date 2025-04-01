local niji = fk.CreateSkill {
  name = "niji",
}

Fk:loadTranslationTable{
  ["niji"] = "逆击",
  [":niji"] = "当你成为非装备牌的目标后，你可以摸一张牌，本回合结束阶段弃置这些牌，弃置前你可以先使用其中一张牌。",

  ["@@niji-inhand-turn"] = "逆击",
  ["#niji-invoke"] = "逆击：你可以摸一张牌，本回合结束阶段弃置之",
  ["#niji-use"] = "逆击：即将弃置所有“逆击”牌，你可以先使用其中一张牌",

  ["$niji1"] = "善战者后动，一击而毙敌。",
  ["$niji2"] = "我所善者，后发制人尔。",
}

niji:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niji.name) and data.card.type ~= Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = niji.name,
      prompt = "#niji-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, niji.name, nil, "@@niji-inhand-turn")
  end,
})

niji:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@niji-inhand-turn") > 0
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@niji-inhand-turn") > 0
    end)
    room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = niji.name,
      prompt = "#niji-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
      }
    })
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id):getMark("@@niji-inhand-turn") > 0 and
        not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:delay(800)
      room:throwCard(cards, niji.name, player, player)
    end
  end,
})

return niji
