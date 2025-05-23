local quanshou = fk.CreateSkill {
  name = "quanshou",
}

Fk:loadTranslationTable{
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数不大于体力上限，你可以令其选择：1.将手牌摸至体力上限（至多摸五张），其于此回合的"..
  "出牌阶段内使用【杀】次数上限-1；2.其于此回合内使用牌被抵消后，你摸一张牌。",

  ["#quanshou-invoke"] = "劝守：是否对 %dest 发动“劝守”，令其选择一项？",
  ["quanshou1"] = "摸牌至体力上限，本回合使用【杀】次数-1",
  ["quanshou2"] = "你本回合使用牌被抵消后，%src摸一张牌",
  ["#quanshou-choice"] = "劝守：选择 %src 令你执行的一项",

  ["$quanshou1"] = "曹军势大，不可刚其锋。",
  ["$quanshou2"] = "持重待守，不战而胜十万雄兵。",
}

quanshou:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quanshou.name) and target:getHandcardNum() <= target.maxHp and
      not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = quanshou.name,
      prompt = "#quanshou-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(target, {
      choices = {"quanshou1", "quanshou2:"..player.id},
      skill_name = quanshou.name,
      prompt = "#quanshou-choice:"..player.id,
    })
    if choice == "quanshou1" then
      room:setPlayerMark(target, "quanshou1-turn", 1)
      local n = math.min(target.maxHp - target:getHandcardNum(), 5)
      if n > 0 then
        target:drawCards(n, quanshou.name)
      end
    else
      room:setPlayerMark(player, "quanshou2-turn", target.id)
    end
  end,
})

quanshou:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.from and player:getMark("quanshou2-turn") == data.from.id and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, quanshou.name)
  end,
})

quanshou:addEffect("targetmod", {
  residue_func = function(self, player, skill2, scope, card)
    if card and card.trueName == "slash" and player:getMark("quanshou1-turn") > 0 and scope == Player.HistoryPhase then
      return -1
    end
  end,
})

return quanshou
