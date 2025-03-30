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
    if card and player:hasSkill(yinbi) then
      local x = player:getHandcardNum()
      return table.every(Fk:currentRoom().alive_players, function (p)
        return p == player or p:getHandcardNum() ~= x
      end)
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    if card and player:hasSkill(yinbi) then
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

local zhurong = General(extension, "ty_sp__zhurong", "qun", 4, 4, General.Female)
local manhou = fk.CreateActiveSkill{
  name = "manhou",
  anim_type = "special",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
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
        if player.dead then return end
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if p ~= player and not p:isKongcheng() then
            table.insert(targets, p.id)
          end
        end
        if #targets > 0 then
          targets = room:askForChoosePlayers(player, targets, 1, 1, "#manhou-prey", self.name, false)
          local to = room:getPlayerById(targets[1])
          local id = room:askForCardChosen(player, to, "h", self.name)
          room:obtainCard(player.id, id, false, fk.ReasonPrey)
        end
      elseif i == 4 then
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if #p:getCardIds{ Player.Equip, Player.Judge } > 0 then
            table.insert(targets, p.id)
          end
        end
        if #targets > 0 then
          targets = room:askForChoosePlayers(player, targets, 1, 1, "#manhou-throw", self.name, false)
          local to = room:getPlayerById(targets[1])
          local id = room:askForCardChosen(player, to, "ej", self.name)
          room:throwCard(id, self.name, to, player)
        end
        room:handleAddLoseSkills(player, "tanluan", nil, true, false)
      end
    end
  end,

  on_lose = function (self, player)
    player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
  end,
}

local tanluan = fk.CreateActiveSkill{
  name = "tanluan",
  prompt = "#tanluan-active",
  anim_type = "offensive",
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards, ids = {}, {}
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          --if not table.contains(cards, id) then
          --  table.insert(cards, id)
            if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and
                room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(ids, id)
            end
          --end
        end
      end
      return false
    end, end_id)
    if #ids == 0 then return end
    local use = room:askForUseRealCard(player, ids, self.name, "#tanluan-active", {
      expand_pile = ids,
      bypass_times = true,
      extraUse = true,
    }, true)
    if use and use.damageDealt then
      player:setSkillUseHistory("manhou", 0, Player.HistoryPhase)
    end
  end,

  on_lose = function (self, player)
    player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
  end,
}

