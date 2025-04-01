local zhengxu = fk.CreateSkill {
  name = "zhengxu",
}

Fk:loadTranslationTable{
  ["zhengxu"] = "正序",
  [":zhengxu"] = "每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，"..
  "你可以摸等量的牌。",

  ["#zhengxu1-invoke"] = "正序：你可以防止你受到的伤害",
  ["#zhengxu2-invoke"] = "正序：你可以摸%arg张牌",

  ["$zhengxu1"] = "陛下怜子无序，此取祸之道。",
  ["$zhengxu2"] = "古语有云，上尊而下卑。",
}

zhengxu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengxu.name) and
      player:getMark("zhengxu1-turn") > 0 and
      player:usedEffectTimes(zhengxu.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhengxu.name,
      prompt = "#zhengxu1-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

zhengxu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhengxu.name) and player:getMark("zhengxu2-turn") > 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhengxu.name,
      prompt = "#zhengxu2-invoke:::"..event:getCostData(self).choice,
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, zhengxu.name)
  end,

  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and player:usedEffectTimes(zhengxu.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
})

zhengxu:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedEffectTimes("#zhengxu_2_trig", Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
})

return zhengxu
