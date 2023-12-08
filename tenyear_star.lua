local extension = Package("tenyear_star")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：袁术 董卓
local yuanshu = General(extension, "tystar__yuanshu", "qun", 4)
local canxi = fk.CreateTriggerSkill{
  name = "canxi",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventAcquireSkill, fk.RoundStart},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventAcquireSkill then
        return target == player and data == self
      elseif event == fk.RoundStart then
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      room:setPlayerMark(player, "canxi_exist_kingdoms", kingdoms)
    elseif event == fk.RoundStart then
      local choice1 = room:askForChoice(player, player:getMark("canxi_exist_kingdoms"), self.name, "#canxi-choice1")
      local choice2 = room:askForChoice(player, {"canxi1", "canxi2"}, self.name, "#canxi-choice2:::"..choice1, true)
      room:setPlayerMark(player, "@"..choice2.."-round", choice1)
    end
  end,
}
local canxi_distance = fk.CreateDistanceSkill{
  name = "#canxi_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getMark("@canxi1-round") == from.kingdom then
        n = n + 1
      end
    end
    return -n
  end,
}
local canxi_trigger = fk.CreateTriggerSkill{
  name = "#canxi_trigger",
  mute = true,
  events = {fk.DamageCaused, fk.HpRecover, fk.PreCardEffect},
  can_trigger = function (self, event, target, player, data)
    if event == fk.DamageCaused then
      return player:getMark("@canxi1-round") ~= 0 and target and
        player:getMark("@canxi1-round") == target.kingdom and target:getMark("canxi1-turn") == 0
    elseif event == fk.HpRecover then
      return player:getMark("@canxi2-round") ~= 0 and player:getMark("@canxi2-round") == target.kingdom and not target.dead and
        target:getMark("canxi21-turn") == 0
    elseif event == fk.PreCardEffect then
      if player:getMark("@canxi2-round") ~= 0 and player.id == data.to then
        local p = player.room:getPlayerById(data.from)
        return player:getMark("@canxi2-round") == p.kingdom and p:getMark("canxi22-turn") == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("canxi")
    if event == fk.DamageCaused then
      room:setPlayerMark(target, "canxi1-turn", 1)
      room:notifySkillInvoked(player, "canxi", "offensive")
      data.damage = data.damage + 1
    elseif event == fk.HpRecover then
      room:setPlayerMark(target, "canxi21-turn", 1)
      room:notifySkillInvoked(player, "canxi", "control")
      room:doIndicate(player.id, {target.id})
      room:loseHp(target, 1, "canxi")
    elseif event == fk.PreCardEffect then
      room:setPlayerMark(room:getPlayerById(data.from), "canxi22-turn", 1)
      room:notifySkillInvoked(player, "canxi", "defensive")
      return true
    end
  end,
}
local pizhi = fk.CreateTriggerSkill{
  name = "pizhi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd, fk.BeforeGameOverJudge},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseEnd then
        return target == player and player.phase == Player.Finish and player:getMark("canxi_removed_kingdoms") ~= 0
      elseif event == fk.BeforeGameOverJudge then
        return (player:getMark("@canxi1-round") == target.kingdom or player:getMark("@canxi2-round") == target.kingdom) and
          player:getMark("canxi_exist_kingdoms") ~= 0 and table.contains(player:getMark("canxi_exist_kingdoms"), target.kingdom)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    if event == fk.BeforeGameOverJudge then
      local room = player.room
      local mark = player:getMark("canxi_exist_kingdoms")
      table.removeOne(mark, target.kingdom)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(player, "canxi_exist_kingdoms", mark)
      mark = player:getMark("canxi_removed_kingdoms")
      if mark == 0 then mark = {} end
      table.insert(mark, target.kingdom)
      room:setPlayerMark(player, "canxi_removed_kingdoms", mark)
    end
    player:drawCards(#player:getMark("canxi_removed_kingdoms"), self.name)
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
canxi:addRelatedSkill(canxi_trigger)
yuanshu:addSkill(canxi)
yuanshu:addSkill(pizhi)
yuanshu:addSkill(zhonggu)
Fk:loadTranslationTable{
  ["tystar__yuanshu"] = "星袁术",
  ["canxi"] = "残玺",
  [":canxi"] = "锁定技，游戏开始时，你获得场上各势力的“玺角”标记。每轮开始时，你选择一个“玺角”势力并选择一个效果生效直到下轮开始：<br>"..
  "「妄生」：该势力角色每回合首次造成伤害+1，计算与其他角色距离-1；<br>「向死」：该势力角色每回合首次回复体力后失去1点体力，"..
  "每回合对你使用的第一张牌无效。",
  ["pizhi"] = "圮秩",
  [":pizhi"] = "锁定技，结束阶段，你摸X张牌；有角色死亡时，若其势力与当前生效的“玺角”势力相同，你失去此“玺角”，然后摸X张牌（X为你已失去的“玺角”数）。",
  ["zhonggu"] = "冢骨",
  [":zhonggu"] = "主公技，锁定技，若游戏轮数不小于群势力角色数，你摸牌阶段摸牌数+2，否则-1。",
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
    return target == player and player.phase == Player.Start and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local command = "AskForUseActiveSkill"
    player.room:notifyMoveFocus(player, "zhangrong_active")
    local dat = {"zhangrong_active", "#zhangrong-invoke", true, json.encode({})}
    local result = player.room:doRequest(player, command, json.encode(dat))
    if result ~= "" then
      self.cost_data = json.decode(result)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.targets
    room:sortPlayersByAction(targets)
    room:setPlayerMark(player, "zhangrong-turn", targets)
    room:doIndicate(player.id, targets)
    local choice = self.cost_data.interaction_data
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
    if not player.dead then
      player:drawCards(#targets, self.name)
    end
  end,
}
local zhangrong_delay = fk.CreateTriggerSkill{
  name = "#zhangrong_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player:usedSkillTimes("zhangrong", Player.HistoryTurn) > 0 then
      local room = player.room
      local playerIds = {}
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        if damage then
          table.insertIfNeed(playerIds, damage.to.id)
        end
      end, Player.HistoryTurn)
      return table.find(player:getMark("zhangrong-turn"), function(id) return not table.contains(playerIds, id) end)
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
  ["weilin"] = "威临",
  [":weilin"] = "锁定技，你于回合内对一名角色造成伤害时，若其本回合没有受到过伤害且你本回合已使用牌数不小于其体力值，则此伤害+1。",
  ["zhangrong"] = "掌戎",
  [":zhangrong"] = "准备阶段，你可以选择一项：1.令至多X名体力值不小于你的角色各失去1点体力；2.令至多X名手牌数不小于你的角色各弃置一张手牌"..
  "（X为你的体力值）。选择完成后，你摸选择角色数量的牌。回合结束时，若这些角色中有角色本回合未受到伤害，你失去1点体力",
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
  --["$zhangrong2"] = "西凉铁骑，天下高楼可摧！",
  ["$haoshou1"] = "满朝主公，试吾剑不利否？",
  ["$haoshou2"] = "顺我者生，逆我者十死无生！",
  --["~tystar__dongzhuo"] = "美人迷人眼，",
}

--玉衡：曹仁
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
    local card = Fk:cloneCard(self.interaction.data)
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
    return player:hasSkill("lifengc", true) and data.card.color ~= Card.NoColor
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

return extension
