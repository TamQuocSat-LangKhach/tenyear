local cixiao = fk.CreateSkill {
  name = "cixiao"
}

Fk:loadTranslationTable{
  ['cixiao'] = '慈孝',
  ['panshi'] = '叛弑',
  ['#cixiao-discard'] = '慈孝：可弃置一张牌来转移“义子”标记',
  ['#cixiao-choose'] = '慈孝：可选择一名其他角色，令其获得“义子”标记',
  [':cixiao'] = '准备阶段，若场上没有“义子”，你可以令一名其他角色获得一个“义子”标记；若场上有“义子”标记，你可以弃置一张牌移动“义子”标记。拥有“义子”标记的角色获得技能〖叛弑〗。',
  ['$cixiao1'] = '吾儿奉先，天下无敌！',
  ['$cixiao2'] = '父慈子孝，义理为先！'
}

cixiao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cixiao.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p) return p ~= player and not p:hasSkill("panshi", true) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.alive_players, function (p) return p:hasSkill("panshi", true) end) then
      local tos, id = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        targets = table.map(table.filter(room.alive_players, function (p)
          return p ~= player and not p:hasSkill("panshi", true) end), Util.IdMapper),
        min_target_num = 1,
        max_target_num = 1,
        pattern = ".",
        prompt = "#cixiao-discard",
        skill_name = cixiao.name,
        cancelable = true
      })
      if #tos > 0 and id then
        event:setCostData(self, {tos = tos, cards = {id} })
        return true
      end
    else
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#cixiao-choose",
        skill_name = cixiao.name,
        cancelable = true
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = room:getPlayerById(cost_data.tos[1])
    if cost_data.cards then
      room:throwCard(cost_data.cards, cixiao.name, player, player)
    end
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "-panshi", nil, true, false)
    end
    room:handleAddLoseSkills(to, "panshi", nil, true, false)
  end,
})

return cixiao
