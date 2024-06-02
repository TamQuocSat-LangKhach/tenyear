local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
  ["tymou"] = "新服谋",
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
      if #U.getEventsByRule(room, GameEvent.UseCard, 2, function(e)
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
    U.getEventsByRule(room, GameEvent.UseCard, 2, function(e)
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
      room:moveCards({
        ids = {table.random(cards)},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
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

--袁胤

local tmp_illustrate = fk.CreateActiveSkill{name = "tmp_illustrate"}

local chezhou = General(extension, "chezhou", "wei", 4)
chezhou:addSkill(tmp_illustrate)
chezhou.hidden = true
Fk:loadTranslationTable{
  ["chezhou"] = "车胄",
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
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data)
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

  ["yinbi"] = "隐避",
  [":yinbi"] = "锁定技，若其他角色的手牌数均不与你相等，你使用牌无距离和次数限制。"..
  "弃牌阶段开始时，若你不是手牌上限最大的角色，你令你的手牌上限的初值于此阶段内改为X（X为其他角色的手牌上限的最大值）。",
  ["shuaiyan"] = "率言",
  [":shuaiyan"] = "锁定技，当其他角色得到/失去手牌后，若其手牌数与你相等，你选择：1.弃置其一张牌；2.摸一张牌。",

  ["shuaiyan_discard"] = "弃置%dest的一张牌",
}


return extension
