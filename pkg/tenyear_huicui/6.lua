local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年-限定专属3",
}

--笔舌如椽：陈琳 杨修 骆统 王昶 程秉 杨彪 阮籍 崔琰毛玠
local yangxiu = General(extension, "ty__yangxiu", "wei", 3)
local ty__danlao = fk.CreateTriggerSkill{
  name = "ty__danlao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and not U.isOnlyTarget(player, data, event)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__danlao-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local ty__jilei = fk.CreateTriggerSkill{
  name = "ty__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#ty__jilei-invoke::"..data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local mark = data.from:getTableMark("@ty__jilei")
    if table.insertIfNeed(mark, choice .. "_char") then
      room:setPlayerMark(data.from, "@ty__jilei", mark)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
}
local ty__jilei_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jilei_prohibit",
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char")
  end,
}
ty__jilei:addRelatedSkill(ty__jilei_prohibit)
yangxiu:addSkill(ty__danlao)
yangxiu:addSkill(ty__jilei)
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["#ty__yangxiu"] = "恃才放旷",
  ["illustrator:ty__yangxiu"] = "alien", -- 传说皮 度龙品酥
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",
  ["#ty__danlao-invoke"] = "啖酪：你可以摸一张牌，令 %arg 对你无效",
  ["#ty__jilei-invoke"] = "鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？",
  ["@ty__jilei"] = "鸡肋",

  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

