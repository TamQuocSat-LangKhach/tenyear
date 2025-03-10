local jianzhuan = fk.CreateSkill {
  name = "jianzhuan"
}

Fk:loadTranslationTable{
  ['jianzhuan'] = '渐专',
  ['#jianzhuan-choice'] = '渐专：选择执行的一项（其中X为%arg）',
  ['jianzhuan1'] = '令一名角色弃置X张牌',
  ['jianzhuan2'] = '摸X张牌',
  ['jianzhuan3'] = '重铸X张牌',
  ['jianzhuan4'] = '弃置X张牌',
  [':jianzhuan'] = '锁定技，当你于出牌阶段内使用牌时，你选择于此阶段内未选择过的一项：1.令一名其他角色弃置X张牌；2.摸X张牌；3.重铸X张牌；4.弃置X张牌。出牌阶段结束时，若选项数大于1且所有选项于此阶段内都被选择过，你随机删除一个选项。（X为你于此阶段内发动过此技能的次数）',
  ['$jianzhuan1'] = '今作擎天之柱，何怜八方风雨？',
  ['$jianzhuan2'] = '吾寄百里之命，当居万丈危楼。',
}

jianzhuan:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
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
      if event == fk.CardUsing and #choices > 0 then
        event:setCostData(self, {choices, all_choices})
        return true
      elseif event == fk.EventPhaseEnd and #choices == 0 and #all_choices > 1 then
        event:setCostData(self, all_choices)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jianzhuan.name)
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, jianzhuan.name)
      local choices = table.simpleClone(event:getCostData(self))
      local x = player:usedSkillTimes(jianzhuan.name, Player.HistoryPhase)
      local choice = room:askToChoice(player, {
        choices = choices[1],
        skill_name = jianzhuan.name,
        prompt = "#jianzhuan-choice:::" .. tostring(x),
        all_choices = choices[2]
      })
      room:setPlayerMark(player, choice .. "-phase", 1)
      doJianzhuan(player, choice, x)
    else
      room:notifySkillInvoked(player, jianzhuan.name, "negative")
      room:setPlayerMark(player, table.random(event:getCostData(self)), 1)
    end
  end,
})

jianzhuan:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
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
      if event == fk.CardUsing and #choices > 0 then
        event:setCostData(self, {choices, all_choices})
        return true
      elseif event == fk.EventPhaseEnd and #choices == 0 and #all_choices > 1 then
        event:setCostData(self, all_choices)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jianzhuan.name)
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, jianzhuan.name)
      local choices = table.simpleClone(event:getCostData(self))
      local x = player:usedSkillTimes(jianzhuan.name, Player.HistoryPhase)
      local choice = room:askToChoice(player, {
        choices = choices[1],
        skill_name = jianzhuan.name,
        prompt = "#jianzhuan-choice:::" .. tostring(x),
        all_choices = choices[2]
      })
      room:setPlayerMark(player, choice .. "-phase", 1)
      doJianzhuan(player, choice, x)
    else
      room:notifySkillInvoked(player, jianzhuan.name, "negative")
      room:setPlayerMark(player, table.random(event:getCostData(self)), 1)
    end
  end,
})

jianzhuan:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return player == target and data == jianzhuan.name
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jianzhuan1", 0)
    room:setPlayerMark(player, "jianzhuan2", 0)
    room:setPlayerMark(player, "jianzhuan3", 0)
    room:setPlayerMark(player, "jianzhuan4", 0)
  end,
})

return jianzhuan
