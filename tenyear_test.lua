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
        n = n + #Fk:translate(use.card.trueName) / 3
      end
    end, end_id)
    room:setPlayerMark(player, "feibaic-turn", event_record)  --记录上次发动技能的事件id
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if #Fk:translate(card.trueName) / 3 == n then
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
}

local matie = General(extension, "matie", "qun", 4)
matie:addSkill("tmp_illustrate")
matie.hidden = true
Fk:loadTranslationTable{
  ["matie"] = "马铁",
}

local hansong = General(extension, "hansong", "wei", 3)
hansong:addSkill("tmp_illustrate")
hansong.hidden = true
Fk:loadTranslationTable{
  ["hansong"] = "韩嵩",
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
      choices = {"liangyan_discard", "draw1", "draw2"}
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
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local linghui_max, linghui_min = true, true
      local x, y = player:getHandcardNum(), 0
      for _, p in ipairs(player.room.alive_players) do
        y = p:getHandcardNum()
        if x > y then
          linghui_min = false
        elseif x < y then
          linghui_max = false
        end
      end
      return linghui_max or linghui_min
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
    y = math.max(1, x-z)
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
  ["~tystar__zhangchunhua"] = "我何为也？竟成可憎之老物……",
}

local simashi = General(extension, "ty__simashi", "wei", 3)
local sanshi = fk.CreateTriggerSkill{
  name = "sanshi",
  events = {fk.CardUsing, fk.TurnEnd, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data.card:isVirtual() and table.contains(U.getMark(player, self.name), data.card.id)
    elseif event == fk.TurnEnd then
      local room = player.room
      local cards = table.filter(U.getMark(player, self.name), function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards == 0 then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local ids = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.removeOne(cards, id) then
              if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
                if move.moveReason == fk.ReasonUse then
                  local use_event = e:findParent(GameEvent.UseCard)
                  if use_event == nil or use_event.data[1].from ~= player.id then
                    table.insert(ids, id)
                  end
                else
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end, turn_event.id)
      if #ids > 0 then
        self.cost_data = ids
        return true
      end
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(player.room.players, Util.IdMapper)
    elseif event == fk.TurnEnd then
      room:moveCardTo(table.simpleClone(self.cost_data), Card.PlayerHand, player, fk.ReasonPrey, self.name)
    elseif event == fk.GameStart then
      local cardmap = {}
      for i = 1, 13, 1 do
        table.insert(cardmap, {})
      end
      for _, id in ipairs(room.draw_pile) do
        local n = Fk:getCardById(id).number
        if n > 0 and n < 14 then
          table.insert(cardmap[n], id)
        end
      end
      local cards = {}
      for _, ids in ipairs(cardmap) do
        if #ids > 0 then
          table.insert(cards, table.random(ids))
        end
      end
      room:setPlayerMark(player, self.name, cards)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and #U.getMark(player, self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = U.getMark(player, self.name)
    for _, cid in ipairs(cards) do
      local card = Fk:getCardById(cid)
      if room:getCardArea(cid) == Card.PlayerHand and card:getMark("@@expendables-inhand") == 0 then
        room:setCardMark(Fk:getCardById(cid), "@@expendables-inhand", 1)
      end
    end
  end,
}
local zhenrao = fk.CreateTriggerSkill{
  name = "zhenrao",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if target == player then
      if not data.firstTarget then return false end
      local tos = AimGroup:getAllTargets(data.tos)
      local targets = {}
      local mark = U.getMark(player, "zhenrao-turn")
      for _, p in ipairs(player.room.alive_players) do
        if p:getHandcardNum() > player:getHandcardNum() and
        table.contains(tos, p.id) and not table.contains(mark, p.id) then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    else
      if data.to == player.id and not target.dead and player:getHandcardNum() < target:getHandcardNum() and
      not table.contains(U.getMark(player, "zhenrao-turn"), target.id) then
        self.cost_data = {target.id}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.cost_data, 1, 1, "#zhenrao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "zhenrao-turn")
    table.insert(mark, self.cost_data)
    room:setPlayerMark(player, "zhenrao-turn", mark)
    room:damage{
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
local chenlue = fk.CreateActiveSkill{
  name = "chenlue",
  anim_type = "drawcard",
  prompt = "#chenlue-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #U.getMark(player, "sanshi") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local areas = {Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile}
    local cards = table.filter(U.getMark(player, "sanshi"), function (id)
      local area = room:getCardArea(id)
      return table.contains(areas, area) or (area == Card.PlayerHand and room:getCardOwner(id) ~= player)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      room:setPlayerMark(player, "chenlue-turn", cards)
    end
  end,
}
local chenlue_delay = fk.CreateTriggerSkill{
  name = "#chenlue_delay",
  events = {fk.TurnEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    local areas = {Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}
    local room = player.room
    local cards = table.filter(U.getMark(player, "chenlue-turn"), function (id)
      local area = room:getCardArea(id)
      return area == Card.DrawPile or area == Card.DiscardPile or
      (room:getCardOwner(id) == player and table.contains(areas, area))
    end)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile("chenlue", table.simpleClone(self.cost_data), true, self.name)
  end,
}
chenlue:addRelatedSkill(chenlue_delay)
simashi:addSkill(sanshi)
simashi:addSkill(zhenrao)
simashi:addSkill(chenlue)
Fk:loadTranslationTable{
  ["ty__simashi"] = "司马师",

  ["sanshi"] = "散士",
  [":sanshi"] = "锁定技，游戏开始时，你将牌堆里每个点数的随机一张牌标记为“死士”牌。"..
  "一名角色的回合结束时，你获得弃牌堆里于本回合非因你使用或打出而移至此区域的“死士”牌。"..
  "当你使用“死士”牌时，你令此牌不可被响应。",
  ["zhenrao"] = "震扰",
  [":zhenrao"] = "每回合对每名角色限一次，当你使用牌指定第一个目标后，或其他角色使用牌指定你为目标后，"..
  "你可以选择手牌数大于你的其中一个目标或使用者，对其造成1点伤害。",
  ["chenlue"] = "沉略",
  [":chenlue"] = "限定技，出牌阶段，你可以从牌堆、弃牌堆、场上或其他角色的手牌中获得所有“死士”牌，"..
  "此回合结束时，将这些牌移出游戏直到你死亡。",
  ["@@expendables-inhand"] = "死士",
  ["#zhenrao-choose"] = "是否发动 震扰，对其中手牌数大于你的1名角色造成1点伤害",
  ["#chenlue-active"] = "发动 沉略，获得所有被标记的“死士”牌（回合结束后移出游戏）",
  ["#chenlue_delay"] = "沉略",

}

local wangling = General(extension, "ty__wangling", "wei", 4)
local jichouw_distribution = fk.CreateActiveSkill{
  name = "jichouw_distribution",
  target_num = 1,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(self.jichouw_cards, to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and not table.contains(self.jichouw_targets, to_select)
  end,
  can_use = Util.FalseFunc,
}
Fk:addSkill(jichouw_distribution)
local jichouw = fk.CreateTriggerSkill{
  name = "jichouw",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local names = {}
      local cards = {}
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          if table.contains(names, use.card.trueName) then
            cards = {}
            return true
          end
          table.insert(names, use.card.trueName)
          table.insertTableIfNeed(cards, Card:getIdList(use.card))
        end
      end, phase_event.id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    local targets = {}
    local moveInfos = {}
    local names = {}
    while true do
      local success, dat = room:askForUseActiveSkill(player, "jichouw_distribution", "#jichouw-distribution", true,
      { expand_pile = cards, jichouw_cards = cards , jichouw_targets = targets }, true)
      if success then
        local to = dat.targets[1]
        local give_cards = dat.cards
        table.insert(targets, to)
        table.removeOne(cards, give_cards[1])
        table.insertIfNeed(names, Fk:getCardById(give_cards[1]).trueName)
        table.insert(moveInfos, {
          ids = give_cards,
          fromArea = Card.DiscardPile,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          proposer = player.id,
          skillName = self.name,
        })
        if #cards == 0 then break end
      else
        break
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
      local x = player:getMark("@jichouw")
      if x > 0 then
        player:drawCards(x, self.name)
      else
        room:setPlayerMark(player, "@jichouw", #names)
      end
      if player:hasSkill("ty__mouli", true) and player:usedSkillTimes("ty__mouli", Player.HistoryGame) == 0 then
        local mark = U.getMark(player, "@$ty__mouli")
        table.insertTableIfNeed(mark, names)
        room:setPlayerMark(player, "@$ty__mouli", mark)
      end
    end
  end,
}
local ty__mouli = fk.CreateTriggerSkill{
  name = "ty__mouli",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #U.getMark(player, "@$ty__mouli") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@$ty__mouli", 0)
    room:changeMaxHp(player, 1)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "ty__zifu", nil, true, false)
  end,
}
local ty__zifu_filter = fk.CreateActiveSkill{
  name = "ty__zifu_filter",
  target_num = 0,
  card_num = function(self)
    local names = {}
    for _, id in ipairs(Self:getCardIds(Player.Hand)) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    return #names
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Hand then return false end
    local name = Fk:getCardById(to_select).trueName
    return table.every(selected, function(id)
      return name ~= Fk:getCardById(id).trueName
    end)
  end,
  target_filter = Util.FalseFunc,
  can_use = Util.FalseFunc,
}
Fk:addSkill(ty__zifu_filter)
local ty__zifu = fk.CreateTriggerSkill{
  name = "ty__zifu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    player:getHandcardNum() < math.min(5, player.maxHp)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player.maxHp)-player:getHandcardNum(), self.name)
    if player.dead then return false end
    local cards = {}
    local names = {}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local name = card.trueName
      if table.contains(names, name) then
        if not player:prohibitDiscard(card) then
          table.insert(cards, id)
        end
      else
        table.insert(names, name)
      end
    end
    if #names == player:getHandcardNum() then return false end
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ty__zifu_filter", "#ty__zifu-select", false)
    if success then
      cards = table.filter(player:getCardIds(Player.Hand), function (id)
        return not (table.contains(dat.cards, id) or player:prohibitDiscard(Fk:getCardById(id)))
      end)
    end
    if #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    end
  end,
}

wangling:addSkill(jichouw)
wangling:addSkill(ty__mouli)
wangling:addRelatedSkill(ty__zifu)

Fk:loadTranslationTable{
  ["ty__wangling"] = "王凌",

  ["jichouw"] = "集筹",
  [":jichouw"] = "出牌阶段结束时，若你于此阶段内使用过的牌的牌名各不相同，你可以将弃牌堆中的这些牌交给你选择的角色各一张。"..
  "然后你摸X张牌（X为你第一次发动此技能时给出的牌名数）。",
  ["ty__mouli"] = "谋立",
  [":ty__mouli"] = "觉醒技，回合结束时，若你因〖集筹〗给出的牌名不同的牌超过了5种，你加1点体力上限，回复1点体力，获得〖自缚〗。",
  ["ty__zifu"] = "自缚",
  [":ty__zifu"] = "锁定技，出牌阶段开始时，你将手牌摸至体力上限（至多摸至5张）。"..
  "若你因此摸牌，你保留手牌中每种牌名的牌各一张，弃置其余的牌。",

  ["#jichouw-distribution"] = "集筹：你可以将本回合使用过的牌交给每名角色各一张",
  ["jichouw_distribution"] = "集筹",
  ["@jichouw"] = "集筹",
  ["@$ty__mouli"] = "谋立",
  ["ty__zifu_filter"] = "自缚",
  ["#ty__zifu-select"] = "自缚：选择每种牌名的牌各一张保留，弃置其余的牌",

}

local caoshuang = General(extension, "ty__caoshuang", "wei", 4)
local function doJianzhuan(player, choice, x)
  local room = player.room
  if choice == "jianzhuan1" then
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
    "#jianzhuan-target:::" .. tostring(x), "jianzhuan", false)
    room:askForDiscard(room:getPlayerById(targets[1]), x, x, true, "jianzhuan", false)
  elseif choice == "jianzhuan2" then
    player:drawCards(x, "jianzhuan")
  elseif choice == "jianzhuan3" then
    x = math.min(x, #player:getCardIds("he"))
    if x > 0 then
      local cards = room:askForCard(player, x, x, true, "jianzhuan", false, ".", "#jianzhuan-recast:::" .. tostring(x))
      room:recastCard(cards, player, "jianzhuan")
    end
  elseif choice == "jianzhuan4" then
    room:askForDiscard(player, x, x, true, "jianzhuan", false)
  end
end
local jianzhuan = fk.CreateTriggerSkill{
  name = "jianzhuan",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local choices, all_choices = {}, {}
      for i = 1, 4, 1 do
        local mark = "jianzhuan"..tostring(i)
        if player:getMark(mark) == 0 then
          table.insert(all_choices, mark)
          if player:getMark(mark .. "-phase") == 0 then
            table.insert(choices, mark)
          end
        end
      end
      if event == fk.CardUsing and #choices > 0 then
        self.cost_data = {choices, all_choices}
        return true
      elseif event == fk.EventPhaseEnd and #choices == 0 then
        self.cost_data = all_choices
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local choices = table.simpleClone(self.cost_data)
      local x = player:usedSkillTimes(self.name)
      local choice = room:askForChoice(player, choices[1], self.name, "#jianzhuan-choice:::"..tostring(x), nil, choices[2])
      room:setPlayerMark(player, choice .. "-phase", 1)
      doJianzhuan(player, choice, x)
    else
      room:setPlayerMark(player, table.random(self.cost_data), 1)
    end
  end,
  
  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jianzhuan1", 0)
    room:setPlayerMark(player, "jianzhuan2", 0)
    room:setPlayerMark(player, "jianzhuan3", 0)
    room:setPlayerMark(player, "jianzhuan4", 0)
  end,
}
local fanshi = fk.CreateTriggerSkill{
  name = "fanshi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:hasSkill(self)
    and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    if player:hasSkill(jianzhuan, true) then
      local x = 0
      for i = 1, 4, 1 do
        if player:getMark("jianzhuan"..tostring(i)) == 0 then
          x = x + 1
        end
      end
      return x < 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = ""
    for i = 1, 4, 1 do
      choice = "jianzhuan"..tostring(i)
      if player:getMark(choice) == 0 then
        for j = 1, 3, 1 do
          doJianzhuan(player, choice, 1)
          if player.dead then return false end
        end
        break
      end
    end
    room:changeMaxHp(player, 2)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 2,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "-jianzhuan|fudou", nil, true, false)
  end,
}
local fudou = fk.CreateTriggerSkill{
  name = "fudou",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player ~= target or data.to == player.id then return false end
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to.dead or not U.isOnlyTarget(to, data, event) then return false end
    local mark = U.getMark(player, "fudou_record")
    if table.contains(mark, data.to) then
      return data.card.color == Card.Black
    elseif data.card.color == Card.Red then
      if #U.getActualDamageEvents(room, 1, function (e)
        local damage = e.data[1]
        if damage.from == to and damage.to == player then
          return true
        end
      end, nil, 0) > 0 then
        table.insert(mark, data.to)
        room:setPlayerMark(player, "fudou_record", mark)
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local opinion = data.card.color == Card.Black and "loseHp" or "draw1"
    if room:askForSkillInvoke(player, self.name, nil, "#fanshi-invoke::"..data.to .. ":" .. opinion) then
      room:doIndicate(player.id, {data.to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local to = room:getPlayerById(data.to)
    if data.card.color == Card.Red then
      room:notifySkillInvoked(player, self.name, "support")
      player:drawCards(1, self.name)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    elseif data.card.color == Card.Black then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:loseHp(player, 1, self.name)
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
caoshuang:addSkill(jianzhuan)
caoshuang:addSkill(fanshi)
caoshuang:addRelatedSkill(fudou)
Fk:loadTranslationTable{
  ["ty__caoshuang"] = "曹爽",
  --["#ty__caoshuang"] = "",
  --["illustrator:ty__caoshuang"] = "",

  ["jianzhuan"] = "渐专",
  [":jianzhuan"] = "锁定技，当你于出牌阶段内使用牌时，你选择于此阶段内未选择过的一项："..
  "1.令一名角色弃置X张牌；2.摸X张牌；3.重铸X张牌；4.弃置X张牌。"..
  "出牌阶段结束时，若所有选项于此阶段内都被选择过，你随机删除一个选项。（X为你于此阶段内发动过此技能的次数）",
  ["fanshi"] = "返势",
  [":fanshi"] = "觉醒技，结束阶段。若〖渐专〗的选项数小于2，你依次执行3次剩余项，加2点体力上限，回复2点体力，失去〖渐专〗，获得〖覆斗〗。",
  ["fudou"] = "覆斗",
  [":fudou"] = "当你使用黑色/红色牌指定其他角色为唯一目标后，若其对你造成过伤害/没有对你造成过伤害，你可以与其各失去1点体力/摸一张牌。",

  ["#jianzhuan-choice"] = "渐专：选择执行的一项（其中X为%arg）",
  ["jianzhuan1"] = "令一名角色弃置X张牌",
  ["jianzhuan2"] = "摸X张牌",
  ["jianzhuan3"] = "重铸X张牌",
  ["jianzhuan4"] = "弃置X张牌",
  ["#jianzhuan-target"] = "渐专：选择一名角色，令其弃置%arg张牌",
  ["#jianzhuan-recast"] = "渐专：选择%arg张牌重铸",
  ["#fanshi-invoke"] = "是否发动 覆斗，与%dest各 %arg",

  ["$jianzhuan1"] = "今作擎天之柱，何怜八方风雨？",
  ["$jianzhuan2"] = "吾寄百里之命，当居万丈危楼。	",
  ["$fanshi1"] = "垒巨木为寨，发屯兵自守。",
  ["$fanshi2"] = "吾居伊周之位，怎可以罪见黜？",
  ["$fudou1"] = "既作困禽，何妨铤险以覆车？",
  ["$fudou2"] = "据将覆之巢，必作犹斗之困兽。",
  ["~ty__caoshuang"] = "我度太傅之意，不欲伤我兄弟耳……",
}












return extension
