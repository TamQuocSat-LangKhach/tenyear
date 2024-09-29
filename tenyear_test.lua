local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

local caiyong = General(extension, "mu__caiyong", "qun", 3)
local jiaowei = fk.CreateTriggerSkill{
  name = "jiaowei",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return not player:isKongcheng()
      else
        return target == player and data.from and data.from:getHandcardNum() <= player:getMark("@jiaowei")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.GameStart then
      local room = player.room
      local cards = player:getCardIds("h")
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@jiaowei-inhand", 1)
      end
      room:setPlayerMark(player, "@jiaowei", #cards)
    else
      return true
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("@jiaowei") > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@jiaowei", #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@jiaowei-inhand") > 0 end))
  end,
}
local jiaowei_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiaowei_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiaowei-inhand") > 0
  end,
}
local feibaic = fk.CreateTriggerSkill{
  name = "feibaic",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = math.max(turn_event.id, player:getMark("feibaic-turn"))  --截至上次发动技能的事件id
      local yes = true
      if #room.logic:getEventsByRule(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if e.id <= room.logic:getCurrentEvent().id then  --插入其他使用事件，eg.闪
          if use.from == player.id then
            return true
          else
            yes = false
            return false
          end
        end
      end, end_id) < 2 then return end
      return yes
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = math.max(turn_event.id, player:getMark("feibaic-turn"))
    local n, event_record = 0, 0
    room.logic:getEventsByRule(GameEvent.UseCard, 2, function(e)
      local use = e.data[1]
      if use.from == player.id then
        if event_record == 0 then
          event_record = e.id
        end
        n = n + Fk:translate(use.card.trueName, "zh_CN"):len()
      end
    end, end_id)
    room:setPlayerMark(player, "feibaic-turn", event_record)  --记录上次发动技能的事件id
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if Fk:translate(card.trueName, "zh_CN"):len() == n then
        table.insertIfNeed(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
    if player:getMark("@jiaowei") <= n then
      player:setSkillUseHistory(self.name, 0, Player.HistoryTurn)
    end
  end,
}
jiaowei:addRelatedSkill(jiaowei_maxcards)
caiyong:addSkill(jiaowei)
caiyong:addSkill(feibaic)
Fk:loadTranslationTable{
  ["mu__caiyong"] = "乐蔡邕",
  ["#mu__caiyong"] = "焦尾识音",
  ["jiaowei"] = "焦尾",
  [":jiaowei"] = "锁定技，游戏开始时，你的初始手牌增加“弦”标记且不计入手牌上限。当你受到伤害时，若伤害来源手牌数不大于“弦”数，防止此伤害。",
  ["feibaic"] = "飞白",
  [":feibaic"] = "每回合限一次，当你连续使用两张牌后，你可以随机获得一张字数为X的牌（X为两张牌字数之和）；若你的“弦”数不大于X，此技能视为未发动。",
  ["@jiaowei"] = "弦",
  ["@@jiaowei-inhand"] = "弦",
}

--嵇康 曹不兴 马良

Fk:loadTranslationTable{
  ["yuanyin"] = "袁胤",
  ["#yuanyin"] = "载路素车",

  ["moshou"] = "墨守",
  [":moshou"] = "当你成为其他角色使用黑色牌的目标后，你可以摸X张牌（X为1、2、3，依次循环）。",
  ["yunjiu"] = "运柩",
  [":yunjiu"] = "一名角色死亡时，你可以弃置其牌数的牌，将其所有牌交给一名其他角色，然后你加1点体力上限并回复1点体力。",
}

local tmp_illustrate = fk.CreateActiveSkill{name = "tmp_illustrate"}