local luotong = General(extension, "ty__luotong", "wu", 3)
local renzheng = fk.CreateTriggerSkill{
  name = "renzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DamageFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if not data.dealtRecorderId then return true end
      if data.extra_data and data.extra_data.renzheng_maxDamage then
        return data.damage < data.extra_data.renzheng_maxDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterSkillEffect, fk.SkillEffect},
  can_refresh = function (self, event, target, player, data)
    return player == player.room.players[1]
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if e then
      local dat = e.data[1]
      dat.extra_data = dat.extra_data or {}
      dat.extra_data.renzheng_maxDamage = dat.extra_data.renzheng_maxDamage or 0
      dat.extra_data.renzheng_maxDamage = math.max(dat.damage, dat.extra_data.renzheng_maxDamage)
    end
  end,
}
local jinjian = fk.CreateTriggerSkill{
  name = "jinjian",
  mute = true,
  events = {fk.DamageCaused, fk.DamageInflicted},
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return player:getMark("@@jinjian_plus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian1-invoke::"..data.to.id)
    else
      return player:getMark("@@jinjian_minus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian2-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      if player:getMark("@@jinjian_plus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 0)
        data.damage = data.damage - 1
      else
        room:notifySkillInvoked(player, self.name, "offensive")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 1)
        data.damage = data.damage + 1
      end
    else
      if player:getMark("@@jinjian_minus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 0)
        data.damage = data.damage + 1
      else
        room:notifySkillInvoked(player, self.name, "defensive")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 1)
        data.damage = data.damage - 1
      end
    end
  end,
}
luotong:addSkill(renzheng)
luotong:addSkill(jinjian)
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["#ty__luotong"] = "蹇谔匪躬",
  ["illustrator:ty__luotong"] = "匠人绘",
  ["renzheng"] = "仁政",  --这两个烂大街的技能名大概率撞车叭……
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",
  ["jinjian"] = "进谏",
  [":jinjian"] = "当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，"..
  "若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。",
  ["#jinjian1-invoke"] = "进谏：你可以令对 %dest 造成的伤害+1",
  ["#jinjian2-invoke"] = "进谏：你可以令受到的伤害-1",
  ["@@jinjian_plus-turn"] = "进谏+",
  ["@@jinjian_minus-turn"] = "进谏-",


  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
  ["$jinjian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$jinjian2"] = "为将者死战，为臣者死谏！",
  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  min_card_num = function ()
    if Self:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  max_card_num = function ()
    if Self:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return Self.maxHp
    end
  end,
  target_num = 0,
  prompt = function ()
    return "#ty__kaiji-"..Self:getSwitchSkillState("ty__kaiji", false, true)..":::"..Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return false
    else
      return #selected < Self.maxHp and not Self:prohibitDiscard(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:throwCard(effect.cards, self.name, player, player)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
            return true
          end
        end
      end, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          n = n + #move.moveInfo
        end
      end
    end, Player.HistoryTurn)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
    end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data.tos
    room:sortPlayersByAction(tos)
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p:isNude() and not p.dead then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard(card, self.name, p, player)
      end
    end
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["#ty__wangchang"] = "攥策及江",
  ["designer:ty__wangchang"] = "韩旭",
  ["illustrator:ty__wangchang"] = "游漫美绘",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸体力上限张数的牌；阴：你可以弃置至多体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可以选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌（无牌则不弃），然后视为对"..
  "这些角色各使用一张【杀】。",
  ["#ty__kaiji-yang"] = "开济：你可以摸%arg张牌",
  ["#ty__kaiji-yin"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",

  ["$ty__kaiji1"] = "谋虑渊深，料远若近。",
  ["$ty__kaiji2"] = "视昧而察，筹不虚运。",
  ["$pingxi1"] = "地有常险，守无常势。",
  ["$pingxi2"] = "国有常众，战无常胜。",
  ["~ty__wangchang"] = "志存开济，人亡政息……",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  prompt = function ()
    return "#jingzao-active:::" + tostring(3 + Self:getMark("jingzao-turn"))
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") > -3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao-turn")
    if n < 1 then return false end
    local cards = U.turnOverCardsFromDrawPile(player, n, self.name)
    local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id).trueName end), ",")
    if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
      room:addPlayerMark(player, "jingzao-turn", 1)
    else
      local to_get = {}
      while #cards > 0 do
        local id = table.random(cards)
        table.insert(to_get, id)
        local name = Fk:getCardById(id).trueName
        cards = table.filter(cards, function (id2)
          return Fk:getCardById(id2).trueName ~= name
        end)
      end
      room:setPlayerMark(player, "jingzao-turn", player:getMark("jingzao-turn") - #to_get)
      room:moveCardTo(to_get, Player.Hand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
    room:cleanProcessingArea(cards, self.name)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function (e)
        local use = e.data[1]
        return use.card.trueName == data.card.trueName and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
      end, Player.HistoryTurn) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["#chengbing"] = "通达五经",
  ["designer:chengbing"] = "韩旭",
  ["illustrator:chengbing"] = "匠人绘",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；"..
  "2.令你随机获得这些牌中牌名不同的牌各一张，每获得一张，此技能本回合亮出的牌数-1。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-active"] = "经造：选择一名其他角色，亮出牌堆顶的%arg张卡牌",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令%src获得其中不同牌名各一张",

  ["$jingzao1"] = "闭门绝韦编，造经教世人。",
  ["$jingzao2"] = "著文成经，可教万世之人。",
  ["$enyu1"] = "君以国士待我，我必国士报之。",
  ["$enyu2"] = "吾本乡野腐儒，幸隆君之大恩。",
  ["~chengbing"] = "著经未成，此憾事也……",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local ty__zhaohan_delay = fk.CreateTriggerSkill{
  name = "#ty__zhaohan_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes(ty__zhaohan.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:isKongcheng() end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true, true)
    end
    if #targets > 0 then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, false, self.name, false, ".", "#zhaohan-give::" .. targets[1])
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#zhaohan-discard")
    end
  end,
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw0", "draw1", "draw2", "draw3", "Cancel"},
    self.name, "#jinjie-invoke::"..target.id)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = tonumber(string.sub(choice, 5, 5))
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if x > 0 then
      room:drawCards(target, x, self.name)
      if player.dead or #player:getCardIds("he") < x or
      #room:askForDiscard(player, x, x, true, self.name, true, ".", "#jinjie-discard::"..target.id..":"..tostring(x)) == 0 or
      target.dead or not target:isWounded() then return false end
    end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not target.dead and target.phase == Player.Finish and
    player:usedSkillTimes(self.name, Player.HistoryRound) < 1 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
        return false
      end, end_id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        self.cost_data = #cards
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if target == player then
      local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#jue-choose:::" .. tostring(x), self.name, true)
      if #targets > 0 then
        self.cost_data = {targets[1], x}
        return true
      end
    else
      x = math.min(x, target.maxHp)
      if room:askForSkillInvoke(player, self.name, nil, "#jue-invoke::" .. target.id .. ":" .. tostring(x)) then
        room:doIndicate(player.id, {target.id})
        self.cost_data = {target.id, x}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local x = math.min(self.cost_data[2], to.maxHp)
    for i = 1, x, 1 do
      local cards = {}
      for _, name in ipairs({"slash", "dismantlement", "amazing_grace"}) do
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
          table.insert(cards, card)
        end
      end
      if #cards == 0 then break end
      local tos = {{to.id}}
      local card = table.random(cards)
      if card.trueName == "amazing_grace" and not player:isProhibited(player, card) then
        table.insert(tos, {player.id})
      end
      room:useCard{
        from = player.id,
        tos = tos,
        card = card,
        extraUse = true
      }
      if player.dead or to.dead then break end
    end
  end,
}
ty__zhaohan:addRelatedSkill(ty__zhaohan_delay)
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["#ty__yangbiao"] = "德彰海内",
  ["cv:ty__yangbiao"] = "袁国庆",
  ["illustrator:ty__yangbiao"] = "DH", -- 忧心国事

  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "每轮限一次，一名角色进入濒死状态时，你可以令其摸0-3张牌，"..
  "然后你可以弃置等量的牌令其回复1点体力。",
  ["jue"] = "举讹",
  [":jue"] = "每轮限一次，一名角色的结束阶段，你可以视为随机对其使用【过河拆桥】、【杀】或【五谷丰登】共计X次"..
  "（X为弃牌堆里于此回合内因弃置而移至此区域的牌数且至多为其体力上限，若其为你，改为你选择一名其他角色）。",

  ["#ty__zhaohan_delay"] = "昭汉",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色交给其两张手牌，或点“取消”则你弃置两张牌",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌交给 %dest",
  ["draw0"] = "摸零张牌",
  ["#jinjie-invoke"] = "你可以发动 尽节，令 %dest 摸0-3张牌，然后你可以弃等量的牌令其回复体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "你可以发动 举讹，选择一名其他角色，视为对其随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",
  ["#jue-invoke"] = "你可以发动 举讹，视为对 %dest 随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",

  ["$ty__zhaohan1"] = "此心昭昭，惟愿汉明。",
  ["$ty__zhaohan2"] = "天曰昭德！天曰昭汉！",
  ["$jinjie1"] = "大汉养士百载，今乃奉节之时。",
  ["$jinjie2"] = "尔等皆忘天地君亲师乎？",
  ["$jue1"] = "尔等一家之言，难堵天下悠悠之口。",
  ["$jue2"] = "区区黄门而敛财千万，可诛其九族。",
  ["~ty__yangbiao"] = "愧无日磾先见之明，犹怀老牛舐犊之爱……",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "zhaowen", all_names, {}, Self:getTableMark("zhaowen-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-turn") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  main_skill = zhaowen,
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhaowen) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, "zhaowen", nil, "#zhaowen-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player:getCardIds("h"))
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen-turn", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return end
    return player:getMark("zhaowen-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhaowen-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen-turn", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-turn", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank + player:getMark("@jiudun_drank") == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiudun-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand", "#jiudun-card:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      player:drawCards(1, self.name)
      room:useVirtualCard("analeptic", nil, player, player, self.name, false)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}

