local yinlu = fk.CreateSkill {
  name = "yinlu",
}

Fk:loadTranslationTable{
  ["yinlu"] = "引路",
  [":yinlu"] = "游戏开始时，你令三名角色依次获得以下一个标记：“乐泉”、“藿溪”、“瘴气”，然后你获得一个“芸香”。<br>"..
  "准备阶段，你可以移动一个标记；有标记的角色死亡时，你可以移动其标记。拥有标记的角色获得对应的效果：<br>"..
  "乐泉：结束阶段，你可以弃置一张<font color='red'>♦</font>牌，然后回复1点体力；<br>"..
  "藿溪：结束阶段，你可以弃置一张<font color='red'>♥</font>牌，然后摸两张牌；<br>"..
  "瘴气：结束阶段，你需要弃置一张♠牌，否则失去1点体力；<br>"..
  "芸香：结束阶段，你可以弃置一张♣牌，获得一个“芸香”；当你受到伤害时，你可以移去所有“芸香”并防止等量的伤害。",

  ["@@yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["@@yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["@@yinlu3"] = "♠瘴气",
  ["@@yinlu4"] = "♣芸香",
  ["@yunxiang"] = "芸香",

  ["#yinlu1-invoke"] = "<font color='red'>♦</font>乐泉：你可以弃置一张<font color='red'>♦</font>牌，回复1点体力",
  ["#yinlu2-invoke"] = "<font color='red'>♥</font>藿溪：你可以弃置一张<font color='red'>♥</font>牌，摸两张牌",
  ["#yinlu3-invoke"] = "♠瘴气：你需弃置一张♠牌，否则失去1点体力",
  ["#yinlu4-invoke"] = "♣芸香：你可以弃置一张♣牌，获得一个可以防止1点伤害的“芸香”标记",
  ["#yinlu-yunxiang"] = "♣芸香：你可以消耗所有“芸香”，防止等量的伤害",

  ["#yinlu-give1"] = "引路：请选择获得“<font color='red'>♦</font>乐泉”（回复体力）的角色",
  ["#yinlu-give2"] = "引路：请选择获得“<font color='red'>♥</font>藿溪”（摸牌）的角色",
  ["#yinlu-give3"] = "引路：请选择获得“♠瘴气”（失去体力）的角色",
  ["#yinlu-give4"] = "引路：请选择获得“♣芸香”（防止伤害）的角色",

  ["#yinlu_move-invoke1"] = "引路：你可以移动一个标记",
  ["#yinlu_move-invoke2"] = "引路：你可以移动 %dest 的标记",
  ["#yinlu-choice"] = "引路：请选择要移动的标记",
  ["#yinlu-move"] = "引路：请选择获得“%arg”的角色",
  ["#yinlu-invoke"] = "引路：选择执行的标记",

  ["$yinlu1"] = "南疆苦瘴，非土人不得过。",
  ["$yinlu2"] = "闻丞相南征，某特来引之。",
}

yinlu:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinlu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for i = 1, 3, 1 do
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#yinlu-give"..i,
        skill_name = yinlu.name,
        cancelable = false,
      })[1]
      room:setPlayerMark(to, "@@yinlu"..i, 1)
    end
    room:setPlayerMark(player, "@@yinlu4", 1)
    room:addPlayerMark(player, "@yunxiang", 1)  --开局自带一个小芸香标记
  end,
})

yinlu:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Finish then
      if player:getMark("@@yinlu3") > 0 then
        return true
      elseif table.find({1, 2, 3, 4}, function (i)
        return player:getMark("@@yinlu"..i) > 0
      end) then
        return not player:isNude()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"diamond", "heart", "spade", "club"}
    local selected = {}
    while not player.dead do
      local choices = table.filter({1, 2, 3, 4}, function (i)
        if player:getMark("@@yinlu"..i) > 0 and not table.contains(selected, i) then
          if i == 3 then
            return true
          elseif not player:isNude() then
            if i == 1 then
              return player:isWounded()
            else
              return true
            end
          end
        end
      end)
      choices = table.map(choices, function (i)
        return "@@yinlu"..i
      end)
      if #choices == 0 then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = yinlu.name,
        prompt = "#yinlu-invoke",
      })
      local index = tonumber(choice[8])
      table.insert(selected, index)
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yinlu.name,
        cancelable = true,
        pattern = ".|.|"..suits[index],
        prompt = "#yinlu"..index.."-invoke",
      })
      if player.dead then return end
      if #card > 0 then
        if index == 1 then
          if player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skill_name = yinlu.name,
            }
          end
        elseif index == 2 then
          player:drawCards(2, yinlu.name)
        elseif index == 4 then
          room:addPlayerMark(player, "@yunxiang", 1)
        end
      elseif index == 3 then
        room:loseHp(player, 1, yinlu.name)
      end
    end
  end,
})

yinlu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yunxiang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yinlu.name,
      prompt = "#yinlu-yunxiang",
    })
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-player:getMark("@yunxiang"))
    player.room:setPlayerMark(player, "@yunxiang", 0)
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices = {}
    for i = 1, 4, 1 do
      if to:getMark("@@yinlu"..i) > 0 then
        table.insert(choices, "@@yinlu"..i)
      end
    end
    if event == fk.Death then
      table.insert(choices, "Cancel")
    end
    while true do
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = yinlu.name,
        prompt = "#yinlu-choice",
      })
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      local tos = room:getOtherPlayers(to, false)
      if #tos > 1 then
        tos = room:askToChoosePlayers(player, {
          targets = tos,
          min_num = 1,
          max_num = 1,
          prompt = "#yinlu-move:::"..choice,
          skill_name = yinlu.name,
          cancelable = false,
        })
      end
      room:setPlayerMark(to, choice, 0)
      room:setPlayerMark(tos[1], choice, 1)
      if event == fk.EventPhaseStart then return end
    end
  end,
}

yinlu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yinlu.name) and player.phase == Player.Start and
      #player.room.alive_players > 0 and
      table.find(player.room.alive_players, function(p)
        return table.find({1, 2, 3, 4}, function (i)
          return p:getMark("@@yinlu"..i) > 0
        end) ~= nil
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return table.find({1, 2, 3, 4}, function (i)
        return p:getMark("@@yinlu"..i) > 0
      end) ~= nil
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#yinlu_move-invoke1",
      skill_name = yinlu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = spec.on_use,
})

yinlu:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinlu.name) and
      table.find({1, 2, 3, 4}, function (i)
        return target:getMark("@@yinlu"..i) > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yinlu.name,
      prompt = "#yinlu_move-invoke2::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = spec.on_use,
})

yinlu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    for i = 1, 4, 1 do
      room:setPlayerMark(p, "@@yinlu"..i, 0)
    end
  end
end)

return yinlu
