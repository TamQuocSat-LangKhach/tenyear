local ty__luochong = fk.CreateSkill {
  name = "ty__luochong",
  dynamic_desc = function(self, player)
    return "ty__luochong_inner:" .. tostring(4 - player:getMark(ty__luochong.name))
  end,
}

Fk:loadTranslationTable{
  ['ty__luochong'] = '落宠',
  ['#ty__luochong-choose'] = '落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）',
  [':ty__luochong'] = '每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。',
  ['$ty__luochong1'] = '陛下独宠她人，奈何雨露不均。',
  ['$ty__luochong2'] = '妾贵于佳丽，然宠不及三千。',
}

ty__luochong:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty__luochong) and player:getMark(ty__luochong.name) < 4 and
      not table.every(player.room.alive_players, function (p) return p:isAllNude() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(ty__luochong.name)
    local n = total
    local to, targets, cards
    local luochong_map = {}
    repeat
      targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then break end
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty__luochong-choose:::" .. tostring(total) .. ":" .. tostring(n),
        skill_name = ty__luochong.name
      })
      if #targets == 0 then break end
      to = room:getPlayerById(targets[1])
      cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = n,
        flag = "hej",
        skill_name = ty__luochong.name
      })
      room:throwCard(cards, ty__luochong.name, to, player)
      luochong_map[to.id] = (luochong_map[to.id] or 0) + #cards
      n = n - #cards
      if n <= 0 then break end
    until total == 0 or player.dead
    for _, value in pairs(luochong_map) do
      if value > 2 then
        room:addPlayerMark(player, ty__luochong.name, 1)
        break
      end
    end
  end,
})

ty__luochong:addEffect('on_lose', {
  on_lose = function (skill, player)
    player.room:setPlayerMark(player, ty__luochong.name, 0)
  end,
})

return ty__luochong