local jd_analeptic = Fk:cloneCard("analeptic")
local jiudun__analepticSkill = fk.CreateActiveSkill{
  name = "jiudun__analepticSkill",
  prompt = "#analeptic_skill",
  max_turn_use_time = 1,
  mod_target_filter = jd_analeptic.skill.modTargetFilter,
  can_use = jd_analeptic.skill.canUse,
  on_use = jd_analeptic.skill.onUse,
  on_effect = function(_, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    if effect.extra_data and effect.extra_data.analepticRecover then
      room:recover({
        who = to,
        num = 1,
        recoverBy = room:getPlayerById(effect.from),
        card = effect.card,
      })
    else
      room:addPlayerMark(to, "@jiudun_drank", 1 + ((effect.extra_data or {}).additionalDrank or 0))
    end
  end,
}
jiudun__analepticSkill.cardSkill = true
Fk:addSkill(jiudun__analepticSkill)

local jiudun_rule = fk.CreateTriggerSkill{
  name = "#jiudun_rule",
  events = {fk.PreCardEffect},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiudun) and data.to == player.id and data.card.trueName == "analeptic" and
    not (data.extra_data and data.extra_data.analepticRecover)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = jiudun__analepticSkill
    data.card = card
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:getMark("@jiudun_drank") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiudun_drank")
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player:getMark("@jiudun_drank")
    player.room:setPlayerMark(player, "@jiudun_drank", 0)
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
jiudun:addRelatedSkill(jiudun_rule)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["#ruanji"] = "命世大贤",
  ["designer:ruanji"] = "韩旭",
  ["illustrator:ruanji"] = "匠人绘",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "以使用方法①使用的【酒】对你的作用效果改为：目标角色使用的下一张[杀]的伤害值基数+1。"..
  "当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",

  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen-turn"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",
  ["#jiudun_rule"] = "酒遁",
  ["@jiudun_drank"] = "酒",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
  ["~ruanji"] = "诸君，欲与我同醉否？",
}