local chezhou = General(extension, "chezhou", "wei", 4)
chezhou:addSkill(tmp_illustrate)
chezhou.hidden = true
Fk:loadTranslationTable{
  ["chezhou"] = "车胄",
  ["#chezhou"] = "当车螳臂",
  ["tmp_illustrate"] = "看画",
  [":tmp_illustrate"] = "这个武将还没上线，你可以看看插画。不会出现在选将框。",

  ["shefuc"] = "慑伏",
  [":shefuc"] = "锁定技，你的牌造成的伤害、其他角色的牌对你造成的伤害均改为X。（X为此牌在手牌中的轮次数）",
  ["pigua"] = "披挂",
  [":pigua"] = "当你对其他角色造成伤害后，若伤害值大于1，你可以获得其至多X张牌（X为轮次数），这些牌于当前回合内不计入手牌上限。",
}

local matie = General(extension, "matie", "qun", 4)
local quxian = fk.CreateTriggerSkill{
  name = "quxian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1,
    "#quxian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data.tos[1])
    local tos = table.filter(room:getAlivePlayers(), function (p)
      return p ~= player and p:inMyAttackRange(tar)
    end)
    if #tos == 0 then return false end
    local to_loseHp = {}
    local no_damage = true
    for _, to in ipairs(tos) do
      if not to.dead then
        local use = room:askForUseCard(to, "slash", "slash", "#quxian-use::"..tar.id, true,
        {exclusive_targets = {tar.id}, bypass_times = true})
        if use then
          room:useCard(use)
          if use.damageDealt and use.damageDealt[tar.id] then
            no_damage = false
          end
        else
          table.insert(to_loseHp, to)
        end
      end
    end
    if no_damage then
      local x = #tos - #to_loseHp
      if x > 0 then
        for _, to in ipairs(to_loseHp) do
          if not to.dead then
            room:loseHp(to, x, self.name)
          end
        end
      end
    end
  end,
}
matie:addSkill("sp__zhuiji")
matie:addSkill(quxian)
Fk:loadTranslationTable{
  ["matie"] = "马铁",
  ["#matie"] = "继志伏波",

  ["quxian"] = "驱险",
  [":quxian"] = "出牌阶段开始时，你可以选择一名角色，攻击范围内有其的其他角色均可以对其使用【杀】。"..
  "若其未以此法受到过伤害，未以此法使用过【杀】的角色各失去X点体力（X为以此法使用过【杀】的角色数）。",

  ["#quxian-choose"] = "是否发动 驱险，选择一名角色，攻击范围含有其的角色各可以对其使用【杀】",
  ["#quxian-use"] = "驱险：你可以对%dest使用【杀】",
}

