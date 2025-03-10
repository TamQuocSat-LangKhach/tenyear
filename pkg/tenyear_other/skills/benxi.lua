local benxi = fk.CreateSkill {
  name = "tycl__benxi"
}

Fk:loadTranslationTable{
  ['tycl__benxi'] = '奔袭',
  ['@tycl__benxi'] = '奔袭',
  ['#tycl__benxi'] = '奔袭: 抽到了已经拥有的技能 %arg，改为对一名角色造成一点伤害',
  [':tycl__benxi'] = '锁定技，转换技，当你失去手牌后，阳：随机念一句含有wuyi的技能台词；阴：获得你上次以此法念出台词的技能直到你下回合开始，若已拥有则改为对一名角色造成一点伤害。',
}

benxi:addEffect(fk.AfterCardsMove, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(benxi.name) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local isYang = player:getSwitchSkillState(benxi.name, true) == fk.SwitchYang

    if isYang then
      local sData = table.random(benxiPool)
      player:chat(string.format("$%s:%d", sData[1], sData[2]))
      room:setPlayerMark(player, "@tycl__benxi", sData[1])
    else
      local skillName = player:getMark("@tycl__benxi")
      if not Fk.skills[skillName] then return end
      if player:hasSkill(skillName, true) then
        local targets = table.map(room.alive_players, Util.IdMapper)
        local tgt = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#tycl__benxi:::" .. skillName,
          skill_name = benxi.name
        })[1]
        room:damage{
          from = player,
          to = room:getPlayerById(tgt),
          damage = 1,
          skillName = benxi.name,
        }
      else
        room:handleAddLoseSkills(player, skillName)
        room:addTableMark(player, benxi.name, skillName)
      end
    end
  end,
})

benxi:addEffect(fk.TurnStart, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(benxi.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, table.concat(
      table.map(player:getMark(benxi.name), function(str)
        return "-" .. str
      end), "|"))
    room:setPlayerMark(player, benxi.name, 0)
  end,
})

return benxi
