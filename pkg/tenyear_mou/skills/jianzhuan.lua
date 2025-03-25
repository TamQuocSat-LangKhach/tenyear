local jianzhuan = fk.CreateSkill {
  name = "jianzhuan",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player)
    local str = {}
    for i = 1, 4, 1 do
      if player:getMark("jianzhuan"..i) == 0 then
        if player:getMark("jianzhuan"..i.."-phase") == 0 then
          table.insert(str, Fk:translate("jianzhuan"..i))
        else
          table.insert(str, "<font color=\"grey\">"..Fk:translate("jianzhuan"..i).."</font>")
        end
      end
    end
    if #str == 0 then
      return "dummyskill"
    else
      return "jianzhuan_inner:"..table.concat(str, "；")
    end
  end,
}

Fk:loadTranslationTable{
  ["jianzhuan"] = "渐专",
  [":jianzhuan"] = "锁定技，出牌阶段每项限一次，当你使用牌时，你选择一项：1.令一名其他角色弃置X张牌；2.摸X张牌；3.重铸X张牌；"..
  "4.弃置X张牌（X为你此阶段发动此技能次数）。出牌阶段结束时，若所有选项于此阶段内都被选择过，随机删除一个选项。",

  [":jianzhuan_inner"] = "锁定技，出牌阶段每项限一次，当你使用牌时，你选择一项：{1}（X为你此阶段发动此技能次数）。出牌阶段结束时，"..
  "若所有选项于此阶段内都被选择过，随机删除一个选项。",

  ["#jianzhuan-choice"] = "渐专：选择执行的一项（其中X为%arg）",
  ["jianzhuan1"] = "令一名其他角色弃置X张牌",
  ["jianzhuan2"] = "摸X张牌",
  ["jianzhuan3"] = "重铸X张牌",
  ["jianzhuan4"] = "弃置X张牌",
  ["#jianzhuan-choose"] = "渐专：令一名角色弃置%arg张牌",
  ["#jianzhuan-recast"] = "渐专：选择%arg张牌重铸",

  ["$jianzhuan1"] = "今作擎天之柱，何怜八方风雨？",
  ["$jianzhuan2"] = "吾寄百里之命，当居万丈危楼。",
}

jianzhuan:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jianzhuan.name) and player.phase == Player.Play then
      local choices, all_choices = {}, {}
      for i = 1, 4, 1 do
        local mark = "jianzhuan"..i
        if player:getMark(mark) == 0 then
          table.insert(all_choices, mark)
          if player:getMark(mark .. "-phase") == 0 then
            table.insert(choices, mark)
          end
        end
      end
      if #choices > 0 then
        event:setCostData(self, {extra_data =  {choices, all_choices}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.simpleClone(event:getCostData(self).extra_data)
    local x = player:usedSkillTimes(jianzhuan.name, Player.HistoryPhase)
    local choice = room:askToChoice(player, {
      choices = choices[1],
      skill_name = jianzhuan.name,
      prompt = "#jianzhuan-choice:::"..x,
      all_choices = choices[2],
    })
    room:setPlayerMark(player, choice .. "-phase", 1)
    if choice == "jianzhuan1" then
      if #room:getOtherPlayers(player, false) == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = jianzhuan.name,
        prompt = "#jianzhuan-choose:::"..x,
        cancelable = false,
      })[1]
      room:askToDiscard(to, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = jianzhuan.name,
        cancelable = false,
      })
    elseif choice == "jianzhuan2" then
      player:drawCards(x, "jianzhuan")
    elseif choice == "jianzhuan3" then
      if player:isNude() then return end
      local cards = player:getCardIds("he")
      if #cards > x then
        cards = room:askToCards(player, {
          min_num = x,
          max_num = x,
          include_equip = true,
          skill_name = jianzhuan.name,
          prompt = "#jianzhuan-recast:::"..x,
          cancelable = false,
        })
      end
      room:recastCard(cards, player, jianzhuan.name)
    elseif choice == "jianzhuan4" then
      room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = jianzhuan.name,
        cancelable = false,
      })
    end
  end,
})

jianzhuan:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jianzhuan.name) and player.phase == Player.Play then
      local choices, all_choices = {}, {}
      for i = 1, 4, 1 do
        local mark = "jianzhuan"..tostring(i)
        if player:getMark(mark) == 0 then
          table.insert(all_choices, mark)
          if player:getMark(mark .. "-phase") == 0 then
            table.insert(choices, mark)
          end
        end
      end
      if #choices == 0 and #all_choices > 1 then
        event:setCostData(self, {extra_data =  all_choices})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jianzhuan.name)
    room:setPlayerMark(player, table.random(event:getCostData(self).extra_data), 1)
  end,
})

jianzhuan:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for i = 1, 4, 1 do
    room:setPlayerMark(player, "jianzhuan"..i, 0)
  end
end)

return jianzhuan
