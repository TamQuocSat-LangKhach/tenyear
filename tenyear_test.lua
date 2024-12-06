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

  on_lose = function (self, player)
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
  [":anjing"] = "每回合限一次，当你造成伤害后，你可以选择至多X名已受伤的角色（X为此技能发动过的次数+1），"..
  "这些角色各摸一张牌，然后其中体力值最小的随机一名角色回复1点体力。",

  ["#zhantao-invoke"] = "是否对 %dest 发动 斩涛，进行判定",
  ["#anjing-choose"] = "是否发动 安境，令1-%arg名已受伤的角色摸牌，体力值最少的角色回复体力",

  ["$zhantao1"] = "",
  ["$zhantao2"] = "",
  ["$anjing1"] = "",
  ["$anjing2"] = "",
  ["~huzun"] = "",
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
          data.tos and #player.room:getUseExtraTargets(data) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return true
    else
      local n = data.extra_data.tanluan[2]
      local tos = player.room:askForChoosePlayers(player, player.room:getUseExtraTargets(data), 1, n,
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

local godpangtong = General(extension, "godpangtong", "god", 3)
godpangtong.hidden = true
godpangtong:addSkill("tmp_illustrate")
local peixiu = General(extension, "ty__peixiu", "qun", 3)
peixiu.subkingdom = "jin"
peixiu.hidden = true
peixiu:addSkill("tmp_illustrate")
Fk:loadTranslationTable{
  ["godpangtong"] = "神庞统",
  ["ty__peixiu"] = "裴秀",
}

local zhangliao = General(extension, "ty_wei__zhangliao", "qun", 4)
local yuxi = fk.CreateTriggerSkill{
  name = "yuxi",
  anim_type = "drawcard",
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name, nil, "@@yuxi-inhand")
  end,
}
local yuxi_targetmod = fk.CreateTargetModSkill{
  name = "#yuxi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@yuxi-inhand") > 0
  end,
}
local porong = fk.CreateTriggerSkill{
  name = "porong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[self.name]  --先随便弄个记录，之后再改
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#porong-invoke")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.additionalEffect = (data.additionalEffect or 0) + 1
    local targets = {}
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      if p:getLastAlive() ~= player then
        table.insert(targets, p:getLastAlive().id)
      end
      if p ~= player then
        table.insert(targets, p.id)
      end
      if p:getNextAlive() ~= player then
        table.insert(targets, p:getNextAlive().id)
      end
    end
    if #targets == 0 then return end
    room:doIndicate(player.id, targets)
    for _, id in ipairs(targets) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p:isKongcheng() then
        local card = room:askForCardChosen(player, p, "h", self.name, "#porong-prey::"..p.id)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card then
      if player:getMark(self.name) > 0 and data.card.trueName == "slash" then
        data.extra_data = data.extra_data or {}
        data.extra_data.combo_skill = data.extra_data.combo_skill or {}
        data.extra_data.combo_skill[self.name] = true
      else
        room:setPlayerMark(player, self.name, 1)
      end
    else
      room:setPlayerMark(player, self.name, 0)
    end
  end,
}
yuxi:addRelatedSkill(yuxi_targetmod)
zhangliao:addSkill(yuxi)
zhangliao:addSkill(porong)
Fk:loadTranslationTable{
  ["ty_wei__zhangliao"] = "威张辽",  --先随便弄个前缀，之后再改
  ["#ty_wei__zhangliao"] = "威锐镇西风",
  ["ty_wei"] = "威",

  ["yuxi"] = "驭袭",
  [":yuxi"] = "你造成或受到伤害时，摸一张牌，以此法获得的牌无次数限制。",
  ["porong"] = "破戎",
  [":porong"] = "连招技（伤害牌+【杀】），你可以获得此【杀】目标和其相邻角色各一张手牌，并令此【杀】额外结算一次。",
  ["@@yuxi-inhand"] = "驭袭",
  ["#porong-invoke"] = "破戎：是否令此【杀】额外结算一次，并获得目标及其相邻角色各一张手牌？",
  ["#porong-prey"] = "破戎：获得 %dest 一张手牌",

  ["$yuxi1"] = "任他千军来，我只一枪去！",
  ["$yuxi2"] = "长枪雪恨，斩尽胡马！",
  ["$porong1"] = "胡未灭，家何为？",
  ["$porong2"] = "诸君且听，这雁门虎啸！",
  ["~ty_wei__zhangliao"] = "血染战袍，虽死犹荣，此心无憾！",
}