local hansong = General(extension, "hansong", "qun", 3)
local yinbi = fk.CreateTriggerSkill{
  name = "yinbi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Discard then
      local x = 0
      for _, p in ipairs(player.room.alive_players) do
        x = math.max(x, p:getMaxCards())
      end
      if x > player:getMaxCards() then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "yinbi-phase", self.cost_data)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) then
      local x = player:getHandcardNum()
      return table.every(player.room.alive_players, function (p)
        return p == player or p:getHandcardNum() ~= x
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local yinbi_maxcards = fk.CreateMaxCardsSkill{
  name = "#yinbi_maxcards",
  fixed_func = function (self, player)
    if player:hasSkill(yinbi) and player:getMark("yinbi-phase") > 0 then
      return player:getMark("yinbi-phase")
    end
  end,
}
local yinbi_targetmod = fk.CreateTargetModSkill{
  name = "#yinbi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    if player:hasSkill(yinbi) then
      local x = player:getHandcardNum()
      return table.every(Fk:currentRoom().alive_players, function (p)
        return p == player or p:getHandcardNum() ~= x
      end)
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    if player:hasSkill(yinbi) then
      local x = player:getHandcardNum()
      return table.every(Fk:currentRoom().alive_players, function (p)
        return p == player or p:getHandcardNum() ~= x
      end)
    end
  end,
}
local shuaiyan = fk.CreateTriggerSkill{
  name = "shuaiyan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local tos = {}
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and not table.contains(tos, move.from) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(tos, move.from)
              break
            end
          end
        end
        if move.to and move.to ~= player.id and not table.contains(tos, move.to) and
        move.toArea == Player.Hand and #move.moveInfo > 0 then
          table.insert(tos, move.to)
        end
      end
      if #tos == 0 then return false end
      local room = player.room
      room:sortPlayersByAction(tos)
      while true do
        local to = room:getPlayerById(tos[1])
        if to.dead or to:getHandcardNum() ~= player:getHandcardNum() then
          table.remove(tos, 1)
          if #tos == 0 then break end
        else
          self.cost_data = tos
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    for _, target_id in ipairs(self.cost_data) do
      if not player:hasSkill(self) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and player:getHandcardNum() == skill_target:getHandcardNum() then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choices = {"draw1"}
    if target:isNude() or room:askForChoice(player,
    {"draw1", "shuaiyan_discard::"..target.id}, self.trueName) == "draw1" then
      player:drawCards(1, self.name)
    else
      local id = room:askForCardChosen(player, target, "he", self.name)
      room:throwCard({id}, self.name, target, player)
    end
  end,
}
yinbi:addRelatedSkill(yinbi_maxcards)
yinbi:addRelatedSkill(yinbi_targetmod)
hansong:addSkill(yinbi)
hansong:addSkill(shuaiyan)
Fk:loadTranslationTable{
  ["hansong"] = "韩嵩",
  ["#hansong"] = "楚国之望",

  ["yinbi"] = "隐避",
  [":yinbi"] = "锁定技，若其他角色的手牌数均不与你相等，你使用牌无距离和次数限制。"..
  "弃牌阶段开始时，若你不是手牌上限最大的角色，你令你的手牌上限的初值于此阶段内改为X（X为其他角色的手牌上限的最大值）。",
  ["shuaiyan"] = "率言",
  [":shuaiyan"] = "锁定技，当其他角色得到/失去手牌后，若其手牌数与你相等，你选择：1.弃置其一张牌；2.摸一张牌。",

  ["shuaiyan_discard"] = "弃置%dest的一张牌",
}

local huzun = General(extension, "huzun", "wei", 4)
local zhantao = fk.CreateTriggerSkill{
  name = "zhantao",
  anim_type = "offensive",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player == target or player:inMyAttackRange(target)) and
    data.from and not data.from.dead and data.from ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#zhantao-invoke::" .. data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 13
    local pattern = ".|0"
    if data.card and data.card.number > 0 and data.card.number < 13 then
      n = data.card.number
      pattern = ".|" .. tostring(n+1) .. "~13"
    end
    local judge = {
      who = player,
      reason = self.name,
      pattern = pattern,
    }
    room:judge(judge)
    if judge.card.number > n then
      room:useVirtualCard("slash", nil, player, data.from, self.name, true)
    end
  end,
}
local anjing = fk.CreateTriggerSkill{
  name = "anjing",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player:usedSkillTimes(self.name) < 1 and
    not table.every(player.room.alive_players, function (p)
      return not p:isWounded()
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return p:isWounded() end)
    local n = math.min(#targets, player:getMark(self.name) + 1)
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, n,
    "#anjing-choose:::" .. tostring(n), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, self.name, 1)
    local tos = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(tos)
    tos = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      if not p.dead then
        p:drawCards(1, self.name)
      end
    end
    local recovers = {}
    for _, p in ipairs(tos) do
      if not p.dead and p:isWounded() then
        if #recovers == 0 then
          table.insert(recovers, p)
        else
          if p.hp < recovers[1].hp then
            recovers = {p}
          elseif p.hp == recovers[1].hp then
            table.insert(recovers, p)
          end
        end
      end
    end
    if #recovers > 0 then
      room:recover{
        who = table.random(recovers),
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
huzun:addSkill(zhantao)
huzun:addSkill(anjing)
Fk:loadTranslationTable{
  ["huzun"] = "胡遵",
  ["#huzun"] = "蓝翎紫璧",
  --["designer:huzun"] = "",
  --["illustrator:huzun"] = "",

  ["zhantao"] = "斩涛",
  [":zhantao"] = "当你或你攻击范围内的角色受到伤害后，若来源不为你，你可以判定，若点数大于伤害牌的点数，你视为对来源使用【杀】。",
  ["anjing"] = "安境",
  [":anjing"] = "当你造成伤害后，若你于当前回合内未发动过此技能，你可以选择至多X名已受伤的角色（X为此技能发动过的次数+1），"..
  "这些角色各摸一张牌，然后其中体力值最小的随机一名角色回复1点体力。",

  ["#zhantao-invoke"] = "是否对 %dest 发动 斩涛，进行判定",
  ["#anjing-choose"] = "是否发动 安境，令1-%arg名已受伤的角色摸牌，体力值最少的角色回复体力",

  ["$zhantao1"] = "",
  ["$zhantao2"] = "",
  ["$anjing1"] = "",
  ["$anjing2"] = "",
  ["~huzun"] = "",
}

local qinghegongzhu = General(extension, "ty__qinghegongzhu", "wei", 3, 3, General.Female)
local ty__zhangjiq = fk.CreateTriggerSkill{
  name = "ty__zhangjiq",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardUseEffect},  --FIXME: 睿智描述，先胡乱结算
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #TargetGroup:getRealTargets(data.tos) > 1 and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local new_tos = {}
    for _, info in ipairs(data.tos) do
      if info[1] == player.id then
        table.insert(new_tos, info)
      end
    end
    for _, info in ipairs(data.tos) do
      if info[1] ~= player.id then
        table.insert(new_tos, info)
      end
    end
    data.tos = new_tos
    player:drawCards(#TargetGroup:getRealTargets(data.tos) - 1, self.name)
  end,
}
local ty__zengou = fk.CreateActiveSkill{
  name = "ty__zengou",
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  prompt = function()
    return "#ty__zengou:::"..Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < Self.maxHp
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    room:setPlayerMark(target, "@@ty__zengou", 1)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id, "@@ty__zengou-inhand")
    if not player.dead then
      player:drawCards(#cards, self.name)
    end
  end,
}
local ty__zengou_delay = fk.CreateTriggerSkill{
  name = "#ty__zengou_delay",
  mute = true,
  events = {fk.HpChanged, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@@ty__zengou") > 0 then
      if event == fk.HpChanged then
        return data.num > 0
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty__zengou", 0)
    if player:isKongcheng() then return end
    local cards = player:getCardIds("h")
    local n = #table.filter(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__zengou-inhand") > 0
    end)
    player:showCards(cards)
    if player.dead or n == 0 then return end
    room:loseHp(player, n, "ty__zengou")
  end,
}
ty__zengou:addRelatedSkill(ty__zengou_delay)
qinghegongzhu:addSkill(ty__zhangjiq)
qinghegongzhu:addSkill(ty__zengou)
Fk:loadTranslationTable{
  ["ty__qinghegongzhu"] = "清河公主",
  ["#ty__qinghegongzhu"] = "大魏长公主",

  ["ty__zhangjiq"] = "长姬",
  [":ty__zhangjiq"] = "锁定技，一张牌指定包括你在内的多名角色为目标时，先结算对你产生的效果，然后你摸X张牌（X为剩余目标数）。",
  ["ty__zengou"] = "谮构",
  [":ty__zengou"] = "出牌阶段限一次，你可以交给一名其他角色至多你体力上限张牌并摸等量的牌，若如此做，其下次体力值增加或使用牌后展示所有手牌，"..
  "每有一张“谮构”牌，其失去1点体力。",
  ["#ty__zengou"] = "谮构：交给一名角色至多%arg张牌并摸等量牌，其下次体力增加或使用牌后失去体力",
  ["@@ty__zengou"] = "谮构",
  ["@@ty__zengou-inhand"] = "谮构",
}

Fk:loadTranslationTable{
  ["ty__lingcao"] = "凌操",--4/5
  ["#ty__lingcao"] = "激浪奋孤胆",

  ["dufeng"] = "独锋",
  [":dufeng"] = "锁定技，出牌阶段开始时，你选择至少一项：1.失去1点体力；2.废除一个装备栏。然后你摸X张牌，你的攻击范围和出牌阶段使用【杀】"..
  "次数上限均改为X（X为你废除的装备栏数与已损失体力值之和，至多为你的体力上限）。",
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
  ["#tystar__zhangzhao"] = "忠蹇方直",

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
}

local zhurong = General(extension, "ty_sp__zhurong", "qun", 4, 4, General.Female)
local manhou = fk.CreateActiveSkill{
  name = "manhou",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  prompt = "#manhou-prompt",
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = self.interaction.data or 1
    player:drawCards(n, self.name)
    for i = 1, n, 1 do
      if player.dead then return end
      if i == 1 then
        room:handleAddLoseSkills(player, "-tanluan", nil, true, false)
      elseif i == 2 then
        room:askForDiscard(player, 1, 1, false, self.name, false)
      elseif i == 3 then
        room:loseHp(player, 1, self.name)
      elseif i == 4 then
        room:askForDiscard(player, 1, 1, true, self.name, false)
        room:handleAddLoseSkills(player, "tanluan", nil, true, false)
      end
    end
  end,
}
local tanluan = fk.CreateTriggerSkill{
  name = "tanluan",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget then
      local n = #player.room.alive_players - 2 * #AimGroup:getAllTargets(data.tos)
      if n <= 0 then
        self.cost_data = 1
        return #player.room:getPlayerById(data.to):getCardIds("ej") > 0
      else
        self.cost_data = 2
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if self.cost_data == 1 then
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function(id)
        return #player.room:getPlayerById(id):getCardIds("ej") > 0
      end)
      if #targets == 0 then return end
      local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#tanluan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      self.cost_data = 2
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "table" then
      local to = room:getPlayerById(self.cost_data[1])
      local cards = room:askForCardsChosen(player, to, 1, 1, "ej", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      room:addPlayerMark(player, "@@tanluan-phase", 1)
    end
  end,
}
local tanluan_trigger = fk.CreateTriggerSkill{
  name = "#tanluan_trigger",
  mute = true,
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.AfterCardUseDeclared then
        return player:getMark("@@tanluan-phase") > 0
      else
        return data.extra_data and data.extra_data.tanluan and data.extra_data.tanluan[1] == player.id and
          data.tos and #U.getUseExtraTargets(player.room, data, false) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return true
    else
      local n = data.extra_data.tanluan[2]
      local tos = player.room:askForChoosePlayers(player, U.getUseExtraTargets(player.room, data, false), 1, n,
        "#tanluan-add:::"..data.card:toLogString()..":"..n, "tanluan", true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local n = player:getMark("@@tanluan-phase")
      player.room:setPlayerMark(player, "@@tanluan-phase", 0)
      data.extra_data = data.extra_data or {}
      data.extra_data.tanluan = {player.id, n}
    else
      table.insertTable(data.tos, table.map(self.cost_data, function(p) return {p} end))
    end
  end,
}
tanluan:addRelatedSkill(tanluan_trigger)
zhurong:addSkill(manhou)
zhurong:addRelatedSkill(tanluan)
Fk:loadTranslationTable{
  ["ty_sp__zhurong"] = "祝融",
  ["#ty_sp__zhurong"] = "诗惹喜莫",

  ["manhou"] = "蛮后",
  [":manhou"] = "出牌阶段限一次，你可以摸至多四张牌，依次执行前等量项：1.失去〖探乱〗；2.弃置一张手牌；3.失去1点体力；4.弃置一张牌并获得〖探乱〗。",
  ["tanluan"] = "探乱",
  [":tanluan"] = "当你使用牌指定目标后，若目标角色数不少于非目标角色数，你可以弃置其中一名目标角色场上的一张牌；若目标角色数少于非目标角色数，"..
  "本回合你使用下一张牌目标数+1。",
  ["#manhou-prompt"] = "蛮后：你可以摸至多四张牌，依次执行等量效果",
  ["#tanluan-choose"] = "探乱：你可以弃置其中一名角色场上的一张牌",
  ["@@tanluan-phase"] = "探乱",
  ["#tanluan-add"] = "探乱：你可以为%arg额外指定%arg2个目标",
}

local wenyuan = General(extension, "wenyuan", "shu", 3, 3, General.Female)
local kengqiang = fk.CreateTriggerSkill{
  name = "kengqiang",
  anim_type = "drawcard",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player:usedSkillTimes("shangjue", Player.HistoryGame) == 0 then
        return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
          player:getMark("kengqiang1-turn") == 0 and player:getMark("kengqiang2-turn") == 0
      else
        return player:getMark("kengqiang1-turn") == 0 or player:getMark("kengqiang2-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"kengqiang1", "kengqiang2", "Cancel"}
    local choices = table.simpleClone(all_choices)
    for i = 2, 1, -1 do
      if player:getMark("kengqiang"..i.."-turn") > 0 then
        table.remove(choices, i)
      end
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#kengqiang-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "kengqiang1" then
      player:drawCards(player.maxHp, self.name)
    else
      data.damage = data.damage + 1
      if data.card and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    end
  end,
}
local kuichi = fk.CreateTriggerSkill{
  name = "kuichi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        if damage.from == player then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n < player.maxHp then return false end
      n = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.moveReason == fk.ReasonDraw then
            n = n + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n >= player.maxHp
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,
}
local shangjue = fk.CreateTriggerSkill{
  name = "shangjue",
  anim_type = "defensive",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name,
    })
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "kunli", nil, true, false)
    end
  end,
}
local kunli = fk.CreateTriggerSkill{
  name = "kunli",
  anim_type = "defensive",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(2, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name,
    })
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "-kuichi", nil, true, false)
    end
  end,
}
wenyuan:addSkill(kengqiang)
wenyuan:addSkill(kuichi)
wenyuan:addSkill(shangjue)
wenyuan:addRelatedSkill(kunli)
Fk:loadTranslationTable{
  ["wenyuan"] = "文鸳",

  ["kengqiang"] = "铿锵",
  [":kengqiang"] = "每回合限一次，当你造成伤害时，你可以选择一项：1.摸X张牌（X为你的体力上限）；2.此伤害+1，你获得造成伤害的牌。",
  ["kuichi"] = "匮饬",
  [":kuichi"] = "锁定技，回合结束时，若你本回合摸牌数和造成的伤害值均不小于你的体力上限，你失去1点体力。",
  ["shangjue"] = "殇决",
  [":shangjue"] = "觉醒技，当你进入濒死状态时，你将体力值回复至1点，加1点体力上限，并获得〖困励〗，然后将〖铿锵〗改为每回合各限一次。",
  ["kunli"] = "困励",
  [":kunli"] = "觉醒技，当你进入濒死状态时，你将体力值回复至2点，加1点体力上限，并失去〖匮饬〗。",
  ["#kengqiang-invoke"] = "铿锵：你可以选择一项",
  ["kengqiang1"] = "摸体力上限张牌",
  ["kengqiang2"] = "此伤害+1，你获得造成伤害的牌",
}

