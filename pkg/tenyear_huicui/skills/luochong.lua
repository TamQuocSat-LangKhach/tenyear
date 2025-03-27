local luochong = fk.CreateSkill {
  name = "ty__luochong",
  dynamic_desc = function(self, player)
    if player:getMark(self.name) == 4 then
      return "dummyskill"
    else
      return "ty__luochong_inner:"..(4 - player:getMark(self.name))
    end
  end,
}

Fk:loadTranslationTable{
  ["ty__luochong"] = "落宠",
  [":ty__luochong"] = "每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",

  [":ty__luochong_inner"] = "每轮开始时，你可以弃置任意名角色区域内共计至多{1}张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",

  ["#ty__luochong-choose"] = "落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）",
  ["#ty__luochong-discard"] = "落宠：弃置 %dest 至多%arg张牌",

  ["$ty__luochong1"] = "陛下独宠她人，奈何雨露不均。",
  ["$ty__luochong2"] = "妾贵于佳丽，然宠不及三千。",
}

luochong:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(luochong.name) and player:getMark(luochong.name) < 4 and
      table.find(player.room.alive_players, function (p)
        return not p:isAllNude()
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(luochong.name)
    local n = total
    local to, targets, cards
    local luochong_map = {}
    repeat
      targets = table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end)
      if #targets == 0 then break end
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty__luochong-choose:::" ..total..":"..n,
        skill_name = luochong.name,
      })
      if #targets == 0 then break end
      to = targets[1]
      if to == player then
        cards = table.filter(player:getCardIds("hej"), function (id)
          return not player:prohibitDiscard(id)
        end)
        cards = room:askToCards(player, {
          min_num = 1,
          max_num = n,
          include_equip = true,
          skill_name = luochong.name,
          pattern = tostring(Exppattern{ id = cards }),
          prompt = "#ty__luochong-discard::"..player.id..":"..n,
          cancelable = false,
          expand_pile = player:getCardIds("j"),
        })
      else
        cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = n,
          flag = "hej",
          skill_name = luochong.name,
          prompt = "#ty__luochong-discard::"..to.id..":"..n,
        })
      end
      room:throwCard(cards, luochong.name, to, player)
      luochong_map[to.id] = (luochong_map[to.id] or 0) + #cards
      n = n - #cards
      if n <= 0 then break end
    until total == 0 or player.dead
    for _, value in pairs(luochong_map) do
      if value > 2 and not player.dead then
        room:addPlayerMark(player, luochong.name, 1)
        return
      end
    end
  end,
})

luochong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, luochong.name, 0)
end)

return luochong
