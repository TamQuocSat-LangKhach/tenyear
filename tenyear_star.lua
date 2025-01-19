local extension = Package("tenyear_star")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：袁术 董卓 袁绍 张昭
local yuanshu = General(extension, "tystar__yuanshu", "qun", 4)
local canxi = fk.CreateTriggerSkill{
  name = "canxi",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.HpRecover, fk.TargetConfirmed, fk.GameStart, fk.RoundStart},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.DamageCaused then
      return target and player:getMark("@canxi1-round") == target.kingdom and
      not table.contains(player:getTableMark("canxi1-turn"), target.id)
    elseif event == fk.HpRecover then
      return player:getMark("@canxi2-round") == target.kingdom and
      not target.dead and target ~= player and not table.contains(player:getTableMark("canxi21-turn"), target.id)
    elseif event == fk.TargetConfirmed then
      if player == target and data.from ~= player.id then
        local p = player.room:getPlayerById(data.from)
        return player:getMark("@canxi2-round") == p.kingdom and not table.contains(player:getTableMark("canxi22-turn"), p.id)
      end
    elseif event == fk.RoundStart then
      return #player:getTableMark("@canxi_exist_kingdoms") > 0
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:addTableMark(player, "canxi1-turn", target.id)
      data.damage = data.damage + 1
    elseif event == fk.HpRecover then
      room:notifySkillInvoked(player, self.name, "control")
      room:addTableMark(player, "canxi21-turn", target.id)
      room:loseHp(target, 1, self.name)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:addTableMark(player, "canxi22-turn", data.from)
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif event == fk.RoundStart then
      room:notifySkillInvoked(player, self.name, "special")
      local choice1 = room:askForChoice(player, player:getMark("@canxi_exist_kingdoms"), self.name, "#canxi-choice1")
      local choice2 = room:askForChoice(player, {"canxi1", "canxi2"}, self.name, "#canxi-choice2:::"..choice1, true)
      room:setPlayerMark(player, "@"..choice2.."-round", choice1)
    elseif event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "special")
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      room:setPlayerMark(player, "@canxi_exist_kingdoms", kingdoms)
      local n = #table.filter({"wei", "shu", "wu", "qun"}, function(s)
        return not table.contains(kingdoms, s)
      end)
      if n > 0 then
        room:changeMaxHp(player, n)
      end
    end
  end,

  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "@canxi_exist_kingdoms", 0)
    room:setPlayerMark(player, "@canxi1-round", 0)
    room:setPlayerMark(player, "@canxi2-round", 0)
  end,
}
local canxi_distance = fk.CreateDistanceSkill{
  name = "#canxi_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    return -#table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(canxi) and p:getMark("@canxi1-round") == from.kingdom
    end)
  end,
}
local pizhi = fk.CreateTriggerSkill{
  name = "pizhi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd, fk.Death},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseEnd then
        return target == player and player.phase == Player.Finish and player:getMark("canxi_removed_kingdoms") > 0
      elseif event == fk.Death then
        return player:getMark("@canxi1-round") == target.kingdom or player:getMark("@canxi2-round") == target.kingdom or
          (not table.find(player.room.alive_players, function(p)
            return p.kingdom == target.kingdom
          end) and table.contains(player:getTableMark("@canxi_exist_kingdoms"), target.kingdom))
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Death then
      if player:getMark("@canxi1-round") == target.kingdom then
        room:setPlayerMark(player, "@canxi1-round", 0)
      end
      if player:getMark("@canxi2-round") == target.kingdom then
        room:setPlayerMark(player, "@canxi2-round", 0)
      end
      local mark = player:getMark("@canxi_exist_kingdoms")
      if table.removeOne(mark, target.kingdom) then
        room:setPlayerMark(player, "@canxi_exist_kingdoms", #mark > 0 and mark or 0)
        room:addPlayerMark(player, "canxi_removed_kingdoms")
      end
      player:drawCards(player:getMark("canxi_removed_kingdoms"), self.name)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    else
      player:drawCards(player:getMark("canxi_removed_kingdoms"), self.name)
    end
  end,
}
local zhonggu = fk.CreateTriggerSkill{
  name = "zhonggu$",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local n = #table.filter(room.alive_players, function(p) return p.kingdom == "qun" end)
    if room:getBanner("RoundCount") >= n then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.n = data.n + 2
    else
      room:notifySkillInvoked(player, self.name, "negative")
      data.n = data.n - 1
    end
  end,
}
canxi:addRelatedSkill(canxi_distance)
yuanshu:addSkill(canxi)
yuanshu:addSkill(pizhi)
yuanshu:addSkill(zhonggu)
Fk:loadTranslationTable{
  ["tystar__yuanshu"] = "星袁术",
  ["#tystar__yuanshu"] = "狂貔猖貅",
  ["designer:tystar__yuanshu"] = "头发好借好还",
  ["illustrator:tystar__yuanshu"] = "黯萤岛工作室",
  ["canxi"] = "残玺",
  [":canxi"] = "锁定技，游戏开始时，你获得场上各势力的“玺角”标记，其中魏、蜀、吴、群每少一个势力你加1点体力上限。每轮开始时，"..
  "你选择一个“玺角”势力并选择一个效果生效直到下轮开始：<br>「妄生」：该势力角色每回合首次造成伤害+1，计算与其他角色距离-1；<br>"..
  "「向死」：该势力其他角色每回合首次回复体力后失去1点体力，每回合对你使用的第一张牌无效。",
  ["pizhi"] = "圮秩",
  [":pizhi"] = "锁定技，结束阶段，你摸X张牌；有角色死亡时，若其势力与当前生效的“玺角”势力相同或是该势力最后一名角色，你失去此“玺角”，"..
  "然后摸X张牌并回复1点体力（X为你已失去的“玺角”数）。",
  ["zhonggu"] = "冢骨",
  [":zhonggu"] = "主公技，锁定技，若游戏轮数不小于群势力角色数，你摸牌阶段摸牌数+2，否则-1。",

  ["@canxi_exist_kingdoms"] = "",
  ["#canxi-choice1"] = "残玺：选择本轮生效的“玺角”势力",
  ["#canxi-choice2"] = "残玺：选择本轮对 %arg 势力角色生效的效果",
  ["canxi1"] = "「妄生」",
  [":canxi1"] = "每回合首次造成伤害+1，计算与其他角色距离-1",
  ["@canxi1-round"] = "「妄生」",
  ["canxi2"] = "「向死」",
  [":canxi2"] = "每回合首次回复体力后失去1点体力，每回合对你使用的第一张牌无效",
  ["@canxi2-round"] = "「向死」",

  ["$canxi1"] = "大势散于天下，全宝玺者其谁？",
  ["$canxi2"] = "汉祚已僵待死，吾可取而代之。",
  ["$pizhi1"] = "春秋无义，秉笔汗青者，胜者尔。",
  ["$pizhi2"] = "大厦将倾，居危墙之下者，愚夫尔。",
  ["$zhonggu1"] = "既登九五之尊位，何惧为冢中之枯骨？",
  ["$zhonggu2"] = "天下英雄多矣，大浪淘沙，谁不老冢中？",
  ["~tystar__yuanshu"] = "英雄不死则已，死则举大名尔……",
}

local dongzhuo = General(extension, "tystar__dongzhuo", "qun", 5)
local weilin = fk.CreateTriggerSkill{
  name = "weilin",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase ~= Player.NotActive then
      local room = player.room
      if #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].to == data.to end) == 0 then
        local n = 0
        return #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          if use and use.from == player.id then
            n = n + 1
          end
          return n >= data.to.hp
        end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhangrong = fk.CreateTriggerSkill{
  name = "zhangrong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(self) and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "zhangrong_active", "#zhangrong-invoke", true)
    if dat then
      local tos = dat.targets
      player.room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos, choice = dat.interaction}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.tos
    room:setPlayerMark(player, "zhangrong-turn", targets)
    local choice = self.cost_data.choice
    player:drawCards(#targets, self.name)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if choice == "zhangrong1" then
          room:loseHp(p, 1, self.name)
        elseif choice == "zhangrong2" then
          room:askForDiscard(p, 1, 1, false, self.name, false)
        end
      end
    end
  end,
}
local zhangrong_delay = fk.CreateTriggerSkill{
  name = "#zhangrong_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player:getMark("zhangrong-turn") ~= 0 then
      local playerIds = table.filter(player:getMark("zhangrong-turn"), function (pid)
        return not player.room:getPlayerById(pid).dead
      end)
      player.room.logic:getActualDamageEvents(1, function(e)
        table.removeOne(playerIds, e.data[1].to.id)
        return #playerIds == 0
      end)
      return #playerIds > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhangrong")
    room:notifySkillInvoked(player, "zhangrong", "negative")
    room:loseHp(player, 1, "zhangrong")
  end,
}
local zhangrong_active = fk.CreateActiveSkill{
  name = "zhangrong_active",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  interaction = function()
    return UI.ComboBox {choices = {"zhangrong1", "zhangrong2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter  = function (self, to_select, selected, selected_cards, card)
    if #selected < Self.hp then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "zhangrong1" then
        return target.hp >= Self.hp
      elseif self.interaction.data == "zhangrong2" then
        return target:getHandcardNum() >= Self:getHandcardNum() and not target:isKongcheng()
      end
    end
  end,
}
local haoshou = fk.CreateTriggerSkill{
  name = "haoshou$",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "analeptic" and target ~= player and target.kingdom == "qun" and player:isWounded()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, nil, "#haoshou-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(target.id, {player.id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = target,
      skillName = self.name
    })
  end,
}
Fk:addSkill(zhangrong_active)
zhangrong:addRelatedSkill(zhangrong_delay)
dongzhuo:addSkill(weilin)
dongzhuo:addSkill(zhangrong)
dongzhuo:addSkill(haoshou)
Fk:loadTranslationTable{
  ["tystar__dongzhuo"] = "星董卓",
  ["#tystar__dongzhuo"] = "千里草的魔阀",
  ["designer:tystar__dongzhuo"] = "对勾对勾w",
  ["illustrator:tystar__dongzhuo"] = "黯荧岛工作室",
  ["weilin"] = "威临",
  [":weilin"] = "锁定技，你于回合内对一名角色造成伤害时，若其本回合没有受到过伤害且你本回合已使用牌数不小于其体力值，则此伤害+1。",
  ["zhangrong"] = "掌戎",
  [":zhangrong"] = "准备阶段，你可以选择一项：1.令至多X名体力值不小于你的角色各失去1点体力；2.令至多X名手牌数不小于你的角色各弃置一张手牌"..
  "（X为你的体力值）。这些角色执行你选择的选项前，你摸选择角色数量的牌。本回合结束时，若这些角色中有存活且本回合未受到伤害的角色，你失去1点体力",
  ["haoshou"] = "豪首",
  [":haoshou"] = "主公技，其他群雄势力角色使用【酒】后，可令你回复1点体力。",
  ["#zhangrong-invoke"] = "掌戎：选择角色各失去1点体力或各弃置一张手牌",
  ["zhangrong_active"] = "掌戎",
  ["zhangrong1"] = "失去体力",
  ["zhangrong2"] = "弃置手牌",
  ["#haoshou-invoke"] = "豪首：是否令 %src 回复1点体力？",

  ["$weilin1"] = "今吾入京城，欲寻人而食。",
  ["$weilin2"] = "天下事在我，我今为之，谁敢不从？",
  ["$zhangrong1"] = "尔欲行大事，问过吾掌中兵刃否？",
  ["$zhangrong2"] = "西凉铁骑曳城，天下高楼可摧！",
  ["$haoshou1"] = "满朝主公，试吾剑不利否？",
  ["$haoshou2"] = "顺我者生，逆我者十死无生！",
  ["~tystar__dongzhuo"] = "美人迷人眼，溢权昏人智……",
}

local yuanshao = General(extension, "tystar__yuanshao", "qun", 4)
local xiaoyan = fk.CreateTriggerSkill{
  name = "xiaoyan",
  anim_type = "offensive",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player)
    if #targets == 0 then return false end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        local card = room:askForCard(p, 1, 1, true, self.name, true, ".", "#xiaoyan-give:"..player.id)
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, p.id)
          if not p.dead and p:isWounded() then
            room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name,
            }
          end
        end
      end
    end
  end,
}