local cuiyanmaojie = General(extension, "ty__cuiyanmaojie", "wei", 3)
local ty__zhengbi = fk.CreateTriggerSkill{
  name = "ty__zhengbi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and #player.room.alive_players > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ex__choose_skill", "#ty__zhengbi-choose", true, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_c_num = 0,
      max_c_num = 1,
      min_t_num = 1,
      max_t_num = 1,
      pattern = ".|.|.|.|.|basic",
      skillName = self.name,
    }, false)
    if success and dat then
      if #dat.cards > 0 then
        self.cost_data = {tos = dat.targets, cards = dat.cards}
      else
        self.cost_data = {tos = dat.targets}
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if self.cost_data.cards then
      room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      if player.dead or to.dead or to:isNude() then return end
      local cards = to:getCardIds("he")
      if #cards > 1 then
        local choices = {}
        local num = #table.filter(to:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic end)
        if num > 1 then
          table.insert(choices, "zhengbi__basic-back:"..player.id)
        end
        if #to:getCardIds("he") - num > 0 then
          table.insert(choices, "zhengbi__nobasic-back:"..player.id)
        end
        if #choices == 0 then return end
        local choice = room:askForChoice(to, choices, self.name)
        if choice:startsWith("zhengbi__basic-back") then
          cards = room:askForCard(to, 2, 2, false, self.name, false, ".|.|.|.|.|basic", "#ld__zhengbi-give1:"..player.id)
        else
          cards = room:askForCard(to, 1, 1, true, self.name, false, ".|.|.|.|.|^basic", "#ld__zhengbi-give2:"..player.id)
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, to.id)
    else
      room:setPlayerMark(player, "ty__zhengbi-phase", to.id)
    end
  end,
}
local ty__zhengbi_delay = fk.CreateTriggerSkill{
  name = "#ty__zhengbi_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:getMark("ty__zhengbi-phase") ~= 0 then
      local room = player.room
      local p = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
      if p.dead or p:isNude() then return end
      return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          return move.to == p.id and move.toArea == Card.PlayerHand
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhengbi")
    room:notifySkillInvoked(player, "ty__zhengbi", "control")
    local to = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
    room:doIndicate(player.id, {to.id})
    local cards = U.askforCardsChosenFromAreas(player, to, "he", self.name, nil, nil, false)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
  end,
}
local ty__fengying = fk.CreateActiveSkill{
  name = "ty__fengying",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self, card)
    return "#ty__fengying"
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      table.find(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
    end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:throwAllCards("h")
    if not player.dead then
      player:gainAnExtraTurn(true, self.name)
    end
  end,
}
local ty__fengying_delay = fk.CreateTriggerSkill{
  name = "#ty__fengying_delay",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:insideExtraTurn() and player:getCurrentExtraTurnReason() == "ty__fengying" and
      player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.hp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), "ty__fengying")
  end,
}
Fk:loadTranslationTable{
  ["ty__zhengbi"] = "征辟",
  [":ty__zhengbi"] = "出牌阶段开始时，你可以选择一名其他角色并选择一项：1.此阶段结束时，若其此阶段获得过手牌，你获得其一张手牌和装备区内"..
  "一张牌；2.交给其一张基本牌，然后其交给你一张非基本牌或两张基本牌。",
  ["ty__fengying"] = "奉迎",
  [":ty__fengying"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，此回合结束后，你执行一个额外回合，此额外回合开始时，若你的体力值"..
  "全场最少，你将手牌摸至体力上限。",
  ["#ty__zhengbi-choose"] = "征辟：选择一名角色<br>点“确定”，若其此阶段获得手牌，此阶段结束时你获得其牌；<br>"..
  "选一张基本牌点“确定”，将此牌交给其，然后其交给你一张非基本牌或两张基本牌。",
  ["#ty__zhengbi_delay"] = "征辟",
  ["#ty__fengying"] = "奉迎：你可以弃置所有手牌，此回合结束后执行一个额外回合！",
  ["#ty__fengying_delay"] = "奉迎",

  ["$ty__zhengbi1"] = "跅弛之士，在御之而已。",
  ["$ty__zhengbi2"] = "内不避亲，外不避仇。",
  ["$ty__fengying1"] = "二臣恭奉，以迎皇嗣。",
  ["$ty__fengying2"] = "奉旨典选，以迎忠良。",
}

--钟灵毓秀：董贵人 滕芳兰 张瑾云 周不疑 许靖 关樾 诸葛京
local dongguiren = General(extension, "dongguiren", "qun", 3, 3, General.Female)
local lianzhi = fk.CreateTriggerSkill{
  name = "lianzhi",
  anim_type = "special",
  events = {fk.GameStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if event == fk.GameStart then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi-choose", self.name, false, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(player, self.name, to.id)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi2-choose", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:handleAddLoseSkills(player, "shouze", nil, true, false)
        room:handleAddLoseSkills(to, "shouze", nil, true, false)
        room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
      end
    end
  end,
}
local lianzhi_trigger = fk.CreateTriggerSkill{
  name = "#lianzhi_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhi) and player:getMark("lianzhi") ~= 0 and
      not player.room:getPlayerById(player:getMark("lianzhi")).dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianzhi")
    room:notifySkillInvoked(player, "lianzhi", "support")
    local lianzhi_id = player:getMark("lianzhi")
    local to = room:getPlayerById(lianzhi_id)
    if player:getMark("@lianzhi") == 0 then
      room:setPlayerMark(player, "@lianzhi", to.general)
    end
    room:doIndicate(player.id, {lianzhi_id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "lianzhi"
    })
    if not player.dead then
      player:drawCards(1, "lianzhi")
    end
    if not to.dead then
      to:drawCards(1, "lianzhi")
    end
  end,
}
local fengying = fk.CreateViewAsSkill{
  name = "fengying",
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function()
    local all_names, names = Self:getTableMark("@$fengying"), {}
    for _, name in ipairs(all_names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = "fengying"
      if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
         (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= Self:getMark("@dongguiren_jiao") and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
        return true
      end
    end
  end,
  before_use = function(self, player, useData)
    useData.extraUse = true
    local names = player:getTableMark("@$fengying")
    if table.removeOne(names, useData.card.name) then
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@$fengying", 0)
  end,
}
local fengying_trigger = fk.CreateTriggerSkill{
  name = "#fengying_trigger",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengying)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    room:setPlayerMark(player, "@$fengying", #names > 0 and names or 0)
  end,
}
local fengying_targetmod = fk.CreateTargetModSkill{
  name = "#fengying_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, "fengying")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "fengying")
  end,
}
Fk:loadTranslationTable{
  ["lianzhi"] = "连枝",
  [":lianzhi"] = "游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力且与其各摸一张牌。"..
  "该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。",
  ["fengying"] = "风影",
  [":fengying"] = "一名角色的回合开始时，你记录弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。"..
  "你可以将一张点数不大于“绞”标记数的手牌当一张记录的本回合未以此法使用过的牌使用（无距离和次数限制）。",
  ["@lianzhi"] = "连枝",
  ["#lianzhi-choose"] = "连枝：选择一名角色成为“连枝”角色",
  ["#lianzhi2-choose"] = "连枝：你可以选择一名角色，你与其获得技能〖受责〗",
  ["@dongguiren_jiao"] = "绞",
  ["@$fengying"] = "风影",
  ["#fengying"] = "发动风影，将一张点数不大于绞标记数的手牌当一张记录的牌使用",

  ["$lianzhi1"] = "刘董同气连枝，一损则俱损。",
  ["$lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
  ["$fengying1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengying2"] = "西风落，西风落，宫墙不堪破。",
}
