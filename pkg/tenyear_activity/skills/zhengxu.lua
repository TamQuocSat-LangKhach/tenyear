local zhengxu = fk.CreateSkill {
  name = "zhengxu"
}

Fk:loadTranslationTable{
  ['zhengxu'] = '正序',
  ['#zhengxu1-invoke'] = '正序：你可以防止你受到的伤害',
  ['#zhengxu_trigger'] = '正序',
  ['#zhengxu2-invoke'] = '正序：你可以摸%arg张牌',
  [':zhengxu'] = '每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，你可以摸等量的牌。',
  ['$zhengxu1'] = '陛下怜子无序，此取祸之道。',
  ['$zhengxu2'] = '古语有云，上尊而下卑。',
}

-- Effect for the first part of zhengxu
zhengxu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhengxu.name) and player:getMark("zhengxu1-turn") > 0 and
      player:usedSkillTimes(zhengxu.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhengxu.name,
      prompt = "#zhengxu1-invoke"
    })
  end,
  on_use = Util.TrueFunc,

  can_refresh = function(self, event, target, player)
    for _, move in ipairs(target) do
      if move.from == player.id and player:usedSkillTimes(zhengxu.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
})

-- Effect for the second part of zhengxu
zhengxu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if player:hasSkill(zhengxu.name) and player:getMark("zhengxu2-turn") > 0 and player:usedSkillTimes(zhengxu.name, Player.HistoryTurn) == 0 then
      event:setCostData(self, 0)
      for _, move in ipairs(target) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local cost_data = event:getCostData(self)
              event:setCostData(self, cost_data + 1)
            end
          end
        end
      end
      return event:getCostData(self) > 0
    end
  end,
  on_trigger = function(self, event, target, player)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhengxu.name,
      prompt = "#zhengxu2-invoke:::"..event:getCostData(self)
    })
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(self)
    player:drawCards(cost_data, zhengxu.name)
  end,

  can_refresh = function(self, event, target, player)
    return target == player and player:usedSkillTimes(zhengxu.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
})

return zhengxu
