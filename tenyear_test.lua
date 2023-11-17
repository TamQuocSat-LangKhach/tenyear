local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

--嵇康 曹不兴 马良

--袁胤

Fk:loadTranslationTable{
  ["sunchen"] = "孙綝",
  ["zigu"] = "自固",
  [":zigu"] = "出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。",
  ["zuowei"] = "作威",
  [":zuowei"] = "当你于回合内使用牌时，若你当前手牌数：大于X，你可以令此牌不可响应；等于X，你可以对一名其他角色造成1点伤害；小于X，"..
  "你可以摸两张牌并令本回合此选项失效。（X为你装备区内的牌数且至少为1）",
}

local wuban = General(extension, "ty__wuban", "shu", 4)
local youzhan = fk.CreateTriggerSkill{
  name = "youzhan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id then
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            yes = true
          end
        end
        if yes then
          player:broadcastSkillInvoke(self.name)
          room:notifySkillInvoked(player, self.name, "drawcard")
          player:drawCards(1, self.name)
          local to = room:getPlayerById(move.from)
          if not to.dead then
            room:addPlayerMark(to, "@youzhan-turn", 1)
            room:addPlayerMark(to, "youzhan-turn", 1)
          end
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("youzhan-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "youzhan_fail-turn", 1)
  end,
}
local youzhan_trigger = fk.CreateTriggerSkill{
  name = "#youzhan_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("youzhan-turn") > 0 then
      if event == fk.DamageInflicted then
        return target == player and player:getMark("@youzhan-turn") > 0
      else
        return target.phase == Player.Finish and player:getMark("youzhan_fail-turn") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      if room.current then
        room.current:broadcastSkillInvoke("youzhan")
        room:notifySkillInvoked(room.current, "youzhan", "offensive")
        room:doIndicate(room.current.id, {player.id})
      end
      data.damage = data.damage + player:getMark("@youzhan-turn")
      room:setPlayerMark(player, "@youzhan-turn", 0)
    else
      target:broadcastSkillInvoke("youzhan")
      room:notifySkillInvoked(target, "youzhan", "drawcard")
      room:doIndicate(target.id, {player.id})
      player:drawCards(player:getMark("youzhan-turn"), "youzhan")
    end
  end,
}
youzhan:addRelatedSkill(youzhan_trigger)
wuban:addSkill(youzhan)
Fk:loadTranslationTable{
  ["ty__wuban"] = "吴班",
  ["youzhan"] = "诱战",
  [":youzhan"] = "锁定技，其他角色在你的回合失去牌后，你摸一张牌，其本回合下次受到的伤害+1。结束阶段，若这些角色本回合未受到过伤害，其摸X张牌"..
  "（X为其本回合失去牌的次数）。",
  ["@youzhan-turn"] = "诱战",
}

Fk:loadTranslationTable{
  ["tianshangyi"] = "田尚衣",
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当本局游戏所用牌堆中此花色的伤害牌使用。",
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以判定，若结果为：红色，你可以令一名角色回复1点体力；黑色，你对受伤角色的上家或下家造成1点"..
  "伤害，然后你可以对同一方向的下一名角色重复此流程，直到有角色死亡或此角色为你。",
}

local caoyi = General(extension, "caoyi", "wei", 4, 4, General.Female)
local miyi = fk.CreateTriggerSkill{
  name = "miyi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Start then
        return player:hasSkill(self)
      elseif player.phase == Player.Finish then
        return player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local command = "AskForUseActiveSkill"
      player.room:notifyMoveFocus(player, "miyi_active")
      local dat = {"miyi_active", "#miyi-invoke", false, json.encode({})}
      local result = player.room:doRequest(player, command, json.encode(dat))
      if result ~= "" then
        self.cost_data = json.decode(result)
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      room:sortPlayersByAction(self.cost_data.targets)
      room:doIndicate(player.id, self.cost_data.targets)
      local choice = self.cost_data.interaction_data
      for _, id in ipairs(self.cost_data.targets) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:setPlayerMark(p, choice.."-turn", 1)
          if choice == "miyi1" and p:isWounded() then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
          elseif choice == "miyi2" then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = self.name,
            }
          end
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        if not p.dead then
          if p:getMark("miyi2-turn") > 0 and p:isWounded() then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
          elseif p:getMark("miyi1-turn") > 0 then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = self.name,
            }
          end
        end
      end
    end
  end,
}
local miyi_active = fk.CreateActiveSkill{
  name = "miyi_active",
  card_num = 0,
  min_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"miyi1", "miyi2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
}
local yinjun = fk.CreateTriggerSkill{
  name = "yinjun",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.tos and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) <= player.hp then
      local cards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cards == 0 then return end
      local yes = false
      local use = player.room.logic:getCurrentEvent()
      use:searchEvents(GameEvent.MoveCards, 1, function(e)
        if e.parent and e.parent.id == use.id then
          local subcheck = table.simpleClone(cards)
          for _, move in ipairs(e.data) do
            if move.from == player.id and move.moveReason == fk.ReasonUse then
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(subcheck, info.cardId) and info.fromArea == Card.PlayerHand then
                  --continue
                else
                  break
                end
              end
            end
          end
          if #subcheck == 0 then
            yes = true
          end
        end
      end)
      if yes then
        local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
        local card = Fk:cloneCard("slash")
        card.skillName = self.name
        return not to.dead and not player:prohibitUse(card) and not player:isProhibited(to, card)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yinjun-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local use = {
      from = player.id,
      tos = {TargetGroup:getRealTargets(data.tos)},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    player.room:useCard(use)
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
}
Fk:addSkill(miyi_active)
caoyi:addSkill(miyi)
caoyi:addSkill(yinjun)
Fk:loadTranslationTable{
  ["caoyi"] = "曹轶",
  ["miyi"] = "蜜饴",
  [":miyi"] = "准备阶段，你可以选择一项令任意名角色执行：1.回复1点体力；2.你对其造成1点伤害。若如此做，结束阶段，这些角色执行另一项。",
  ["yinjun"] = "寅君",
  [":yinjun"] = "当你对其他角色从手牌使用指定唯一目标的【杀】或锦囊牌结算后，你可以视为对其使用一张【杀】（此【杀】伤害无来源）。若本回合发动次数"..
  "大于你当前体力值，此技能本回合无效。",
  ["miyi_active"] = "蜜饴",
  ["#miyi-invoke"] = "蜜饴：你可以令任意名角色执行你选择的效果，本回合结束阶段执行另一项",
  ["miyi1"] = "各回复1点体力",
  ["miyi2"] = "各受到你的1点伤害",
  ["#yinjun-invoke"] = "寅君：你可以视为对 %dest 使用【杀】",
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

local pangshanmin = General(extension, "pangshanmin", "wei", 3)
local caisi = fk.CreateTriggerSkill{
  name = "caisi",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeBasic and player:getMark("caisi-turn") <= player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if player.phase ~= Player.NotActive then
      cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic")
    else
      cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", 1, "drawPile")
    end
    if #cards > 0 then
      room:addPlayerMark(player, "caisi-turn", 1)
      room:obtainCard(player.id, cards[1], true, fk.ReasonJustMove)
    end
  end,
}
local zhuoli = fk.CreateTriggerSkill{
  name = "zhuoli",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (player.maxHp < #player.room.alive_players or player:isWounded()) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == player.id then
          return true
        end
      end, Player.HistoryTurn)
      return #events > player.maxHp
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.maxHp < #player.room.alive_players then
      room:changeMaxHp(player, 1)
    end
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
pangshanmin:addSkill(caisi)
pangshanmin:addSkill(zhuoli)
Fk:loadTranslationTable{
  ["pangshanmin"] = "庞山民",
  ["caisi"] = "才思",
  [":caisi"] = "当你于回合内/回合外使用基本牌后，你可以从牌堆/弃牌堆随机获得一张非基本牌。每回合以此法获得牌的张数不能超过你的体力上限。",
  ["zhuoli"] = "擢吏",
  [":zhuoli"] = "锁定技，每个回合结束时，若你本回合使用牌张数大于体力上限，你加1点体力上限并回复1点体力（体力上限不能超过存活人数）。",
}

local kuaiqi = General(extension, "kuaiqi", "wei", 3)
local liangxiu = fk.CreateActiveSkill{
  name = "liangxiu",
  anim_type = "drawcard",
  card_num = 2,
  target_num = 0,
  prompt = "#liangxiu",
  can_use = function(self, player)
    if #player:getCardIds("he") > 1 then
      for _, type in ipairs({"basic", "trick", "equip"}) do
        return player:getMark("liangxiu_"..type.."-phase") == 0
      end
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      if #selected == 0 then
        return true
      else
        if Fk:getCardById(to_select).type ~= Fk:getCardById(selected[1]).type then
          local types = {"basic", "trick", "equip"}
          table.removeOne(types, Fk:getCardById(to_select):getTypeString())
          table.removeOne(types, Fk:getCardById(selected[1]):getTypeString())
          return Self:getMark("liangxiu_"..types[1].."-phase") == 0
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local types = {"basic", "trick", "equip"}
    for i = 1, 2, 1 do
      table.removeOne(types, Fk:getCardById(effect.cards[i]):getTypeString())
    end
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:setPlayerMark(player, "liangxiu_"..types[1].."-phase", 1)
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|"..types[1], 2)
    if #cards > 0 then
      local card = room:askForCardsChosen(player, player, 1, 1, {card_data = {{self.name, cards}}}, self.name, "#liangxiu-get")
      if #card > 0 then
        card = card[1]
      else
        card = cards[1]
      end
      room:obtainCard(player.id, card, true, fk.ReasonJustMove)
    end
  end
}
local xunjie = fk.CreateTriggerSkill{
  name = "xunjie",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("xunjie_caninvoke-turn") > 0 and
      table.find(player.room.alive_players, function(p) return p:getHandcardNum() ~= p.hp end) and
      player:usedSkillTimes(self.name, Player.HistoryRound) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p) return p:getHandcardNum() ~= p.hp end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#xunjie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {}
    for i = 1, 2, 1 do
      if player:getMark("xunjie"..i.."-round") == 0 then
        table.insert(choices, "xunjie"..i)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xunjie-choice::"..to.id, false, {"xunjie1", "xunjie2"})
    room:setPlayerMark(player, choice.."-round", 1)
    local n = to:getHandcardNum() - to.hp
    if choice == "xunjie1" then
      if n > 0 then
        room:askForDiscard(to, n, n, false, self.name, false)
      else
        to:drawCards(-n, self.name)
      end
    else
      if n > 0 then
        if to:isWounded() then
          room:recover({
            who = to,
            num = math.min(n, to:getLostHp()),
            recoverBy = player,
            skillName = self.name
          })
        end
      else
        room:loseHp(to, -n, self.name)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},  --不能用记录器
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and player:getMark("xunjie_caninvoke-turn") == 0 and player.phase ~= Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        player.room:setPlayerMark(player, "xunjie_caninvoke-turn", 1)
        return
      end
    end
  end,
}
kuaiqi:addSkill(liangxiu)
kuaiqi:addSkill(xunjie)
Fk:loadTranslationTable{
  ["kuaiqi"] = "蒯祺",
  ["liangxiu"] = "良秀",
  [":liangxiu"] = "出牌阶段，你可以弃置两张不同类型的牌，然后从两张与你弃置牌类型均不同的牌中选择一张获得（每种类别限一次）。",
  ["xunjie"] = "殉节",
  [":xunjie"] = "每轮各限一次，每个回合结束时，若你本回合获得过手牌（摸牌阶段除外），你可以令一名角色将手牌/体力值调整至其体力值/手牌数。",
  ["#liangxiu"] = "良秀：你可以弃置两张类别不同的牌，获得一张另一类别的牌",
  ["#liangxiu-get"] = "良秀：选择获得一张牌",
  ["#xunjie-choose"] = "殉节：你可以令一名角色将手牌/体力值调整至其体力值/手牌数",
  ["#xunjie-choice"] = "殉节：选择令 %dest 执行的一项",
  ["xunjie1"] = "手牌数调整至体力值",
  ["xunjie2"] = "体力值调整至手牌数",

  ["$liangxiu1"] = "君子性谦，不夺人之爱。",
  ["$liangxiu2"] = "蒯门多隽秀，吾居其末。",
  ["$xunjie1"] = "君子有节，可杀而不可辱。",
  ["$xunjie2"] = "吾受国命，城破则身死。",
  ["~kuaiqi"] = "泉下万事休，人间雪满头。",
}

--马铁 车胄 韩嵩 诸葛梦雪 诸葛若雪

return extension
