local extension = Package("tenyear_sp5")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp5"] = "十周年专属5",
  ["wm"] = "武",
}

local shiyi = General(extension, "shiyi", "wu", 3)
local cuichuan = fk.CreateActiveSkill{
  name = "cuichuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      for _, type in ipairs(types) do
        if card.sub_type == type and target:getEquipment(type) == nil then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo({table.random(cards)}, Player.Equip, target, fk.ReasonJustMove, self.name)
    end
    local n = #target.player_cards[Player.Equip]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    if #cards > 0 and n > 3 then
      room:handleAddLoseSkills(player, "-cuichuan|zuojian", nil, true, false)
      target:gainAnExtraTurn(true)
    end
  end,
}
local zhengxu = fk.CreateTriggerSkill{
  name = "zhengxu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("zhengxu1-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu1-invoke")
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
}
local zhengxu_trigger = fk.CreateTriggerSkill{
  name = "#zhengxu_trigger",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("zhengxu2-turn") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              self.cost_data = self.cost_data + 1
            end
          end
        end
      end
      return self.cost_data > 0
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu2-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
}
local zuojian = fk.CreateTriggerSkill{
  name = "zuojian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("zuojian-phase") >= player.hp and
      (#table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end) > 0 or
      #table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end)
    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end
    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zuojian1" then
      room:doIndicate(player.id, table.map(targets1, function(p) return p.id end))
      for _, p in ipairs(targets1) do
        p:drawCards(1, self.name)
      end
    end
    if choice == "zuojian2" then
      room:doIndicate(player.id, table.map(targets2, function(p) return p.id end))
      for _, p in ipairs(targets2) do
        local id = room:askForCardChosen(player, p, "h", self.name)
        room:throwCard({id}, self.name, p, player)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.CardUsing then
        return target == player
      else
        return data == self
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "zuojian-phase", 1)
      if player:hasSkill(self.name, true) then
        room:addPlayerMark(player, "@zuojian-phase", 1)
      end
    else
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)
    end
  end,
}
zhengxu:addRelatedSkill(zhengxu_trigger)
shiyi:addSkill(cuichuan)
shiyi:addSkill(zhengxu)
shiyi:addRelatedSkill(zuojian)
Fk:loadTranslationTable{
  ["shiyi"] = "是仪",
  ["cuichuan"] = "榱椽",
  [":cuichuan"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，从牌堆中将一张随机装备牌置入其装备区空位，你摸X张牌（X为其装备区牌数）。"..
  "若其装备区内的牌因此达到4张或以上，你失去〖榱椽〗并获得〖佐谏〗，然后令其在此回合结束后获得一个额外回合。",
  ["zhengxu"] = "正序",
  [":zhengxu"] = "每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，你可以摸等量的牌。",
  ["zuojian"] = "佐谏",
  [":zuojian"] = "出牌阶段结束时，若你此阶段使用的牌数大于等于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；"..
  "2.弃置装备区牌数小于你的每名角色各一张手牌。",
  ["#zhengxu_trigger"] = "正序",
  ["#zhengxu1-invoke"] = "正序：你可以防止你受到的伤害",
  ["#zhengxu2-invoke"] = "正序：你可以摸%arg张牌",
  ["@zuojian-phase"] = "佐谏",
  ["zuojian1"] = "装备区牌数大于你的角色各摸一张牌",
  ["zuojian2"] = "你弃置装备区牌数小于你的角色各一张手牌",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao_num-turn")
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    if not target:isNude() then
      local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id, true).trueName end), ",")
      if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
        room:addPlayerMark(player, "jingzao_num-turn", 1)
        room:moveCards({
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
        return
      end
    end
    local dummy = Fk:cloneCard("dilu")
    while #cards > 0 do
      local id = table.random(cards)
      if not table.find(dummy.subcards, function(c) return Fk:getCardById(c, true).trueName == Fk:getCardById(id, true).trueName end) then
        dummy:addSubcard(id)
      end
      table.removeOne(cards, id)
    end
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    room:setPlayerMark(player, "jingzao-turn", 1)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from ~= player.id and (data.card:isCommonTrick() or
      data.card.type == Card.TypeBasic) and player:getMark("enyu-turn") ~= 0 and
      #table.filter(player:getMark("enyu-turn"), function(name) return name == data.card.trueName end) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.from ~= player.id and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("enyu-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "enyu-turn", mark)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；2.令你随机获得这些牌中牌名不同的牌各一张，然后此技能本回合失效。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用基本牌或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令 %src 获得其中不同牌名各一张",
}

local sunlang = General(extension, "sunlang", "shu", 4)
local tingxian = fk.CreateTriggerSkill{
  name = "tingxian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip]
    return n > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#tingxian-invoke:::"..n)
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip]
    player:drawCards(n, self.name)
    local targets = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, n, "#tingxian-choose:::"..n, self.name, true)
    if #targets > 0 then
      table.insertTable(data.nullifiedTargets, targets)
    end
  end,
}
local benshi = fk.CreateTriggerSkill{
  name = "benshi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and player:inMyAttackRange(p) and not player:isProhibited(p, data.card) then
        TargetGroup:pushTargets(data.targetGroup, p.id)
      end
    end
  end,
}
local benshi_attackrange = fk.CreateAttackRangeSkill{
  name = "#benshi_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(self.name) then
      local fix = 1
      if from:getEquipment(Card.SubtypeWeapon) then
        fix = fix + 1 - Fk:getCardById(from:getEquipment(Card.SubtypeWeapon)).attack_range
      end
      return fix
    end
    return 0
  end,
}
benshi:addRelatedSkill(benshi_attackrange)
sunlang:addSkill(tingxian)
sunlang:addSkill(benshi)
Fk:loadTranslationTable{
  ["sunlang"] = "孙狼",
  ["tingxian"] = "铤险",
  [":tingxian"] = "每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后令此【杀】对其中至多X个目标无效（X为你装备区的牌数）。",
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你装备区内的武器牌不提供攻击范围，你的攻击范围+1，你使用【杀】须指定攻击范围内所有角色为目标。",
  ["#tingxian-invoke"] = "铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效",
  ["#tingxian-choose"] = "铤险：你可以令此【杀】对至多%arg名目标无效",
}
--霍峻 孙寒华
Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，弃牌堆中的红色牌数量多于黑色牌时，你使用牌时回复1点体力并获得一个“灵”标记；"..
  "弃牌堆中黑色牌数量多于红色牌时，你使用牌时可弃置一名其他角色区域内的一张牌。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "锁定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌时，根据此牌的失去方式执行以下效果：使用-此牌不能被响应；打出-摸一张牌；弃置-回复1点体力；其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合失去牌时触发〖踏寂〗时随机额外获得一种效果。",
}

local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("xialei-turn") < 3 then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Red then
                return true
              end
            end
          end
        end
      else
        if target == player and player.room:getCardArea(data.card) == Card.Processing then
          if data.card:isVirtual() and #data.card.subcards > 0 then
            for _, id in ipairs(data.card.subcards) do
              if Fk:getCardById(id).color == Card.Red then
                return true
              end
            end
          else
            return data.card.color == Card.Red
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    room:fillAG(player, ids)
    local chosen = room:askForAG(player, ids, false, self.name)
    table.removeOne(ids, chosen)
    room:obtainCard(player.id, chosen, false, fk.ReasonPrey)
    room:closeAG(player)
    if #ids > 0 then
      local choice = room:askForChoice(player, {"xialei_top", "xialei_bottom"}, self.name)
      local place = 1
      if choice == "xialei_top" then
        for i = #ids, 1, -1 do
          table.insert(room.draw_pile, 1, ids[i])
        end
      else
        for _, id in ipairs(ids) do
          table.insert(room.draw_pile, id)
        end
      end
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then return end
      for _, id in ipairs(ids) do
        if room:getCardArea(id) ~= Card.DiscardPile then
          table.removeOne(ids, id)
        end
      end
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), function(p) return p.id end), 1, 1, "#anzhi-choose", self.name, true)
      if #to > 0 then
        local get = {}
        room:fillAG(player, ids)
        while #get < 2 and #ids > 0 do
          local id = room:askForAG(player, ids, true)
          if id == nil then break end
          table.insert(get, id)
          table.removeOne(ids, id)
          room:takeAG(player, id, {player})
        end
        room:closeAG(player)
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local anzhi_record = fk.CreateTriggerSkill{
  name = "#anzhi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "anzhi", "#anzhi-invoke", true)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local room = player.room
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then ids = {} end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      room:setPlayerMark(player, "anzhi_record-turn", ids)
    end
  end,
}
anzhi:addRelatedSkill(anzhi_record)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；"..
  "黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-invoke"] = "你想发动技能“暗织”吗？",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}

