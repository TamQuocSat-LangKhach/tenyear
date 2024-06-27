local extension = Package("tenyear_star")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：袁术 董卓 袁绍
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
      not table.contains(U.getMark(player, "canxi1-turn"), target.id)
    elseif event == fk.HpRecover then
      return player:getMark("@canxi2-round") == target.kingdom and
      not target.dead and target ~= player and not table.contains(U.getMark(player, "canxi21-turn"), target.id)
    elseif event == fk.TargetConfirmed then
      if player == target and data.from ~= player.id then
        local p = player.room:getPlayerById(data.from)
        return player:getMark("@canxi2-round") == p.kingdom and not table.contains(U.getMark(player, "canxi22-turn"), p.id)
      end
    elseif event == fk.RoundStart then
      return #U.getMark(player, "@canxi_exist_kingdoms") > 0
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      local mark = U.getMark(player, "canxi1-turn")
      table.insert(mark, target.id)
      room:setPlayerMark(player, "canxi1-turn", mark)
      data.damage = data.damage + 1
    elseif event == fk.HpRecover then
      room:notifySkillInvoked(player, self.name, "control")
      local mark = U.getMark(player, "canxi21-turn")
      table.insert(mark, target.id)
      room:setPlayerMark(player, "canxi21-turn", mark)
      room:loseHp(target, 1, self.name)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "defensive")
      local mark = U.getMark(player, "canxi22-turn")
      table.insert(mark, data.from)
      room:setPlayerMark(player, "canxi22-turn", mark)
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

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
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
          end) and table.contains(U.getMark(player, "@canxi_exist_kingdoms"), target.kingdom))
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
    if room:getTag("RoundCount") >= n then
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
  [":canxi"] = "锁定技，游戏开始时，你获得场上各势力的“玺角”标记（魏、蜀、吴、群每少一个势力，你加1点体力上限）。每轮开始时，"..
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
      if #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        if damage and damage.to == data.to and e.id < room.logic:getCurrentEvent().id then
          return true
        end
      end, Player.HistoryTurn) == 0 then
        local n = 0
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          if use and use.from == player.id then
            n = n + 1
          end
        end, Player.HistoryTurn)
        return n >= data.to.hp
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
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.targets
    room:sortPlayersByAction(targets)
    room:setPlayerMark(player, "zhangrong-turn", targets)
    room:doIndicate(player.id, targets)
    local choice = self.cost_data.interaction
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
      U.getActualDamageEvents(player.room, 1, function(e)
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
local getZongshiTargets = function (room, player, card)
  if player:prohibitUse(card) then return {} end

  if card.skill:getMinTargetNum() > 0 then
    if not player:canUse(card) then return {} end
    local targets = {}
    local extra_data = {
      bypass_distances = true,
      bypass_times = (player.phase == Player.NotActive)
    }
    for _, p in ipairs(room.alive_players) do
      if not player:isProhibited(p, card) and card.skill:targetFilter(p.id, {}, {}, card, extra_data) then
        table.insert(targets, p.id)
      end
    end
    return targets
  else
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not player:isProhibited(p, card) and
      card.skill:modTargetFilter(p.id, {}, player.id, card, player.phase == Player.NotActive) then
        table.insert(targets, p.id)
      end
    end
    return targets
  end
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
    --FIXME：不给targetFilter传使用者真是离大谱，目前只能通过强制修改Self来实现
    Self = player
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
  mute = true,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim, fk.AfterPropertyChange},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return target:hasSkill(self, true, true)
    elseif event == fk.AfterPropertyChange then
      return target == player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local attached_aoshi = player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(self, true)
    end)
    if attached_aoshi and not player:hasSkill("aoshi_other&", true, true) then
      room:handleAddLoseSkills(player, "aoshi_other&", nil, false, true)
    elseif not attached_aoshi and player:hasSkill("aoshi_other&", true, true) then
      room:handleAddLoseSkills(player, "-aoshi_other&", nil, false, true)
    end
  end,
}
local aoshi_other = fk.CreateActiveSkill{
  name = "aoshi_other&",
  anim_type = "support",
  prompt = "#aoshi-active",
  mute = true,
  can_use = function(self, player)
    if player.kingdom ~= "qun" then return false end
    local targetRecorded = U.getMark(player, "aoshi_sources-phase")
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
    not table.contains(U.getMark(Self, "aoshi_sources-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, aoshi.name)
    target:broadcastSkillInvoke(aoshi.name)
    local targetRecorded = U.getMark(player, "aoshi_sources-phase")
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, "aoshi_sources-phase", targetRecorded)
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
    local card = Fk:getCardById(cards[1])
    if card.trueName == card_name then
      card_name = card.name
      --for 一个奇怪的本意 →_→
    end
    card = Fk:cloneCard(card_name)
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
    U.getActualDamageEvents(room, 1, function (e)
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
        return #U.getActualDamageEvents(player.room, 1, function(e)
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
gangyi:addRelatedSkill(gangyi_prohibit)
sunjian:addSkill(ruijun)
sunjian:addSkill(gangyi)
Fk:loadTranslationTable{
  ["tystar__sunjian"] = "星孙坚",
  ["#tystar__sunjian"] = "破虏将军",
  ["illustrator:tystar__sunjian"] = "鬼画府",
  ["ruijun"] = "锐军",
  [":ruijun"] = "当你于出牌阶段内第一次使用牌指定其他角色为目标后，你可以摸X张牌（X为你已损失的体力值+1），"..
  "此阶段内：除其外的其他角色视为不在你的攻击范围内；当你对其造成伤害时，伤害值比上次增加1（至多为5）。",
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

return extension
