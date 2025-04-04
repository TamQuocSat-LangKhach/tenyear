local yinlu = fk.CreateSkill {
  name = "yinlu"
}

Fk:loadTranslationTable{
  ["yinlu"] = "引路",
  ["#yinlu_move-invoke1"] = "引路：你可以移动一个标记",
  ["#yinlu_move-invoke2"] = "引路：你可以移动 %dest 的标记",
  ["@@yinlu4"] = "♣芸香",
  ["@yunxiang"] = "芸香",
  ["#yinlu-choice"] = "引路：请选择要移动的标记",
  ["#yinlu-move"] = "引路：请选择获得“%arg”的角色",
  ["#yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["@@yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["#yinlu1-invoke"] = "<font color='red'>♦</font>乐泉：你可以弃置一张<font color='red'>♦</font>牌，回复1点体力",
  ["#yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["@@yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["#yinlu2-invoke"] = "<font color='red'>♥</font>藿溪：你可以弃置一张<font color='red'>♥</font>牌，摸两张牌",
  ["#yinlu3"] = "♠瘴气",
  ["@@yinlu3"] = "♠瘴气",
  ["#yinlu3-invoke"] = "♠瘴气：你需弃置一张♠牌，否则失去1点体力",
  ["#yinlu4"] = "♣芸香",
  ["#yinlu4-invoke"] = "♣芸香：你可以弃置一张♣牌，获得一个可以防止1点伤害的“芸香”标记",
  ["#yinlu-yunxiang"] = "♣芸香：你可以消耗所有“芸香”，防止等量的伤害",
  [":yinlu"] = "游戏开始时，你令三名角色依次获得以下一个标记：“乐泉”、“藿溪”、“瘴气”，然后你获得一个“芸香”。<br>准备阶段，你可以移动一个标记；有标记的角色死亡时，你可以移动其标记。拥有标记的角色获得对应的效果：<br>乐泉：结束阶段，你可以弃置一张<font color='red'>♦</font>牌，然后回复1点体力；<br>藿溪：结束阶段，你可以弃置一张<font color='red'>♥</font>牌，然后摸两张牌；<br>瘴气：结束阶段，你需要弃置一张♠牌，否则失去1点体力；<br>芸香：结束阶段，你可以弃置一张♣牌，获得一个“芸香”；当你受到伤害时，你可以移去所有“芸香”并防止等量的伤害。",
  ["$yinlu1"] = "南疆苦瘴，非土人不得过。",
  ["$yinlu2"] = "闻丞相南征，某特来引之。",
}

-- 主技能
yinlu:addEffect({fk.GameStart, fk.EventPhaseStart, fk.Death}, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        for i = 1, 4, 1 do
          if target:getMark("@@yinlu"..i) > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      local targets = {}
      for _, p in ipairs(player.room:getAlivePlayers()) do
        for i = 1, 4, 1 do
          if p:getMark("@@yinlu"..i) > 0 then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#yinlu_move-invoke1",
          skill_name = skill.name,
          cancelable = true
        })
        if #to > 0 then
          event:setCostData(skill, to[1])
          return true
        end
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = skill.name,
        prompt = "#yinlu_move-invoke2::"..target.id
      }) then
        event:setCostData(skill, target.id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getAlivePlayers(), Util.IdMapper)
      for i = 1, 3, 1 do
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#yinlu-give"..i,
          skill_name = skill.name
        })
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:setPlayerMark(room:getPlayerById(to), "@@yinlu"..i, 1)
      end
      room:setPlayerMark(player, "@@yinlu4", 1)
      room:addPlayerMark(player, "@yunxiang", 1)  --开局自带一个小芸香标记
    else
      local to = room:getPlayerById(event:getCostData(skill))
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
          skill_name = skill.name,
          prompt = "#yinlu-choice"
        })
        if choice == "Cancel" then return end
        table.removeOne(choices, choice)
        local targets = table.map(room:getOtherPlayers(to), Util.IdMapper)
        local dest
        if #targets > 1 then
          dest = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yinlu-move:::"..choice,
            skill_name = skill.name,
            cancelable = false
          })
          if #dest > 0 then
            dest = dest[1]
          else
            dest = table.random(targets)
          end
        else
          dest = targets[1]
        end
        dest = room:getPlayerById(dest)
        room:setPlayerMark(to, choice, 0)
        room:setPlayerMark(dest, choice, 1)
        if event == fk.EventPhaseStart then return end
      end
    end
  end,
})

-- 刷新技能效果
yinlu:addEffect({fk.Deathed}, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name, true, true) and
      not table.find(player.room.alive_players, function(p) return p:hasSkill(skill.name, true) end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for i = 1, 4, 1 do
        room:setPlayerMark(p, "@@yinlu"..i, 0)
      end
    end
  end,
})

-- 子技能 yinlu1
yinlu:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu1") > 0 and player.phase == Player.Finish and player:isWounded() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = "yinlu",
      cancelable = true,
      pattern = ".|.|diamond",
      prompt = "#yinlu1-invoke"
    }) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "yinlu",
    }
  end,
})

-- 子技能 yinlu2
yinlu:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu2") > 0 and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = "yinlu",
      cancelable = true,
      pattern = ".|.|heart",
      prompt = "#yinlu2-invoke"
    }) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, yinlu.name)
  end,
})

-- 子技能 yinlu3
yinlu:addEffect(fk.EventPhaseStart, {
  mute = true,
  
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu3") > 0 and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    if player:isNude() or #player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = "yinlu",
      cancelable = true,
      pattern = ".|.|spade",
      prompt = "#yinlu3-invoke"
    }) == 0 then
      player.room:loseHp(player, 1, yinlu.name)
    end
  end,
})

-- 子技能 yinlu4
yinlu:addEffect({fk.EventPhaseStart, fk.DamageInflicted}, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:getMark("@@yinlu4") > 0 and player.phase == Player.Finish and not player:isNude()
      else
        return player:getMark("@yunxiang") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return #player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = "yinlu",
        cancelable = true,
        pattern = ".|.|club",
        prompt = "#yinlu4-invoke"
      }) > 0
    else
      return player.room:askToSkillInvoke(player, {
        skill_name = yinlu.name,
        prompt = "#yinlu-yunxiang"
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@yunxiang", 1)
    else
      local num = player:getMark("@yunxiang")
      room:setPlayerMark(player, "@yunxiang", 0)
      if data.damage > num then
        data.damage = data.damage - num
      else
        return true
      end
    end
  end,
})

return yinlu