zhurong:addSkill(manhou)
zhurong:addRelatedSkill(tanluan)
Fk:loadTranslationTable{
  ["ty_sp__zhurong"] = "祝融",
  ["#ty_sp__zhurong"] = "诗惹喜莫",

  ["manhou"] = "蛮后",
  [":manhou"] = "出牌阶段限一次，你可以摸至多四张牌，依次执行前等量项："..
  "1.失去〖探乱〗；2.弃置一张手牌；3.失去1点体力并获得一名其他角色的一张手牌；4.弃置场上的一张牌并获得〖探乱〗。",
  ["tanluan"] = "探乱",
  [":tanluan"] = "出牌阶段限一次，你可以使用一张于此回合内因弃置而移至弃牌堆的牌，然后若此牌造成过伤害，〖蛮后〗视为未发动过。",
  ["#manhou-prompt"] = "蛮后：你可以摸至多四张牌，依次执行等量效果",
  ["#manhou-prey"] = "蛮后：选择1名其他角色，获得其1张手牌",
  ["#manhou-throw"] = "蛮后：选择1名角色，弃置其场上的1张牌",
  ["#tanluan-active"] = "发动 探乱，使用一张本回合内因弃置而置入弃牌堆的牌，若造成伤害则重置 蛮后",
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
      room:cleanProcessingArea(cards, self.name)
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

local wenchou = General(extension, "tystar__wenchou", "qun", 4)
local lianzhan = fk.CreateTriggerSkill{
  name = "lianzhan",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and #TargetGroup:getRealTargets(data.tos) == 1 and
      data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getUseExtraTargets(data)
    local success, dat = room:askForUseActiveSkill(player, "lianzhan_active",
      "#lianzhan-choose:::"..data.card:toLogString(), true, {exclusive_targets = targets}, false)
    if success and dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = self.cost_data.targets
    if #tos > 0 then
      for _, id in ipairs(tos) do
        table.insert(data.tos, {id})
      end
    else
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.lianzhan = player.id
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data[1]
        if use.extra_data and use.extra_data.lianzhan then
          return table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      local use = use_event.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.lianzhan_count = (use.extra_data.lianzhan_count or 0) + 1
    end
  end,
}
local lianzhan_delay = fk.CreateTriggerSkill{
  name = "#lianzhan_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.lianzhan == player.id
  end,
  on_cost = function (self, event, target, player, data)
    local n = data.extra_data.lianzhan_count
    if n == nil or n == 0 then
      self.cost_data = {choice = "negative"}
      return true
    elseif n == 2 then
      if player:isWounded() then
        if player.room:askForSkillInvoke(player, "lianzhan", nil, "#lianzhan-recover") then
          self.cost_data = {choice = "recover"}
          return true
        end
      elseif player.room:askForSkillInvoke(player, "lianzhan", nil, "#lianzhan-draw") then
        self.cost_data = {choice = "draw"}
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice
    if choice == "recover" then
      if player:isWounded() then
        player:broadcastSkillInvoke("lianzhan")
        room:notifySkillInvoked(player, "lianzhan", "support")
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = "lianzhan",
        })
      end
    elseif choice == "draw" then
      player:broadcastSkillInvoke("lianzhan")
      room:notifySkillInvoked(player, "lianzhan", "drawcard")
      player:drawCards(2, "lianzhan")
    elseif choice == "negative" then
      player:broadcastSkillInvoke("lianzhan")
      room:notifySkillInvoked(player, "lianzhan", "negative")
      room:sortPlayersByAction(TargetGroup:getRealTargets(data.tos))
      for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
        if player.dead then return end
        local p = room:getPlayerById(id)
        if not p.dead then
          room:useVirtualCard(data.card.name, nil, p, player, "lianzhan", true)
        end
      end
    end
  end,
}
local lianzhan_active = fk.CreateActiveSkill{
  name = "lianzhan_active",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and table.contains(extra_data.exclusive_targets, to_select)
  end,
}
local weimingw = fk.CreateTriggerSkill{
  name = "weimingw",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and data.tos and table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
      self.cost_data = {}
      if target.hp < player.hp then
        table.insert(self.cost_data, 1)
      end
      if #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        return damage.from == player and damage.to == target
      end, Player.HistoryRound) > 0 then
        table.insert(self.cost_data, 2)
      end
      if #self.cost_data == 2 then
        return true
      elseif self.cost_data[1] == 1 then
        return not target:isKongcheng()
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = table.filter(target:getCardIds("h"), function (id)
      return not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(table.random(cards), self.name, target, target)
    end
    local choices = table.simpleClone(self.cost_data)
    if #choices == 2 and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
lianzhan:addRelatedSkill(lianzhan_delay)
Fk:addSkill(lianzhan_active)
wenchou:addSkill(lianzhan)
wenchou:addSkill(weimingw)
Fk:loadTranslationTable{
  ["tystar__wenchou"] = "星文丑",
  ["#tystar__wenchou"] = "夔威天下",

  ["lianzhan"] = "连战",
  [":lianzhan"] = "当你使用伤害牌指定唯一目标时，你可以选择一项：1.额外指定一个目标；2.此牌额外结算一次。然后，若此牌对目标造成伤害次数为2，"..
  "你可以回复1点体力（若你未受伤改为摸两张牌）；为0，目标角色视为对你使用同名牌。",
  ["weimingw"] = "威名",
  [":weimingw"] = "锁定技，体力值小于你或本轮受到过你造成伤害的其他角色对你使用牌时，随机弃置一张手牌，若皆满足，你摸一张牌。",
  ["lianzhan_active"] = "连战",
  ["#lianzhan-choose"] = "连战：你可以为此%arg额外指定一个目标，或直接点“确定”额外结算一次",
  ["#lianzhan_delay"] = "连战",
  ["#lianzhan-recover"] = "连战：是否回复1点体力？",
  ["#lianzhan-draw"] = "连战：是否摸两张牌？",
}

local lukang = General(extension, "wm__lukang", "wu", 4)
local kegou = fk.CreateTriggerSkill{
  name = "kegou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return #events == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    cards = table.filter(cards, function (id)
      return table.every(cards, function (id2)
        return Fk:getCardById(id).number >= Fk:getCardById(id2).number
      end)
    end)
    room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local jiduan = fk.CreateTriggerSkill{
  name = "jiduan",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function (id)
        return not player.room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
    end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jiduan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if data.card.number ~= 13 then
      room:addTableMark(player, "jiduan-turn", to.id)
    end
    if to:isKongcheng() then return end
    local prompt = "#jiduan0-show"
    if data.card.number > 0 and data.card.number < 14 then
      prompt = "#jiduan-show:::"..data.card.number
    end
    local card = room:askForCard(to, 1, 1, false, self.name, false, nil, "#jiduan-show:::"..data.card.number)
    local yes = prompt ~= "#jiduan0-show" and Fk:getCardById(card[1]).number < data.card.number
    to:showCards(card)
    if player.dead or to.dead or not yes then return end
    local choices = {"jiduan_discard::"..to.id, "jiduan_draw::"..to.id}
    local choice = room:askForChoice(player, choices, self.name)
    if choice:startsWith("jiduan_discard") then
      if table.find(to:getCardIds("h"), function (id)
        return not to:prohibitDiscard(id) and table.contains({1, 2, 3, 4}, Fk:getCardById(id).suit)
      end) then
        local success, dat = room:askForUseActiveSkill(to, "jiduan_active", "#jiduan-discard", false)
        if success and dat then
        else
          dat = {}
          dat.cards = {}
          local suits = {1, 2, 3, 4}
          for _, id in ipairs(to:getCardIds("h")) do
            local suit = Fk:getCardById(id).suit
            if table.contains(suits, suit) and not to:prohibitDiscard(id) then
              table.insert(dat.cards, id)
              table.removeOne(suits, suit)
              if #suits == 0 then
                break
              end
            end
          end
        end
        if #dat.cards > 0 then
          room:throwCard(dat.cards, self.name, to, to)
        end
      end
    else
      local suits = table.filter({1, 2, 3, 4}, function (suit)
        return not table.find(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).suit == suit
        end)
      end)
      if #suits == 0 then return end
      local cards = {}
      local id = -1
      for i = #room.draw_pile, 1, -1 do
        id = room.draw_pile[i]
        if table.removeOne(suits, Fk:getCardById(id).suit) then
          table.insert(cards, id)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonDraw, self.name, nil, false, to.id)
      end
    end
  end,
}
local jiduan_active = fk.CreateActiveSkill{
  name = "jiduan_active",
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, to_select, selected, user)
    return table.contains(Self:getCardIds("h"), to_select) and
    not table.find(selected, function (id)
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id))
    end) and not Self:prohibitDiscard(to_select)
  end,
  feasible = function (self, selected, selected_cards)
    return #selected == 0 and #selected_cards > 0 and
      not table.find(Self:getCardIds("h"), function (id)
        return Fk:getCardById(id).suit ~= Card.NoSuit and
          not table.find(selected_cards, function (id2)
            return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
          end) and
          not Self:prohibitDiscard(id)
      end)
  end,
}
local dixian = fk.CreateActiveSkill{
  name = "dixian",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  min_card_num = 1,
  target_num = 0,
  prompt = "#dixian",
  can_use = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select)
    return not Self:prohibitDiscard(Fk:getCardById(to_select)) and table.contains(Self:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = {}
    for i = 13, 1, -1 do
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == i then
          table.insert(cards, id)
          if #cards == #effect.cards then
            break
          end
        end
      end
      if #cards == #effect.cards then
        break
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id, "@@dixian-inhand")
    end
  end,
}
local dixian_maxcards = fk.CreateMaxCardsSkill{
  name = "#dixian_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@dixian-inhand") > 0
  end,
}
lukang:addSkill(kegou)
Fk:addSkill(jiduan_active)
lukang:addSkill(jiduan)
dixian:addRelatedSkill(dixian_maxcards)
lukang:addSkill(dixian)
Fk:loadTranslationTable{
  ["wm__lukang"] = "武陆抗",
  ["#wm__lukang"] = "桢武熙朝",
}
Fk:loadTranslationTable{
  ["kegou"] = "克构",
  [":kegou"] = "锁定技，其他角色回合结束时，你随机获得本回合进入弃牌堆的点数最大的一张牌。",
}
Fk:loadTranslationTable{
  ["jiduan"] = "急断",
  [":jiduan"] = "每回合每名角色限一次，当你使用牌指定目标后，你可以令其中一名角色展示一张手牌，若点数小于你使用的牌，你选择一项："..
  "1.其弃置每种花色的手牌各一张；2.其摸手牌中没有的花色各一张牌。若你使用的牌点数为K，则不计入此技能次数限制。",
  ["#jiduan-choose"] = "急断：令一名角色展示一张手牌，若点数小于你使用的牌则令其弃牌或摸牌",
  ["#jiduan0-show"] = "急断：请展示一张手牌",
  ["#jiduan-show"] = "急断：请展示一张手牌，若点数小于%arg则执行效果",
  ["jiduan_discard"] = "%dest 弃置每种花色手牌各一张",
  ["jiduan_draw"] = "%dest 摸手牌中缺少的花色牌各一张",
  ["jiduan_active"] = "急断",
  ["#jiduan-discard"] = "急断：请弃置每种花色的手牌各一张",
}
Fk:loadTranslationTable{
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以弃置任意张手牌，从牌堆中按点数从大到小顺序获得等量的牌，这些牌不计入手牌上限。",
  ["#dixian"] = "砥贤：弃置任意张手牌，从牌堆按点数从大到小获得等量的牌",
  ["@@dixian-inhand"] = "砥贤",
}

