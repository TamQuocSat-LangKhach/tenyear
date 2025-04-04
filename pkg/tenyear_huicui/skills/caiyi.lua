local caiyi = fk.CreateSkill {
  name = "caiyi",
  tags = { Skill.Switch },
  dynamic_desc = function (self, player)
    if #player:getTableMark("caiyi_removed_yang") == 4 and #player:getTableMark("caiyi_removed_yin") == 4 then
      return "dummyskill"
    end
    local state = player:getSwitchSkillState(self.name, false, true)
    local state2 = state == "yang" and "yin" or "yang"
    local str = {
      yang = {},
      yin = {},
    }
    for i = 1, 4 do
      if table.contains(player:getTableMark("caiyi_removed_"..state), i) then
        table.insert(str[state], "<s>"..Fk:translate("caiyi_"..state..i).."</s>")
      else
        table.insert(str[state], Fk:translate("caiyi_"..state..i))
      end
      if table.contains(player:getTableMark("caiyi_removed_"..state2), i) then
        table.insert(str[state2], "<s>"..Fk:translate("caiyi_"..state2..i).."</s>")
      else
        table.insert(str[state2], Fk:translate("caiyi_"..state2..i))
      end
    end
    return "caiyi_"..state..":"..table.concat(str[state], "；")..":"..table.concat(str[state2], "；")
  end,
}

Fk:loadTranslationTable{
  ["caiyi"] = "彩翼",
  [":caiyi"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：1.回复X点体力；2.摸X张牌；3.复原武将牌；"..
  "4.随机执行一个已移除的阳选项；阴：1.受到X点伤害；2.弃置X张牌；3.翻面并横置；4.随机执行一个已移除的阴选项。（X为当前状态剩余选项数）",

  [":caiyi_yang"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：<font color=\"#E0DB2F\">阳：{1}；</font>" ..
  "阴：{2}。（X为当前状态剩余选项数）",
  [":caiyi_yin"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：{2}；" ..
  "<font color=\"#E0DB2F\">阴：{1}</font>。（X为当前状态剩余选项数）",

  ["#caiyi_yang-choose"] = "彩翼：你可以令一名角色执行一个正面选项",
  ["#caiyi_yin-choose"] = "彩翼：你可以令一名角色执行一个负面选项",
  ["#caiyi-choice"] = "彩翼：选择执行的一项（其中X为%arg）",
  ["caiyi_yang1"] = "回复X点体力",
  ["caiyi_yang2"] = "摸X张牌",
  ["caiyi_yang3"] = "复原武将牌",
  ["caiyi_yang4"] = "随机一个已移除的阳选项",
  ["caiyi_yin1"] = "受到X点伤害",
  ["caiyi_yin2"] = "弃置X张牌",
  ["caiyi_yin3"] = "翻面并横置",
  ["caiyi_yin4"] = "随机一个已移除的阴选项",

  ["$caiyi1"] = "凰凤化越，彩翼犹存。",
  ["$caiyi2"] = "身披彩翼，心有灵犀。",
}

local function doCaiyi(player, target, state, choice)
  local room = player.room
  if choice == 4 then
    doCaiyi(player, target, state, table.random(player:getTableMark("caiyi_removed_"..state)))
  else
    local n = 4 - #player:getTableMark("caiyi_removed_"..state)
    if state == "yang" then
      if choice == 1 then
        if target:isWounded() then
          room:recover{
            who = target,
            num = math.min(n, target.maxHp - target.hp),
            recoverBy = player,
            skillName = caiyi.name,
          }
        end
      elseif choice == 2 then
        target:drawCards(n, caiyi.name)
      else
        target:reset()
      end
    else
      if choice == 1 then
        room:damage{
          to = target,
          damage = n,
          skillName = caiyi.name,
        }
      elseif choice == 2 then
        room:askToDiscard(target, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = caiyi.name,
          cancelable = false,
        })
      else
        target:turnOver()
        if not target.chained and not target.dead then
          target:setChainState(true)
        end
      end
    end
  end
end

caiyi:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caiyi.name) and player.phase == Player.Finish and
      #player:getTableMark("caiyi_removed_"..player:getSwitchSkillState(caiyi.name, false, true)) < 4
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      skill_name = caiyi.name,
      prompt = "#caiyi_"..player:getSwitchSkillState(caiyi.name, false, true).."-choose",
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices, all_choices = {}, {}
    local state = player:getSwitchSkillState(caiyi.name, true, true)
    for i = 1, 4 do
      table.insert(all_choices, "caiyi_"..state..i)
      if not table.contains(player:getTableMark("caiyi_removed_"..state), i) then
        if i == 4 and #choices == 3 then break end
        table.insert(choices, "caiyi_"..state..i)
      end
    end
    local num = 4 - #player:getTableMark("caiyi_removed_"..state)

    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = caiyi.name,
      prompt = "#caiyi-choice:::"..num,
      all_choices = all_choices,
    })
    doCaiyi(player, to, state, table.indexOf(all_choices, choice))
    if player:hasSkill(caiyi.name, true) then
      room:addTableMark(player, "caiyi_removed_"..state, table.indexOf(all_choices, choice))
    end
  end,
})

caiyi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "caiyi_removed_yang", 0)
  room:setPlayerMark(player, "caiyi_removed_yin", 0)
end)

return caiyi
