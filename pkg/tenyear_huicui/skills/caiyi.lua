local caiyi = fk.CreateSkill {
  name = "caiyi",
  dynamic_desc = function (self, player)
    if table.every({1,2,3,4}, function(i)
      return player:getMark("caiyiyang" .. i) > 0 and player:getMark("caiyiyinn" .. i) > 0
    end) then
      return "dummyskill"
    end

    local highlight_color = "<font color='#E0DB2F'>"
    local gray_color = "<font color='gray'>"
    local clean_color = "</font>"
    local texts = {"caiyi_inner"}
    local isYang = player:getSwitchSkillState(caiyi.name, false) == fk.SwitchYang
    local colors = {clean_color, gray_color}

    if isYang then
      table.insert(texts, highlight_color)
      colors = {clean_color .. highlight_color, clean_color .. gray_color}
    else
      table.insert(texts, "")
    end

    local x = 1
    for i = 1, 4 do
      if player:getMark("caiyiyang" .. i) == x then
        table.insert(texts, colors[x+1])
        x = 1-x
      else
        table.insert(texts, "")
      end
    end

    if not isYang then
      if x == 0 then
        table.insert(texts, clean_color .. highlight_color)
      else
        table.insert(texts, highlight_color)
      end
      colors = {clean_color .. highlight_color, clean_color .. gray_color}
    else
      table.insert(texts, clean_color)
      colors = {clean_color, gray_color}
    end

    x = 1
    for i = 1, 4 do
      if player:getMark("caiyiyinn" .. i) == x then
        table.insert(texts, colors[x+1])
        x = 1-x
      else
        table.insert(texts, "")
      end
    end

    table.insert(texts, clean_color)

    return table.concat(texts, ":")
  end,
}

Fk:loadTranslationTable{
  ['caiyi'] = '彩翼',
  ['#caiyi1-invoke'] = '彩翼：你可以令一名角色执行一个正面选项',
  ['#caiyi2-invoke'] = '彩翼：你可以令一名角色执行一个负面选项',
  ['#caiyi-choice'] = '彩翼：选择执行的一项（其中X为%arg）',
  ['caiyiyang1'] = '回复X点体力',
  ['caiyiyang2'] = '摸X张牌',
  ['caiyiyang3'] = '复原武将牌',
  ['caiyiyang4'] = '随机一个已移除的阳选项',
  ['caiyiyinn1'] = '受到X点伤害',
  ['caiyiyinn2'] = '弃置X张牌',
  ['caiyiyinn3'] = '翻面并横置',
  ['caiyiyinn4'] = '随机一个已移除的阴选项',
  [':caiyi'] = '转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：1.回复X点体力；2.摸X张牌；3.复原武将牌；4.随机执行一个已移除的阳选项；阴：1.受到X点伤害；2.弃置X张牌；3.翻面并横置；4.随机执行一个已移除的阴选项。（X为当前状态剩余选项数）',
  ['$caiyi1'] = '凰凤化越，彩翼犹存。',
  ['$caiyi2'] = '身披彩翼，心有灵犀。',
}

caiyi:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  switch_skill_name = caiyi.name,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(caiyi) and player.phase == Player.Finish then
      local state = "yang"
      if player:getSwitchSkillState(caiyi.name, false) == fk.SwitchYin then
        state = "yinn"
      end
      for i = 1, 4 do
        local mark = "caiyi"..state..tostring(i)
        if player:getMark(mark) == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiyi1-invoke"
    if player:getSwitchSkillState(caiyi.name, false) == fk.SwitchYin then
      prompt = "#caiyi2-invoke"
    end

    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getAlivePlayers(), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = caiyi.name,
      prompt = prompt
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices, all_choices = {}, {}
    local state = "yang"
    if player:getSwitchSkillState(caiyi.name, true) == fk.SwitchYin then
      state = "yinn"
    end

    for i = 1, 4 do
      local mark = "caiyi"..state..tostring(i)
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
      table.insert(all_choices, mark)
    end

    local num = #choices
    if num == 4 then
      table.remove(choices, 4)
    end

    local to = room:getPlayerById(event:getCostData(skill))
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = caiyi.name,
      prompt = "#caiyi-choice:::"..tostring(num),
      all_choices = all_choices
    })
    room:setPlayerMark(player, choice, 1)
    doCaiyi(player, to, choice, num)
  end,
  on_lose = function (skill, player)
    local room = player.room
    room:setPlayerMark(player, "caiyiyang1", 0)
    room:setPlayerMark(player, "caiyiyang2", 0)
    room:setPlayerMark(player, "caiyiyang3", 0)
    room:setPlayerMark(player, "caiyiyang4", 0)
    room:setPlayerMark(player, "caiyiyinn1", 0)
    room:setPlayerMark(player, "caiyiyinn2", 0)
    room:setPlayerMark(player, "caiyiyinn3", 0)
    room:setPlayerMark(player, "caiyiyinn4", 0)
  end,
})

return caiyi