local laoyan = fk.CreateTriggerSkill{
  name = "laoyan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) then
      local targets = AimGroup:getAllTargets(data.tos)
      local tos = {}
      for _, p in ipairs(player.room.alive_players) do
        if p ~= player and table.contains(targets, p.id) then
          table.insert(tos, p.id)
        end
      end
      if #tos > 0 then
        self.cost_data = { tos = tos }
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(self.cost_data.tos) do
      table.insertIfNeed(data.nullifiedTargets, to)
    end
  end,
}

Fk:loadTranslationTable{
  ["laoyan"] = "劳燕",
  [":laoyan"] = "锁定技，当你成为牌的目标后，若有其他目标，你令此牌对这些目标均无效。",
}

local jueyan = fk.CreateTriggerSkill{
  name = "jueyanz",
  anim_type = "control",
  dynamic_desc = function(self, player)
    return
      "jueyanz_inner:" ..
      ((#player:getTableMark("jueyanz_choices") > 2) and ":" or "jueyanz_pindian:jueyanz_update") .. ":" ..
      (player:getMark("jueyanz_damage") + 1) .. ":" ..
      (player:getMark("jueyanz_recover") + 1) .. ":" ..
      (player:getMark("jueyanz_prey") + 1)
  end,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local tos = TargetGroup:getRealTargets(data.tos)
    if #tos ~= 1 then return false end
    if player.id == tos[1] then return false end
    local mark = player:getTableMark("jueyanz_choices")
    if #mark > 2 then return true end
    local to = player.room:getPlayerById(tos[1])
    return not to.dead and player:canPindian(to)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("jueyanz_choices")
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if #mark > 2 then
      local choices = {
        "jueyanz_damage::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_damage") + 1),
        "jueyanz_recover:::" .. tostring(player:getMark("jueyanz_recover") + 1),
        "jueyanz_prey::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_prey") + 1),
        "Cancel"
      }
      local choice = room:askForChoice(player, choices, self.name, nil, false)
      if choice == "Cancel" then return false end
      self.cost_data = { tos = { to.id }, choice = choice:split(":")[1] }
      return true
    elseif room:askForSkillInvoke(player, self.name, nil, "#jueyanz-invoke::" .. to.id) then
      self.cost_data = { tos = { to.id } }
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice
    local to = room:getPlayerById(self.cost_data.tos[1])
    if choice == nil then
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner ~= player or player.dead then return false end
      local choices = {
        "jueyanz_damage::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_damage") + 1),
        "jueyanz_recover:::" .. tostring(player:getMark("jueyanz_recover") + 1),
        "jueyanz_prey::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_prey") + 1),
        "Cancel"
      }
      choice = room:askForChoice(player, choices, self.name, nil, false)
      if choice == "Cancel" then return false end
      choice = choice:split(":")[1]
    end
    local x = player:getMark(choice) + 1
    if choice == "jueyanz_damage" then
      room:damage{
        from = player,
        to = player,
        damage = x,
        skillName = self.name,
      }
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = x,
          skillName = self.name,
        }
      end
    elseif choice == "jueyanz_recover" then
      if player:isWounded() then
        room:recover{
          who = player,
          num = x,
          recoverBy = player,
          skillName = self.name
        }
      end
    else
      x = math.max(x, #to:getCardIds(Player.Hand))
      if x > 0 then
        local ids = room:askForCardsChosen(player, to, x, x, "h", self.name)
        room:obtainCard(player.id, ids, false, fk.ReasonPrey)
      end
    end
    if not player:hasSkill(self, true) then return false end
    for _, choice_name in ipairs({"jueyanz_damage", "jueyanz_recover", "jueyanz_prey"}) do
      if choice_name == choice then
        room:setPlayerMark(player, choice_name, 0)
      else
        room:addPlayerMark(player, choice_name, 1)
      end
    end
    local mark = player:getTableMark("jueyanz_choices")
    if #mark > 2 then return false end
    room:addTableMarkIfNeed(player, "jueyanz_choices", choice)
  end,

  on_lose = function (self, player)
    local room = player.room
    for _, name in ipairs({"jueyanz_damage", "jueyanz_recover", "jueyanz_prey", "jueyanz_choices"}) do
      room:setPlayerMark(player, name, 0)
    end
  end,
}

