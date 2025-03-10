local zhishi = fk.CreateSkill {
  name = "zhishi"
}

Fk:loadTranslationTable{
  ['zhishi'] = '指誓',
  ['jiping_li'] = '疠',
  ['#zhishi-choose'] = '指誓：选择一名角色，当其成为【杀】的目标后或进入濒死状态时，你可以移去“疠”令其摸牌',
  ['#zhishi-invoke'] = '指誓：你可以移去任意张“疠”，令 %dest 摸等量的牌',
  ['@@zhishi'] = '指誓',
  [':zhishi'] = '结束阶段，你可以选择一名角色，直到你下回合开始，该角色成为【杀】的目标后或进入濒死状态时，你可以移去任意张“疠”，令其摸等量的牌。',
  ['$zhishi1'] = '嚼指为誓，誓杀国贼！',
  ['$zhishi2'] = '心怀汉恩，断指相随。',
}

zhishi:addEffect({fk.EventPhaseStart, fk.TargetConfirmed, fk.EnterDying}, {
  global = false,
  can_trigger = function(self, event, target, player)
    if player:hasSkill(skill.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return player:getMark(skill.name) == target.id and not target.dead and
          ((event == fk.TargetConfirmed and data.card.trueName == "slash") or event == fk.EnterDying) and
          #player:getPile("jiping_li") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player)
    if event == fk.EventPhaseStart then
      local to = player.room:askToChoosePlayers(player, {
        targets = table.map(player.room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#zhishi-choose",
        skill_name = skill.name,
        cancelable = true
      })
      if #to > 0 then
        event:setCostData(skill, to[1])
        return true
      end
    else
      local cards = player.room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        include_equip = false,
        pattern = ".|.|.|jiping_li",
        prompt = "#zhishi-invoke::"..target.id,
        skill_name = "jiping_li"
      })
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(event:getCostData(skill))
      room:setPlayerMark(to, "@@zhishi", 1)
      room:setPlayerMark(player, skill.name, to.id)
    else
      room:doIndicate(player.id, {target.id})
      local cards = table.simpleClone(event:getCostData(skill))
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true, player.id)
      if not target.dead then
        target:drawCards(#cards, skill.name)
      end
    end
  end,
})

zhishi:addEffect({fk.TurnStart, fk.Death}, {
  global = false,
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark(skill.name) ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(player:getMark(skill.name))
    if not to.dead then
      room:setPlayerMark(to, "@@zhishi", 0)
    end
    room:setPlayerMark(player, skill.name, 0)
  end,
})

return zhishi