local liupi = General(extension, "liupi", "qun", 4)
local juying = fk.CreateTriggerSkill{
  name = "juying",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      local n = 1
      local skill = Fk.skills["slash_skill"]
      local status_skills = player.room.status_skills[TargetModSkill] or Util.DummyTable
      for _, skill in ipairs(status_skills) do
        local correct = skill:getResidueNum(player, skill, Player.HistoryPhase, Fk:cloneCard("slash"), nil)
        if correct == nil then correct = 0 end
        n = n + correct
      end
      return player:usedCardTimes("slash", Player.HistoryPhase) < n
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local choices = {"Cancel", "juying1", "juying2", "juying3"}
    for i = 1, 3, 1 do
      local choice = room:askForChoice(player, choices, self.name, "#juying-choice")
      if choice == "Cancel" then break end
      if choice == "juying1" then
        room:addPlayerMark(player, self.name, 1)
      elseif choice == "juying2" then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
      else
        player:drawCards(3, self.name)
      end
      table.removeOne(choices, choice)
      n = n + 1
    end
    if n > 0 and n > player.hp then
      n = n - player.hp
      if #player:getCardIds{Player.Hand, Player.Equip} < n then return end
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local juying_targetmod = fk.CreateTargetModSkill{
  name = "#juying_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("juying") > 0 and scope == Player.HistoryPhase then
      return player:getMark("juying")
    end
  end,
}
juying:addRelatedSkill(juying_targetmod)
liupi:addSkill(juying)
Fk:loadTranslationTable{
  ["liupi"] = "刘辟",
  ["juying"] = "踞营",
  [":juying"] = "出牌阶段结束时，若你本阶段使用【杀】的次数小于次数上限，你可以选择任意项：1.下个回合出牌阶段使用【杀】次数上限+1；"..
  "2.本回合手牌上限+2；3.摸三张牌。若你选择的选项数大于你的体力值，每多一项你弃置一张牌（不足则不弃）。",
  ["#juying-choice"] = "踞营：你可以选择任意项，每比体力值多选一项便弃一张牌",
  ["juying1"] = "下个回合出牌阶段使用【杀】上限+1",
  ["juying2"] = "本回合手牌上限+2",
  ["juying3"] = "摸三张牌",
}

local guannings = General(extension, "guannings", "shu", 3)
local xiuwen = fk.CreateTriggerSkill{
  name = "xiuwen",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player:getMark("@$xiuwen") == 0 or not table.contains(player:getMark("@$xiuwen"), data.card.trueName))
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getMark("@$xiuwen")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    player.room:setPlayerMark(player, "@$xiuwen", mark)
    player:drawCards(1, self.name)
  end,
}
local longsong_active = fk.CreateActiveSkill{
  name = "longsong_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, effect.cards[1], false, fk.ReasonGive)
    local skills = {}
    for _, s in ipairs(target.player_skills) do  --实际是许劭技能池。这不加强没法玩
      if not (s.attached_equip or s.name[#s.name] == "&") and not player:hasSkill(s, true) then
        if s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then
          if s.frequency ~= Skill.Limited then
            table.insertIfNeed(skills, s.name)
          end
        elseif s:isInstanceOf(TriggerSkill) then
          local str = Fk:translate(":"..s.name)
          if string.sub(str, 1, 12) == "出牌阶段" and string.sub(str, 13, 15) ~= "开始" and string.sub(str, 13, 15) ~= "结束" then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
    end
    if #skills > 0 then
      room:setPlayerMark(player, "longsong-phase", skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local longsong = fk.CreateTriggerSkill{
  name = "longsong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForUseActiveSkill(player, "longsong_active", "#longsong-invoke", true)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and
      player:getMark("longsong-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("longsong-phase")
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local longsong_invalidity = fk.CreateInvaliditySkill {
  name = "#longsong_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("longsong-phase") ~= 0 and table.contains(from:getMark("longsong-phase"), skill.name) and
      from:usedSkillTimes(skill.name, Player.HistoryPhase) > 0
  end
}
Fk:addSkill(longsong_active)
longsong:addRelatedSkill(longsong_invalidity)
guannings:addSkill(xiuwen)
guannings:addSkill(longsong)
Fk:loadTranslationTable{
  ["guannings"] = "关宁",
  ["xiuwen"] = "修文",
  [":xiuwen"] = "你使用一张牌时，若此牌名是你本局游戏第一次使用，你摸一张牌。",
  ["longsong"] = "龙诵",
  [":longsong"] = "出牌阶段开始时，你可以交给一名其他角色一张红色牌，然后你此阶段获得其拥有的“出牌阶段”的技能（每回合限发动一次）。<br>"..
  "<font color='grey'>可以获得的技能包括：<br>非限定技的转化技和主动技，技能描述前四个字为“出牌阶段”且五~六字不为“开始”和“结束”的触发技<br/>",
  ["@$xiuwen"] = "修文",
  ["#longsong-invoke"] = "龙诵：你可以交给一名其他角色一张红色牌，本阶段获得其拥有的“出牌阶段”技能",
  ["longsong_active"] = "龙诵",
}

local godzhangjiao = General(extension, "godzhangjiao", "god", 3)
local yizhao = fk.CreateTriggerSkill{
  name = "yizhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.number
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@zhangjiao_huang"))
    room:addPlayerMark(player, "@zhangjiao_huang", math.min(data.card.number, 184 - player:getMark("@zhangjiao_huang")))
    local n2 = tostring(player:getMark("@zhangjiao_huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == 0 then x = 10 end  --yes, tenyear is so strange
    local card = room:getCardsFromPileByRule(".|"..x)
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
  end,
}
local sanshou = fk.CreateTriggerSkill{
  name = "sanshou",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local yes = false
    for _, id in ipairs(cards) do
      if player:getMark("sanshou_"..Fk:getCardById(id):getTypeString().."-turn") == 0 then
        room:setCardEmotion(id, "judgegood")
        yes = true
      else
        room:setCardEmotion(id, "judgebad")
      end
    end
    room:delay(1000)
    room:moveCards({
      ids = cards,
      fromArea = Card.Processing,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    if yes then
      return true
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "sanshou_"..data.card:getTypeString().."-turn", 1)
  end,
}
local sijun = fk.CreateTriggerSkill{
  name = "sijun",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      player:getMark("@zhangjiao_huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhangjiao_huang", 0)
    room:shuffleDrawPile()
    local cards = {}
    local total = 36
    local i = 0
    while total > 0 and i < 999 do
      local num = math.random(1, math.min(13, total))
      local id = room:getCardsFromPileByRule(".|"..num)[1]
      if id ~= nil then
        table.insert(cards, id)
        total = total - num
      end
      i = i + 1
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local tianjie = fk.CreateTriggerSkill{
  name = "tianjie",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if player:getMark(self.name) > 0 then
        player.room:setPlayerMark(player, self.name, 0)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 3, "#tianjie-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      local n = math.max(1, #table.filter(p.player_cards[Player.Hand], function(c) return Fk:getCardById(c).name == "jink" end))
      room:damage{
        from = player,
        to = p,
        damage = n,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
  end,
}
godzhangjiao:addSkill(yizhao)
godzhangjiao:addSkill(sanshou)
godzhangjiao:addSkill(sijun)
godzhangjiao:addSkill(tianjie)
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["yizhao"] = "异兆",
  [":yizhao"] = "锁定技，当你使用或打出一张牌后，获得等同于此牌点数的“黄”标记，然后若“黄”标记数的十位数变化，你随机获得牌堆中一张点数为变化后十位数的牌。",
  ["sanshou"] = "三首",
  [":sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。",
  ["sijun"] = "肆军",
  [":sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记并洗牌，然后获得随机张点数之和为36的牌。",
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",
  ["@zhangjiao_huang"] = "黄",
  ["#tianjie-choose"] = "天劫：你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】数，至少为1）",
  
  ["$yizhao1"] = "苍天已死，此黄天当立之时。",
  ["$yizhao2"] = "甲子尚水，显炎汉将亡之兆。",
  ["$sanshou1"] = "三公既现，领大道而立黄天。",
  ["$sanshou2"] = "天地三才，载厚德以驱魍魉。",
  ["$sijun1"] = "联九州黎庶，撼一家之王庭。",
  ["$sijun2"] = "吾以此身为药，欲医天下之疾。",
  ["$tianjie1"] = "苍天既死，贫道当替天行道。",
  ["$tianjie2"] = "贫道张角，请大汉赴死！",
  ["~godzhangjiao"] = "诸君唤我为贼，然我所窃何物？",
}

local zhouxuan = General(extension, "zhouxuan", "wei", 3)
local wumei = fk.CreateTriggerSkill{
  name = "wumei",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.RoundStart and player.faceup and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getMark("@@wumei_extra") == 0 end), function(p) return p.id end), 1, 1, "#wumei-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@wumei_extra", 1)
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setPlayerMark(to, "wumei_record", hp_record)
    if to == player then
      room:addPlayerMark(to, "wumei_self", 1)
    end
    to:gainAnExtraTurn()
    player:gainAnExtraTurn()
    --FIXME: 回合顺序反了！！
    room.logic:breakTurn()
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("wumei_self") > 0 then
      room:setPlayerMark(player, "wumei_self", 0)
    else
      room:setPlayerMark(player, "@@wumei_extra", 0)
      room:setPlayerMark(player, "wumei_record", 0)
    end
  end,
}

local wumei_delay = fk.CreateTriggerSkill{
  name = "#wumei_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@@wumei_extra") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, wumei.name, "special")
    local hp_record = player:getMark("wumei_record")
    if type(hp_record) ~= "table" then return false end

    for _, p in ipairs(room:getAlivePlayers()) do
      local p_record = table.find(hp_record, function (sub_record)
        return #sub_record == 2 and sub_record[1] == p.id
      end)

      if p_record then
        p.hp = math.min(p.maxHp, p_record[2])
        room:broadcastProperty(p, "hp")
      end
    end
  end,
}

local zhanmeng = fk.CreateTriggerSkill{
  name = "zhanmeng",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i).."-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and not table.contains(room:getTag("zhanmeng1"), data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local targets = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isNude() then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(targets, p.id)
        end
      end
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    self.cost_data[1] = choice
    if choice == "zhanmeng3" then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanmeng-choose", self.name, false)
      if #to > 0 then
        self.cost_data[2] = to[1]
      else
        self.cost_data[2] = table.random(targets)
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if not card.is_damage_card then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
      if #cards > 0 then
        local card = table.random(cards)
        room:moveCards({
          ids = {card},
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng2_invoke", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(self.cost_data[2])
      local n = math.min(2, #p:getCardIds{Player.Hand, Player.Equip})
      local cards = room:askForDiscard(p, n, 2, true, self.name, false, ".", "#zhanmeng-discard:"..player.id.."::"..tostring(n))
      local x = Fk:getCardById(cards[1]).number
      if #cards == 2 then
        x = x + Fk:getCardById(cards[2]).number
      end
      if x > 10 then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local zhanmeng_record = fk.CreateTriggerSkill{
  name = "#zhanmeng_record",

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.CardUsing then
        return true
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      if not table.contains(zhanmeng2, data.card.trueName) then
        table.insert(zhanmeng2, data.card.trueName)
        room:setTag("zhanmeng2", zhanmeng2)
      end
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("zhanmeng2_get-turn") == data.card.trueName then
          room:setPlayerMark(p, "zhanmeng2_get-turn", 0)
          local cards = {}
          for i = 1, #room.draw_pile, 1 do
            local card = Fk:getCardById(room.draw_pile[i])
            if card.is_damage_card then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
          if #cards > 0 then
            local card = table.random(cards)
            room:moveCards({
              ids = {card},
              to = p.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonJustMove,
              proposer = p.id,
              skillName = "zhanmeng",
            })
          end
        end
      end
    else
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      room:setTag("zhanmeng1", zhanmeng2)  --上回合使用的牌
      zhanmeng2 = {}
      room:setTag("zhanmeng2", zhanmeng2)  --当前回合使用的牌
      for _, p in ipairs(room:getAlivePlayers()) do
        if type(p:getMark("zhanmeng2_invoke")) == "string" then
          room:setPlayerMark(p, "zhanmeng2_get-turn", p:getMark("zhanmeng2_invoke"))
          room:setPlayerMark(p, "zhanmeng2_invoke", 0)
        end
      end
    end
  end,
}
wumei:addRelatedSkill(wumei_delay)
zhanmeng:addRelatedSkill(zhanmeng_record)
zhouxuan:addSkill(wumei)
zhouxuan:addSkill(zhanmeng)
Fk:loadTranslationTable{
  ["zhouxuan"] = "周宣",
  ["wumei"] = "寤寐",
  ["#wumei_delay"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。",
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>"..
  "1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>"..
  "2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>"..
  "3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",
  ["#wumei-choose"] = "寤寐: 你可以令一名角色执行一个额外的回合",
  ["@@wumei_extra"] = "寤寐",
  ["zhanmeng1"] = "你获得一张非伤害牌",
  ["zhanmeng2"] = "下一回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-choose"] = "占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-discard"] = "占梦：弃置%arg张牌，若点数之和大于10，%src 对你造成1点火焰伤害",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
  ["$zhanmeng1"] = "梦境缥缈，然有迹可占。",
  ["$zhanmeng2"] = "万物有兆，唯梦可卜。",
  ["~zhouxuan"] = "人生如梦，假时亦真。",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawCards",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and player:getHandcardNum() > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:isKongcheng() end), function(p) return p.id end)
    local prompt = "#zhaohan-discard"
    if #targets > 0 then
      prompt = "#zhaohan-give"
    end
    local cards = room:askForCard(player, 2, 2, false, self.name, false, ".", prompt)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true)
      if #to > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(to[1], dummy, false, fk.ReasonJustMove)
        return
      end
    end
    room:throwCard(cards, self.name, player, player)
  end
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("jinjie-round") > 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jinjie-draw::"..target.id)
    else
      local n = player:usedSkillTimes(self.name, Player.HistoryRound)
      if n == 0 then
        return player.room:askForSkillInvoke(player, self.name, nil, "#jinjie-invoke::"..target.id)
      else
        if player:getHandcardNum() < n then return end
        return #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#jinjie-discard::"..target.id..":"..n) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("jinjie-round") > 0 then
      target:drawCards(1, self.name)
    else
      player.room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "jinjie-round", 1)
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isWounded() and not player:isProhibited(p, Fk:cloneCard("slash")) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
  end,
}
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "一名角色进入濒死状态时，若本轮你还没有进行回合，你可以弃置X张手牌令其回复1点体力（X为本轮此技能的发动次数）；若你已进行过回合，你可以令其摸一张牌。",
  ["jue"] = "举讹",
  [":jue"] = "准备阶段，你可以视为对一名满体力的角色使用一张【杀】。",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌，交给一名没有手牌的角色或弃置之",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色获得这些牌，或点“取消”弃置之",
  ["#jinjie-draw"] = "尽节：你可以令 %dest 摸一张牌",
  ["#jinjie-invoke"] = "尽节：你可以令 %dest 回复1点体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "举讹：你可以视为对一名未受伤的角色使用【杀】",
}

local furongfuqian = General(extension, "furongfuqian", "shu", 4, 6)
local ty__xuewei = fk.CreateTriggerSkill{
  name = "ty__xuewei",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@ty__xuewei") > 0 and player.tag[self.name][1] == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
        return p.hp <= player.hp end), function (p) return p.id end), 1, 1, "#ty__xuewei-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(room:getPlayerById(self.cost_data), "@@ty__xuewei", 1)
      player.tag[self.name] = {self.cost_data}
    else
      room:loseHp(player, 1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
      return true
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and data.from == Player.RoundStart and
      player.tag[self.name] and #player.tag[self.name] > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player.tag[self.name][1])
    room:setPlayerMark(to, "@@ty__xuewei", 0)
    player.tag[self.name] = {}
  end,
}
local yuguan = fk.CreateTriggerSkill{
  name = "yuguan",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and table.every(player.room:getOtherPlayers(player), function (p)
      return p:getLostHp() <= player:getLostHp()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuguan-invoke:::"..math.max(0, player:getLostHp() - 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:getLostHp() > 0 then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return #p.player_cards[Player.Hand] < p.maxHp end), function(p) return p.id end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#yuguan-choose:::"..player:getLostHp(), self.name, false)
      if #tos == 0 then
        tos = {player.id}
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        p:drawCards(p.maxHp - #p.player_cards[Player.Hand], self.name)
      end
    end
  end,
}
furongfuqian:addSkill(ty__xuewei)
furongfuqian:addSkill(yuguan)
Fk:loadTranslationTable{
  ["furongfuqian"] = "傅肜傅佥",
  ["ty__xuewei"] = "血卫",
  [":ty__xuewei"] = "结束阶段，你可以选择一名体力值不大于你的角色。直到你的下回合开始前，该角色受到伤害时，防止此伤害，然后你失去1点体力并与其各摸一张牌。",
  ["yuguan"] = "御关",
  [":yuguan"] = "每个回合结束时，若你是损失体力值最多的角色，你可以减1点体力上限，然后令至多X名角色将手牌摸至体力上限（X为你已损失的体力值）。",
  ["@@ty__xuewei"] = "血卫",
  ["#ty__xuewei-choose"] = "血卫：你可以指定一名体力值不大于你的角色<br>直到你下回合开始前防止其受到的伤害，你失去1点体力并与其各摸一张牌",
  ["#yuguan-invoke"] = "御关：你可以减1点体力上限，令至多%arg名角色将手牌摸至体力上限",
  ["#yuguan-choose"] = "御关：令至多%arg名角色将手牌摸至体力上限",
}

-- 孙桓 杨弘 芮姬 桥蕤2023.3.11
local xianglang = General(extension, "xianglang", "shu", 3)
local kanji = fk.CreateActiveSkill{
  name = "kanji",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local suits = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return
        else
          table.insert(suits, suit)
        end
      end
    end
    local suits1 = #suits
    player:drawCards(2, self.name)
    if suits1 == 4 then return end
    suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    if #suits == 4 then
      player:skip(Player.Discard)
    end
  end,
}
local qianzheng = fk.CreateTriggerSkill{
  name = "qianzheng",
  anim_type = "drawcard",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #player:getCardIds{Player.Hand, Player.Equip} > 1 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#qianzheng1-card:::"..data.card:getTypeString()..":"..data.card:toLogString()
    if data.card:isVirtual() and not data.card:getEffectiveId() then
      prompt = "#qianzheng2-card"
    end
    local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", prompt)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if Fk:getCardById(cards[1]).type ~= data.card.type and Fk:getCardById(cards[2]).type ~= data.card.type then
      data.extra_data = data.extra_data or {}
      data.extra_data.qianzheng = player.id
    end
    room:recastCard(cards, player, self.name)
  end,
}
local qianzheng_trigger = fk.CreateTriggerSkill{
  name = "#qianzheng_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qianzheng and data.extra_data.qianzheng == player.id and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "qianzheng", nil, "#qianzheng-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
}
qianzheng:addRelatedSkill(qianzheng_trigger)
xianglang:addSkill(kanji)
xianglang:addSkill(qianzheng)
Fk:loadTranslationTable{
  ["xianglang"] = "向朗",
  ["kanji"] = "勘集",
  [":kanji"] = "出牌阶段限两次，你可以展示所有手牌，若花色均不同，你摸两张牌，然后若因此使手牌包含四种花色，则你跳过本回合的弃牌阶段。",
  ["qianzheng"] = "愆正",
  [":qianzheng"] = "每回合限两次，当你成为其他角色使用普通锦囊牌或【杀】的目标时，你可以重铸两张牌，若这两张牌与使用牌类型均不同，"..
  "此牌结算后进入弃牌堆时你可以获得之。",
  ["#qianzheng1-card"] = "愆正：你可以重铸两张牌，若均不为%arg，结算后获得%arg2",
  ["#qianzheng2-card"] = "愆正：你可以重铸两张牌",
  ["#qianzheng-invoke"] = "愆正：你可以获得此%arg",
}

local yanghong = General(extension, "yanghong", "qun", 3)
local function IsNext(from, to)
  if from.dead or to.dead then return false end
  if from.next == to then return true end
  local temp = table.simpleClone(from.next)
  while true do
    if temp.dead then
      temp = temp.next
    else
      return temp == to
    end
  end
end
local ty__jianji = fk.CreateActiveSkill{
  name = "ty__jianji",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if not target:isNude() and #selected < Self:getAttackRange() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          if IsNext(target, Fk:currentRoom():getPlayerById(id)) or IsNext(Fk:currentRoom():getPlayerById(id), target) then
            return true
          end
        end
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    for _, id in ipairs(effect.tos) do
      room:askForDiscard(room:getPlayerById(id), 1, 1, true, self.name, false, ".")
    end
    if #effect.tos < 2 then return end
    local n = 0
    for _, id in ipairs(effect.tos) do
      local num = #room:getPlayerById(id).player_cards[Player.Hand]
      if num > n then
        n = num
      end
    end
    local src = table.filter(effect.tos, function(id) return #room:getPlayerById(id).player_cards[Player.Hand] == n end)
    src = room:getPlayerById(table.random(src))
    table.removeOne(effect.tos, src.id)
    local targets = table.filter(effect.tos, function(id) return not src:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(src, effect.tos, 1, 1, "#ty__jianji-choose", self.name, true)
    if #to > 0 then
      room:useVirtualCard("slash", nil, src, room:getPlayerById(to[1]), self.name, true)
    end
  end,
}
local yuanmo = fk.CreateTriggerSkill{
  name = "yuanmo",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askForChoice(player, {"yuanmo_add", "yuanmo_minus"}, self.name)
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#yuanmo-choose", self.name, true)
        if #tos > 0 then
          for _, id in ipairs(tos) do
            room:doIndicate(player.id, {id})
            local card = room:askForCardChosen(player, room:getPlayerById(id), "he", self.name)
            room:obtainCard(player.id, card, false, fk.ReasonPrey)
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local yuanmo_attackrange = fk.CreateAttackRangeSkill{
  name = "#yuanmo_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
}
yuanmo:addRelatedSkill(yuanmo_attackrange)
yanghong:addSkill(ty__jianji)
yanghong:addSkill(yuanmo)
Fk:loadTranslationTable{
  ["yanghong"] = "杨弘",
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后其中手牌最多的角色可以视为对其中另一名角色使用【杀】。",
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",
  ["#ty__jianji-choose"] = "间计：你可以视为对其中一名角色使用【杀】",
  ["#yuanmo1-invoke"]= "远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌",
  ["#yuanmo2-invoke"]= "远谟：你可以令攻击范围+1",
  ["@yuanmo"] = "远谟",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得任意名角色各一张牌",
}

local ruiji = General(extension, "ty__ruiji", "wu", 4, 4, General.Female)
local wangyuan = fk.CreateTriggerSkill{
  name = "wangyuan",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id, true)
      if card.type ~= Card.TypeEquip and not table.find(player:getPile("ruiji_wang"), function(c)
        return card.trueName == Fk:getCardById(c, true).trueName end) then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if #names > 0 then
      local card = room:getCardsFromPileByRule(table.random(names))
      player:addToPile("ruiji_wang", card[1], true, self.name)
    end
  end,
}
local lingyin = fk.CreateViewAsSkill{
  name = "lingyin",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("lingyin-turn") > 0
  end,
}
local lingyin_trigger = fk.CreateTriggerSkill{
  name = "#lingyin_trigger",
  mute = true,
  expand_pile = "ruiji_wang",
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self.name) and player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
      else
        return player:getMark("lingyin-turn") > 0 and not data.chain and data.to ~= player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local n = player.room:getTag("RoundCount")
      local cards = player.room:askForCard(player, 1, n, false, "liying", true,
        ".|.|.|ruiji_wang|.|.", "#lingyin-invoke:::"..tostring(n), "ruiji_wang")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:broadcastSkillInvoke("lingyin")
      room:notifySkillInvoked(player, "lingyin", "drawcard")
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
      if #player:getPile("ruiji_wang") == 0 or table.every(player:getPile("ruiji_wang"), function(id)
        return Fk:getCardById(id).color == Fk:getCardById(player:getPile("ruiji_wang")[1]).color end) then
        room:setPlayerMark(player, "lingyin-turn", 1)
      end
    else
      data.damage = data.damage + 1
    end
  end,
}
local liying = fk.CreateTriggerSkill{
  name = "liying",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.Draw and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, info.cardId)
        end
      end
    end
    room:setPlayerMark(player, "liying-phase", mark)
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    return player.room:askForUseActiveSkill(player, "liying_active", prompt, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead then
      player:drawCards(1, self.name)
      if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
}
local liying_active = fk.CreateActiveSkill{
  name = "liying_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Self:getMark("liying-phase") ~= 0 and table.contains(Self:getMark("liying-phase"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
  end,
}
lingyin:addRelatedSkill(lingyin_trigger)
Fk:addSkill(liying_active)
ruiji:addSkill(wangyuan)
ruiji:addSkill(lingyin)
ruiji:addSkill(liying)
Fk:loadTranslationTable{
  ["ty__ruiji"] = "芮姬",
  ["wangyuan"] = "妄缘",
  [":wangyuan"] = "当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。",
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",
  ["liying"] = "俐影",
  [":liying"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。",
  ["ruiji_wang"] = "妄",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，然后若“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用",
  ["liying_active"] = "俐影",
  ["#liying1-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌",
  ["#liying2-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”",

  ["$wangyuan1"] = "小女子不才，愿伴公子余生。",
  ["$wangyuan2"] = "纵有万钧之力，然不斩情丝。",
  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
  ["$liying1"] = "飞影略白鹭，日暮栖君怀。",
  ["$liying2"] = "妾影婆娑，摇曳君心。",
  ["~ty__ruiji"] = "佳人芳华逝，空余孤铃鸣……",
}

Fk:loadTranslationTable{
  ["ty__qiaorui"] = "桥蕤",
  ["aishou"] = "隘守",
  [":aishou"] = "结束阶段，你可以摸X张牌（X为你的体力上限），这些牌标记为“隘”。当你于回合外失去最后一张“隘”时，你减1点体力上限。<be>"..
  "准备阶段，弃置你手牌中的所有“隘”，若弃置的“隘”数量大于你的体力值，你加1点体力上限。",
  ["saowei"] = "扫围",
  [":saowei"] = "当一名其他角色使用【杀】结算结束后，若目标角色不为你且目标角色在你的攻击范围内，你可以将一张“隘”当【杀】对该目标角色使用。",
}

local qinlang = General(extension, "qinlang", "wei", 4)
local haochong = fk.CreateTriggerSkill{
  name = "haochong",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getHandcardNum() ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      if #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#haochong-discard:::"..n) then
        self.cost_data = n
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#haochong-draw:::"..player:getMaxCards()) then
        self.cost_data = n
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(math.min(-self.cost_data, 5), self.name)
      if player:getMaxCards() > 0 then  --不允许减为负数
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    end
  end,
}
local jinjin = fk.CreateTriggerSkill{
  name = "jinjin",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMaxCards() ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jinjin-invoke::"..data.from.id..":"..player:getMaxCards())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(player:getMaxCards() - player.hp)
    room:setPlayerMark(player, MarkEnum.AddMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 0)
    if data.from and not data.from.dead then
      local x = #room:askForDiscard(data.from, 1, n, true, self.name, false, ".", "#jinjin-discard:"..player.id.."::"..n)
      if x < n then
        player:drawCards(n - x, self.name)
      end
    end
  end,
}
qinlang:addSkill(haochong)
qinlang:addSkill(jinjin)
Fk:loadTranslationTable{
  ["qinlang"] = "秦朗",
  ["haochong"] = "昊宠",
  [":haochong"] = "当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。",
  ["jinjin"] = "矜谨",
  [":jinjin"] = "每回合限一次，当你造成或受到伤害后，你可以将你的手牌上限重置为当前体力值。"..
  "若如此做，伤害来源可以弃置至多X张牌（X为你因此变化的手牌上限数且至少为1），然后其每少弃置一张，你便摸一张牌。",
  ["#haochong-discard"] = "昊宠：你可以将手牌弃至手牌上限（弃置%arg张），然后手牌上限+1",
  ["#haochong-draw"] = "昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1",
  ["#jinjin-invoke"] = "矜谨：你可将手牌上限（当前为%arg）重置为体力值，令 %dest 弃至多等量的牌",
  ["#jinjin-discard"] = "矜谨：弃置1~%arg张牌，每少弃置一张 %src 便摸一张牌",

  ["$haochong1"] = "幸得义父所重，必效死奉曹。",
  ["$haochong2"] = "朗螟蛉之子，幸隆曹氏厚恩。",
  ["$jinjin1"] = "螟蛉终非麒麟，不可气盛自矜。",
  ["$jinjin2"] = "我姓非曹，可敬人，不可欺人。",
  ["~qinlang"] = "二姓之人，死无其所。",
}

local zhenghun = General(extension, "zhenghun", "wei", 3)
local qiangzhiz = fk.CreateActiveSkill{
  name = "qiangzhiz",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and
      #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Hand, Player.Equip} + #Self:getCardIds{Player.Hand, Player.Equip} > 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local result = room:askForCustomDialog(player, self.name,
      "packages/tenyear/qml/QiangzhiBox.qml", {
        player.general, player:getCardIds(Player.Hand), player:getCardIds(Player.Equip),
        target.general, target:getCardIds(Player.Hand), target:getCardIds(Player.Equip),
      })
    local cards
    if result == "" then
      local ids1 = table.simpleClone(player:getCardIds{Player.Hand, Player.Equip})
      local ids2 = table.simpleClone(target:getCardIds{Player.Hand, Player.Equip})
      table.insertTable(ids1, ids2)
      cards = table.random(ids1, 3)
    else
      cards = json.decode(result)
    end
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds{Player.Hand, Player.Equip}, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds{Player.Hand, Player.Equip}, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if not player.dead and not target.dead then
      if #cards1 == 3 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      elseif #cards2 == 3 then
        room:damage{
          from = target,
          to = player,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
local pitian = fk.CreateTriggerSkill{
  name = "pitian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            return true
          end
        end
      elseif event == fk.Damaged then
        return target == player
      else
        return target == player and player.phase == Player.Finish and player:getHandcardNum() < player:getMaxCards()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#pitian-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:drawCards(math.min(player:getMaxCards() - player:getHandcardNum(), 5), self.name)
      player.room:setPlayerMark(player, "@pitian", 0)
    else
      player.room:addPlayerMark(player, "@pitian", 1)
    end
  end,
}
local pitian_maxcards = fk.CreateMaxCardsSkill{
  name = "#pitian_maxcards",
  correct_func = function(self, player)
    return player:getMark("@pitian")
  end,
}
pitian:addRelatedSkill(pitian_maxcards)
zhenghun:addSkill(qiangzhiz)
zhenghun:addSkill(pitian)
Fk:loadTranslationTable{
  ["zhenghun"] = "郑浑",
  ["qiangzhiz"] = "强峙",
  [":qiangzhiz"] = "出牌阶段限一次，你可以弃置你和一名其他角色共计三张牌。若有角色因此弃置三张牌，其对另一名角色造成1点伤害。",
  ["pitian"] = "辟田",
  [":pitian"] = "当你的牌因弃置而进入弃牌堆后或当你受到伤害后，你的手牌上限+1。结束阶段，若你的手牌数小于手牌上限，"..
  "你可以将手牌摸至手牌上限（最多摸五张），然后重置因此技能而增加的手牌上限。",
  ["#qiangzhiz-choose"] = "强峙：弃置双方共计三张牌",
  ["#pitian-invoke"] = "辟田：你可以将手牌摸至手牌上限，然后重置本技能增加的手牌上限",
  ["@pitian"] = "辟田",
}

local mengjie = General(extension, "mengjie", "qun", 3)
local yinlu = fk.CreateTriggerSkill{
  name = "yinlu",
  events = {fk.GameStart, fk.EventPhaseStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        for i = 1, 4, 1 do
          if target:getMark("@@yinlu"..i) > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      local targets = {}
      for _, p in ipairs(player.room:getAlivePlayers()) do
        for i = 1, 4, 1 do
          if p:getMark("@@yinlu"..i) > 0 then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#yinlu_move-invoke1", self.name, true)
        if #to > 0 then
          self.cost_data = to[1]
          return true
        end
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#yinlu_move-invoke2::"..target.id) then
        self.cost_data = target.id
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
      for i = 1, 3, 1 do
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-give"..i, self.name)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:setPlayerMark(room:getPlayerById(to), "@@yinlu"..i, 1)
      end
      room:setPlayerMark(player, "@@yinlu4", 1)
      room:addPlayerMark(player, "@yunxiang", 1)  --开局自带一个小芸香标记
    else
      local to = room:getPlayerById(self.cost_data)
      local choices = {}
      for i = 1, 4, 1 do
        if to:getMark("@@yinlu"..i) > 0 then
          table.insert(choices, "@@yinlu"..i)
        end
      end
      if event == fk.Death then
        table.insert(choices, "Cancel")
      end
      while true do
        local choice = room:askForChoice(player, choices, self.name, "#yinlu-choice")
        if choice == "Cancel" then return end
        table.removeOne(choices, choice)
        local targets = table.map(room:getOtherPlayers(to), function(p) return p.id end)
        local dest
        if #targets > 1 then
          dest = room:askForChoosePlayers(player, targets, 1, 1, "#yinlu-move:::"..choice, self.name, false)
          if #dest > 0 then
            dest = dest[1]
          else
            dest = table.random(targets)
          end
        else
          dest = targets[1]
        end
        dest = room:getPlayerById(dest)
        room:setPlayerMark(to, choice, 0)
        room:setPlayerMark(dest, choice, 1)
        if event == fk.EventPhaseStart then return end
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true) and
      not table.find(player.room.alive_players, function(p) return p:hasSkill(self.name, true) end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      for i = 1, 4, 1 do
        room:setPlayerMark(p, "@@yinlu"..i, 0)
      end
    end
  end,
}
local yinlu1 = fk.CreateTriggerSkill{
  name = "#yinlu1",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu1") > 0 and player.phase == Player.Finish and player:isWounded() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|diamond", "#yinlu1-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "yinlu",
    }
  end,
}
local yinlu2 = fk.CreateTriggerSkill{
  name = "#yinlu2",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu2") > 0 and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|heart", "#yinlu2-invoke") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, "yinlu")
  end,
}
local yinlu3 = fk.CreateTriggerSkill{
  name = "#yinlu3",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yinlu3") > 0 and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    if player:isNude() or #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|spade", "#yinlu3-invoke") == 0 then
      player.room:loseHp(player, 1, "yinlu")
    end
  end,
}
local yinlu4 = fk.CreateTriggerSkill{
  name = "#yinlu4",
  mute = true,
  events = {fk.EventPhaseStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:getMark("@@yinlu4") > 0 and player.phase == Player.Finish and not player:isNude()
      else
        return player:getMark("@yunxiang") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return #player.room:askForDiscard(player, 1, 1, true, "yinlu", true, ".|.|club", "#yinlu4-invoke") > 0
    else
      return player.room:askForSkillInvoke(player, "yinlu", nil, "#yinlu-yunxiang")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:addPlayerMark(player, "@yunxiang", 1)
    else
      local num = player:getMark("@yunxiang")
      room:setPlayerMark(player, "@yunxiang", 0)
      if data.damage > num then
        data.damage = data.damage - num
      else
        return true
      end
    end
  end,
}
local youqi = fk.CreateTriggerSkill{
  name = "youqi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.skillName == "yinlu" and move.from and move.from ~= player.id then
          self.cost_data = move
          local x = 1 - (math.min(5, player:distanceTo(player.room:getPlayerById(move.from))) / 10)
          return x > math.random()  --据说，距离1 0.9概率，距离5以上 0.5概率
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, info in ipairs(self.cost_data.moveInfo) do
      player.room:obtainCard(player.id, info.cardId, true, fk.ReasonJustMove)
    end
  end,
}
yinlu:addRelatedSkill(yinlu1)
yinlu:addRelatedSkill(yinlu2)
yinlu:addRelatedSkill(yinlu3)
yinlu:addRelatedSkill(yinlu4)
mengjie:addSkill(yinlu)
mengjie:addSkill(youqi)
Fk:loadTranslationTable{
  ["mengjie"] = "孟节",
  ["yinlu"] = "引路",
  [":yinlu"] = "游戏开始时，你令三名角色依次获得以下一个标记：“乐泉”、“藿溪”、“瘴气”，然后你获得一个“芸香”。<br>"..
  "准备阶段，你可以移动一个标记；有标记的角色死亡时，你可以移动其标记。拥有标记的角色获得对应的效果：<br>"..
  "乐泉：结束阶段，你可以弃置一张<font color='red'>♦</font>牌，然后回复1点体力；<br>"..
  "藿溪：结束阶段，你可以弃置一张<font color='red'>♥</font>牌，然后摸两张牌；<br>"..
  "瘴气：结束阶段，你需要弃置一张♠牌，否则失去1点体力；<br>"..
  "芸香：结束阶段，你可以弃置一张♣牌，获得一个“芸香”；当你受到伤害时，你可以移去所有“芸香”并防止等量的伤害。",
  ["youqi"] = "幽栖",
  [":youqi"] = "锁定技，其他角色因“引路”弃置牌时，你有概率获得此牌，该角色距离你越近，概率越高。",
  ["#yinlu-give1"] = "引路：请选择获得“乐泉”（回复体力）的角色",
  ["#yinlu-give2"] = "引路：请选择获得“藿溪”（摸牌）的角色",
  ["#yinlu-give3"] = "引路：请选择获得“瘴气”（失去体力）的角色",
  ["#yinlu-give4"] = "引路：请选择获得“芸香”（防止伤害）的角色",
  ["@@yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["@@yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["@@yinlu3"] = "♠瘴气",
  ["@@yinlu4"] = "♣芸香",
  ["@yunxiang"] = "芸香",
  ["#yinlu_move-invoke1"] = "引路：你可以移动一个标记",
  ["#yinlu_move-invoke2"] = "引路：你可以移动 %dest 的标记",
  ["#yinlu-choice"] = "引路：请选择要移动的标记",
  ["#yinlu-move"] = "引路：请选择获得“%arg”的角色",
  ["#yinlu1"] = "<font color='red'>♦</font>乐泉",
  ["#yinlu2"] = "<font color='red'>♥</font>藿溪",
  ["#yinlu3"] = "♠瘴气",
  ["#yinlu4"] = "♣芸香",
  ["#yinlu1-invoke"] = "<font color='red'>♦</font>乐泉：你可以弃置一张<font color='red'>♦</font>牌，回复1点体力",
  ["#yinlu2-invoke"] = "<font color='red'>♥</font>藿溪：你可以弃置一张<font color='red'>♥</font>牌，摸两张牌",
  ["#yinlu3-invoke"] = "♠瘴气：你需弃置一张♠牌，否则失去1点体力",
  ["#yinlu4-invoke"] = "♣芸香：你可以弃置一张♣牌，获得一个可以防止1点伤害的“芸香”标记",
  ["#yinlu-yunxiang"] = "♣芸香：你可以消耗所有“芸香”，防止等量的伤害",
}

local sunziliufang = General(extension, "ty__sunziliufang", "wei", 3)
local qinshen = fk.CreateTriggerSkill{
  name = "qinshen",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("qinshen_"..suit.."-turn") == 0 then
        self.cost_data = self.cost_data + 1
      end
    end
    return self.cost_data > 0 and player.room:askForSkillInvoke(player, self.name, nil, "#qinshen-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase < Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "qinshen_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
local weidang_active = fk.CreateActiveSkill{
  name = "#weidang_active",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      local n = 0
      for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
        if Self:getMark("weidang_"..suit.."-turn") == 0 then
          n = n + 1
        end
      end
      return #Fk:translate(Fk:getCardById(to_select).trueName) / 3 == n
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = -1,
    })
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if #Fk:translate(card.trueName) == #Fk:translate(Fk:getCardById(effect.cards[1]).trueName) then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    local id = table.random(cards)
    local card = Fk:getCardById(id)
    room:moveCards({
      ids = {id},
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
    if card.trueName ~= "jink" and card.trueName ~= "nullification" then
      local use = room:askForUseCard(player, card.name, ".|.|.|.|.|.|"..id, "#weidang-use:::"..card:toLogString(), false)
      if use then
        room:useCard(use)
      end
    end
  end,
}
local weidang = fk.CreateTriggerSkill{
  name = "weidang",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("weidang_"..suit.."-turn") == 0 then
        n = n + 1
      end
    end
    if n > 0 then
      player.room:askForUseActiveSkill(player, "#weidang_active", "#weidang-invoke:::"..n, true)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.room.current
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          player.room:addPlayerMark(player, "weidang_"..Fk:getCardById(info.cardId):getSuitString().."-turn", 1)
        end
      end
    end
  end,
}
sunziliufang:addSkill(qinshen)
sunziliufang:addSkill(weidang)
Fk:addSkill(weidang_active)
Fk:loadTranslationTable{
  ["ty__sunziliufang"] = "孙资刘放",
  ["qinshen"] = "勤慎",
  [":qinshen"] = "弃牌阶段结束时，你可摸X张牌（X为本回合没有进入过弃牌堆的花色数量）。",
  ["weidang"] = "伪谠",
  [":weidang"] = "其他角色的结束阶段，你可以将一张字数为X的牌置于牌堆底，然后获得牌堆中一张字数为X的牌（X为本回合没有进入过弃牌堆的花色数量），能使用则使用之。",
  ["#qinshen-invoke"] = "勤慎：你可以摸%arg张牌",
  ["#weidang_active"] = "伪谠",
  ["#weidang-invoke"] = "伪谠：你可以将一张牌名字数为%arg的牌置于牌堆底，然后从牌堆获得一张字数相同的牌并使用之",
  ["#weidang-use"] = "伪谠：请使用%arg",
}

local tengfanglan = General(extension, "ty__tengfanglan", "wu", 3, 3, General.Female)
local ty__luochong = fk.CreateTriggerSkill{
  name = "ty__luochong",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark(self.name) < 4 and
      not table.every(player.room.alive_players, function (p) return p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#ty__luochong-choose:::"..tostring(4 - player:getMark(self.name))..":"..tostring(4 - player:getMark(self.name)), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(self.name)
    local n = total
    local to = room:getPlayerById(self.cost_data)
    repeat
      local cards = room:askForCardsChosen(player, to, 1, n, "hej", self.name)
      if #cards > 0 then
        room:throwCard(cards, self.name, to, player)
        if #cards > 2 then
          room:addPlayerMark(player, self.name, 1)
        end
        n = n - #cards
        if n <= 0 then break end
      end
      room:setPlayerMark(to, "ty__luochong_target", 1)
      local targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude() and p:getMark("ty__luochong_target") == 0 end), function(p) return p.id end)
      if #targets == 0 then break end
      local tos = room:askForChoosePlayers(player, targets, 1, 1,
        "#ty__luochong-choose:::"..tostring(total)..":"..tostring(n), self.name, true)
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        break
      end
    until total == 0 or player.dead
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "ty__luochong_target", 0)
    end
  end,
}
local ty__aichen = fk.CreateTriggerSkill{
  name = "ty__aichen",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseChanging, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove and #player.room.draw_pile > 80 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__luochong" and move.from == player.id then
            return true
          end
        end
      elseif event == fk.EventPhaseChanging and #player.room.draw_pile > 40 then
        return target == player and data.to == Player.Discard
      elseif event == fk.TargetConfirmed and #player.room.draw_pile < 40 then
        return target == player and data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:drawCards(2, self.name)
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
    elseif event == fk.EventPhaseChanging then
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.TargetConfirmed then
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
tengfanglan:addSkill(ty__luochong)
tengfanglan:addSkill(ty__aichen)
Fk:loadTranslationTable{
  ["ty__tengfanglan"] = "滕芳兰",
  ["ty__luochong"] = "落宠",
  [":ty__luochong"] = "每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",
  ["ty__aichen"] = "哀尘",
  [":ty__aichen"] = "锁定技，若剩余牌堆数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；"..
  "若剩余牌堆数大于40，你跳过弃牌阶段；若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。",
  ["#ty__luochong-choose"] = "落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）",
  
  ["$ty__luochong1"] = "陛下独宠她人，奈何雨露不均？",
  ["$ty__luochong2"] = "妾贵于佳丽，然宠不及三千。",
  ["$ty__aichen1"] = "君可负妾，然妾不负君。",
  ["$ty__aichen2"] = "所思所想，皆系陛下。",
  ["~ty__tengfanglan"] = "今生缘尽，来世两宽……",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("moyu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target ~= Self and target:getMark("moyu-turn") == 0 and not target:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    room:addPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-use::"..player.id..":"..player:usedSkillTimes(self.name), true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      use.additionalDamage = (use.additionalDamage or 0) + player:usedSkillTimes(self.name) - 1
      use.card.extra_data = use.card.extra_data or {}
      table.insert(use.card.extra_data, self.name)
      room:useCard(use)
    end
  end,
}
local moyu_record = fk.CreateTriggerSkill{
  name = "#moyu_record",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.extra_data and table.contains(data.card.extra_data, "moyu")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "moyu-turn", 1)
  end,
}
moyu:addRelatedSkill(moyu_record)
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以对你使用一张无距离限制且伤害值为X的【杀】"..
  "（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-use"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target:getMark("@@xinzhong") > 0 then
      if #target.player_cards[Player.Hand] <= 3 then
        target:throwAllCards("h")
      else
        room:askForDiscard(target, 3, 3, false, self.name, false, ".", "#jizhong-discard2")
      end
    else
      if #target.player_cards[Player.Hand] < 3 then
        room:setPlayerMark(target, "@@xinzhong", 1)
      else
        local cards = room:askForDiscard(target, 3, 3, false, self.name, true, ".", "#jizhong-discard1")
        if #cards == 0 then
          room:setPlayerMark(target, "@@xinzhong", 1)
        end
      end
    end
  end,
}
local jucheng = fk.CreateTriggerSkill{
  name = "jucheng",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          return room:askForSkillInvoke(player, self.name, data, "#jucheng-use")
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#jucheng-get")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local guangshi = fk.CreateTriggerSkill{
  name = "guangshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start and
      table.every(player.room:getOtherPlayers(player), function (p)
        return p:getMark("@@xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(jucheng)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其不是“信众”，则其选择一项：1.成为“信众”；"..
  "2.弃置三张手牌；若其是“信众”，则其弃置三张手牌（不足则全弃）。",
  ["jucheng"] = "聚逞",
  [":jucheng"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你失去1点体力并摸两张牌。",
  ["@@xinzhong"] = "信众",
  ["#jizhong-discard1"] = "集众：你需弃置三张手牌，否则成为“信众”",
  ["#jizhong-discard2"] = "集众：你需弃置三张手牌",
  ["#jucheng-use"] = "聚逞：你可以令所有“信众”视为对其使用此牌",
  ["#jucheng-get"] = "聚逞：你可以获得其区域内一张牌",
}

local dongwan = General(extension, "dongwan", "qun", 3, 3, General.Female)
local shengdu = fk.CreateTriggerSkill{
  name = "shengdu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#shengdu-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local n = target:getMark(self.name)
    player.room:setPlayerMark(target, self.name, 0)
    for i = 1, n, 1 do
      player:drawCards(data.n, self.name)  --yes! do n times!
    end
  end,
}
local xianjiao = fk.CreateActiveSkill{
  name = "xianjiao",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
      else
        return false
      end
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("slash", effect.cards, player, target, self.name, false)
  end,
}
local xianjiao_record = fk.CreateTriggerSkill{
  name = "#xianjiao_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "xianjiao")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xianjiao")
    else
      local room = player.room
      for _, p in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local to = room:getPlayerById(p)
        if data.card.extra_data and table.contains(data.card.extra_data, "xianjiao") then
          room:loseHp(to, 1, self.name)
        else
          room:addPlayerMark(to, "shengdu", 1)
        end
      end
    end
  end,
}
xianjiao:addRelatedSkill(xianjiao_record)
dongwan:addSkill(shengdu)
dongwan:addSkill(xianjiao)
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名其他角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
  ["xianjiao"] = "献绞",
  [":xianjiao"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。"..
  "若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
}

--袁胤 谢灵毓 高翔 笮融 周善 2023.4.19
local zerong = General(extension, "zerong", "qun", 4)
local cansi = fk.CreateTriggerSkill{
  name = "cansi",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cansi-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if to:isWounded() then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:setPlayerMark(player, self.name, to.id)
    for _, name in ipairs({"slash", "duel", "fire_attack"}) do
      if player.dead or to.dead then break end
      room:useVirtualCard(name, nil, player, to, self.name)
    end
    room:setPlayerMark(player, self.name, 0)
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, self.name) and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    if data.damageDealt and data.damageDealt[player:getMark(self.name)] then
      player:drawCards(2*data.damageDealt[player:getMark(self.name)], self.name)
    end
  end,
}
local fozong = fk.CreateTriggerSkill{
  name = "fozong",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getHandcardNum() > 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - 7
    local cards = room:askForCard(player, n, n, false, self.name, false, ".", "#fozong-card:::"..n)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, true, self.name)
    if #player:getPile(self.name) >= 7 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then return end
        local choices = {"fozong_lose"}
        if #player:getPile(self.name) > 0 then  --很难想象怎样才会不够发
          table.insert(choices, 1, "fozong_get")
        end
        local choice = room:askForChoice(p, choices, self.name, "#fozong-choice:"..player.id)  --之后应该改成选牌框
        if choice == "fozong_get" then
          local cards = player:getPile(self.name)
          table.forEach(room.players, function(p) room:fillAG(p, cards) end)
          local id = room:askForAG(p, cards, false, self.name)
          room:takeAG(p, id, room.players)
          room:obtainCard(p.id, id, true, fk.ReasonJustMove)
          table.removeOne(cards, id)
          table.forEach(room.players, function(p) room:closeAG(p) end)
          if player:isWounded() then
            room:recover({
              who = player,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
          end
        else
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
zerong:addSkill(cansi)
zerong:addSkill(fozong)
Fk:loadTranslationTable{
  ["zerong"] = "笮融",
  ["cansi"] = "残肆",
  [":cansi"] = "锁定技，准备阶段，你选择一名其他角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】，其每因此受到1点伤害，你摸两张牌。",
  ["fozong"] = "佛宗",
  [":fozong"] = "锁定技，出牌阶段开始时，若你的手牌多于七张，你将超出数量的手牌置于武将牌上，然后若你武将牌上有至少七张牌，"..
  "其他角色依次选择一项：1.获得其中一张牌并令你回复1点体力；2.令你失去1点体力。",
  ["#cansi-choose"] = "残肆：选择一名角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】",
  ["#fozong-card"] = "佛宗：将 %arg 张手牌置于武将牌上",
  ["#fozong-choice"] = "佛宗：选择对 %src 执行的一项",
  ["fozong_get"] = "获得一张“佛宗”牌，其回复1点体力",
  ["fozong_lose"] = "其失去1点体力",
  
  ["$cansi1"] = "君不入地狱，谁入地狱？",
  ["$cansi2"] = "众生皆苦，唯渡众生于极乐。",
  ["$fozong1"] = "此身无长物，愿奉骨肉为浮屠。",
  ["$fozong2"] = "驱大白牛车，颂无上功德。",
  ["~zerong"] = "此劫，不可避……",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuandi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yuandi_discard" then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
  end,
}
local xinyou = fk.CreateActiveSkill{
  name = "xinyou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 1 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
}
local xinyou_record = fk.CreateTriggerSkill{
  name = "#xinyou_record",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 and not player:isNude() then
      if #player:getCardIds{Player.Hand, Player.Equip} < 3 then
        player:throwAllCards("he")
      else
        room:askForDiscard(player, 2, 2, true, "xinyou", false)
      end
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过一张牌，结束阶段你失去1点体力；"..
  "若你因此回复体力，结束阶段你弃置两张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}

local zhoushan = General(extension, "zhoushan", "wu", 4)
local miyun_active = fk.CreateActiveSkill{
  name = "miyun_active",
  target_num = 1,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
    local id = Self:getMark("miyun")
    return to_select == id or table.contains(selected, id)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return table.contains(selected_cards, Self:getMark("miyun")) and #selected == 0 and to_select ~= Self.id
  end,
}
local miyun = fk.CreateTriggerSkill{
  name = "miyun",
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.RoundEnd, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.RoundStart then
      return not table.every(player.room.alive_players, function (p) return p == player or p:isNude() end)
    elseif event == fk.RoundEnd then
      return table.contains(player.player_cards[player.Hand], player:getMark(self.name))
    elseif event == fk.AfterCardsMove then
      local miyun_losehp = (data.extra_data or {}).miyun_losehp or {}
      return table.contains(miyun_losehp, player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not p:isNude()
      end)
      if #targets == 0 then return false end
      room:notifySkillInvoked(player, self.name, "control")
      room:broadcastSkillInvoke(self.name)
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#miyun-choose", self.name, false, true)
      local cid = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
      local move = {
        from = tos[1],
        ids = {cid},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = "miyun_prey",
      }
      room:moveCards(move)
    elseif event == fk.RoundEnd then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:broadcastSkillInvoke(self.name)

      local cid = player:getMark(self.name)
      local card = Fk:getCardById(cid)

      local _, ret = room:askForUseActiveSkill(player, "miyun_active", "#miyun-give:::" .. card:toLogString(), false)
      local to_give = {cid}
      local target = room:getOtherPlayers(to_give)[1].id
      if ret and #ret.cards > 0 and #ret.targets == 1 then
        to_give = ret.cards
        target = ret.targets[1]
      end
      local move = {
        from = player.id,
        ids = to_give,
        to = target,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = "miyun_give",
      }
      room:moveCards(move)
      if not player.dead then
        local x = player.maxHp - player:getHandcardNum()
        if x > 0 then
          room:drawCards(player, x, self.name)
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = {}
    for _, move in ipairs(data) do
      if move.from == player.id and (move.to ~= player.id or move.toArea ~= Card.PlayerHand) then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if player:getMark(self.name) == info.cardId then
            room:setPlayerMark(player, self.name, 0)
            room:setPlayerMark(player, "@miyun_safe", 0)
            room:setCardMark(Fk:getCardById(info.cardId), "@@miyun_safe", 0)
            if move.skillName ~= "miyun_give" then
              data.extra_data = data.extra_data or {}
              local miyun_losehp = data.extra_data.miyun_losehp or {}
              table.insert(miyun_losehp, player.id)
              data.extra_data.miyun_losehp = miyun_losehp
            end
          end
        end
      elseif move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "miyun_prey" then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(marked, id)
          end
        end
      end
    end
    if #marked > 0 then
      for _, id in ipairs(player.player_cards[player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@miyun_safe", 0)
      end
      local card = Fk:getCardById(marked[1])
      room:setPlayerMark(player, self.name, card.id)
      local num = card.number
      if num > 0 then
        if num == 1 then
          num = "A"
        elseif num == 11 then
          num = "J"
        elseif num == 12 then
          num = "Q"
        elseif num == 13 then
          num = "K"
        end
      end
      room:setPlayerMark(player, "@miyun_safe", {card.name, card:getSuitString(true), num})
      room:setCardMark(card, "@@miyun_safe", 1)
    end
  end,
}
local danying = fk.CreateViewAsSkill{
  name = "danying",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    local slash = Fk:cloneCard("slash")
    if pat == nil and slash.skill:canUse(Self, slash)  then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") then
          table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink")  then
          table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  view_as = function(self, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cid = player:getMark(miyun.name)
    if table.contains(player.player_cards[player.Hand], cid) then
      player:showCards({cid})
    end
  end,
  enabled_at_play = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local slash = Fk:cloneCard("slash")
    return slash.skill:canUse(player, slash)
  end,
  enabled_at_response = function(self, player)
    if player:usedSkillTimes(self.name) > 0 or not table.contains(player.player_cards[player.Hand], player:getMark(miyun.name)) then
      return false
    end
    local pat = Fk.currentResponsePattern
    return pat and Exppattern:Parse(pat):matchExp(self.pattern)
  end,
}
local danying_delay = fk.CreateTriggerSkill{
  name = "#danying_delay",
  events = {fk.TargetConfirming},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(danying.name) > 0 and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if not from.dead and not player.dead and not player:isNude() then
      local cid = room:askForCardChosen(from, player, "he", danying.name)
      room:throwCard({cid}, danying.name, player, from)
    end
  end,
}
Fk:addSkill(miyun_active)
zhoushan:addSkill(miyun)
danying:addRelatedSkill(danying_delay)
zhoushan:addSkill(danying)

Fk:loadTranslationTable{
  ["zhoushan"] = "周善",
  ["miyun"] = "密运",
  ["miyun_active"] = "密运",
  [":miyun"] = "锁定技，每轮开始时，你展示并获得一名其他角色的一张牌，称为『安』；"..
  "每轮结束时，你将包括『安』在内的任意张手牌交给一名其他角色，然后你将手牌摸至体力上限。你不以此法失去『安』时，你失去1点体力。",
  ["danying"] = "胆迎",
  ["#danying_delay"] = "胆迎",
  [":danying"] = "每回合限一次，你可展示手牌中的『安』，然后视为使用或打出一张【杀】或【闪】。"..
  "若如此做，本回合你下次成为牌的目标后，使用者弃置你一张牌。",

  ["#miyun-choose"] = "密运：选择一名角色，获得其一张牌作为『安』",
  ["#miyun-give"] = "密运：选择包含『安』（%arg）在内的任意张手牌，交给一名角色",
  ["@miyun_safe"] = "安",
  ["@@miyun_safe"] = "安",

  ["$miyun1"] = "不要大张旗鼓，要神不知鬼不觉。",
  ["$miyun2"] = "小阿斗，跟本将军走一趟吧。",
  ["$danying1"] = "早就想会会你常山赵子龙了。",
  ["$danying2"] = "赵子龙是吧？兜鍪给你打掉。",
  ["~zhoushan"] = "夫人救我！夫人救我！",
}

local zhangkai = General(extension, "zhangkai", "qun", 4)
local xiangshuz = fk.CreateTriggerSkill{
  name = "xiangshuz",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return #target.player_cards[Player.Hand] >= target.hp
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiangshuz-invoke::"..target.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local choices = {}
      for i = 0, 5, 1 do
        table.insert(choices, tostring(i))
      end
      local choice = room:askForChoice(player, choices, self.name, "#xiangshuz-choice::"..target.id)
      local mark = self.name
      if player:isKongcheng() or #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#xiangshuz-discard") == 0 then
        mark = "@"..self.name
      end
      room:setPlayerMark(target, mark, choice)
    else
      local n1 = #target.player_cards[Player.Hand]
      local n2 = math.max(tonumber(target:getMark(self.name)), tonumber(target:getMark("@"..self.name)))
      room:setPlayerMark(target, self.name, 0)
      room:setPlayerMark(target, "@"..self.name, 0)
      if math.abs(n1 - n2) < 2 and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
      if n1 == n2 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
zhangkai:addSkill(xiangshuz)
Fk:loadTranslationTable{
  ["zhangkai"] = "张闿",
  ["xiangshuz"] = "相鼠",
  [":xiangshuz"] = "其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。"..
  "此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。",
  ["#xiangshuz-invoke"] = "相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害",
  ["#xiangshuz-choice"] = "相鼠：猜测 %dest 此阶段结束时的手牌数",
  ["#xiangshuz-discard"] = "相鼠：你可以弃置一张手牌令你猜测的数值不公布",
  ["@xiangshuz"] = "相鼠",
}

--桓范 孟优 陈泰 孙綝 孙瑜 郤正 刘宠骆俊 乐綝 武庙诸葛亮 城孙权
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).number == 7 then
        n = n + 1
      end
    end
    n = math.max(n, 1)
    if player.hp > n then
      room:loseHp(player, player.hp - n, self.name)
    elseif player.hp < n then
      room:recover({
        who = player,
        num = math.min(n - player.hp, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      })
    end
    room:askForGuanxing(player, room:getNCards(player.hp))
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@@qingshi-turn") == 0 and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "qingshi2", "qingshi3"}
    if data.card.is_damage_card and data.tos then
      table.insert(choices, 2, "qingshi1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "qingshi1" then
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(TargetGroup:getRealTargets(data.tos))
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi = to
    elseif self.cost_data == "qingshi2" then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 10, "#qingshi2-choose", self.name, false)
      if #tos == 0 then
        tos = table.random(targets, 1)
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data == "qingshi3" then
      player:drawCards(player.hp, self.name)
      room:setPlayerMark(player, "@@qingshi-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.qingshi and data.to.id == use.extra_data.qingshi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
      (card.type == Card.TypeBasic or card:isCommonTrick())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = nil
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "zhizhe_token" then
        card = id
        break
      end
    end
    if card then
      room:moveCards({
        ids = {card},
        fromArea = Card.Void,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
      local c = Fk:getCardById(effect.cards[1])
      room:setCardMark(Fk:getCardById(card), self.name, {c.name, c.suit, c.number})
      room:setPlayerMark(player, self.name, card)
    end
  end
}
local zhizhe_filter = fk.CreateFilterSkill{
  name = "#zhizhe_filter",
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("zhizhe") ~= 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("zhizhe")[1], card:getMark("zhizhe")[2], card:getMark("zhizhe")[3])
  end,
}
local zhizhe_maxcards = fk.CreateMaxCardsSkill{
  name = "#zhizhe_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("zhizhe") ~= 0 and player:getMark("zhizhe") == card:getEffectiveId()
  end,
}
local zhizhe_trigger = fk.CreateTriggerSkill{
  name = "#zhizhe_trigger",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card:getMark("zhizhe") ~= 0 and player:getMark("zhizhe") == data.card:getEffectiveId() and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Processing and move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if Fk:getCardById(info.cardId, true):getMark("zhizhe") ~= 0 then
            if move.to and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.to):getMark("zhizhe") == info.cardId then
              --continue
            else
              id = info.cardId
              table.removeOne(move.moveInfo, info)
            end
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("zhizhe") ~= 0 and player:usedSkillTimes("#zhizhe_trigger", Player.HistoryTurn) > 0 and
      player:getMark("zhizhe") == card:getEffectiveId()
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("zhizhe") ~= 0 and player:usedSkillTimes("#zhizhe_trigger", Player.HistoryTurn) > 0 and
      player:getMark("zhizhe") == card:getEffectiveId()
  end,
}
zhizhe:addRelatedSkill(zhizhe_filter)
zhizhe:addRelatedSkill(zhizhe_maxcards)
zhizhe:addRelatedSkill(zhizhe_trigger)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "诸葛亮",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。然后你观看牌堆顶X张牌，"..
  "将这些牌以任意顺序放回牌堆顶或牌堆底（X为你的体力值）",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时，若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸X张牌（X为你的体力值），然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张（基本牌或普通锦囊牌）手牌。此牌不计入你的手牌上限；当你使用或打出此牌后，收回手牌，"..
  "然后本回合你不能再使用或打出此牌。",
  ["@@qingshi-turn"] = "情势失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "你摸体力值张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#zhizhe_filter"] = "智哲",
}

local duanqiaoxiao = General(extension, "duanqiaoxiao", "wei", 3, 3, General.Female)
local caizhuang = fk.CreateActiveSkill{
  name = "caizhuang",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    while true do
      player:drawCards(1, self.name)
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= #effect.cards then return end
    end
  end,
}
local huayi = fk.CreateTriggerSkill{
  name = "huayi",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#huayi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") ~= 0 and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
}
local huayi_trigger = fk.CreateTriggerSkill{
  name = "#huayi_trigger",
  mute = true,
  events = {fk.TurnEnd, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@huayi") ~= 0 then
      if event == fk.TurnEnd then
        return target ~= player and player:getMark("@huayi") == "red"
      elseif event == fk.Damaged then
        return target == player and player:getMark("@huayi") == "black"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(1, "huayi")
    elseif event == fk.Damaged then
      room:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(2, "huayi")
    end
  end,
}
huayi:addRelatedSkill(huayi_trigger)
duanqiaoxiao:addSkill(caizhuang)
duanqiaoxiao:addSkill(huayi)
Fk:loadTranslationTable{
  ["duanqiaoxiao"] = "段巧笑",
  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张花色各不相同的牌，然后重复摸牌直到手牌中的花色数等同于弃牌数。",
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，其他角色回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",
  ["#huayi-invoke"] = "华衣：你可以判定，根据颜色直到你下回合开始获得效果",
  ["@huayi"] = "华衣",
  
  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
  ["~duanqiaoxiao"] = "佳人时光少，君王总薄情……",
}

local zhangjinyun = General(extension, "zhangjinyun", "shu", 3, 3, General.Female)
local huizhi = fk.CreateTriggerSkill{
  name = "huizhi",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, false, self.name, true, ".", "#huizhi-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local n = player:getHandcardNum()
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] > n then
        n = #p.player_cards[Player.Hand]
      end
    end
    if n > player:getHandcardNum() then
      player:drawCards(math.min(n - player:getHandcardNum()), 5)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local jijiao = fk.CreateActiveSkill{
  name = "jijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #Fk:currentRoom().discard_pile > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    local events = room.logic.all_game_events[1]:searchEvents(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card:isCommonTrick() and not use.card:isVirtual()
    end, room.logic:getCurrentEvent())
    for _, e in ipairs(events) do
      local use = e.data[1]
      if room:getCardArea(use.card.id) == Card.DiscardPile then
        table.insertIfNeed(ids, use.card.id)
      end
    end
    events = room.logic.all_game_events[1]:searchEvents(GameEvent.MoveCards, 999, function(e)
      local move = e.data[1]
      return move.from == player.id and move.moveReason == fk.ReasonDiscard
    end, room.logic:getCurrentEvent())
    for _, e in ipairs(events) do
      local move = e.data[1]
      for _, id in ipairs(move.ids) do
        if Fk:getCardById(id):isCommonTrick() and room:getCardArea(id) == Card.DiscardPile then
          table.insertIfNeed(ids, id)
        end
      end
    end
    if #ids > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(ids)
      room:setPlayerMark(player, "jijiao_cards", dummy.subcards)
      room:obtainCard(target.id, dummy, true, fk.ReasonJustMove)
    end
  end,
}
local jijiao_record = fk.CreateTriggerSkill{
  name = "#jijiao_record",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark(self.name) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,

  refresh_events = {fk.AfterDrawPileShuffle, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:usedSkillTimes("jijiao", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 1)
  end,
}
local jijiao_trigger = fk.CreateTriggerSkill{
  name = "#jijiao_trigger",
  mute = true,
  events = {fk.CardUsing, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("jijiao_cards") ~= 0 and #player:getMark("jijiao_cards") > 0 then
      if event == fk.CardUsing then
        return target == player and data.card:isCommonTrick() and not data.card:isVirtual()
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then  --TODO: 这也弄个全局记录！
      local mark = player:getMark("jijiao_cards")
      if table.contains(mark, data.card.id) then
        data.prohibitedCardNames = {"nullification"}
        table.removeOne(mark, data.card.id)
        room:setPlayerMark(player, "jijiao_cards", mark)
      end
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local mark = player:getMark("jijiao_cards")
              if table.contains(mark, info.cardId) then
                table.removeOne(mark, info.cardId)
                room:setPlayerMark(player, "jijiao_cards", mark)
              end
            end
          end
        end
      end
    end
  end,
}
jijiao:addRelatedSkill(jijiao_record)
jijiao:addRelatedSkill(jijiao_trigger)
zhangjinyun:addSkill(huizhi)
zhangjinyun:addSkill(jijiao)
Fk:loadTranslationTable{
  ["zhangjinyun"] = "张瑾云",
  ["huizhi"] = "蕙质",
  [":huizhi"] = "摸牌阶段结束时，你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，最多摸五张）。",
  ["jijiao"] = "继椒",
  [":jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被【无懈可击】响应。"..
  "每回合结束后，若此回合内牌堆洗过牌或有角色死亡，复原此技能。",
  ["#huizhi-invoke"] = "蕙质：你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（最多摸五张）",
  ["#jijiao_record"] = "继椒",
  
  ["$huizhi1"] = "妾有一席幽梦，予君三千暗香。",
  ["$huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
  ["$jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
  ["$jijiao2"] = "居椒之殊荣，妾得之惶恐。",
  ["~zhangjinyun"] = "陛下，妾身来陪你了……",
}

local mengda = General(extension, "ty__mengda", "wei", 4)
mengda.subkingdom = "shu"
local libang = fk.CreateActiveSkill{
  name = "libang",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:sortPlayersByAction(effect.tos, false)
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local id1 = room:askForCardChosen(player, target1, "he", self.name)
    local id2 = room:askForCardChosen(player, target2, "he", self.name)
    room:obtainCard(player.id, id1, true, fk.ReasonPrey)
    room:obtainCard(player.id, id2, true, fk.ReasonPrey)
    player:showCards({id1, id2})
    local pattern = "."
    if Fk:getCardById(id1, true).color == Fk:getCardById(id2, true).color then
      if Fk:getCardById(id1, true).color == Card.Black then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
    end
    local judge = {
      who = player,
      reason = self.name,
      pattern = pattern,
      extra_data = {effect.tos, {id1, id2}},
    }
    room:judge(judge)
  end,
}
local libang_record = fk.CreateTriggerSkill{
  name = "#libang_record",

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == "libang"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then return end
    local targets = data.extra_data[1]
    for i = 2, 1, -1 do
      if room:getPlayerById(targets[i]).dead then
        table.removeOne(targets, targets[i])
      end
    end
    if data.card.color ~= Fk:getCardById(data.extra_data[2][1], true).color and
      data.card.color ~= Fk:getCardById(data.extra_data[2][2], true).color then
      if #targets == 0 or #player:getCardIds{Player.Hand, Player.Equip} < 2 then
        room:loseHp(player, 1, "libang")
      else
        room:setPlayerMark(player, "libang-phase", targets)
        if not room:askForUseActiveSkill(player, "#libang_active", "#libang-card", true) then
          room:loseHp(player, 1, "libang")
        end
        room:setPlayerMark(player, "libang-phase", 0)
      end
    else
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      targets = table.filter(targets, function(id) return not player:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#libang-slash", "libang", false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:useVirtualCard("slash", nil, player, room:getPlayerById(to), "libang")
    end
  end,
}
local libang_active = fk.CreateActiveSkill{
  name = "#libang_active",
  mute = true,
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(Self:getMark("libang-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
  end,
}
local wujie = fk.CreateTriggerSkill{
  name = "wujie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.AfterCardUseDeclared then
        return player:hasSkill(self.name) and data.card.color == Card.NoColor
      else
        return player:hasSkill(self.name, false, true) and not player.room:getTag("SkipNormalDeathProcess")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      player.room:setTag("SkipNormalDeathProcess", true)
      player.room:setTag(self.name, true)
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag("SkipNormalDeathProcess", false)
    player.room:setTag(self.name, false)
  end,
}
local wujie_targetmod = fk.CreateTargetModSkill{
  name = "#wujie_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("wujie") and card and card.color == Card.NoColor and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill("wujie") and card and card.color == Card.NoColor then
      return 999
    end
  end,
}
Fk:addSkill(libang_active)
libang:addRelatedSkill(libang_record)
wujie:addRelatedSkill(wujie_targetmod)
mengda:addSkill(libang)
mengda:addSkill(wujie)
Fk:loadTranslationTable{
  ["ty__mengda"] = "孟达",
  ["libang"] = "利傍",
  [":libang"] = "出牌阶段限一次，你可以弃置一张牌，获得并展示两名其他角色各一张牌，然后你判定，若结果与这两张牌的颜色："..
  "均不同，你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。",
  ["wujie"] = "无节",
  [":wujie"] = "锁定技，你使用的无色牌不计入次数且无距离限制；其他角色杀死你后不执行奖惩。",
  ["#libang-card"] = "利傍：交给其中一名角色两张牌，否则失去1点体力",
  ["#libang-slash"] = "利傍：视为对其中一名角色使用一张【杀】",
}

local guanyu = General(extension, "ty__guanyu", "wei", 4)
local ty__danji = fk.CreateTriggerSkill{
  name = "ty__danji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "mashu|nuchen", nil, true, false)
  end,
}
local nuchen = fk.CreateActiveSkill{
  name = "nuchen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    local suit = Fk:getCardById(id):getSuitString()
    if suit == "nosuit" then return end
    local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".|.|"..suit, "#nuchen-card::"..target.id..":"..suit)
    if #cards > 0 then
      room:damage{
        from = player,
        to = target,
        damage = #cards,
        skillName = self.name,
      }
    else
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(target.player_cards[Player.Hand]) do
        if Fk:getCardById(id):getSuitString() == suit then
          dummy:addSubcard(id)
        end
      end
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
  end,
}
guanyu:addSkill("ex__wusheng")
guanyu:addSkill(ty__danji)
guanyu:addRelatedSkill(nuchen)
Fk:loadTranslationTable{
  ["ty__guanyu"] = "关羽",
  ["ty__wusheng"] = "武圣",
  [":ty__wusheng"] = "你可以将一张红色牌当【杀】使用或打出；你使用<font color='red'>♦</font>【杀】无距离限制。",
  ["ty__danji"] = "单骑",
  [":ty__danji"] = "觉醒技，准备阶段，若你的手牌数大于体力值，你减1点体力上限，回复体力至体力上限，然后获得〖马术〗和〖怒嗔〗。",
  ["nuchen"] = "怒嗔",
  [":nuchen"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你选择一项：1.弃置任意张相同花色的牌，对其造成等量的伤害；"..
  "2.获得其手牌中所有此花色的牌。",
  ["#nuchen-card"] = "怒嗔：你可以弃置任意张%arg牌对 %dest 造成等量伤害，或获得其全部此花色手牌",
}

--张曼成 杜预 阮籍 神邓艾
Fk:loadTranslationTable{
  ["ty__duyu"] = "杜预",
  ["jianguo"] = "谏国",
  [":jianguo"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向下取整）；"..
  "令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）",
  ["qingshid"] = "倾势",
  [":qingshid"] = "当你于回合内使用【杀】或锦囊牌指定一名其他角色为目标后，若此牌是你本回合使用的第X张牌，你可对其中一名目标角色造成1点伤害（X为你的手牌数）",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$zhaowen-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local c = Fk:cloneCard(card.name)
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, c) and not Self:prohibitUse(c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))) then
          if mark == 0 or (not table.contains(mark, card.trueName)) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("@$zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "@$zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("#zhaowen_trigger", Player.HistoryTurn) > 0 and
      table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("#zhaowen_trigger", Player.HistoryTurn) > 0 and
      table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("zhaowen") and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen") > 0
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
    room:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player.player_cards[Player.Hand])
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.TurnEnd, fk.Death},
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
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.TurnEnd then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen", 0)
      end
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank == 0 then
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
    if player.drank == 0 then
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

  refresh_events = {fk.EventPhaseStart, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target.phase == Player.NotActive and player.drank > 0
      else
        return player:getMark(self.name) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, self.name, player.drank)
    else
      player.drank = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      room:broadcastProperty(player, "drank")
    end
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "你的【酒】效果不会因回合结束而消失。当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",
  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["@$zhaowen-turn"] = "昭文",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",
}

Fk:loadTranslationTable{
  ["goddengai"] = "神邓艾",
  ["tuoyu"] = "拓域",
  [":tuoyu"] = "锁定技，你的手牌区域添加三个未开发的副区域：<br>丰田：伤害和回复值+1；<br>清渠：无距离和次数限制；峻山：不能被响应。<br>"..
  "出牌阶段开始时和结束时，你将手牌分配至已开发的副区域中。",
  ["xianjin"] = "险进",
  [":xianjin"] = "锁定技，你每造成或受到两次伤害后开发一个手牌副区域，摸X张牌（X为你已开发的手牌副区域数，若你手牌全场最多则改为1）。",
  ["qijing"] = "奇径",
  [":qijing"] = "觉醒技，每个回合结束时，若你的手牌副区域均已开发，你减1点体力上限，将座次移动至两名其他角色之间，获得〖摧心〗并执行一个额外回合。",
  ["cuixin"] = "摧心",
  [":cuixin"] = "当你不以此法对上家/下家使用的牌结算后，你可以视为对下家/上家使用一张同名牌。",
}

return extension