Fk:loadTranslationTable{
  ["jueyanz"] = "诀言",
  [":jueyanz"] = "当你使用的牌结算结束后，若目标数为1且此目标不为你，你可以与其拼点，若你赢，你选择："..
    "1.对你和其各造成1点伤害；2.回复1点体力；3.获得其的1张手牌。"..
    "然后，此次选择的选项的数值改为1，其他选项的数值均+1，"..
    "若三个选项均被选择过，你修改此技能（跳过拼点步骤直接选择选项）。",

  ["#jueyanz-invoke"] = "是否发动 诀言，与 %dest 拼点，若你赢则可选择一项效果",
  ["jueyanz_damage"] = "对你和%dest各造成%arg点伤害",
  ["jueyanz_recover"] = "回复%arg点体力",
  ["jueyanz_prey"] = "获得%dest的%arg张手牌",

  [":jueyanz_inner"] = "当你使用的牌结算结束后，若目标数为1且此目标不为你，你可以{1}选择："..
    "1.对你和其各造成{3}点伤害；2.回复{4}点体力；3.获得其的{5}张手牌。"..
    "然后，此次选择的选项的数值改为1，其他选项的数值均+1{2}。",
  ["jueyanz_pindian"] = "与其拼点，若你赢，你",
  ["jueyanz_update"] = "，若三个选项均被选择过，你修改此技能（跳过拼点步骤直接选择选项）",
}

