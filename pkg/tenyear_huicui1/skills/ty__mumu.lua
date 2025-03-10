local ty__mumu = fk.CreateSkill {
  name = "ty__mumu"
}

Fk:loadTranslationTable{
  ['ty__mumu'] = '穆穆',
  ['ty__mumu1'] = '弃置一名角色一张装备，你出牌阶段使用【杀】次数+1',
  ['ty__mumu2'] = '获得一名角色一张装备，你出牌阶段使用【杀】次数-1',
  [':ty__mumu'] = '出牌阶段开始时，你可以选择一项：1.弃置一名其他角色装备区里的一张牌，你本回合出牌阶段使用【杀】次数上限+1；2.获得一名其他角色装备区里的一张牌，你本回合出牌阶段使用【杀】次数上限-1。',
  ['$ty__mumu1'] = '素性贞淑，穆穆春山。',
  ['$ty__mumu2'] = '雍穆融治，吾之所愿。',
}

ty__mumu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__mumu.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local choices = {"Cancel", "ty__mumu1", "ty__mumu2"}
    local choice = room:askToChoice(player, {choices = choices, skill_name = ty__mumu.name})
    if choice ~= "Cancel" then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return #p:getCardIds("e") > 0 end), Util.IdMapper)
      local to = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1, skill_name = ty__mumu.name, prompt = "#"..choice.."-choose"})
      if #to > 0 then
        event:setCostData(skill, {choice, to[1].id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = event:getCostData(skill)
    local to = room:getPlayerById(data[2])
    local id = room:askToChooseCard(player, {target = to, flag = "e", skill_name = ty__mumu.name})
    room:setPlayerMark(player, data[1].."-turn", 1)
    if data[1] == "ty__mumu1" then
      room:throwCard({id}, ty__mumu.name, to, player)
    else
      room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, ty__mumu.name, nil, true, player.id)
    end
  end,
})

ty__mumu:addEffect('targetmod', {
  residue_func = function(self, player, skill2, scope)
    if skill2.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if player:getMark("ty__mumu1-turn") > 0 then
        return 1
      end
      if player:getMark("ty__mumu2-turn") > 0 then
        return -1
      end
    end
  end,
})

return ty__mumu