local zhugeguo = General(extension, "mu__zhugeguo", "shu", 3, 3, General.Female)
local xidi = fk.CreateTriggerSkill{
  name = "xidi",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if event == fk.GameStart then
      return #handcards > 0
    elseif player == target and player.phase == Player.Start then
      local x = #table.filter(handcards, function (id)
        return Fk:getCardById(id):getMark("@@xidi-inhand") > 0
      end)
        if x > 0 then
          self.cost_data = math.min(x, 5)
          return true
        end
      end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@xidi-inhand", 1)
      end
    else
      room:askForGuanxing(player, room:getNCards(self.cost_data))
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@xidi-inhand", 0)
    end
  end,
}
local xidi_maxcards = fk.CreateMaxCardsSkill{
  name = "#xidi_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xidi-inhand") > 0
  end,
}
local chengyan = fk.CreateTriggerSkill{
  name = "chengyan",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
    (data.card.trueName == "slash" or data.card:isCommonTrick()) and
    not table.contains(AimGroup:getAllTargets(data.tos), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(1)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    }
    room:delay(1000)
    local card = Fk:getCardById(cards[1])
    if card.trueName == "slash" or card:isCommonTrick() then
      if not card.is_passive and card.skill:getMinTargetNum() < 2 and card.name ~= data.card.name then
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event ~= nil then
            local new_card = Fk:cloneCard(data.card.name, data.card.suit, data.card.number)
          for k, v in pairs(data.card) do
            if new_card[k] == nil then
              new_card[k] = v
            end
          end
          if data.card:isVirtual() then
            new_card.subcards = data.card.subcards
          else
            new_card.id = data.card.id
          end
          new_card.skillNames = data.card.skillNames
          new_card.skill = card.skill
          data.card = new_card
          use_event.data[1].card = new_card
          --FIXME：对单体目标的data.card的修改不会同步给使用事件
          local useCardIds = new_card:isVirtual() and new_card.subcards or { new_card.id }
          if #useCardIds > 0 then
            room:sendCardVirtName(useCardIds, card.name)
          end
        end
      end
      U.clearRemainCards(room, cards, self.name)
    else
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, self.name, nil, true, player.id, "@@xidi-inhand")
    end
  end,
}

xidi:addRelatedSkill(xidi_maxcards)
zhugeguo:addSkill(xidi)
zhugeguo:addSkill(chengyan)

Fk:loadTranslationTable{
  ["mu__zhugeguo"] = "乐诸葛果",
  --["#mu__zhugeguo"] = "",
  --["designer:mu__zhugeguo"] = "",

  ["xidi"] = "羲笛",
  [":xidi"] = "锁定技，游戏开始时，你的初始手牌增加“笛”标记且不计入手牌上限。"..
  "准备阶段，你观看牌堆顶的X张牌（X为你手牌区里的“笛”数且至多为5），然后将这些牌以任意顺序置于牌堆顶或牌堆底。",
  ["chengyan"] = "乘烟",
  [":chengyan"] = "当你于出牌阶段内使用【杀】或普通锦囊牌指定第一个目标后，若你不是此牌的目标，你可以亮出牌堆顶的一张牌，"..
  "若亮出的牌：为【杀】或普通锦囊牌（【无懈可击】、【借刀杀人】除外），你令使用的牌的作用效果变成与亮出的牌的作用效果相同；"..
  "不为【杀】且不为普通锦囊牌，你获得亮出的牌并标记为“笛”。",

  ["@@xidi-inhand"] = "笛",
}

local zhouyu = General(extension, "mu__zhouyu", "wu", 3)
local guyinz = fk.CreateTriggerSkill{
  name = "guyinz",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
          for _, info in ipairs(move.moveInfo) do
            if info.extra_data and info.extra_data.guyinz and info.extra_data.guyinz ~= player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
        for _, info in ipairs(move.moveInfo) do
          if info.extra_data and info.extra_data.guyinz and info.extra_data.guyinz ~= player.id then
            n = n + 1
          end
        end
      end
    end
    for _ = 1, n, 1 do
      if not player:hasSkill(self) then return end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.DrawInitialCards, fk.AfterDrawInitialCards, fk.AfterCardsMove},
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DrawInitialCards then
        return true
      elseif event == fk.AfterDrawInitialCards then
        return target ~= player and not target:isKongcheng()
      end
    end
    if event == fk.AfterCardsMove and player.seat == 1 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.DrawInitialCards then
      if target == player then
        data.num = 0
      else
        data.num = data.num + 1
      end
    elseif event == fk.AfterDrawInitialCards then
      local room = player.room
      for _, id in ipairs(target:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@guyinz", target.id)
      end
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@guyinz") ~= 0 then
              if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard then
                info.extra_data = info.extra_data or {}
                info.extra_data.guyinz = Fk:getCardById(info.cardId):getMark("@@guyinz")
              end
              player.room:setCardMark(Fk:getCardById(info.cardId), "@@guyinz", 0)
            end
          end
        end
      end
    end
  end,
}
local pinglu = fk.CreateActiveSkill{
  name = "pinglu",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#pinglu",
  can_use = function(self, player)
    return not table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@pinglu-inhand-phase") > 0
    end) and
    table.find(Fk:currentRoom().alive_players, function (p)
      return player:inMyAttackRange(p) and not p:isKongcheng()
    end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if player:inMyAttackRange(p) and not p.dead and not p:isKongcheng() then
        room:moveCardTo(table.random(p:getCardIds("h")), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id,
          "@@pinglu-inhand-phase")
      end
    end
  end,
}
zhouyu:addSkill(guyinz)
zhouyu:addSkill(pinglu)
Fk:loadTranslationTable{
  ["mu__zhouyu"] = "乐周瑜",
  ["#mu__zhouyu"] = "顾曲周郎",

  ["guyinz"] = "顾音",
  [":guyinz"] = "锁定技，你没有初始手牌，其他角色的初始手牌+1。其他角色的初始手牌被使用或弃置进入弃牌堆后，你摸一张牌。",
  ["pinglu"] = "平虏",
  [":pinglu"] = "出牌阶段，你可以获得攻击范围内每名其他角色各一张随机手牌。你此阶段不能再发动该技能直到这些牌离开你的手牌。",
  ["@@guyinz"] = "顾音",
  ["#pinglu"] = "平虏：获得攻击范围内每名角色各一张随机手牌",
  ["@@pinglu-inhand-phase"] = "平虏",
}