---@param from Player @ 使用者
---@param card Card @ 牌
---@param to Player @ 目标角色
---@return boolean
local zongshiWithinTimesLimit = function(from, to, card)
  --FIXME: 幽默手动判次数限制，直接摆
  local limited_cards = {
    {"slash"},
    {"analeptic"},
    {},
    {},
  }
  local skill = card.skill
  for i = 1, 4, 1 do
    if table.contains(limited_cards[i], card.trueName) and not skill:withinTimesLimit(from, i, card, card.trueName, to) then
      return false
    end
  end
  return true
end

---@param room Room @ 游戏房间
---@param player Player @ 使用者
---@param card Card @ 牌
---@return string[] @ 返回合法目标的角色数组
local getZongshiTargets = function(room, player, card)
  if player:prohibitUse(card) then return {} end
  local extra_data = {
    bypass_distances = true,
    bypass_times = (player.phase ~= Player.Play)
  }
  if not player:canUse(card, extra_data) then return {} end
  local skill = card.skill
  local targets = {}
  for _, p in ipairs(room.alive_players) do
    if not player:isProhibited(p, card) and skill:modTargetFilter(p.id, {}, player, card, false) then
      if player.phase ~= Player.Play or zongshiWithinTimesLimit(player, p, card) then
        table.insert(targets, p.id)
      end
    end
  end
  return targets
end

