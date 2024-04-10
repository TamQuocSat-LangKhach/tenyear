local extension = Package("tenyear_yj22")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_yj22"] = "十周年-一将2022",
}

--李婉 韩龙 诸葛尚 谯周 陆凯 苏飞 轲比能 武安国
local liwan = General(extension, "liwan", "wei", 3, 3, General.Female)
local liandui = fk.CreateTriggerSkill{
  name = "liandui",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or target.dead then return false end
    local logic = player.room.logic
    local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return false end
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.id == use_event.id then
        last_find = true
      elseif last_find then
        local last_use = e.data[1]
        if player == target then
          if last_use.from ~= player.id then
            self.cost_data = last_use.from
            return true
          end
        else
          if last_use.from == player.id then
            self.cost_data = player.id
            return true
          end
        end
        return false
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(target, self.name, nil, "#liandui-invoke:"..player.id .. ":" .. self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, player == target and "support" or "drawcard")
    room:getPlayerById(self.cost_data):drawCards(2, self.name)
  end,
}
local biejun = fk.CreateTriggerSkill{
  name = "biejun",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and
      table.every(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@biejun-inhand-turn") == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#biejun-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    return true
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "biejun" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@biejun-inhand-turn", 1)
            end
          end
        end
      end
    else
      if table.every(room.alive_players, function(p) return not p:hasSkill(self, true) or p == player end) then
        if player:hasSkill("biejun&", true, true) then
          room:handleAddLoseSkills(player, "-biejun&", nil, false, true)
        end
      else
        if not player:hasSkill("biejun&", true, true) then
          room:handleAddLoseSkills(player, "biejun&", nil, false, true)
        end
      end
    end
  end,
}
local biejun_active = fk.CreateActiveSkill{
  name = "biejun&",
  anim_type = "support",
  prompt = "#biejun-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = U.getMark(player, "biejun_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(biejun) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(biejun) and
    not table.contains(U.getMark(Self, "biejun_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:broadcastSkillInvoke(biejun.name)
    local targetRecorded = U.getMark(player, "biejun_targets-phase")
    table.insert(targetRecorded, target.id)
    room:setPlayerMark(player, "biejun_targets-phase", targetRecorded)
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, "biejun", nil, false, player.id)
  end,
}
Fk:addSkill(biejun_active)
liwan:addSkill(liandui)
liwan:addSkill(biejun)
Fk:loadTranslationTable{
  ["liwan"] = "李婉",
  ["#liwan"] = "才媛淑美",
  ["illustrator:liwan"] = "荧光笔工作室",
  ["liandui"] = "联对",
  [":liandui"] = "当你使用一张牌时，若上一张牌的使用者不为你，你可以令其摸两张牌；其他角色使用一张牌时，若上一张牌的使用者为你，其可以令你摸两张牌。",
  ["biejun"] = "别君",
  [":biejun"] = "其他角色出牌阶段限一次，其可以交给你一张手牌。当你受到伤害时，若你手牌中没有本回合以此法获得的牌，你可以翻面并防止此伤害。",
  ["biejun&"] = "别君",
  [":biejun&"] = "出牌阶段限一次，你可以将一张手牌交给李婉。",
  ["#liandui-invoke"] = "联对：你可以发动 %src 的“联对”，令 %dest 摸两张牌",
  ["#biejun-invoke"] = "别君：你可以翻面，防止你受到的伤害",
  ["@@biejun-inhand-turn"] = "别君",
  ["#biejun-active"] = "别君：选择一张手牌交给一名拥有“别君”的角色",

  ["$liandui1"] = "以句相联，抒离散之苦。",
  ["$liandui2"] = "以诗相对，颂哀怨之情。",
  ["$biejun1"] = "彼岸荼蘼远，落寞北风凉。",
  ["$biejun2"] = "此去经年，不知何时能归？",
  ["~liwan"] = "生不能同寝，死亦难同穴……",
}

local hanlong = General(extension, "hanlong", "wei", 4)
local duwang = fk.CreateTriggerSkill{
  name = "duwang",
  anim_type = "special",
  derived_piles = "hanlong_ci",
  frequency = Skill.Compulsory,
  events = {fk.AfterDrawInitialCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    local n = 0
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).trueName ~= "slash" then
        dummy:addSubcard(id)
        n = n + 1
      end
      if n >= 5 then break end
    end
    player:addToPile("hanlong_ci", dummy, true, self.name)
  end,
}
local duwang_distance = fk.CreateDistanceSkill{
  name = "#duwang_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if #from:getPile("hanlong_ci") > 0 or #to:getPile("hanlong_ci") > 0 then
      return 1
    end
    return 0
  end,
}
local cibei = fk.CreateTriggerSkill{
  name = "cibei",
  anim_type = "special",
  events = {fk.CardUseFinished, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and #player:getPile("hanlong_ci") > 0 then
      if event == fk.CardUseFinished then
        if table.find(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName ~= "slash" end) then
          return data.card.trueName == "slash" and (not data.card:isVirtual() or #data.card.subcards == 1) and data.damageDealt and
          Fk:getCardById(data.card:getEffectiveId(), true).trueName == "slash" and player.room:getCardArea(data.card) == Card.Processing
        end
      else
        return table.every(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName == "slash" end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player.room:askForSkillInvoke(player, self.name, nil, "#cibei-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local c = data.card:getEffectiveId()
      local ids = table.filter(player:getPile("hanlong_ci"), function(id) return Fk:getCardById(id).trueName ~= "slash" end)
      local piles = U.askForArrangeCards(player, self.name, {{c}, ids, "slash", "hanlong_ci"}, "#cibei-cibei")
      local c2 = 0
      if piles[1][1] == c then
        c2 = table.random(ids)
      else
        c2 = piles[1][1]
      end
      local moves = {{
        ids = {c},
        to = player.id,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        specialName = "hanlong_ci",
      }, {
        ids = {c2},
        from = player.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonExchange,
        skillName = self.name,
        fromSpecialName = "hanlong_ci",
      }}
      room:moveCards(table.unpack(moves))
      if player.dead then return end
      local targets = table.filter(room.alive_players, function(p) return not p:isAllNude() end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#cibei-choose", self.name, false)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "hej", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
    else
      room:moveCardTo(player:getPile("hanlong_ci"), Card.PlayerHand, player, fk.ReasonPrey, self.name)
    end
  end,
}
local cibei_delay = fk.CreateTriggerSkill{
  name = "#cibei_delay",
  mute = true,
  events = {fk.BeforeCardsMove, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    if event == fk.BeforeCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@cibei-inhand") > 0 then
              return true
            end
          end
        end
      end
    else
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonPrey and move.skillName == "cibei" then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.player_cards[Player.Hand], info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeCardsMove then
      local ids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          local move_info = {}
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@cibei-inhand") > 0 then
              table.insert(ids, info.cardId)
            else
              table.insert(move_info, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = move_info
          end
        end
      end
      if #ids > 0 then
        player.room:sendLog{
          type = "#cancelDismantle",
          card = ids,
          arg = "cibei",
        }
      end
    else
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonPrey and move.skillName == "cibei" then
          for _, info in ipairs(move.moveInfo) do
            room:setCardMark(Fk:getCardById(info.cardId), "@@cibei-inhand", 1)
          end
        end
      end
    end
  end,
}
local cibei_prohibit = fk.CreateProhibitSkill{
  name = "#cibei_prohibit",
  prohibit_discard = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
}
local cibei_maxcards = fk.CreateMaxCardsSkill{
  name = "#cibei_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@cibei-inhand") > 0
  end,
}
local cibei_targetmod = fk.CreateTargetModSkill{
  name = "#cibei_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and card:getMark("@@cibei-inhand") > 0
  end,
}
duwang:addRelatedSkill(duwang_distance)
cibei:addRelatedSkill(cibei_prohibit)
cibei:addRelatedSkill(cibei_maxcards)
cibei:addRelatedSkill(cibei_targetmod)
cibei:addRelatedSkill(cibei_delay)
hanlong:addSkill(duwang)
hanlong:addSkill(cibei)
Fk:loadTranslationTable{
  ["hanlong"] = "韩龙",
  ["#hanlong"] = "冯河易水",
  ["designer:hanlong"] = "雾燎鸟",
  ["illustrator:hanlong"] = "游漫美绘",

  ["duwang"] = "独往",
  [":duwang"] = "锁定技，游戏开始时，你将牌堆顶五张不为【杀】的牌置于武将牌上，称为“刺”。若你有“刺”，你与其他角色互相计算距离均+1。",
  ["cibei"] = "刺北",
  [":cibei"] = "当【杀】使用结算结束后，若此【杀】造成过伤害，你可以将此【杀】与一张不为【杀】的“刺”交换，然后弃置一名角色区域内的一张牌。"..
  "一名角色的回合结束时，若所有“刺”均为【杀】，你获得所有“刺”，这些【杀】不能被弃置、不计入手牌上限、使用时无距离和次数限制。",
  ["hanlong_ci"] = "刺",
  ["#cibei-invoke"] = "刺北：是否将此【杀】和一张“刺”交换？",
  ["#cibei-exchange"] = "刺北：将此【杀】和一张“刺”交换",
  ["#cibei-choose"] = "刺北：选择一名角色，弃置其区域内一张牌",
  ["@@cibei-inhand"] = "刺北",
  ["#cibei_delay"] = "刺北",

  ["$duwang1"] = "此去，欲诛敌莽、杀单于。",
  ["$duwang2"] = "风萧萧兮易水寒，壮士一去兮不复还！",
  ["$cibei1"] = "匹夫一怒，流血二人，天下缟素。",
  ["$cibei2"] = "我欲效专诸、聂政之旧事，逐天狼于西北。",
  ["~hanlong"] = "杀轲比能者，韩龙也！",
}

local zhugeshang = General(extension, "zhugeshang", "shu", 3)
local sangu = fk.CreateTriggerSkill{
  name = "sangu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#sangu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = player:getMark("sangu_cards")
    if type(cards) ~= "table" then
      local ban_cards = {"nullification", "collateral"}
      cards = table.filter(U.getUniversalCards(room, "bt", true), function (id)
        local card = Fk:getCardById(id)
        return card.trueName == "slash" or (card:isCommonTrick() and not table.contains(ban_cards, card.trueName))
      end)
      room:setPlayerMark(player, "sangu_cards", cards)
    end
    local cards_copy = table.simpleClone(cards)
    local names = {}
    for i = 1, 3, 1 do
      if #cards_copy == 0 then break end
      local result = U.askforChooseCardsAndChoice(player, cards_copy, {"OK"}, self.name,
      "#sangu-declare::" .. to.id .. ":" .. tostring(i), {"Cancel"}, 1, 1, cards)
      if #result == 0 then break end
      table.removeOne(cards_copy, result[1])
      table.insert(names, Fk:getCardById(result[1]).trueName)
    end
    if #names == 0 then return false end
    local mark = U.getMark(to, "@$sangu")
    table.insertTable(mark, names)
    room:setPlayerMark(to, "@$sangu", mark)

    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == player.id then
        table.removeOne(names, use.card.trueName)
      end
      return false
    end, end_id)
    if #names == 0 then
      mark = U.getMark(player, "sangu_avoid")
      table.insert(mark, to.id)
      room:setPlayerMark(player, "sangu_avoid", mark)
    end
  end,
}
local sangu_delay = fk.CreateTriggerSkill{
  name = "#sangu_delay",
  events = {fk.EventPhaseStart, fk.CardUsing, fk.CardResponding, fk.AfterCardsMove, fk.DamageInflicted},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      if player == target and data.card and table.contains(data.card.skillNames, "sangu") then
        local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if not card_event then return false end
        return table.contains(U.getMark(player, "sangu_avoid"), card_event.data[1].from)
      end
      return false
    end
    if player:isAlive() and player.phase == Player.Play and #U.getMark(player, "@$sangu") > 0 then
      if event == fk.EventPhaseStart then return player == target end
      if player:getMark("sangu_effect-phase") == 0 then return false end
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonRecast then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
        return false
      end
      return player == target
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      return true
    elseif event == fk.EventPhaseStart then
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      if phase_event ~= nil then
        room:setPlayerMark(player, "sangu_effect-phase", 1)
        player:filterHandcards()
        phase_event:addCleaner(function()
          room:setPlayerMark(player, "@$sangu", 0)
          player:filterHandcards()
          for _, p in ipairs(room.alive_players) do
            local mark = U.getMark(p, "sangu_avoid")
            table.removeOne(mark, player.id)
            room:setPlayerMark(p, "sangu_avoid", #mark > 0 and mark or 0)
          end
        end)
      end
    else
      local mark = U.getMark(player, "@$sangu")
      table.remove(mark, 1)
      room:setPlayerMark(player, "@$sangu", #mark > 0 and mark or 0)
      if #mark == 0 then
        room:setPlayerMark(player, "sangu_effect-phase", 0)
      end
      player:filterHandcards()
    end
  end,
}
local sangu_filter = fk.CreateFilterSkill{
  name = "#sangu_filter",
  mute = true,
  card_filter = function(self, to_select, player)
    return player:getMark("sangu_effect-phase") ~= 0 and #U.getMark(player, "@$sangu") > 0 and
    table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select, player)
    local mark = U.getMark(player, "@$sangu")
    if #mark > 0 then
      local card = Fk:cloneCard(mark[1], to_select.suit, to_select.number)
      card.skillName = sangu.name
      return card
    end
  end,
}
local yizu = fk.CreateTriggerSkill{
  name = "yizu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.contains({"slash", "duel"}, data.card.trueName) and
      player.room:getPlayerById(data.from).hp >= player.hp and player:isWounded() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
sangu:addRelatedSkill(sangu_delay)
sangu:addRelatedSkill(sangu_filter)
zhugeshang:addSkill(sangu)
zhugeshang:addSkill(yizu)
Fk:loadTranslationTable{
  ["zhugeshang"] = "诸葛尚",
  ["#zhugeshang"] = "尚节殉义",
  ["designer:zhugeshang"] = "叫什么啊你妹",
  ["illustrator:zhugeshang"] = "君桓文化",
  ["sangu"] = "三顾",
  [":sangu"] = "结束阶段，你可依次选择至多三张【杀】或普通锦囊牌（【借刀杀人】、【无懈可击】除外）并指定一名其他角色，"..
  "其下个出牌阶段使用的前X张牌视为你选择的牌（X为你选择的牌数）。若你选择的牌均为本回合你使用过的牌，防止“三顾”牌对你造成的伤害。",
  ["yizu"] = "轶祖",
  [":yizu"] = "锁定技，每回合限一次，当你成为【杀】或【决斗】的目标后，若你的体力值不大于使用者的体力值，你回复1点体力。",

  ["#sangu-choose"] = "你可以发动 三顾，选择一名其他角色，指定其下个出牌阶段使用前三张牌的牌名",
  ["#sangu-declare"] = "三顾：宣言 %dest 在下个出牌阶段使用或打出的第 %arg 张牌的牌名",
  ["@$sangu"] = "三顾",
  ["#sangu_filter"] = "三顾",
  ["#sangu_delay"] = "三顾",

  ["$sangu1"] = "思报君恩，尽父子之忠。",
  ["$sangu2"] = "欲酬三顾，竭三代之力。",
  ["$yizu1"] = "仿祖父行事，可阻敌袭。",
  ["$yizu2"] = "习先人故智，可御寇侵。",
  ["~zhugeshang"] = "父子荷国重恩，当尽忠以报！",
}

local qiaozhou = General(extension, "ty__qiaozhou", "shu", 3)
local shiming = fk.CreateTriggerSkill{
  name = "shiming",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Draw and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#shiming-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    local to_return = U.askforChooseCardsAndChoice(player, ids, {"OK"}, self.name, "#shiming-chooose", {"Cancel"})
    if #to_return > 0 then
      table.insert(room.draw_pile, to_return[1])
      table.removeOne(ids, to_return[1])
    end
    for i = #ids, 1, -1 do
      table.insert(room.draw_pile, 1, ids[i])
    end
    if room:askForSkillInvoke(target, self.name, nil, "#shiming-damage") then
      room:damage{
        from = target,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      if not target.dead then
        target:drawCards(3, self.name, "bottom")
      end
      return true
    end
  end,
}
local jiangxi = fk.CreateTriggerSkill{
  name = "jiangxi",
  anim_type = "support",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      local events = room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
        local dying = e.data[1]
        return room:getPlayerById(dying.who).seat == 1
      end, Player.HistoryTurn)
      if #events > 0 then return true end
      events = room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and damage.to.seat == 1
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory("shiming", 0, Player.HistoryRound)
    player:drawCards(1, self.name)
    if player.dead or target.dead then return false end
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    if #U.getEventsByRule(room, GameEvent.ChangeHp, 1, function (e)
      return e.data[5]
    end, turn_event.id) == 0 and room:askForSkillInvoke(player, self.name, nil, "#jiangxi-invoke::" .. target.id) then
      player:drawCards(1, self.name)
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,
}
qiaozhou:addSkill(shiming)
qiaozhou:addSkill(jiangxi)
Fk:loadTranslationTable{
  ["ty__qiaozhou"] = "谯周",
  ["#ty__qiaozhou"] = "谶星沉祚",
  ["designer:ty__qiaozhou"] = "夜者之歌",
  ["illustrator:ty__qiaozhou"] = "鬼画府",
  ["shiming"] = "识命",
  [":shiming"] = "每轮限一次，一名角色的摸牌阶段，你可以观看牌堆顶三张牌，然后可以将其中一张置于牌堆底，"..
  "若如此做，当前回合角色可以放弃摸牌，改为对自己造成1点伤害，然后从牌堆底摸三张牌。",
  ["jiangxi"] = "将息",
  [":jiangxi"] = "一名角色回合结束时，若一号位本回合进入过濒死状态或未受到过伤害，你重置〖识命〗并摸一张牌。"..
  "若所有角色均未受到过伤害，你可以与当前回合角色各摸一张牌。",
  ["#shiming-invoke"] = "识命：%dest 的摸牌阶段，你可以先观看牌堆顶三张牌，将其中一张置于牌堆底",
  ["#shiming-chooose"] = "识命：你可以将其中一张牌置于牌堆底",
  ["#shiming-damage"] = "识命：你可以对自己造成1点伤害，放弃摸牌，改为从牌堆底摸三张牌",
  ["#jiangxi-invoke"] = "将息：你可以与 %dest 各摸一张牌",

  ["$shiming1"] = "今天命在北，我等已尽人事。",
  ["$shiming2"] = "益州国疲民敝，非人力可续之。",
  ["$jiangxi1"] = "典午忽兮，月酉没兮。",
  ["$jiangxi2"] = "周慕孔子遗风，可与刘、扬同轨。",
  ["~ty__qiaozhou"] = "炎汉百年之业，吾一言毁之……",
}

local lukai = General(extension, "lukai", "wu", 4)
local bushil = fk.CreateTriggerSkill{
  name = "bushil",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished, fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.CardUseFinished or event == fk.CardRespondFinished then
        return player:getMark("bushil2") == "log_"..data.card:getSuitString()
      elseif event == fk.TargetConfirmed then
        return data.card.type ~= Card.TypeEquip and player:getMark("bushil3") == "log_"..data.card:getSuitString() and not player:isKongcheng()
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start or player.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, nil, "#bushil-invoke")
    elseif event == fk.TargetConfirmed then
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#bushil-discard:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      room:notifySkillInvoked(player, self.name, "special")
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
      for i = 1, 4, 1 do
        local choices = table.map(suits, function(s) return Fk:translate(s) end)
        local choice = room:askForChoice(player, choices, self.name, "#bushil"..i.."-choice")
        local str = suits[table.indexOf(choices, choice)]
        table.removeOne(suits, str)
        room:setPlayerMark(player, "bushil"..i, str)
        room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
        Fk:translate(player:getMark("bushil1")),
        Fk:translate(player:getMark("bushil2")),
        Fk:translate(player:getMark("bushil3")),
        Fk:translate(player:getMark("bushil4"))))
      end
    elseif event == fk.CardUseFinished or event == fk.CardRespondFinished then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:notifySkillInvoked(player, self.name, "drawcard")
      local card = room:getCardsFromPileByRule(".|.|"..string.sub(player:getMark("bushil4"), 5))
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self, true) then
      if event == fk.GameStart then
        return true
      else
        return target == player and data == self
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "bushil1", "log_spade")
      room:setPlayerMark(player, "bushil2", "log_heart")
      room:setPlayerMark(player, "bushil3", "log_club")
      room:setPlayerMark(player, "bushil4", "log_diamond")
      room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
      Fk:translate(player:getMark("bushil1")),
      Fk:translate(player:getMark("bushil2")),
      Fk:translate(player:getMark("bushil3")),
      Fk:translate(player:getMark("bushil4"))))
    else
      for _, mark in ipairs({"bushil1", "bushil2", "bushil3", "bushil4", "@bushil"}) do
        room:setPlayerMark(player, mark, 0)
      end
    end
  end,
}
local bushil_targetmod = fk.CreateTargetModSkill{
  name = "#bushil_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(bushil) and player:getMark("bushil1") == "log_"..card:getSuitString()
  end,
}
local zhongzhuang = fk.CreateTriggerSkill{
  name = "zhongzhuang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.chain and
      (player:getAttackRange() > 3 or (player:getAttackRange() < 3 and data.damage > 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getAttackRange() > 3 then
      data.damage = data.damage + 1
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "offensive")
    elseif player:getAttackRange() < 3 then
      data.damage = 1
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
  end,
}
bushil:addRelatedSkill(bushil_targetmod)
lukai:addSkill(bushil)
lukai:addSkill(zhongzhuang)
Fk:loadTranslationTable{
  ["lukai"] = "陆凯",
  ["#lukai"] = "青辞宰辅",
  ["designer:lukai"] = "GT",
  ["illustrator:lukai"] = "游漫美绘",

  ["bushil"] = "卜筮",
  [":bushil"] = "你使用♠牌无次数限制；<br>你使用或打出<font color='red'>♥</font>牌后，摸一张牌；<br>当你成为♣牌的目标后，"..
  "你可以弃置一张手牌令此牌对你无效；<br>结束阶段，你获得一张<font color='red'>♦</font>牌。<br>准备阶段，你可以将以上四种花色重新分配。",
  ["zhongzhuang"] = "忠壮",
  [":zhongzhuang"] = "锁定技，你使用【杀】造成伤害时，若你的攻击范围大于3，则此伤害+1；若你的攻击范围小于3，则此伤害改为1。",
  ["@bushil"] = "卜筮",
  ["#bushil-invoke"] = "卜筮：是否重新分配“卜筮”的花色？",
  ["#bushil-discard"] = "卜筮：你可以弃置一张手牌令%arg对你无效",
  ["#bushil1-choice"] = "卜筮：使用此花色牌无次数限制",
  ["#bushil2-choice"] = "卜筮：使用或打出此花色牌后摸一张牌",
  ["#bushil3-choice"] = "卜筮：成为此花色牌目标后可弃置一张手牌对你无效",

  ["$bushil1"] = "论演玄意，以筮辄验。",
  ["$bushil2"] = "手不释书，好研经卷。",
  ["$zhongzhuang1"] = "秽尘天听，卿有不测之祸！",
  ["$zhongzhuang2"] = "倾乱国政，安得寿终正寝？",
  ["~lukai"] = "不听忠言，国将亡矣……",
}

local sufei = General(extension, "ty__sufei", "wu", 4)
local shuojian = fk.CreateActiveSkill{
  name = "shuojian",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#shuojian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 3 and player:getMark("shuojian_invalid-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if target.dead then return end
    local n = 4 - player:usedSkillTimes(self.name, Player.HistoryPhase)
    local choices = {}
    if not player.dead then
      table.insert(choices, "shuojian1:"..player.id.."::"..n..":"..(n-1))
    end
    if not target:prohibitUse(Fk:cloneCard("dismantlement")) then
      table.insert(choices, "shuojian2:::"..n)
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(target, choices, self.name)
    if choice[9] == "1" then
      player:drawCards(n, self.name)
      if not player.dead and n > 1 then
        room:askForDiscard(player, n - 1, n - 1, true, self.name, false)
      end
    else
      room:setPlayerMark(player, "shuojian_invalid-turn", 1)
      for i = 1, n, 1 do
        if target.dead then return end
        local success, data = room:askForUseActiveSkill(target, "shuojian_viewas", "#shuojian-use:::"..i..":"..n, true)
        if success then
          local card = Fk:cloneCard("dismantlement")
          card.skillName = self.name
          room:useCard{
            from = target.id,
            tos = table.map(data.targets, function(id) return {id} end),
            card = card,
          }
        else
          break
        end
      end
    end
  end,
}
local shuojian_viewas = fk.CreateViewAsSkill{
  name = "shuojian_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("dismantlement")
    card.skillName = "shuojian"
    return card
  end,
}
Fk:addSkill(shuojian_viewas)
sufei:addSkill(shuojian)
Fk:loadTranslationTable{
  ["ty__sufei"] = "苏飞",
  ["#ty__sufei"] = "义荐恩还",
  ["designer:ty__sufei"] = "文小远",

  ["shuojian"] = "数荐",
  [":shuojian"] = "出牌阶段限三次，你可以交给一名其他角色一张牌，然后其选择一项：1.令你摸3张牌并弃2张牌；2.视为使用3张【过河拆桥】，本回合此技能失效。"..
  "此阶段下次发动该技能，选项中所有数字-1。",
  ["#shuojian"] = "数荐：交给一名角色一张牌，其选择令你摸牌或其视为使用【过河拆桥】",
  ["shuojian1"] = "令 %src 摸%arg张牌并弃%arg2张牌",
  ["shuojian2"] = "你视为使用%arg张【过河拆桥】，本回合此技能失效",
  ["shuojian_viewas"] = "数荐",
  ["#shuojian-use"] = "数荐：视为使用【过河拆桥】（第%arg张，共%arg2张）",

  ["$shuojian1"] = "我数荐卿而祖不用，其之失也。",
  ["$shuojian2"] = "兴霸乃当世豪杰，何患无爵。",
  ["~ty__sufei"] = "兴霸何在？吾命休矣……",
}

local kebineng = General(extension, "kebineng", "qun", 4)
local koujing = fk.CreateTriggerSkill{
  name = "koujing",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 1, player:getHandcardNum(), false, self.name, true, ".", "#koujing-invoke")
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(self.cost_data) do
      player.room:setCardMark(Fk:getCardById(id), "@@koujing-inhand", 1)
    end
    player:filterHandcards()
  end,

  refresh_events = {fk.AfterTurnEnd, fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      return target == player and table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    else
      return target == player and table.contains(data.card.skillNames, "koujing")
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        player.room:setCardMark(Fk:getCardById(id), "@@koujing-inhand", 0)
      end
      player:filterHandcards()
    else
      data.extraUse = true
    end
  end,
}
local koujing_filter = fk.CreateFilterSkill{
  name = "#koujing_filter",
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return card:getMark("@@koujing-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "koujing"
    return c
  end,
}
local koujing_targetmod = fk.CreateTargetModSkill{
  name = "#koujing_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "koujing")
  end,
}
local koujing_trigger = fk.CreateTriggerSkill{
  name = "#koujing_trigger",
  mute = true,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if data.from and data.from == player and target ~= player and not player.dead and
      data.card and table.contains(data.card.skillNames, "koujing") then
      return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    player:showCards(ids)
    if player.dead or target.dead or target:isKongcheng() then return end
    room:doIndicate(player.id, {target.id})
    if room:askForSkillInvoke(target, "koujing", nil, "#koujing-card:"..player.id) then
      local cards2 = table.simpleClone(target:getCardIds("h"))
      local cards1 = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
      U.swapCards(room, player, player, target, cards1, cards2, "koujing")
    end
  end,
}
koujing:addRelatedSkill(koujing_filter)
koujing:addRelatedSkill(koujing_targetmod)
koujing:addRelatedSkill(koujing_trigger)
kebineng:addSkill(koujing)
Fk:loadTranslationTable{
  ["kebineng"] = "轲比能",
  ["#kebineng"] = "瀚海鲸波",
  ["designer:kebineng"] = "zero",
  ["illustrator:kebineng"] = "君桓文化",

  ["koujing"] = "寇旌",
  [":koujing"] = "出牌阶段开始时，你可以选择任意张手牌，这些牌本回合视为不计入次数的【杀】。其他角色受到以此法使用的【杀】的伤害后展示这些牌，"..
  "其可用所有手牌交换这些牌。",
  ["#koujing-invoke"] = "寇旌：你可以将任意张手牌作为“寇旌”牌，本回合视为不计入次数的【杀】",
  ["@@koujing-inhand"] = "寇旌",
  ["#koujing_filter"] = "寇旌",
  ["#koujing-card"] = "寇旌：你可以用所有手牌交换 %src 这些“寇旌”牌",

  ["$koujing1"] = "驰马掠野，塞外称雄。",
  ["$koujing2"] = "控弦十万，纵横漠南。",
  ["~kebineng"] = "草原雄鹰，折翼于此……",
}

local wuanguo = General(extension, "wuanguo", "qun", 4)
local diezhang = fk.CreateTriggerSkill{
  name = "diezhang",
  anim_type = "switch",
  switch_skill_name = "diezhang",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.responseToEvent then
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        if data.responseToEvent.from == player.id and not player:isNude() then
          return target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
        end
      else
        if target == player then
          local from = player.room:getPlayerById(data.responseToEvent.from)
          return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#diezhang1-invoke::"..target.id, true)
      if #card > 0 then
        self.cost_data = {target.id, card}
        return true
      end
    else
      if room:askForSkillInvoke(player, self.name, nil, "#diezhang2-invoke::"..data.responseToEvent.from) then
        self.cost_data = {data.responseToEvent.from}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:throwCard(self.cost_data[2], self.name, player, player)
    else
      player:drawCards(1, self.name)
    end
    local to = room:getPlayerById(self.cost_data[1])
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
}
local diezhang_targetmod = fk.CreateTargetModSkill{
  name = "#diezhang_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and player:hasSkill("diezhang") and card.trueName == "slash" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local duanwan = fk.CreateTriggerSkill{
  name = "duanwan",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#duanwan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(2, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if not player:hasSkill("diezhang", true) then return end
    local skill = "diezhangYang"
    if player:getSwitchSkillState("diezhang", false) == fk.SwitchYang then
      skill = "diezhangYin"
    end
    room:handleAddLoseSkills(player, "-diezhang|"..skill, nil, false, true)
  end,
}
local diezhangYang = fk.CreateTriggerSkill{
  name = "diezhangYang",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
      return player:hasSkill(self) and data.responseToEvent and data.responseToEvent.from == player.id and not player:isNude() and
        target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#diezhangYang-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    for i = 1, 2, 1 do
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    end
  end,
}
local diezhangYin = fk.CreateTriggerSkill{
  name = "diezhangYin",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.responseToEvent then
      local from = player.room:getPlayerById(data.responseToEvent.from)
      return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#diezhangYin-invoke::"..data.responseToEvent.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.responseToEvent.from)
    player:drawCards(2, self.name)
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
}
diezhang:addRelatedSkill(diezhang_targetmod)
wuanguo:addSkill(diezhang)
wuanguo:addSkill(duanwan)
Fk:addSkill(diezhangYang)
Fk:addSkill(diezhangYin)
Fk:loadTranslationTable{
  ["wuanguo"] = "武安国",
  ["#wuanguo"] = "虎口折腕",
  ["designer:wuanguo"] = "息吹123",
  ["illustrator:wuanguo"] = "目游",
  ["diezhang"] = "叠嶂",
  [":diezhang"] = "转换技，你出牌阶段使用【杀】次数上限+1。阳：当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用(一)张【杀】；"..
  "阴：当你使用牌抵消其他角色使用的牌后，你可以摸(一)张牌视为对其使用一张【杀】。",
  ["duanwan"] = "断腕",
  [":duanwan"] = "限定技，当你处于濒死状态时，你可以将体力回复至2点，然后修改〖叠嶂〗：失去当前状态的效果，括号内的数字+1。",
  ["diezhangYang"] = "叠嶂",
  [":diezhangYang"] = "每回合限一次，当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用两张【杀】。",
  ["diezhangYin"] = "叠嶂",
  [":diezhangYin"] = "每回合限一次，当你使用牌抵消其他角色使用的牌后，你可以摸两张牌视为对其使用一张【杀】。",
  ["#diezhang1-invoke"] = "叠嶂：你可以弃置一张牌，视为对 %dest 使用【杀】",
  ["#diezhang2-invoke"] = "叠嶂：你可以摸一张牌，视为对 %dest 使用【杀】",
  ["#duanwan-invoke"] = "断腕：你可以回复体力至2点，删除现在的“叠嶂”状态！",
  ["#diezhangYang-invoke"] = "叠嶂：你可以弃置一张牌，视为对 %dest 使用两张【杀】",
  ["#diezhangYin-invoke"] = "叠嶂：你可以摸两张牌，视为对 %dest 使用【杀】",

  ["$diezhang1"] = "某家这大锤，舞起来那叫一个万夫莫敌。",
  ["$diezhang2"] = "贼吕布何在？某家来取汝性命了！",
  ["$duanwan1"] = "好你个吕奉先，竟敢卸我膀子！",
  ["$duanwan2"] = "汝这匹夫，为何往手腕上招呼？",
  ["~wuanguo"] = "吕奉先，你给某家等着！",
}

return extension