local menghuo = General(extension, "ty_sp__menghuo", "qun", 4)
--- 执行蛮王的某项
local function doManwang(player, i)
  local room = player.room
  if i == 1 then
    room:handleAddLoseSkills(player, "ty__panqin", nil, true, false)
  elseif i == 2 then
    player:drawCards(1, "ty__manwang")
  elseif i == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "ty__manwang",
      }
    end
  elseif i == 4 then
    player:drawCards(2, "ty__manwang")
    room:handleAddLoseSkills(player, "-ty__panqin", nil, true, false)
  end
end
local manwang = fk.CreateActiveSkill{
  name = "ty__manwang",
  anim_type = "special",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  prompt = function ()
    return "#ty__manwang-prompt:::"..(#Self:getTableMark("@[:]ty__manwang"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for i = 1, #effect.cards, 1 do
      if i > 4 or i > #player:getTableMark("@[:]ty__manwang") or player.dead then return end
      doManwang(player, i)
    end
  end,
  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", 0)
  end,
  on_acquire = function (self, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", {"ty__manwang1", "ty__manwang2", "ty__manwang3", "ty__manwang4"})
  end,
}
local panqin = fk.CreateTriggerSkill{
  name = "ty__panqin",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and
                table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if #ids == 0 then return false end
      local card = Fk:cloneCard("savage_assault")
      card:addSubcards(ids)
      local tos = table.filter(player.room:getOtherPlayers(player), function(p) return not player:isProhibited(p, card) end)
      if not player:prohibitUse(card) and #tos > 0 then
        self.cost_data = {ids, tos}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards_num = #self.cost_data[1]
    local tos_num = #self.cost_data[2]
    local promot = (#player:getTableMark("@[:]ty__manwang") > 0 and tos_num >= cards_num) and "#ty__panqin_delete-invoke" or "#ty__panqin-invoke"
    if player.room:askForSkillInvoke(player, self.name, nil, promot) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data[1]
    local tos = self.cost_data[2]
    room:useVirtualCard("savage_assault", cards, player, tos, self.name)
    if #tos >= #cards then
      doManwang(player, #player:getTableMark("@[:]ty__manwang"))
      local mark = player:getTableMark("@[:]ty__manwang")
      if #mark > 0 then
        room:removeTableMark(player, "@[:]ty__manwang", mark[#mark])
        room:changeMaxHp(player, 1)
        if player:isWounded() and not player.dead then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
menghuo:addSkill(manwang)
menghuo:addRelatedSkill(panqin)
Fk:loadTranslationTable{
  ["ty_sp__menghuo"] = "孟获",
  ["#ty_sp__menghuo"] = "勒格诗惹",
  ["designer:ty_sp__menghuo"] = "玄蝶既白",
  --["illustrator:ty_sp__menghuo"] = "",

  ["ty__manwang"] = "蛮王",
  [":ty__manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["ty__panqin"] = "叛侵",
  [":ty__panqin"] = "出牌阶段或弃牌阶段结束时，你可以将本阶段你因弃置进入弃牌堆且仍在弃牌堆的牌当【南蛮入侵】使用，然后若此牌目标数不小于"..
  "这些牌的数量，你执行并移除〖蛮王〗的最后一项，然后加1点体力上限并回复1点体力。",
  ["@[:]ty__manwang"] = "蛮王",
  ["ty__manwang1"] = "蛮王1",
  ["ty__manwang2"] = "蛮王2",
  ["ty__manwang3"] = "蛮王3",
  ["ty__manwang4"] = "蛮王4",
  [":ty__manwang1"] = "获得〖叛侵〗",
  [":ty__manwang2"] = "摸一张牌",
  [":ty__manwang3"] = "回复1点体力",
  [":ty__manwang4"] = "摸两张牌并失去〖叛侵〗",
  ["#ty__manwang-prompt"] = "蛮王：弃置任意张牌，依次执行〖蛮王〗的前等量项（剩余 %arg 项）",

  ["#ty__panqin-invoke"] = "叛侵：你可将弃牌堆中你弃置的牌当【南蛮入侵】使用",
  ["#ty__panqin_delete-invoke"] = "叛侵：将弃牌堆中你弃置的牌当【南蛮入侵】使用，然后执行并移除〖蛮王〗的最后一项，加1点体力上限并回复1点体力",
}

return extension
