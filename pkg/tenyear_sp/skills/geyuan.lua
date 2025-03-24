local geyuan = fk.CreateSkill {
  name = "geyuan",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:usedSkillTimes("gusuan", Player.HistoryGame) > 0 then
      return "geyuan_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["geyuan"] = "割圆",
  [":geyuan"] = "锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环。有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。"..
  "当圆环完成后，你获得牌堆和场上所有完成此圆环最初和最后点数的牌，然后从圆环中移除这两个点数（不会被移除到三个以下），重新开始圆环。",

  ["@[geyuan]"] = "割圆",
  ["#gusuan-choose"] = "割圆：依次选择至多三名角色，第一名角色摸三张牌，第二名角色弃四张牌，第三名角色手牌交换牌堆底五张牌",
  ["geyuan_tip1"] = "摸三张牌",
  ["geyuan_tip2"] = "弃四张牌",
  ["geyuan_tip3"] = "交换牌堆五张牌",

  ["$geyuan1"] = "绘同径之距，置内圆而割之。",
  ["$geyuan2"] = "矩割弥细，圆失弥少，以至不可割。",
}

local function startCircle(player, points)
  local room = player.room
  table.shuffle(points)
  room:setPlayerMark(player, "@[geyuan]", {
    all = points, ok = {}
  })
end

--- 返回下一个能点亮圆环的点数
---@return integer[]
local function getCircleProceed(value)
  local all_points = value.all
  local ok_points = value.ok
  local all_len = #all_points
  -- 若没有点亮的就全部都满足
  if #ok_points == 0 then return all_points end
  -- 若全部点亮了返回空表
  if #ok_points == all_len then return Util.DummyTable end

  local function c(idx)
    if idx == 0 then idx = all_len end
    if idx == all_len + 1 then idx = 1 end
    return idx
  end

  -- 否则，显示相邻的，逻辑上要构成循环
  local ok_map = {}
  for _, v in ipairs(ok_points) do ok_map[v] = true end
  local start_idx, end_idx
  for i, v in ipairs(all_points) do
    -- 前一个不亮，这个是左端
    if ok_map[v] and not ok_map[all_points[c(i-1)]] then
      start_idx = i
    end
    -- 后一个不亮，这个是右端
    if ok_map[v] and not ok_map[all_points[c(i+1)]] then
      end_idx = i
    end
  end

  start_idx = c(start_idx - 1)
  end_idx = c(end_idx + 1)

  if start_idx == end_idx then
    return { all_points[start_idx] }
  else
    return { all_points[start_idx], all_points[end_idx] }
  end
end

Fk:addQmlMark{
  name = "geyuan",
  how_to_show = function(name, value)
    -- FIXME: 神秘bug导致value可能为空串有待排查
    if type(value) ~= "table" then return " " end
    local nums = getCircleProceed(value)
    if #nums == 1 then
      return Card:getNumberStr(nums[1])
    elseif #nums == 2 then
      return Card:getNumberStr(nums[1]) .. Card:getNumberStr(nums[2])
    else
      return " "
    end
  end,
  qml_path = "packages/tenyear/qml/GeyuanBox"
}

Fk:addTargetTip{
  name = "geyuan",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if table.contains(selected, to_select) then
      return "geyuan_tip"..table.indexOf(selected, to_select)
    end
  end,
}

geyuan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(geyuan.name) and player:getMark("@[geyuan]") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("geyuan")
    local points = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    startCircle(player, points)
  end
})

geyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(geyuan.name) then
      local circle_data = player:getMark("@[geyuan]")
      if circle_data == 0 then return end
      local proceed = getCircleProceed(circle_data)
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(proceed, Fk:getCardById(info.cardId).number) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local circle_data = player:getMark("@[geyuan]")
    local proceed = getCircleProceed(circle_data)
    local completed = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then
            table.insert(circle_data.ok, number)
            proceed = getCircleProceed(circle_data)
            if proceed == Util.DummyTable then -- 已完成？
              completed = true
              goto BREAK
            end
          end
        end
      end
    end
    ::BREAK::

    if completed then
      local start_num, end_num = circle_data.ok[1], circle_data.ok[#circle_data.ok]
      local waked = player:usedSkillTimes("gusuan", Player.HistoryGame) > 0
      if waked then
        local players = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 3,
          prompt = "#gusuan-choose",
          skill_name = geyuan.name,
          cancelable = true,
          target_tip_name = geyuan.name,
        })

        if #players > 0 then
          players[1]:drawCards(3, geyuan.name)
        end
        if #players > 1 and not players[2].dead then
          room:askToDiscard(players[2], {
            min_num = 4,
            max_num = 4,
            include_equip = true,
            skill_name = geyuan.name,
            cancelable = false,
          })
        end
        if #players > 2 and not players[3].dead then
          room:swapCardsWithPile(players[3], player:getCardIds("h"), room:getNCards(5, "bottom"), geyuan.name, "Bottom", false, player)
        end
      else
        local toget = {}
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("ej")) do
            local c = Fk:getCardById(id, true)
            if c.number == start_num or c.number == end_num then
              table.insert(toget, id)
            end
          end
        end
        for _, id in ipairs(room.draw_pile) do
          local c = Fk:getCardById(id, true)
          if c.number == start_num or c.number == end_num then
            table.insert(toget, id)
          end
        end
        room:moveCardTo(toget, Card.PlayerHand, player, fk.ReasonPrey, geyuan.name, nil, true, player)
      end

      local all = circle_data.all
      if not waked then
        if #all > 3 then table.removeOne(all, start_num) end
        if #all > 3 then table.removeOne(all, end_num) end
      end
      startCircle(player, all)
    else
      room:setPlayerMark(player, "@[geyuan]", circle_data)
    end
  end,
})

geyuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[geyuan]", 0)
end)

return geyuan
