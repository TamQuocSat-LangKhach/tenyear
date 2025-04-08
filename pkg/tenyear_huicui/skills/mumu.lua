local mumu = fk.CreateSkill {
  name = "ty__mumu",
}

Fk:loadTranslationTable{
  ["ty__mumu"] = "穆穆",
  [":ty__mumu"] = "出牌阶段开始时，你可以选择一项：1.弃置一名其他角色装备区里的一张牌，你本回合出牌阶段使用【杀】次数上限+1；"..
  "2.获得一名其他角色装备区里的一张牌，你本回合出牌阶段使用【杀】次数上限-1。",

  ["ty__mumu1"] = "弃置一名角色一张装备，使用【杀】次数+1",
  ["ty__mumu2"] = "获得一名角色一张装备，使用【杀】次数-1",
  ["#ty__mumu1-choose"] = "穆穆：选择一名角色，弃置其装备区里的一张牌",
  ["#ty__mumu2-choose"] = "穆穆：选择一名角色，获得其装备区里的一张牌",

  ["$ty__mumu1"] = "素性贞淑，穆穆春山。",
  ["$ty__mumu2"] = "雍穆融治，吾之所愿。",
}

mumu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mumu.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"ty__mumu1", "ty__mumu2", "Cancel"},
      skill_name = mumu.name,
    })
    if choice ~= "Cancel" then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return #p:getCardIds("e") > 0
      end)
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = mumu.name,
        prompt = "#"..choice.."-choose",
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "e",
      skill_name = mumu.name,
    })
    room:addPlayerMark(player, choice.."-turn", 1)
    if choice == "ty__mumu1" then
      room:throwCard(id, mumu.name, to, player)
    else
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, mumu.name, nil, true, player)
    end
  end,
})

mumu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("ty__mumu1-turn") - player:getMark("ty__mumu2-turn")
    end
  end,
})

return mumu
