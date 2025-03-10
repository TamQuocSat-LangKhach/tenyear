local zhenrao = fk.CreateSkill {
  name = "zhenrao"
}

Fk:loadTranslationTable{
  ['zhenrao'] = '震扰',
  ['#zhenrao-invoke'] = '是否发动 震扰，对%dest造成1点伤害',
  ['#zhenrao-choose'] = '是否发动 震扰，对其中手牌数大于你的1名角色造成1点伤害',
  [':zhenrao'] = '每回合对每名角色限一次，当你使用牌指定第一个目标后，或其他角色使用牌指定你为目标后，你可以选择手牌数大于你的其中一个目标或使用者，对其造成1点伤害。',
  ['$zhenrao1'] = '此病需静养，怎堪兵戈铁马之扰。',
  ['$zhenrao2'] = '孤值有疾，竟为文家小儿所扰。',
}

zhenrao:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zhenrao.name) then return false end
    if target == player then
      if not data.firstTarget then return false end
      local tos = AimGroup:getAllTargets(data.tos)
      local targets = {}
      local mark = player:getTableMark("zhenrao-turn")
      for _, p in ipairs(player.room.alive_players) do
        if p:getHandcardNum() > player:getHandcardNum() and
          table.contains(tos, p.id) and not table.contains(mark, p.id) then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    else
      if data.to == player.id and not target.dead and player:getHandcardNum() < target:getHandcardNum() and
        not table.contains(player:getTableMark("zhenrao-turn"), target.id) then
        event:setCostData(self, {target.id})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.simpleClone(event:getCostData(self))
    local room = player.room
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = zhenrao.name,
        prompt = "#zhenrao-invoke::" .. targets[1]
      }) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets[1])
        return true
      end
    else
      local chosenPlayers = room:askToChoosePlayers(player, {
        targets = {room:getPlayerById(id) for id in pairs(targets)},
        min_num = 1,
        max_num = 1,
        prompt = "#zhenrao-choose",
        skill_name = zhenrao.name,
      })
      if #chosenPlayers > 0 then
        event:setCostData(self, chosenPlayers[1].id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "zhenrao-turn", event:getCostData(self))
    room:damage{
      from = player,
      to = room:getPlayerById(event:getCostData(self)),
      damage = 1,
      skillName = zhenrao.name,
    }
  end,
})

return zhenrao
