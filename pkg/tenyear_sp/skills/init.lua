local extension = Package("tenyear_sp4")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp4"] = "十周年-限定专属4",
}

--高山仰止：王朗 刘徽
local wanglang = General(extension, "ty__wanglang", "wei", 3)
local ty__gushe = fk.CreateActiveSkill{
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#ty__gushe-active",
  times = function(self)
    return Self.phase ~= Player.NotActive and 7 - Self:getMark("ty__raoshe_win-turn") - Self:getMark("@ty__raoshe") or -1
  end,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    room:getPlayerById(effect.from):pindian(table.map(tos, function(p) return room:getPlayerById(p) end), self.name)
  end,
}
local ty__gushe_delay = fk.CreateTriggerSkill{
  name = "#ty__gushe_delay",
  events = {fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.reason == "ty__gushe" and data.from == player
    --王朗死亡后依旧有效
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead and data.winner ~= player then
      room:addPlayerMark(player, "@ty__raoshe", 1)
      if player:getMark("@ty__raoshe") >= 7 then
        room:killPlayer({who = player.id,})
      end
      if not player.dead then
        if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
    if not data.to.dead and data.winner ~= data.to then
      if player.dead then
        room:askForDiscard(data.to, 1, 1, true, self.name, false, ".", "#ty__gushe2-discard")
      else
        if #room:askForDiscard(data.to, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.PindianResultConfirmed, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PindianResultConfirmed then
      return data.winner and data.winner == player and player:hasSkill(ty__gushe, true)
    elseif event == fk.EventLoseSkill then
      return player == target and data == ty__gushe
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianResultConfirmed then
      room:addPlayerMark(player, "ty__raoshe_win-turn")
      if player:getMark("@ty__raoshe") + player:getMark("ty__raoshe_win-turn") > 6 then
        room:invalidateSkill(player, "ty__gushe", "-turn")
      end
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty__raoshe", 0)
      room:setPlayerMark(player, "ty__raoshe_win-turn", 0)
    end
  end,
}
local ty__jici = fk.CreateTriggerSkill{
  name = "ty__jici",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.PindianCardsDisplayed, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PindianCardsDisplayed then
      if player:hasSkill(self) then
        if data.from == player then
          return data.fromCard.number <= player:getMark("@ty__raoshe")
        elseif table.contains(data.tos, player) then
          return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
        end
      end
    elseif event == fk.Death then
      return target == player and player:hasSkill(self, false, true) and data.damage and data.damage.from and not data.damage.from.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianCardsDisplayed then
      local card
      if data.from == player then
        card = data.fromCard
      elseif table.contains(data.tos, player) then
        card = data.results[player.id].toCard
      end
      card.number = card.number + player:getMark("@ty__raoshe")
      if player.dead then return end
      local n = card.number
      if data.fromCard.number > n then
        n = data.fromCard.number
      end
      for _, result in pairs(data.results) do
        if result.toCard.number > n then
          n = result.toCard.number
        end
      end
      local cards = {}
      if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertIfNeed(cards, data.fromCard)
      end
      for _, result in pairs(data.results) do
        if result.toCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
          table.insertIfNeed(cards, result.toCard)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
      end
    elseif event == fk.Death then
      local n = 7 - player:getMark("@ty__raoshe")
      if n > 0 then
        room:askForDiscard(data.damage.from, n, n, true, self.name, false)
        if data.damage.from.dead then return false end
      end
      room:loseHp(data.damage.from, 1, self.name)
    end
  end,
}
ty__gushe:addRelatedSkill(ty__gushe_delay)
wanglang:addSkill(ty__gushe)
wanglang:addSkill(ty__jici)
Fk:loadTranslationTable{
  ["ty__wanglang"] = "王朗",
  ["#ty__wanglang"] = "凤鹛",
  ["illustrator:ty__wanglang"] = "第七个桔子", -- 皮肤 骧龙御宇
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。"..
  "若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",
  ["ty__jici"] = "激词",
  [":ty__jici"] = "锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。"..
  "你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。",
  ["#ty__gushe-active"] = "发动 鼓舌，与1-3名角色拼点！",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",
  ["#ty__gushe_delay"] = "鼓舌",
  ["@ty__raoshe"] = "饶舌",
  ["times_left"] = "剩余",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
  ["$ty__jici1"] = "天数有变，神器更易，而归于有德之人，此自然之理也。",
  ["$ty__jici2"] = "王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。",
  ["~ty__wanglang"] = "我本东海弄墨客，如何枉做沙场魂……",
}

local liuhui = General(extension, "liuhui", "qun", 4)

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

local geyuan = fk.CreateTriggerSkill{
  name = "geyuan",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local circle_data = player:getMark("@[geyuan]")
    if circle_data == 0 then return end
    local proceed = getCircleProceed(circle_data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then return true end
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
              -- FAQ: 成功了后还需结算剩下的？摸了，我不结算
              completed = true
              goto BREAK
            end
          end
        end
      end
    end
    ::BREAK::

    if completed then
      local start, end_ = circle_data.ok[1], circle_data.ok[#circle_data.ok]
      local waked = player:usedSkillTimes("gusuan", Player.HistoryGame) > 0
      if waked then
        local players = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
          0, 3, "#gusuan-choose", self.name, true)

        if players[1] then
          room:getPlayerById(players[1]):drawCards(3, self.name)
        end
        if players[2] then
          local p = room:getPlayerById(players[2])
          room:askForDiscard(p, 4, 4, true, self.name, false)
        end
        if players[3] then
          local p = room:getPlayerById(players[3])
          local cards = p:getCardIds(Player.Hand)
          room:moveCards({
            from = p.id,
            ids = cards,
            toArea = Card.Processing,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
          })
          if not p.dead then
            room:moveCardTo(room:getNCards(5, "bottom"), Card.PlayerHand, p, fk.ReasonExchange, self.name, nil, false, player.id)
          end
          if #cards > 0 then
            table.shuffle(cards)
            room:moveCards({
              ids = cards,
              fromArea = Card.Processing,
              toArea = Card.DrawPile,
              moveReason = fk.ReasonExchange,
              skillName = self.name,
              moveVisible = false,
              drawPilePosition = -1,
            })
          end
        end
      else
        local toget = {}
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("ej")) do
            local c = Fk:getCardById(id, true)
            if c.number == start or c.number == end_ then
              table.insert(toget, c.id)
            end
          end
        end
        for _, id in ipairs(room.draw_pile) do
          local c = Fk:getCardById(id, true)
          if c.number == start or c.number == end_ then
            table.insert(toget, c.id)
          end
        end
        room:moveCardTo(toget, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end

      local all = circle_data.all
      if not waked then
        if #all > 3 then table.removeOne(all, start) end
        if #all > 3 then table.removeOne(all, end_) end
      end
      startCircle(player, all)
    else
      room:setPlayerMark(player, "@[geyuan]", circle_data)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[geyuan]", 0)
  end,
}
local geyuan_start = fk.CreateTriggerSkill{
  name = "#geyuan_start",
  main_skill = geyuan,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(geyuan) and player:getMark("@[geyuan]") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("geyuan")
    local points = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    startCircle(player, points)
  end
}
geyuan:addRelatedSkill(geyuan_start)
local jieshu = fk.CreateTriggerSkill{
  name = "jieshu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getMark("@[geyuan]") ~= 0 then
      local proceed = getCircleProceed(player:getMark("@[geyuan]"))
      return table.contains(proceed, data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local jieshu_max = fk.CreateMaxCardsSkill{
  name = "#jieshu_maxcard",
  exclude_from = function(self, player, card)
    if player:hasSkill(jieshu) then
      local mark = player:getMark("@[geyuan]")
      local all = Util.DummyTable
      if type(mark) == "table" and mark.all then all = mark.all end
      return not table.contains(all, card.number)
    end
  end,
}
jieshu:addRelatedSkill(jieshu_max)
local gusuan = fk.CreateTriggerSkill{
  name = "gusuan",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local mark = player:getMark("@[geyuan]")
    return type(mark) == "table" and #mark.all == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
  end,
}
liuhui:addSkill(geyuan)
liuhui:addSkill(jieshu)
liuhui:addSkill(gusuan)
Fk:loadTranslationTable{
  ["liuhui"] = "刘徽",
  ["#liuhui"] = "周天古率",
  ["cv:liuhui"] = "冰霜墨菊",
  ["illustrator:liuhui"] = "凡果_肉山大魔王",

  ["geyuan"] = "割圆",
  [":geyuan"] = '锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环。有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你获得牌堆和场上所有完成此圆环最初和最后点数的牌，然后从圆环中移除这两个点数（不会被移除到三个以下），重新开始圆环。<br><font color="grey">进度点数：圆环中即将被点亮的点数。</font>',
  ["jieshu"] = "解术",
  [":jieshu"] = "锁定技，非圆环内点数的牌不计入你的手牌上限。你使用或打出牌时，若满足圆环进度点数，你摸一张牌。",
  ["gusuan"] = "股算",
  [":gusuan"] = '觉醒技，每个回合结束时，若圆环剩余点数为3个，你减1点体力上限，并修改“割圆”。<br><font color="grey">☆割圆·改：锁定技，有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你至多依次选择三名角色（按照点击他们的顺序）并依次执行其中一项：1.摸三张牌；2.弃四张牌；3.将其手牌与牌堆底五张牌交换。结算完成后，重新开始圆环。</font>',

  ["@[geyuan]"] = "割圆", -- 仅用到了前缀，因为我感觉够了，实际上右括号后能加更多后缀
  ["#geyuan_start"] = "割圆",
  ["#gusuan-choose"] = "割圆：依次点选至多三名角色，第一个摸3，第二个弃4，第三个换牌",

  ["$geyuan1"] = "绘同径之距，置内圆而割之。",
  ["$geyuan2"] = "矩割弥细，圆失弥少，以至不可割。",
  ["$jieshu1"] = "累乘除以成九数者，可以加减解之。",
  ["$jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$gusuan1"] = "勾中容横，股中容直，可知其玄五。",
  ["$gusuan2"] = "累矩连索，类推衍化，开立而得法。",
  ["~liuhui"] = "算学如海，穷我一生，只得杯水……",
}

--武庙：诸葛亮 陆逊 关羽 皇甫嵩
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      player.hp = math.min(player.maxHp, math.max(n, 1))
      room:broadcastProperty(player, "hp")
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      not table.contains(player:getTableMark("qingshi-turn"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"qingshi1", "qingshi2", "qingshi3", "Cancel"},
    self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice == "qingshi1" then
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi2" then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 998,
      "#qingshi2-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi3" then
      self.cost_data = {choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "qingshi-turn", data.card.trueName)
    if self.cost_data[1] == "qingshi1" then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi_data = data.extra_data.qingshi_data or {}
      table.insert(data.extra_data.qingshi_data, {player.id, self.cost_data[2][1]})
    elseif self.cost_data[1] == "qingshi2" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local tos = self.cost_data[2]
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data[1] == "qingshi3" then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      player:drawCards(3, self.name)
      room:invalidateSkill(player, self.name, "-turn")
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    room:setPlayerMark(player, "qingshi-turn", 0)
    room:validateSkill(player, self.name, "-turn")
  end,
}
local qingshi_delay = fk.CreateTriggerSkill{
  name = "#qingshi_delay",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or data.chain then return false end
    local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      if use.extra_data then
        local qingshi_data = use.extra_data.qingshi_data
        if qingshi_data then
          return table.find(qingshi_data, function (players)
            return players[1] == player.id and players[2] == data.to.id
          end)
        end
      end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(qingshi.name)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
    and not Fk:getCardById(to_select).is_derived and to_select > 0
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = self.name,
      moveVisible = false,
    })
  end
}
local zhizhe_delay = fk.CreateTriggerSkill{
  name = "#zhizhe_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("zhizhe")
    if #mark == 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        local to_get = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
        if #to_get > 0 then
          self.cost_data = to_get
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(zhizhe.name)
    room:obtainCard(player, self.cost_data, true, fk.ReasonJustMove, player.id, "zhizhe")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = player:getTableMark("zhizhe")
    local marked2 = player:getTableMark("zhizhe-turn")
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
}
qingshi:addRelatedSkill(qingshi_delay)
zhizhe:addRelatedSkill(zhizhe_delay)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "武诸葛亮",
  ["#wm__zhugeliang"] = "忠武良弼",
  ["designer:wm__zhugeliang"] = "韩旭",
  ["illustrator:wm__zhugeliang"] = "梦回唐朝",
  ["cv:wm__zhugeliang"] = "马洋",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌（X为你的体力值），将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",
  ["qingshi-turn"] = "情势",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#qingshi_delay"] = "情势",
  ["#zhizhe_delay"] = "智哲",
  ["#zhizhe-active"] = "发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制",
  ["@@zhizhe-inhand"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

local luxun = General(extension, "wm__luxun", "wu", 3)
local xiongmu = fk.CreateTriggerSkill{
  name = "xiongmu",
  mute = true,
  events = {fk.RoundStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return player == target and player:getHandcardNum() <= player.hp and player:getMark("xiongmu_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          return damage and damage.to == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      local x = player.maxHp - player:getHandcardNum()
      if x > 0 and room:askForSkillInvoke(player, self.name, nil, "#xiongmu-draw:::" .. tostring(x)) then
        room:drawCards(player, x, self.name)
        if player.dead then return false end
      end
      if player:isNude() then return false end
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#xiongmu-cards")
      x = #cards
      if x == 0 then return false end
      table.shuffle(cards)
      local positions = {}
      local y = #room.draw_pile
      for _ = 1, x, 1 do
        table.insert(positions, math.random(y+1))
      end
      table.sort(positions, function (a, b)
        return a > b
      end)
      local moveInfos = {}
      for i = 1, x, 1 do
        table.insert(moveInfos, {
          ids = {cards[i]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = positions[i],
        })
      end
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
      cards = room:getCardsFromPileByRule(".|8", x)
      if x > #cards then
        table.insertTable(cards, room:getCardsFromPileByRule(".|8", x - #cards, "discardPile"))
      end
      if #cards > 0 then
        player.room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
          moveMark = "@@xiongmu-inhand-round",
        })
      end
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      room:setPlayerMark(player, "xiongmu_defensive-turn", 1)
      data.damage = data.damage - 1
    end
  end,

}
local xiongmu_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiongmu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand-round") > 0
  end,
}
local zhangcai = fk.CreateTriggerSkill{
  name = "zhangcai",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player:getMark("@@ruxian") > 0 or data.card.number == 8)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.max(1, #table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id):compareNumberWith(data.card, false)
    end)), self.name)
  end,
}
local ruxian = fk.CreateActiveSkill{
  name = "ruxian",
  prompt = "#ruxian-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(room:getPlayerById(effect.from), "@@ruxian", 1)
  end,
}
local ruxian_refresh = fk.CreateTriggerSkill{
  name = "#ruxian_refresh",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
}
xiongmu:addRelatedSkill(xiongmu_maxcards)
ruxian:addRelatedSkill(ruxian_refresh)
luxun:addSkill(xiongmu)
luxun:addSkill(zhangcai)
luxun:addSkill(ruxian)
Fk:loadTranslationTable{
  ["wm__luxun"] = "武陆逊",
  ["#wm__luxun"] = "释武怀儒",
  ["designer:wm__luxun"] = "韩旭",
  ["illustrator:wm__luxun"] = "小新",
  ["xiongmu"] = "雄幕",
  [":xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，"..
  "这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数小于等于体力值，此伤害-1。",
  ["zhangcai"] = "彰才",
  [":zhangcai"] = "当你使用或打出点数为8的牌时，你可以摸X张牌（X为手牌中与使用的牌点数相同的牌的数量且至少为1）。",
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可以将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#xiongmu-draw"] = "雄幕：是否将手牌补至体力上限（摸%arg张牌）",
  ["#xiongmu-cards"] = "雄幕：你可将任意张牌随机置入牌堆，然后获得等量张点数为8的牌",
  ["@@xiongmu-inhand-round"] = "雄幕",
  ["#ruxian-active"] = "发动 儒贤，令你发动〖彰才〗没有点数的限制直到你的下个回合开始",
  ["@@ruxian"] = "儒贤",

  ["$xiongmu1"] = "步步为营者，定无后顾之虞。",
  ["$xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
  ["$zhangcai1"] = "今提墨笔绘乾坤，湖海添色山永春。",
  ["$zhangcai2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
  ["~wm__luxun"] = "此生清白，不为浊泥所染……",
}

local guanyu = General(extension, "wm__guanyu", "shu", 5)
local juewu = fk.CreateViewAsSkill{
  name = "juewu",
  prompt = "#juewu-viewas",
  anim_type = "offensive",
  pattern = ".",
  handly_pile = true,
  interaction = function(self, player)
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local choices = U.getViewAsCardNames(player, "juewu", names, nil, player:getTableMark("juewu-turn"))
    return U.CardNameBox {
      choices = choices,
      all_choices = names,
      default_choice = "juewu"
    }
  end,
  card_filter = function(self, to_select, selected)
    if Fk.all_card_types[self.interaction.data] == nil or #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.number == 2 then
      return true
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getTableMark("juewu-turn")
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "juewu-turn", mark)
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = function(self, player, response)
    if response then return false end
    if Fk.currentResponsePattern == nil then return false end
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = player:getTableMark("juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if not table.contains(mark, to_use.trueName) and Exppattern:Parse(Fk.currentResponsePattern):match(to_use) then
        return true
      end
    end
  end,

  on_lose = function (self, player, is_death)
    player.room:setPlayerMark(player, "juewu-turn", 0)
  end
}
local juewu_trigger = fk.CreateTriggerSkill{
  name = "#juewu_trigger",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(juewu) then return false end
    local cards = {}
    local handcards = player:getCardIds(Player.Hand)
    for _, move in ipairs(data) do
      if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains({Player.Hand, Player.Equip}, info.fromArea) and  table.contains(handcards, id) then
            table.insert(cards, id)
          end
        end
      end
    end
    cards = U.moveCardsHoldingAreaCheck(player.room, cards)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      room:setCardMark(Fk:getCardById(id), "@@juewu-inhand", 1)
    end
  end,
}
local juewu_filter = fk.CreateFilterSkill{
  name = "#juewu_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@juewu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card.name, card.suit, 2)
  end,
}
local wuyou = fk.CreateActiveSkill{
  name = "wuyou",
  attached_skill_name = "wuyou&",
  prompt = "#wuyou-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos and #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    local card_names = player:getMark("wuyou_names")
    if type(card_names) ~= "table" then
      card_names = {}
      local tmp_names = {}
      local card, index
      for _, id in ipairs(Fk:getAllCardIds()) do
        card = Fk:getCardById(id, true)
        if not card.is_derived and card.type ~= Card.TypeEquip then
          index = table.indexOf(tmp_names, card.trueName)
          if index == -1 then
            table.insert(tmp_names, card.trueName)
            table.insert(card_names, {card.name})
          else
            table.insertIfNeed(card_names[index], card.name)
          end
        end
      end
      room:setPlayerMark(player, "wuyou_names", card_names)
    end
    if #card_names == 0 then return end
    card_names = table.map(table.random(card_names, 5), function (card_list)
      return table.random(card_list)
    end)
    local success, dat = room:askForUseActiveSkill(player, "wuyou_declare",
    "#wuyou-declare::" .. target.id, true, { interaction_choices = card_names })
    if not success then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id, {"@@wuyou-inhand", card_name})
    end
  end,
}
local wuyou_active = fk.CreateActiveSkill{
  name = "wuyou&",
  anim_type = "support",
  prompt = "#wuyou-other",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getTableMark("wuyou_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(wuyou) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards, card, extra_data, player)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(wuyou) and
    not table.contains(player:getTableMark("wuyou_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.from)
    local player = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke("wuyou")
    room:addTableMarkIfNeed(target, "wuyou_targets-phase", player.id)
    room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
    if player.dead or player:isKongcheng() or target.dead then return end
    wuyou:onUse(room, {from = player.id, tos = { target.id } })
  end,
}
local wuyou_declare = fk.CreateActiveSkill{
  name = "wuyou_declare",
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    return U.CardNameBox {
      choices = self.interaction_choices,
      default_choice = "wuyou"
    }
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk.all_card_types[self.interaction.data] ~= nil and
      Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
}
local wuyou_filter = fk.CreateFilterSkill{
  name = "#wuyou_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
}
local wuyou_targetmod = fk.CreateTargetModSkill{
  name = "#wuyou_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
}
local wuyou_refresh = fk.CreateTriggerSkill{
  name = "#wuyou_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local yixian = fk.CreateActiveSkill{
  name = "yixian",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  interaction = function()
    return UI.ComboBox {
      choices = { "yixian_field", "yixian_discard" }
    }
  end,
  prompt = function(self)
    return "#yixian-active:::" .. self.interaction.data
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "yixian_field" then
      local yixianmap = {}
      local cards = {}
      local equips = {}
      for _, p in ipairs(room.alive_players) do
        equips = p:getCardIds{Player.Equip}
        if #equips > 0 then
          yixianmap[p.id] = #equips
          table.insertTable(cards, equips)
        end
      end
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      if player.dead then return end
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then
          local n = yixianmap[p.id]
          if n and n > 0 and room:askForSkillInvoke(player, self.name, nil, "#yixian-repay::" .. p.id..":"..tostring(n)) then
            room:drawCards(p, n, self.name)
            if not p.dead and p:isWounded() then 
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name,
              }
            end
            if player.dead then break end
          end
        end
      end
    elseif self.interaction.data == "yixian_discard" then
      local equips = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      if #equips > 0 then
        room:moveCardTo(equips, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,
}
Fk:addSkill(wuyou_active)
Fk:addSkill(wuyou_declare)
juewu:addRelatedSkill(juewu_trigger)
juewu:addRelatedSkill(juewu_filter)
wuyou:addRelatedSkill(wuyou_filter)
wuyou:addRelatedSkill(wuyou_targetmod)
wuyou:addRelatedSkill(wuyou_refresh)
guanyu:addSkill(juewu)
guanyu:addSkill(wuyou)
guanyu:addSkill(yixian)
Fk:loadTranslationTable{
  ["wm__guanyu"] = "武关羽",
  ["#wm__guanyu"] = "义武千秋",
  ["illustrator:wm__guanyu"] = "黯荧岛_小董",
  ["designer:wm__guanyu"] = "韩旭",
  ["juewu"] = "绝武",
  [":juewu"] = "你可以将点数为2的牌当伤害牌或【水淹七军】使用（每回合每种牌名限一次）。当你得到其他角色的牌后，这些牌的点数视为2。",
  ["wuyou"] = "武佑",
  [":wuyou"] = "出牌阶段限一次，你可以从五个随机的不为装备牌的牌名中声明一个并选择你的一张手牌，此牌视为你声明的牌且使用时无距离和次数限制。"..
  "其他角色的出牌阶段限一次，其可以将一张手牌交给你，然后你可以从五个随机的不为装备牌的牌名中声明一个并将一张手牌交给该角色，"..
  "此牌视为你声明的牌且使用时无距离和次数限制。",
  ["yixian"] = "义贤",
  [":yixian"] = "限定技，出牌阶段，你可以选择：1.获得场上的所有装备牌，你对以此法被你获得牌的角色依次可以令其摸等量的牌并回复1点体力；"..
  "2.获得弃牌堆中的所有装备牌。",

  ["#juewu-viewas"] = "发动 绝武，将点数为2的牌转化为任意伤害牌使用",
  ["#juewu_trigger"] = "绝武",
  ["#juewu_filter"] = "绝武",
  ["@@juewu-inhand"] = "绝武",
  ["wuyou&"] = "武佑",
  [":wuyou&"] = "出牌阶段限一次，你可以将一张牌交给武关羽，然后其可以将一张牌交给你并声明一种基本牌或普通锦囊牌的牌名，此牌视为声明的牌。",
  ["#wuyou-active"] = "发动 武佑，令一张手牌视为你声明的牌（五选一）",
  ["#wuyou-other"] = "发动 武佑，选择一张牌交给一名拥有“武佑”的角色",
  ["#wuyou-declare"] = "武佑：将一张手牌交给%dest并令此牌视为声明的牌名",
  ["wuyou_declare"] = "武佑",
  ["#wuyou_filter"] = "武佑",
  ["@@wuyou-inhand"] = "武佑",
  ["#yixian-active"] = "发动 义贤，%arg",
  ["yixian_field"] = "获得场上的装备牌",
  ["yixian_discard"] = "获得弃牌堆里的装备牌",
  ["#yixian-repay"] = "义贤：是否令%dest摸%arg张牌并回复1点体力",

  ["$juewu1"] = "此身屹沧海，覆手潮立，浪涌三十六天。",
  ["$juewu2"] = "青龙啸肃月，长刀裂空，威降一十九将。",
  ["$wuyou1"] = "秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！",
  ["$wuyou2"] = "着青袍，饮温酒，五关已过，来将且通名！",
  ["$yixian1"] = "春秋着墨十万卷，长髯映雪千里行。",
  ["$yixian2"] = "义驱千里长路，风起桃园芳菲。",
  ["~wm__guanyu"] = "天下泪染将军袍，且枕青山梦桃园……",
}

local huangfusong = General(extension, "wm__huangfusong", "qun", 4)
local chaozhen = fk.CreateTriggerSkill{
  name = "chaozhen",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (event == fk.EventPhaseStart and player.phase == Player.Start or event == fk.EnterDying)
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"Field", "Pile", "Cancel"}, self.name, "#chaozhen-invoke")
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, num = {}, 14
    if self.cost_data.choice == "Field" then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("ej")) do
          if Fk:getCardById(id).number <= num then
            num = Fk:getCardById(id).number
            table.insert(cards, id)
          end
        end
      end
    else
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number <= num then
          num = Fk:getCardById(id).number
          table.insert(cards, id)
        end
      end
    end
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).number == num
    end)
    if #cards == 0 then return end
    local card = table.random(cards)
    local yes = Fk:getCardById(card).number == 1
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    if player.dead then return end
    if yes then
      room:invalidateSkill(player, self.name, "-turn")
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    end
  end,
}
local lianjie = fk.CreateTriggerSkill{
  name = "lianjie",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and player:getHandcardNum() < player.maxHp and
      U.IsUsingHandcard(player, data) and not player:isKongcheng() and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number >= data.card.number
      end) and
      not table.contains(player:getTableMark("lianjie-turn"), data.card.number)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "lianjie-turn", data.card.number)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name, "top", "@@lianjie-inhand-turn")
  end,
}
local lianjie_targetmod = fk.CreateTargetModSkill{
  name = "#lianjie_targetmod",
  bypass_times = function (self, player, skill, scope, card, to)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
}
local jiangxian = fk.CreateActiveSkill{
  name = "jiangxian",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  prompt = "#jiangxian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@@jiangxian-turn", 1)
  end,
}
local jiangxian_delay = fk.CreateTriggerSkill{
  name = "#jiangxian_delay",
  mute = true,
  events = {fk.DamageCaused, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target and target == player and player:getMark("@@jiangxian-turn") > 0 then
      if event == fk.DamageCaused then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data[1]
        return (use.extra_data or {}).jiangxian == player.id
      end
      elseif event == fk.TurnEnd then
        return player:hasSkill(lianjie, true) and
          (player:hasSkill(lianjie, true) or player:hasSkill(chaozhen, true))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    elseif event == fk.TurnEnd then
      local choices = table.filter({"lianjie", "chaozhen"}, function (s)
        return player:hasSkill(s, true)
      end)
      local choice = room:askForChoice(player, choices, "jiangxian", "#jiangxian-lose")
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and data.card.is_damage_card and
      data.card:getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiangxian = player.id
  end,
}
lianjie:addRelatedSkill(lianjie_targetmod)
jiangxian:addRelatedSkill(jiangxian_delay)
huangfusong:addSkill(chaozhen)
huangfusong:addSkill(lianjie)
huangfusong:addSkill(jiangxian)
Fk:loadTranslationTable{
  ["wm__huangfusong"] = "武皇甫嵩",
  ["#wm__huangfusong"] = "襄武翼汉",
  ["illustrator:wm__huangfusong"] = "",

  ["chaozhen"] = "朝镇",
  [":chaozhen"] = "准备阶段或当你进入濒死状态时，你可以选择从场上或牌堆中随机获得一张点数最小的牌，若此牌点数为A，你回复1点体力，"..
  "此技能本回合失效。",
  ["lianjie"] = "连捷",
  [":lianjie"] = "当你使用手牌指定目标后，若你手牌的点数均不小于此牌点数（每个点数每回合限一次，无点数视为0），你可以将手牌摸至体力上限，"..
  "本回合使用以此法摸到的牌无距离次数限制。",
  ["jiangxian"] = "将贤",
  [":jiangxian"] = "限定技，出牌阶段，你可以令本回合使用因〖连捷〗摸的牌造成伤害时，此伤害+1。若如此做，回合结束后失去〖连捷〗或〖朝镇〗。",
  ["#chaozhen-invoke"] = "朝镇：你可以从场上或牌堆中随机获得一张点数最小的牌",
  ["@@lianjie-inhand-turn"] = "连捷",
  ["#jiangxian"] = "将贤：令你本回合使用〖连捷〗牌伤害+1，回合结束时失去““连捷”或“朝镇”！",
  ["#jiangxian_delay"] = "将贤",
  ["@@jiangxian-turn"] = "将贤",
}



return extension