local zhanghuai = General(extension, "zhanghuai", "wu", 3, 3, General.Female)

zhanghuai:addSkill(laoyan)
zhanghuai:addSkill(jueyan)

Fk:loadTranslationTable{
  ["zhanghuai"] = "张怀",
  ["#zhanghuai"] = "连理分枝",
  ["~zhanghuai"] = "",
}

local guangyong = fk.CreateTriggerSkill{
  name = "guangyong",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player == target and data.firstTarget and player:hasSkill(self) then
      local targets = AimGroup:getAllTargets(data.tos)
      local tos = {}
      for _, p in ipairs(player.room.alive_players) do
        if table.contains(targets, p.id) then
          table.insert(tos, p.id)
        end
      end
      if #tos > 0 then
        self.cost_data = { tos = tos }
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data.tos
    if table.contains(tos, player.id) then
      if player.maxHp < 8 then
        room:changeMaxHp(player, 1)
        if player.dead then return false end
      end
      if #tos == 1 then return false end
    end
    if player.maxHp > 1 then
      room:changeMaxHp(player, -1)
      if player.dead then return false end
    end
    tos = table.filter(tos, function (pid)
      return pid ~= player.id and not room:getPlayerById(pid):isNude()
    end)
    if #tos == 0 then return false end
    if #tos > 1 then
      tos = room:askForChoosePlayers(player, tos, 1, 1, "#guangyong-choose", self.name, false)
    end
    local to = room:getPlayerById(tos[1])
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
  end,
}