local zongshiy = fk.CreateActiveSkill{
  name = "zongshiy",
  prompt = function (self, cards, selected_targets)
    if #cards == 0 then
      return "#zongshiy-active"
    else
      local card = Fk:getCardById(cards[1])
      local i = #table.filter(Self:getCardIds(Player.Hand), function (id)
        return id ~= cards[1] and Fk:getCardById(id).suit == card.suit
      end)
      return "#zongshiy-use:::" .. card.trueName .. ":" .. tostring(i)
    end
  end,
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic or card:isCommonTrick() then
        --FIXME：未测试，暂且排除【借刀杀人】类卡。
        if card.skill:getMinTargetNum() > 1 then return false end

        local suit = card.suit
        if suit == Card.NoSuit then return false end

        local cards = table.filter(Self:getCardIds(Player.Hand), function (id)
          return id ~= to_select and Fk:getCardById(id).suit == suit
        end)
        if #cards == 0 then return false end

        local to_use = Fk:cloneCard(card.name)
        to_use.skillName = self.name
        to_use:addSubcards(cards)
        return #getZongshiTargets(Fk:currentRoom(), Self, to_use) > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:getCardById(effect.cards[1])
    local suit = card.suit
    player:showCards(effect.cards)
    if player.dead then return end
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return id ~= effect.cards[1] and Fk:getCardById(id).suit == suit
    end)
    if #cards == 0 then return end
    local to_use = Fk:cloneCard(card.name)
    to_use.skillName = self.name
    to_use:addSubcards(cards)
    if player:prohibitUse(to_use) then return end
    local targets = getZongshiTargets(room, player, to_use)
    if #targets == 0 then return end
    targets = room:askForChoosePlayers(player, targets, 1, #cards,
    "#zongshiy-target:::" .. to_use:toLogString() .. ":" .. tostring(#cards), self.name, false, true)

    room:useCard{
      from = player.id,
      tos = table.map(targets, function(p) return {p} end),
      card = to_use,
      extraUse = (player.phase == Player.NotActive),
    }
  end,
}
local jiaowang = fk.CreateTriggerSkill{
  name = "jiaowang",
  frequency = Skill.Compulsory,
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local round_event = logic:getCurrentEvent()
      return #deathevents == 0 or deathevents[#deathevents].id < round_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    xiaoyan:use(event, target, player, data)
  end,
}
local aoshi = fk.CreateTriggerSkill{
  name = "aoshi$",
  attached_skill_name = "aoshi_other&",

  refresh_events = {fk.AfterPropertyChange},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(self, true)
    end) then
      room:handleAddLoseSkills(player, "aoshi_other&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-aoshi_other&", nil, false, true)
    end
  end,

  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "qun" then
        room:handleAddLoseSkills(p, self.attached_skill_name, nil, false, true)
      end
    end
  end
}
local aoshi_other = fk.CreateActiveSkill{
  name = "aoshi_other&",
  anim_type = "support",
  prompt = "#aoshi-active",
  mute = true,
  can_use = function(self, player)
    if player.kingdom ~= "qun" then return false end
    local targetRecorded = player:getTableMark("aoshi_sources-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(aoshi) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return
    #selected == 0 and to_select ~= Self.id and
    Fk:currentRoom():getPlayerById(to_select):hasSkill(aoshi) and
    not table.contains(Self:getTableMark("aoshi_sources-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, aoshi.name)
    target:broadcastSkillInvoke(aoshi.name)
    room:addTableMarkIfNeed(player, "aoshi_sources-phase", target.id)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if target.dead then return end
    room:askForUseActiveSkill(target, "zongshiy", "#zongshiy-active", true)
  end,
}

Fk:addSkill(aoshi_other)
yuanshao:addSkill(xiaoyan)
yuanshao:addSkill(zongshiy)
yuanshao:addSkill(jiaowang)
yuanshao:addSkill(aoshi)

Fk:loadTranslationTable{
  ["tystar__yuanshao"] = "星袁绍",
  ["#tystar__yuanshao"] = "熏灼群魔",
  ["illustrator:tystar__yuanshao"] = "鬼画府",
  ["xiaoyan"] = "硝焰",
  [":xiaoyan"] = "游戏开始时，所有其他角色各受到你造成的1点火焰伤害，然后这些角色可以依次交给你一张牌并回复1点体力。",
  ["zongshiy"] = "纵势",
  [":zongshiy"] = "出牌阶段，你可以展示一张基本牌或普通锦囊牌，然后将此花色的所有其他手牌当这张牌使用（此牌可指定的目标数改为以此法使用的牌数）。",
  ["jiaowang"] = "骄妄",
  [":jiaowang"] = "锁定技，每轮结束时，若本轮没有角色死亡，你失去1点体力并发动〖硝焰〗。",
  ["aoshi"] = "傲势",
  [":aoshi"] = "主公技，其他群势力角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以发动一次〖纵势〗。",

  ["aoshi_other&"] = "傲势",
  [":aoshi_other&"] = "出牌阶段限一次，你可将一张手牌交给星袁绍，然后其可以发动一次〖纵势〗。",

  ["#xiaoyan-give"] = "硝焰：你可以选择一张牌交给%src来回复1点体力",
  ["#zongshiy-active"] = "发动 纵势，选择展示一张基本牌或普通锦囊牌",
  ["#zongshiy-use"] = "发动 纵势，将手牌中其他所有同花色的牌当【%arg】使用，并可指定至多%arg2个目标",
  ["#zongshiy-target"] = "纵势：为即将使用的%arg指定至多%arg2个目标（无距离限制）",
  ["#aoshi-active"] = "发动 傲势，选择一张手牌交给一名拥有“傲势”的角色",

  ["$xiaoyan1"] = "万军付薪柴，戾火燃苍穹。",
  ["$xiaoyan2"] = "九州硝烟起，烽火灼铁衣。",
  ["$zongshiy1"] = "四世三公之家，当为天下之望。",
  ["$zongshiy2"] = "大势在我，可怀问鼎之心。",
  ["$jiaowang1"] = "剑顾四野，马踏青山，今谁堪敌手？",
  ["$jiaowang2"] = "并土四州，带甲百万，吾可居大否？",
  ["$aoshi1"] = "无傲骨近于鄙夫，有傲心方为君子。",
  ["$aoshi2"] = "得志则喜，临富贵如何不骄？",
  ["~tystar__yuanshao"] = "骄兵必败，奈何不记前辙……",
}

local zhangzhao = General(extension, "tystar__zhangzhao", "wu", 3)
local function DoZhongyanz(player, source, choice)
  local room = player.room
  if choice == "recover" then
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = source,
        skillName = "zhongyanz",
      }
    end
  else
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getCardIds("ej") > 0
    end), Util.IdMapper)
    if not player.dead and #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhongyanz-choose", "zhongyanz", false)
      to = room:getPlayerById(to[1])
      local cards = room:askForCardsChosen(player, to, 1, 1, "ej", "zhongyanz")
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, "zhongyanz", "", true, player.id)
    end
  end
