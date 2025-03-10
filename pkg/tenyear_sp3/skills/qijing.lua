local qijing = fk.CreateSkill {
  name = "qijing"
}

Fk:loadTranslationTable{
  ['qijing'] = '奇径',
  ['tuoyu1'] = '丰田',
  ['tuoyu2'] = '清渠',
  ['tuoyu3'] = '峻山',
  ['cuixin'] = '摧心',
  ['#qijing-choose'] = '奇径：选择一名角色，你移动座次成为其下家',
  [':qijing'] = '觉醒技，每个回合结束时，若你的手牌副区域均已开发，你减1点体力上限，获得技能“摧心”，然后将座次移动至相邻的两名其他角色之间并执行一个额外回合。',
  ['$qijing1'] = '今神兵于天降，贯奕世之长虹！',
  ['$qijing2'] = '辟罗浮之险径，捣伪汉之黄龙！'
}

qijing:addEffect(fk.TurnEnd, {
  frequency = Skill.Wake,
  priority = 2,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(qijing.name) and player:usedSkillTimes(qijing.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return player:getMark("tuoyu1") > 0 and player:getMark("tuoyu2") > 0 and player:getMark("tuoyu3") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "cuixin", nil, true, false)
    local tos = table.filter(room.alive_players, function (p)
      return p ~= player and p:getNextAlive(true) ~= player
    end)
    if #tos > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#qijing-choose",
        skill_name = qijing.name,
        cancelable = true,
        no_indicate = true,
      })
      if #to > 0 then
        local players = table.simpleClone(room.players)
        table.removeOne(players, player)
        for index, value in ipairs(players) do
          if value.id == to[1]:id() then
            table.insert(players, index + 1, player)
            if player == target and #player:getTableMark("_extra_turn_count") == 0 then
              local x = player.seat
              if x == #players then
                x = -1
              elseif x > index then
                x = x + 1
              end
              room:setBanner("qijing_destroyrulebook", x)
            end
            break
          end
        end
        room.players = players
        local player_circle = {}
        for i = 1, #room.players do
          room.players[i].seat = i
          table.insert(player_circle, room.players[i].id)
        end
        for i = 1, #room.players - 1 do
          room.players[i].next = room.players[i + 1]
        end
        room.players[#room.players].next = room.players[1]
        room:doBroadcastNotify("ArrangeSeats", json.encode(player_circle))
      end
    end
    player:gainAnExtraTurn(true)
  end,
  can_refresh = function(self, event, target, player)
    return player == target and player.room:getBanner("qijing_destroyrulebook") ~= nil
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local index = room:getBanner("qijing_destroyrulebook")

    if index == -1 then
      data.to = room.players[1]
    else
      data.to = room.players[index]
      data.skipRoundPlus = true
    end

    room:setBanner("qijing_destroyrulebook", nil)
  end,
})

return qijing