local huangwudie = General(extension, "huangwudie", "shu", 4, 4, General.Female)
local shuangrui = fk.CreateTriggerSkill{
  name = "shuangrui",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#shuangrui-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    local use = {
      from = player.id,
      tos = {{to.id}},
      card = card,
      extraUse = true,
    }
    local skill = ""
    if player:inMyAttackRange(to) then
      use.additionalDamage = 1
      skill = "shaxue"
    else
      use.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      skill = "shouxing"
    end
    room:handleAddLoseSkills(player, skill, nil, true, false)
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
    end)
    if not player:isProhibited(to, card) then
      room:useCard(use)
    end
  end,
}
local fuxie = fk.CreateActiveSkill{
  name = "fuxie",
  anim_type = "control",
  target_num = 1,
  prompt = function (self)
    if self.interaction.data == "fuxie_weapon" then
      return "#fuxie_weapon"
    else
      return "#fuxie_skill"
    end
  end,
  interaction = function()
    local choices = {"fuxie_weapon"}
    local skills = table.map(table.filter(Self.player_skills, function (s)
      return s:isPlayerSkill(Self) and s.visible
    end), Util.NameMapper)
    table.insertTable(choices, skills)
    return UI.ComboBox { choices = choices }
  end,
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == "fuxie_weapon" then
      return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and not Self:prohibitDiscard(Fk:getCardById(to_select))
      and #selected == 0
    else
      return false
    end
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and (self.interaction.data ~= "fuxie_weapon" or #cards == 1)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player)
    else
      room:handleAddLoseSkills(player, "-"..self.interaction.data, nil, true, false)
    end
    if not target.dead and not target:isKongcheng() then
      room:askForDiscard(target, 2, 2, false, self.name, false)
    end
  end,
}
local shouxing = fk.CreateActiveSkill{
  name = "shouxing",
  anim_type = "offensive",
  prompt = "#shouxing",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return player:canUse(card)
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id and #selected_cards > 0 then
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      card:addSubcards(selected_cards)
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not Self:inMyAttackRange(target) and Self:distanceTo(target) == #selected_cards and not Self:isProhibited(target, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("slash", effect.cards, player, target, self.name, true)
  end,
}
local shouxing_targetmod = fk.CreateTargetModSkill{
  name = "#shouxing_targetmod",
  bypass_distances = function(self, player, skill, card)
    return skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "shouxing")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card and table.contains(card.skillNames, "shouxing")
  end,
}
local shaxue = fk.CreateTriggerSkill{
  name = "shaxue",
  anim_type = "drawcard",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if player.dead or data.to.dead or player:isNude() then return end
    local n = player:distanceTo(data.to)
    room:askForDiscard(player, n, n, true, self.name, false)
  end,
}
shouxing:addRelatedSkill(shouxing_targetmod)
huangwudie:addSkill(shuangrui)
huangwudie:addSkill(fuxie)
huangwudie:addRelatedSkill(shouxing)
huangwudie:addRelatedSkill(shaxue)
Fk:loadTranslationTable{
  ["huangwudie"] = "黄舞蝶",

  ["shuangrui"] = "双锐",
  [":shuangrui"] = "准备阶段，你可以选择一名其他角色，视为对其使用一张【杀】。若其：不在你攻击范围内，此【杀】不可响应，你获得〖狩星〗"..
  "直到回合结束；在你攻击范围内，此【杀】伤害+1，你获得〖铩雪〗直到回合结束。",
  ["fuxie"] = "伏械",
  [":fuxie"] = "出牌阶段，你可以弃置一张武器牌或失去一个技能，令一名其他角色弃置两张手牌。",
  ["shouxing"] = "狩星",
  [":shouxing"] = "你可以将X张牌当一张不计次数的【杀】对一名攻击范围外的角色使用（X为你计算与该角色的距离）。",
  ["shaxue"] = "铩雪",
  [":shaxue"] = "当你对其他角色造成伤害后，你可以摸两张牌，然后弃置X张牌（X为你计算与该角色的距离）。",
  ["#shuangrui-choose"] = "双锐：选择一名角色视为对其使用【杀】，你根据是否在其攻击范围内获得不同的技能",
  ["#fuxie_weapon"] = "伏械：弃置一张武器牌，令一名其他角色弃置两张手牌",
  ["#fuxie_skill"] = "伏械：失去一个技能，令一名其他角色弃置两张手牌",
  ["fuxie_weapon"] = "弃置武器牌",
  ["#shouxing"] = "狩星：将任意张牌当一张不计次数的【杀】对一名攻击范围外、距离为牌数的角色使用",
}

return extension