end
local zhongyanz = fk.CreateActiveSkill{
  name = "zhongyanz",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#zhongyanz",
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    if to.dead or to:isKongcheng() then
      room:moveCards({
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      return
    end
    local results = U.askForExchange(to, "Top", "hand_card", cards, to:getCardIds("h"), "#zhongyanz-exchange", 1, false)
    local to_hand = {}
    if #results > 0 then
      to_hand = table.filter(results, function(id)
        return table.contains(cards, id)
      end)
      table.removeOne(results, to_hand[1])
      for i = #cards, 1, -1 do
        if cards[i] == to_hand[1] then
          cards[i] = results[1]
          break
        end
      end
    else
      to_hand, cards[1] = {cards[1]}, to:getCardIds("h")[1]
    end
    U.swapCardsWithPile(to, cards, to_hand, self.name, "Top", false, player.id)
    if to.dead then return end
    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end) then
      local choices = {"recover", "zhongyanz_prey"}
      local choice = room:askForChoice(to, choices, self.name)
      DoZhongyanz(to, player, choice)
      if to ~= player then
        table.removeOne(choices, choice)
        DoZhongyanz(player, player, choices[1])
      end
    end
  end,
}
local jinglun = fk.CreateTriggerSkill{
  name = "jinglun",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target and not target.dead and player:distanceTo(target) <= 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jinglun-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = #target:getCardIds("e")
    if n > 0 then
      target:drawCards(n, self.name)
    end
    if target.dead then return end
    room:notifySkillInvoked(player, "zhongyanz")
    player:broadcastSkillInvoke("zhongyanz")
    zhongyanz:onUse(room, {
      from = player.id,
      tos = {target.id},
    })
  end,
}
zhangzhao:addSkill(zhongyanz)
zhangzhao:addSkill(jinglun)
Fk:loadTranslationTable{
  ["tystar__zhangzhao"] = "星张昭",
  ["#tystar__zhangzhao"] = "忠謇方直",
  ["illustrator:tystar__zhangzhao"] = "君桓文化",

  ["zhongyanz"] = "忠言",
  [":zhongyanz"] = "出牌阶段限一次，你可展示牌堆顶三张牌，令一名角色将一张手牌交换其中一张牌。然后若这些牌颜色相同，"..
  "其选择回复1点体力或获得场上一张牌；若该角色不为你，你执行另一项。",
  ["jinglun"] = "经纶",
  [":jinglun"] = "每回合限一次，你距离1以内的角色造成伤害后，你可以令其摸X张牌，并对其发动〖忠言〗（X为其装备区牌数）。",
  ["#zhongyanz"] = "忠言：亮出牌堆顶三张牌，令一名角色用一张手牌交换其中一张牌",
  ["#zhongyanz-exchange"] = "忠言：请用一张手牌交换其中一张牌",
  ["zhongyanz_prey"] = "获得场上一张牌",
  ["#zhongyanz-choose"] = "忠言：选择一名角色，获得其场上一张牌",
  ["#jinglun-invoke"] = "经纶：是否令 %dest 摸牌并对其发动“忠言”？",

  ["$zhongyanz1"] = "腹有珠玑，可坠在殿之玉盘。",
  ["$zhongyanz2"] = "胸纳百川，当汇凌日之沧海。",
  ["$jinglun1"] = "千夫诺诺，不如一士谔谔。",
  ["$jinglun2"] = "忠言如药，苦口而利身。",
  ["~tystar__zhangzhao"] = "曹公虎豹也，不如以礼早降。",
}

--天璇：荀彧 法正
local xunyu = General(extension, "tystar__xunyu", "wei", 3)
local anshu = fk.CreateTriggerSkill{
  name = "anshu",
  anim_type = "support",
  events = {fk.RoundEnd, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundEnd then
        return true
      elseif event == fk.TurnEnd then
        return table.find(player:getTableMark("anshu-turn"), function (id)
          local p = player.room:getPlayerById(id)
          return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundEnd then
      return room:askForSkillInvoke(player, self.name, nil, "#anshu-use")
    elseif event == fk.TurnEnd then
      local targets = table.filter(player:getTableMark("anshu-turn"), function (id)
        local p = room:getPlayerById(id)
        return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
      end)
      local tos = room:askForChoosePlayers(player, targets, 1, 10, "#anshu-draw", self.name, true)
      if #tos > 0 then
        self.cost_data = {tos = tos}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundEnd then
      local cards = {}
      for _, id in ipairs(room.discard_pile) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic then
          cards[card.trueName] = cards[card.trueName] or {}
          table.insert(cards[card.trueName], id)
        end
      end
      if next(cards) ~= nil then
        local card_data = {}
        for _, name in ipairs({"slash", "jink", "peach", "analeptic"}) do  --按杀闪桃酒顺序排列
          if cards[name] then
            table.insert(card_data, {name, cards[name]})
          end
        end
        for name, ids in pairs(cards) do
          if not table.contains({"slash", "jink", "peach", "analeptic"}, name) and #ids > 0 then  --其他基本牌按牌名排列
            table.insert(card_data, {name, ids})
          end
        end
        local ret = room:askForPoxi(player, self.name, card_data, nil, false)
        ret = table.reverse(ret)
        room:moveCards({
          ids = ret,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
      local targets = table.filter(room:getAlivePlayers(), function (p)
        return not player:isProhibited(p, Fk:cloneCard("amazing_grace"))
      end)
      if #targets == 0 then return end
      local tos = table.map(table.filter(targets, function (p)
        return p:isWounded()
      end), Util.IdMapper)
      if table.contains(targets, player) then
        table.insertIfNeed(tos, player.id)
      end
      local card = Fk:cloneCard("amazing_grace")
      card.skillName = self.name
      local use = {
        from = player.id,
        card = card,
      }
      if #tos > 0 then
        use.extra_data = {}
        use.extra_data.anshu_start = room:askForChoosePlayers(player, tos, 1, 1, "#anshu-choose", self.name, false)[1]
      end
      room:useCard(use)
    elseif event == fk.TurnEnd then
      room:sortPlayersByAction(self.cost_data.tos)
      for _, id in ipairs(self.cost_data.tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          local n = math.min(p.maxHp, 5) - p:getHandcardNum()
          if n > 0 then
            p:drawCards(n, self.name)
          end
        end
      end
    end
  end,

  refresh_events = {fk.BeforeCardUseEffect, fk.CardUseFinished, fk.AfterCardsMove, fk.RoundEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardUseEffect then
      return target == player and data.extra_data and data.extra_data.anshu_start
    elseif event == fk.CardUseFinished then
      return target == player and table.contains(data.card.skillNames, self.name) and data.extra_data and data.extra_data.AGResult
    elseif event == fk.AfterCardsMove then
      if player:getTableMark("anshu_record") ~= 0 then
        local mark = player:getTableMark("anshu_record")
        for _, move in ipairs(data) do
          if move.from and mark[string.format("%.0f", move.from)] then
            return true
          end
        end
      end
    elseif event == fk.RoundEnd then
      return player:getTableMark("anshu_record") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeCardUseEffect then
      local new_tos = {}
      local n = 0
      for i, info in ipairs(data.tos) do
        if info[1] == data.extra_data.anshu_start then
          table.insert(new_tos, info)
          n = i
        end
        if n > 0 and i > n then
          table.insert(new_tos, info)
        end
      end
      for i, info in ipairs(data.tos) do
        if i < n then
          table.insert(new_tos, info)
        end
      end
      data.tos = new_tos
    elseif event == fk.CardUseFinished then
      local mark = {}
      for _, dat in ipairs(data.extra_data.AGResult) do
        local to = room:getPlayerById(dat[1])
        if not to.dead and table.contains(to:getCardIds("h"), dat[2]) then
          mark[string.format("%.0f", to.id)] = mark[string.format("%.0f", to.id)] or {}
          table.insert(mark[string.format("%.0f", to.id)], dat[2])
        end
      end
      room:setPlayerMark(player, "anshu_record", mark)
    elseif event == fk.AfterCardsMove then
      local mark = player:getTableMark("anshu_record")
      for _, move in ipairs(data) do
        if move.from and mark[string.format("%.0f", move.from)] then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.removeOne(mark[string.format("%.0f", move.from)], info.cardId) then
              room:addTableMark(player, "anshu-turn", move.from)
            end
          end
        end
      end
      room:setPlayerMark(player, "anshu_record", mark)
    elseif event == fk.RoundEnd then
      room:setPlayerMark(player, "anshu_record", 0)
    end
  end,
}
Fk:addPoxiMethod{
  name = "anshu",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data)
    if data and #data == #selected then
      local areas = {}
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) then
            table.insertIfNeed(areas, v[2])
            break
          end
        end
      end
      return #areas == #selected
    end
  end,
  prompt = "#anshu_put",
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}
local kuangzuo = fk.CreateActiveSkill{
  name = "kuangzuo",
  anim_type = "support",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 1,
  prompt = "#kuangzuo",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local skills = {"chengfeng"}
    if target.role == "lord" and not table.find(target.player_skills, function(s)
      return s.lordSkill
    end) then
      table.insert(skills, "tongyin")
    end
    room:handleAddLoseSkills(target, skills, nil, true, false)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target), function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#kuangzuo-choose::"..target.id, self.name, false)
    to = room:getPlayerById(to[1])
    local success, dat = room:askForUseActiveSkill(to, "kuangzuo_active", "#kuangzuo-put::"..target.id, false)
    if success and dat then
    else
      dat = {
        cards = {},
      }
      for _, id in ipairs(to:getCardIds("he")) do
        if Fk:getCardById(id).suit ~= Card.NoSuit and
          not table.find(dat.cards, function (id2)
            return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
          end) then
          table.insert(dat.cards, id)
        end
      end
    end
    target:addToPile(self.name, dat.cards, true, self.name, to.id)
  end,
}
local kuangzuo_active = fk.CreateActiveSkill{
  name = "kuangzuo_active",
  card_filter = function(self, to_select, selected)
    return table.contains(Self:getCardIds("he"), to_select) and Fk:getCardById(to_select).suit ~= Card.NoSuit and
      table.every(selected, function(id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
  end,
  feasible = function (self, selected, selected_cards)
    local suits = {}
    for _, id in ipairs(Self:getCardIds("he")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    return #selected_cards == #suits
  end,
}
local chengfeng = fk.CreateViewAsSkill{
  name = "chengfeng",
  pattern = "jink,nullification",
  expand_pile = "kuangzuo",
  prompt = "#chengfeng",
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Self:getPileNameOfId(to_select) == "kuangzuo" then
      local _c = Fk:getCardById(to_select)
      local c
      if _c.color == Card.Red then
        c = Fk:cloneCard("jink")
      elseif _c.color == Card.Black then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c)
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card
    if Fk:getCardById(cards[1]).color == Card.Red then
      card = Fk:cloneCard("jink")
    elseif Fk:getCardById(cards[1]).color == Card.Black then
      card = Fk:cloneCard("nullification")
    end
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function (self, player, use)
    local room = player.room
    if not player.dead then
      local colors = {}
      for _, id in ipairs(player:getPile("kuangzuo")) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      if #colors < 2 and room:askForSkillInvoke(player, self.name, nil, "#chengfeng-put") then
        player:addToPile("kuangzuo", room:getNCards(1), true, self.name, player.id)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if
      not (
        not response and
        (
          response == nil or
          player:getMark("chengfeng_activated") > 0
        ) and
        #player:getPile("kuangzuo") > 0
      )
    then
      return false
    end
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
}
local chengfeng_trigger = fk.CreateTriggerSkill{
  name = "#chengfeng_trigger",

  refresh_events = {fk.HandleAskForPlayCard},
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest and (data.extra_data or {}).chengfeng_effected then
      return player:getMark("chengfeng_activated") > 0
    end

    return
      player:hasSkill(chengfeng) and
      data.eventData and
      data.eventData.to and
      data.eventData.to == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.afterRequest then
      room:setPlayerMark(player, "chengfeng_activated", 0)
    else
      room:setPlayerMark(player, "chengfeng_activated", 1)
      data.extra_data = data.extra_data or {}
      data.extra_data.chengfeng_effected = true
    end
  end,
}
local tongyin = fk.CreateTriggerSkill{
  name = "tongyin$",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from and data.from ~= player and data.card then
      if data.from.kingdom == player.kingdom then
        return player.room:getCardArea(data.card) == Card.Processing
      else
        return not data.from.dead and not data.from:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if data.from.kingdom == player.kingdom then
      return player.room:askForSkillInvoke(player, self.name, nil, "#tongyin1-invoke:::"..data.card)
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#tongyin2-invoke::"..data.from.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    if data.from.kingdom == player.kingdom then
      card = data.card
    else
      room:doIndicate(player.id, {data.from.id})
      card = room:askForCardChosen(player, data.from, "he", self.name, "#tongyin2-put::"..data.from.id)
    end
    player:addToPile("kuangzuo", card, true, self.name, player.id)
  end,
}
Fk:addSkill(kuangzuo_active)
chengfeng:addRelatedSkill(chengfeng_trigger)
xunyu:addSkill(anshu)
xunyu:addSkill(kuangzuo)
xunyu:addRelatedSkill(chengfeng)
xunyu:addRelatedSkill(tongyin)
Fk:loadTranslationTable{
  ["tystar__xunyu"] = "星荀彧",
  ["#tystar__xunyu"] = "怀忠念治",
  ["designer:tystar__xunyu"] = "对勾对勾w",
  ["illustrator:tystar__xunyu"] = "黯荧岛",

  ["anshu"] = "安庶",
  [":anshu"] = "每轮结束时，你可以将弃牌堆中牌名不同的基本牌各一张置于牌堆顶，然后视为使用一张【五谷丰登】，你选择从你或一名已受伤角色开始"..
  "结算此【五谷丰登】。直到下轮结束，若有角色失去了因此【五谷丰登】选择的牌，当前回合结束时你可以令其将手牌摸至体力上限（最多摸至五张）。",
  ["kuangzuo"] = "匡祚",
  [":kuangzuo"] = "限定技，出牌阶段，你可以令一名角色获得技能〖承奉〗（若其为主公且没有主公技，则额外获得〖统荫〗），然后令另一名角色将"..
  "每种花色各一张牌置于获得技能角色的武将牌上（称为“匡祚”牌）。",
  ["chengfeng"] = "承奉",
  [":chengfeng"] = "每回合限一次，你可以将一张红色“匡祚”牌当【闪】或黑色“匡祚”牌当【无懈可击】对即将对你生效的牌使用，此牌结算后，"..
  "若“匡祚”不足两种颜色，你可以将牌堆顶一张牌置为“匡祚”。",
  ["tongyin"] = "统荫",
  [":tongyin"] = "主公技，当你受到其他角色使用牌造成的伤害后，若伤害来源与你势力相同，你可以将造成伤害的牌置为“匡祚”；若与你势力不同，"..
  "你可以将其一张牌置为“匡祚”。",
  ["#anshu-use"] = "安庶：是否视为使用【五谷丰登】？",
  ["#anshu-draw"] = "安庶：你可以令这些角色将手牌摸至体力上限（最多摸至五张）",
  ["#anshu_put"] = "安庶：将每种牌名各一张牌置于牌堆顶（按选择的顺序从上到下放置）",
  ["#anshu-choose"] = "安庶：选择一名角色，从其开始结算此【五谷丰登】",
  ["#kuangzuo"] = "匡祚：令一名角色获得技能〖承奉〗，若其为主公且没有主公技，则额外获得〖统荫〗",
  ["#kuangzuo-choose"] = "匡祚：令一名角色将其每种花色各一张牌置为 %dest 的“匡祚”牌",
  ["kuangzuo_active"] = "匡祚",
  ["#kuangzuo-put"] = "匡祚：请将每种花色各一张牌置为 %dest 的“匡祚”牌",
  ["#chengfeng"] = "承奉：你可以将红色“匡祚”当【闪】、黑色“匡祚”当【无懈可击】对即将对你生效的牌使用",
  ["#chengfeng-put"] = "承奉：是否将牌堆顶一张牌置为“匡祚”？",
  ["#tongyin1-invoke"] = "统荫：是否将%arg置为“匡祚”？",
  ["#tongyin2-invoke"] = "统荫：是否将 %dest 的一张牌置为“匡祚”？",
  ["#tongyin2-put"] = "统荫：将 %dest 的一张牌置为“匡祚”",

  ["$anshu1"] = "春种其粟，秋得其实。",
  ["$anshu2"] = "与民休养生息，则国可得安泰。",
  ["$kuangzuo1"] = "家国兴衰，系于一肩之上，朝纲待重振之时。",
  ["$kuangzuo2"] = "吾辈向汉，当矢志不渝，不可坐视神州陆沉。",
  ["$chengfeng1"] = "臣簇于君侧，为耳目，为股肱。",
  ["$chengfeng2"] = "承臣子之任，奉天子之统。",
  ["~tystar__xunyu"] = "臣固忠于国，非一家之臣。",
}

local fazheng = General(extension, "tystar__fazheng", "shu", 3)
local zhijif = fk.CreateTriggerSkill{
  name = "zhijif",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local extraData = {
      num = 999,
      min_num = 0,
      include_equip = false,
      skillName = self.name,
      pattern = ".",
    }
    local success, dat = player.room:askForUseActiveSkill(player, "discard_skill", "#zhijif-invoke", true, extraData)
    if success then
      self.cost_data = {cards = dat.cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data.cards > 0 then
      room:throwCard(self.cost_data.cards, self.name, player, player)
    end
    if player.dead then return end
    local n = 5 - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
    end
    if player.dead then return end
    n = #self.cost_data.cards - math.max(n, 0)
    if n > 0 then
      local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, n,
        "#zhijif-choose:::"..n, self.name, true)
      if #targets > 0 then
        room:sortPlayersByAction(targets)
        for _, id in ipairs(targets) do
          local p = room:getPlayerById(id)
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = self.name,
            }
          end
        end
      end
    elseif n == 0 then
      room:setPlayerMark(player, "@@zhijif-turn", 1)
    elseif n < 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards.."-turn", 2)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@zhijif-turn") > 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function (self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local anji = fk.CreateTriggerSkill{
  name = "anji",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) and data.card.suit ~= Card.NoSuit then
      local mark = player:getTableMark("anji-round")
      if #mark == 4 then
        local x = mark[data.card.suit]
        return table.every(mark, function (y)
          return y >= x
        end)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true) and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("anji-round")
    if type(mark) ~= "table" then
      mark = {0,0,0,0}
    end
    mark[data.card.suit] = mark[data.card.suit] + 1
    room:setPlayerMark(player, "anji-round", mark)
    local x, y = mark[1], 0
    local babymark = 1
    for i = 2, 4, 1 do
      y = mark[i]
      if y == x then
        babymark = 0
      elseif y < x then
        babymark = i
        x = y
      end
    end
    if babymark == 0 then
      room:setPlayerMark(player, "@anji-round", 0)
    else
      room:setPlayerMark(player, "@anji-round", U.ConvertSuit(babymark, "int", "sym"))
    end
  end,
}
fazheng:addSkill(zhijif)
fazheng:addSkill(anji)
Fk:loadTranslationTable{
  ["tystar__fazheng"] = "星法正",
  ["#tystar__fazheng"] = "定军佐功",
  ["illustrator:tystar__fazheng"] = "匠人绘",

  ["zhijif"] = "知机",
  [":zhijif"] = "准备阶段，你可以弃置任意张手牌（可以不弃），然后将手牌摸至5张。若你因此弃牌数比摸牌数：多，你可以对至多X名其他角色各造成1点伤害"..
  "（X为弃牌数比摸牌数多的数量）；相等，你本回合使用牌不能被响应；少，你本回合手牌上限+2。",
  ["anji"] = "谙计",
  [":anji"] = "锁定技，当一名角色使用牌时，若此牌花色是本轮中使用次数最少的，你摸一张牌。",
  ["#zhijif-invoke"] = "知机：你可以弃置任意张手牌，然后将手牌摸至5张，根据弃牌数和摸牌数执行效果",
  ["#zhijif-choose"] = "知机：你可以对至多%arg名其他角色各造成1点伤害",
  ["@@zhijif-turn"] = "知机 不可响应",
  ["@anji-round"] = "谙计",

  ["$zhijif1"] = "筹谋部划，知天机，行人事。",
  ["$zhijif2"] = "渊孤军出寨，可一鼓击之。",
  ["$anji1"] = "兵法谙熟于胸，今乃施为之时。",
  ["$anji2"] = "我军待时而动，以有备击不备。",
  ["~tystar__fazheng"] = "我当为君之子房，奈何命寿将尽……",
}

--玉衡：曹仁 张春华
local caoren = General(extension, "tystar__caoren", "wei", 4)
local sujun = fk.CreateTriggerSkill{
  name = "sujun",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      2 * #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) == player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local lifengc = fk.CreateViewAsSkill{
  name = "lifengc",
  pattern = "slash,nullification",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "nullification"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      Self:getMark("lifengc_"..Fk:getCardById(to_select):getColorString().."-turn") == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card_name = self.interaction.data
    local card = Fk:cloneCard(card_name)
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng()
  end,
}
local lifengc_trigger = fk.CreateTriggerSkill{
  name = "#lifengc_trigger",

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(lifengc, true) and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "lifengc_"..data.card:getColorString().."-turn", 1)
  end,
}
lifengc:addRelatedSkill(lifengc_trigger)
caoren:addSkill(sujun)
caoren:addSkill(lifengc)
Fk:loadTranslationTable{
  ["tystar__caoren"] = "星曹仁",
  ["#tystar__caoren"] = "伏波四方",
  ["designer:tystar__caoren"] = "追风少年",
  ["illustrator:tystar__caoren"] = "君桓文化",
  ["sujun"] = "肃军",
  [":sujun"] = "当你使用一张牌时，若你手牌中基本牌与非基本牌数量相等，你可以摸两张牌。",
  ["lifengc"] = "砺锋",
  [":lifengc"] = "你可以将一张本回合未被使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。",

  ["$sujun1"] = "将为军魂，需以身作则。",
  ["$sujun2"] = "整肃三军，可育虎贲。",
  ["$lifengc1"] = "锋出百砺，健卒亦如是。",
  ["$lifengc2"] = "强军者，必校之以三九，练之三伏。",
  ["~tystar__caoren"] = "濡须之败，此生之耻……",
}

local zhangchunhua = General(extension, "tystar__zhangchunhua", "wei", 3, 3, General.Female)
local liangyan = fk.CreateActiveSkill{
  name = "liangyan",
  target_num = 1,
  min_card_num = 0,
  max_card_num = 2,
  prompt = function(self, card, selected_targets)
    if self.interaction.data == "liangyan_discard" then
      return "#liangyan1-active"
    else
      return "#liangyan2-active"
    end
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"draw2", "draw1", "liangyan_discard"}
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return self.interaction.data == "liangyan_discard" and #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and (#selected_cards > 0 or self.interaction.data ~= "liangyan_discard")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    if n > 0 then
      room:throwCard(effect.cards, self.name, player, player)
      if target.dead then return end
      target:drawCards(n, self.name)
      if not (player.dead or target.dead) and player:getHandcardNum() == target:getHandcardNum() then
        room:setPlayerMark(target, "@@liangyan", 1)
      end
    else
      n = 1
      if self.interaction.data == "draw2" then
        n = 2
      end
      player:drawCards(n, self.name)
      if target.dead then return end
      room:askForDiscard(target, n, n, true, self.name, false)
      if not (player.dead or target.dead) and player:getHandcardNum() == target:getHandcardNum() then
        room:setPlayerMark(player, "@@liangyan", 1)
      end
    end
  end,
}
local liangyan_delay = fk.CreateTriggerSkill{
  name = "#liangyan_delay",
  events = {fk.EventPhaseChanging},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@liangyan") > 0 and data.to == Player.Discard
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@liangyan", 0)
    player:skip(Player.Discard)
    return true
  end,
}
local minghui = fk.CreateTriggerSkill{
  name = "minghui",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local x = player:getHandcardNum()
      if x == 0 then return true end
      local minghui_max, minghui_min, all_kongcheng = true, true, true
      local y = 0
      for _, p in ipairs(player.room.alive_players) do
        if p ~= player then
          y = p:getHandcardNum()
          if y > 0 then
            all_kongcheng = false
          end
          if x > y then
            minghui_min = false
          elseif x < y then
            minghui_max = false
          end
        end
      end
      return (minghui_max and not all_kongcheng) or minghui_min
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getHandcardNum()
    if table.every(room.alive_players, function (p)
      return p:getHandcardNum() >= x
    end) then
      if U.askForUseVirtualCard(room, player, "slash", {}, self.name, "#minghui-slash", true, true, true, true) then
        if player.dead then return false end
        x = player:getHandcardNum()
      end
    end
    if player:isKongcheng() or #room.alive_players < 2 then return false end
    local y, z = 0, 0
    for _, p in ipairs(room.alive_players) do
      if player ~= p then
        y = p:getHandcardNum()
        if y > x then return false end
        if y > z then
          z = y
        end
      end
    end
    if z == 0 then return false end
    y = x-z+1
    if #room:askForDiscard(player, y, x, false, self.name, true, ".", "#minghui-discard:::" .. tostring(y)) > 0 and
    not player.dead then
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:isWounded()
      end), Util.IdMapper)
      if #targets > 0 then
        targets = room:askForChoosePlayers(player, targets, 1, 1, "#minghui-recover", self.name, false)
        room:recover({
          who = room:getPlayerById(targets[1]),
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    end
  end,
}
liangyan:addRelatedSkill(liangyan_delay)
zhangchunhua:addSkill(liangyan)
zhangchunhua:addSkill(minghui)

Fk:loadTranslationTable{
  ["tystar__zhangchunhua"] = "星张春华",
  ["#tystar__zhangchunhua"] = "皑雪皎月",
  ["illustrator:tystar__zhangchunhua"] = "七兜豆",

  ["liangyan"] = "梁燕",
  [":liangyan"] = "出牌阶段限一次，你可以选择一名其他角色并选择："..
  "1.你摸一至两张牌，其弃置等量的牌，若你与其手牌数相同，你跳过下个弃牌阶段；"..
  "2.你弃置一至两张牌，其摸等量的牌，若你与其手牌数相同，其跳过下个弃牌阶段。",
  ["minghui"] = "明慧",
  [":minghui"] = "一名角色的回合结束时，若你是手牌数最小的角色，你可视为使用一张【杀】（无距离关系的限制）。"..
  "若你是手牌数最大的角色，你可将手牌弃置至不为全场最多，令一名角色回复1点体力。",

  ["liangyan_discard"] = "弃置至多两张牌",
  ["#liangyan1-active"] = "发动 梁燕，弃置1-2张牌，令一名其他角色摸等量的牌",
  ["#liangyan2-active"] = "发动 梁燕，摸1-2张牌，令一名其他角色弃置等量的牌",
  ["@@liangyan"] = "梁燕",
  ["#liangyan_delay"] = "梁燕",
  ["#minghui-slash"] = "明慧：你可以视为使用【杀】",
  ["#minghui-discard"] = "明慧：你可以弃置至少%arg张手牌，然后令一名角色回复1点体力",
  ["#minghui-recover"] = "明慧：选择一名角色，令其回复1点体力",

  ["$liangyan1"] = "家燕并头语，不恋雕梁而归于万里。",
  ["$liangyan2"] = "灵禽非醴泉不饮，非积善之家不栖。",
  ["$minghui1"] = "大智若愚，女子之锦绣常隐于华服。",
  ["$minghui2"] = "知者不惑，心有明镜以照人。",
  ["~tystar__zhangchunhua"] = "我何为也？竟称可憎之老物……",
}

--开阳：孙坚
local sunjian = General(extension, "tystar__sunjian", "qun", 4, 5)
local ruijun = fk.CreateTriggerSkill{
  name = "ruijun",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:hasSkill(self) and data.firstTarget then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = player:getMark("ruijun_record-phase")
      if mark == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and table.find(TargetGroup:getRealTargets(use.tos), function (pid)
            return pid ~= player.id
          end) then
            mark = e.id
            room:setPlayerMark(player, "ruijun_record-phase", mark)
            return true
          end
        end, Player.HistoryPhase)
      end
      return mark == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead and id ~= player.id
    end)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#ruijun-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#ruijun-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    player:drawCards(player:getLostHp() + 1, self.name)
    if player.dead or to.dead then return false end
    room:setPlayerMark(to, "@@ruijun-phase", 1)
    room:setPlayerMark(player, "ruijun_targets-phase", to.id)
    room:setPlayerMark(player, "ruijun_event_id-phase", room.logic.current_event_id)
  end,
}
local ruijun_delay = fk.CreateTriggerSkill{
  name = "#ruijun_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("ruijun_targets-phase") == data.to.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ruijun")
    room:notifySkillInvoked(player, "ruijun", "offensive")
    local x = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.from == player and damage.to == data.to then
        x = damage.damage
        return true
      end
    end, nil, player:getMark("ruijun_event_id-phase"))
    if x > 0 then
      data.damage = math.min(5, x+1)
    end
  end,
}
local ruijun_attackrange = fk.CreateAttackRangeSkill{
  name = "#ruijun_attackrange",
  without_func = function (self, from, to)
    local mark = from:getMark("ruijun_targets-phase")
    return mark ~= 0 and mark ~= to.id
  end,
}
local ruijun_targetmod = fk.CreateTargetModSkill{
  name = "#ruijun_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("ruijun_targets-phase") == to.id
  end,
}
local gangyi = fk.CreateTriggerSkill{
  name = "gangyi",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.PreHpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dying and player:hasSkill(self) and
    data.card and table.contains({"peach", "analeptic"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,

  refresh_events = {fk.AskForPeaches, fk.HpChanged, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    if event == fk.AskForPeaches then
      return player == target and player:hasSkill(self) and player:getMark("gangyi-turn") == 0
    elseif event == fk.HpChanged then
      return data.damageEvent and player == data.damageEvent.from and
      player:hasSkill(self, true) and player:getMark("gangyi-turn") == 0
    elseif event == fk.EventAcquireSkill then
      if player == target and data == self and player:getMark("gangyi-turn") == 0 then
        local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn_event == nil then return false end
        return #player.room.logic:getActualDamageEvents(1, function(e)
          return e.data[1].from == player
        end, nil, turn_event.id) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AskForPeaches then
      player.room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
    elseif event == fk.HpChanged then
      player.room:setPlayerMark(player, "gangyi-turn", 1)
    elseif event == fk.EventAcquireSkill then
      player.room:setPlayerMark(player, "gangyi-turn", 1)
    end
  end,
}
local gangyi_prohibit = fk.CreateProhibitSkill{
  name = "#gangyi_prohibit",
  prohibit_use = function(self, player, card)
    return card.name == "peach" and player.phase ~= Player.NotActive and
    player:hasSkill(gangyi) and player:getMark("gangyi-turn") == 0
  end,
}
ruijun:addRelatedSkill(ruijun_delay)
ruijun:addRelatedSkill(ruijun_attackrange)
ruijun:addRelatedSkill(ruijun_targetmod)
gangyi:addRelatedSkill(gangyi_prohibit)
sunjian:addSkill(ruijun)
sunjian:addSkill(gangyi)
Fk:loadTranslationTable{
  ["tystar__sunjian"] = "星孙坚",
  ["#tystar__sunjian"] = "破虏将军",
  ["illustrator:tystar__sunjian"] = "鬼画府",
  ["ruijun"] = "锐军",
  [":ruijun"] = "当你于出牌阶段内第一次使用牌指定其他角色为目标后，你可以摸X张牌（X为你已损失的体力值+1），"..
  "此阶段内：除其外的其他角色视为不在你的攻击范围内；你对其使用牌无距离限制；当你对其造成伤害时，伤害值比上次增加1（至多为5）。",
  ["gangyi"] = "刚毅",
  [":gangyi"] = "锁定技，若你于回合内未造成过伤害，你于此回合内不能使用【桃】。"..
  "当你因执行【桃】或【酒】的作用效果而回复体力时，若你处于濒死状态，你令回复值+1。",

  ["#ruijun-choose"] = "是否发动 锐军，选择一名角色作为目标",
  ["#ruijun-invoke"] = "是否对%dest发动 锐军",
  ["@@ruijun-phase"] = "锐军",
  ["#ruijun_delay"] = "锐军",

  ["$ruijun1"] = "三军夺锐，势不可挡。",
  ["$ruijun2"] = "士如钢锋，可破三属之甲。",
  ["$gangyi1"] = "不见狼居胥，何妨马革裹尸。",
  ["$gangyi2"] = "既无功，不受禄。",
  ["~tystar__sunjian"] = "身怀宝器，必受群狼觊觎……",
}

--瑶光：孙尚香
local sunshangxiang = General(extension, "tystar__sunshangxiang", "wu", 3, 3, General.Female)
local saying = fk.CreateViewAsSkill{
  name = "saying",
  pattern = "slash,jink,peach,analeptic",
  prompt = function (self)
    if self.interaction.data == nil then
      return "#saying-nil"
    end
    return "#saying-" .. self.interaction.data
  end,
  interaction = function()
    local all_names = {"slash", "jink", "peach", "analeptic"}
    local names = U.getViewAsCardNames(Self, "saying", all_names, {}, Self:getTableMark("saying-round"))
    if #names == 0 then return end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, to_select, selected)
    if #selected > 0 then return false end
    if self.interaction.data == "slash" or self.interaction.data == "jink" then
      if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
      local card = Fk:getCardById(to_select)
      return card.type == Card.TypeEquip and Self:canUseTo(card, Self)
    elseif self.interaction.data == "peach" or self.interaction.data == "analeptic" then
      return Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
    end
  end,
  view_as = function(self, cards)
    if not self.interaction.data or #cards == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark(self.name, cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "saying-round", use.card.trueName)
    local card_id = use.card:getMark(self.name)
    if use.card.trueName == "slash" or use.card.trueName == "jink" then
      room:useCard{
        from = player.id,
        tos = { {player.id} },
        card = Fk:getCardById(card_id),
      }
    elseif use.card.trueName == "peach" or use.card.trueName == "analeptic" then
      room:obtainCard(player, card_id, true, fk.ReasonPrey, player.id, self.name)
    end
  end,
  enabled_at_play = function(self, player)
    local card
    local mark = player:getTableMark("saying-round")
    return not table.every({"slash", "peach", "analeptic"}, function(name)
      if table.contains(mark, name) then return true end
      card = Fk:cloneCard(name)
      card.skillName = self.name
      return not player:canUse(card) or player:prohibitUse(card)
    end)
  end,
  enabled_at_response = function(self, player, response)
    if response or Fk.currentResponsePattern == nil then return false end
    local card
    local mark = player:getTableMark("saying-round")
    return not table.every({"slash", "jink", "peach", "analeptic"}, function(name)
      if table.contains(mark, name) then return true end
      card = Fk:cloneCard(name)
      card.skillName = self.name
      return not Exppattern:Parse(Fk.currentResponsePattern):match(card) or player:prohibitUse(card)
    end)
  end,
}
local jiaohao = fk.CreateActiveSkill{
  name = "ty__jiaohao",
  anim_type = "control",
  prompt = "#ty__jiaohao-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return Self:canPindian(target) and #Self:getCardIds(Player.Equip) >= #target:getCardIds(Player.Equip)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if player.dead then return end
    local winner = pindian.results[target.id].winner
    if winner == nil or winner.dead then return end
    local cards = {}
    local id = pindian.fromCard:getEffectiveId()
    if room:getCardArea(id) == Card.DiscardPile then
      table.insert(cards, id)
    end
    id = pindian.results[target.id].toCard:getEffectiveId()
    if room:getCardArea(id) == Card.DiscardPile then
      table.insertIfNeed(cards, id)
    end
    local choices = {"ty__jiaohao_slash", "Cancel"}
    if #cards > 0 then
      table.insert(choices, "ty__jiaohao_obtain")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ty__jiaohao-choice::" .. winner.id, false,
    {"ty__jiaohao_obtain", "ty__jiaohao_slash", "Cancel"})
    if choice == "ty__jiaohao_obtain" then
      room:obtainCard(winner, cards, true, fk.ReasonJustMove, winner.id, self.name)
    elseif choice == "ty__jiaohao_slash" then
      local use = room:askForUseCard(winner, "slash", "slash", "#ty__jiaohao-slash", true, { bypass_times = true })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
}
sunshangxiang:addSkill(saying)
sunshangxiang:addSkill(jiaohao)
Fk:loadTranslationTable{
  ["tystar__sunshangxiang"] = "星孙尚香",
  ["#tystar__sunshangxiang"] = "鸳袖衔剑珮",
  ["illustrator:tystar__sunshangxiang"] = "匠人绘",

  ["saying"] = "飒影",
  [":saying"] = "每轮每种牌名限一次，当你需要使用【杀】或【闪】时，你可以使用一张装备牌，然后视为使用之；"..
  "当你需要使用【桃】或【酒】时，你可以收回装备区里的一张牌，然后视为使用之。",
  ["ty__jiaohao"] = "骄豪",
  [":ty__jiaohao"] = "出牌阶段限一次，你可以与装备区里的牌数不大于你的角色拼点，然后你可以令拼点赢的角色获得拼点的牌或者令其使用一张【杀】。",

  ["#saying-nil"] = "发动 飒影，没有可使用的牌",
  ["#saying-slash"] = "发动 飒影，选择手牌中一张装备牌使用，并选择使用【杀】的目标角色",
  ["#saying-jink"] = "发动 飒影，选择手牌中一张装备牌使用，视为使用【闪】",
  ["#saying-peach"] = "发动 飒影，选择装备区里的一张牌收回手牌，视为使用【桃】",
  ["#saying-analeptic"] = "发动 飒影，选择装备区里的一张牌收回手牌，视为使用【酒】",
  ["#ty__jiaohao-active"] = "发动 骄豪，与装备区里的牌数不大于你的角色拼点",
  ["#ty__jiaohao-choice"] = "骄豪：你可以选择一项令%dest执行",
  ["ty__jiaohao_obtain"] = "令其获得拼点的牌",
  ["ty__jiaohao_slash"] = "令其可以使用一张【杀】",
  ["#ty__jiaohao-slash"] = "骄豪：你可以使用一张【杀】",

  ["$saying1"] = "倩影映江汀，巾帼犹飒爽！",
  ["$saying2"] = "我有一袭红袖，欲揾英雄泪！",
  ["$ty__jiaohao1"] = "身虽为碧玉，手不怠锟铻！",
  ["$ty__jiaohao2"] = "站住！且与本姑娘分个高下！",
  ["~tystar__sunshangxiang"] = "秋风冷，江水寒……",
}

return extension