Fk:loadTranslationTable{
  ["guangyong"] = "犷勇",
  [":guangyong"] = "锁定技，当你使用牌指定自己为目标后，你加1点体力上限（至多加至8）；"..
  "当你使用牌指定其他角色为目标后，你减1点体力上限（至多减至1），获得其中一名目标角色一张牌。",

  ["#guangyong-choose"] = "犷勇：选择1名目标角色，获得其1张牌",
}

local juchui = fk.CreateTriggerSkill{
  name = "juchui",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[self.name]  --先随便弄个记录，之后再改
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead
    end)
    if #targets == 0 then return false end
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#juchui-choose", self.name, true, true)
    if #targets > 0 then
      local choice
      local to = room:getPlayerById(targets[1])
      if to.maxHp > player.maxHp then
        choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name, "#juchui-max::" .. to.id)
      else
        choice = room:askForChoice(player, {"recover", "loseHp"}, self.name, "#juchui-min::" .. to.id)
      end
      self.cost_data = { tos = targets, choice = choice }
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local choice = self.cost_data.choice
    if choice == "recover" then
      room:recover {
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    elseif choice == "loseHp" then
      room:loseHp(to, 1, self.name)
    else
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. choice)
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player.id, self.name)
      end
      if not to.dead then
        room:addTableMarkIfNeed(to, "@juchui_limit-turn", choice .. "_char")
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeEquip then
      room:setPlayerMark(player, self.name, 1)
    elseif data.card.type == Card.TypeTrick then
      if player:getMark(self.name) > 0 then
        room:setPlayerMark(player, self.name, 0)
        data.extra_data = data.extra_data or {}
        data.extra_data.combo_skill = data.extra_data.combo_skill or {}
        data.extra_data.combo_skill[self.name] = true
      end
    else
      room:setPlayerMark(player, self.name, 0)
    end
  end,
}

local juchuiProhibit = fk.CreateProhibitSkill{
  name = "#juchui_prohibit",
  prohibit_use = function(self, player, card)
    return table.contains(player:getTableMark("@juchui_limit-turn"), card:getTypeString() .. "_char")
  end,
}

juchui:addRelatedSkill(juchuiProhibit)

Fk:loadTranslationTable{
  ["juchui"] = "据陲",
  [":juchui"] = "连招技（装备牌+锦囊牌），你可以选择其中一名目标角色，若其体力上限：不大于你，你令其失去或回复1点体力；"..
    "大于你，你选择一种牌的类别，获得牌堆中一张此类别的牌且其本回合不能使用此类别的牌。",
  ["#juchui_prohibit"] = "据陲",

  ["#juchui-choose"] = "是否发动 据陲，选择1名目标角色，根据你与其体力上限大小来执行效果",
  ["#juchui-max"] = "据陲：选择一种类别的牌获得，且令%dest本回合不能使用",
  ["#juchui-min"] = "据陲：选择令%dest执行的效果",
  ["@juchui_limit-turn"] = "据陲",
}

local dongzhuo = General(extension, "ty_wei__dongzhuo", "qun", 5)
dongzhuo:addSkill(guangyong)
dongzhuo:addSkill(juchui)

Fk:loadTranslationTable{
  ["ty_wei__dongzhuo"] = "威董卓",
  ["#ty_wei__dongzhuo"] = "魔震西凉",
  ["~ty_wei__dongzhuo"] = "",
}


return extension
