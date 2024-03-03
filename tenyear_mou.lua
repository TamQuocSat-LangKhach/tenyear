local extension = Package("tenyear_mou")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_mou"] = "十周年-谋定天下",
  ["tymou"] = "新服谋",
  ["tymou2"] = "新服谋",
}

--谋定天下：周瑜、鲁肃、司马懿
local tymou__zhouyu = General(extension, "tymou__zhouyu", "wu", 4)
local ronghuo = fk.CreateTriggerSkill{
  name = "ronghuo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and
    table.contains({"fire_attack", "fire__slash"}, data.card.name) then
      local room = player.room
      if not U.damageByCardEffect(room) then return false end
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      local x = #kingdoms - 1
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + self.cost_data
  end,
}
local yingmou = fk.CreateTriggerSkill{
  name = "yingmou",
  anim_type = "switch",
  switch_skill_name = "yingmou",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id and not player.room:getPlayerById(id).dead end) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).dead end)
    local prompt
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      prompt = "#yingmou_yang-invoke"
    elseif player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      prompt = "#yingmou_yin-invoke"
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      if player:getHandcardNum() < to:getHandcardNum() then
        player:drawCards(math.min(to:getHandcardNum() - player:getHandcardNum(), 5), self.name)
      end
      if not player.dead and not to.dead and not to:isKongcheng() then
        room:useVirtualCard("fire_attack", nil, player, to, self.name)
      end
    elseif player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return table.every(room.alive_players, function(p2)
          return p:getHandcardNum() >= p2:getHandcardNum()
        end)
      end), Util.IdMapper)
      if room:getPlayerById(targets[1]):getHandcardNum() == 0 then return end
      local src
      if #targets == 1 then
        src = targets[1]
      else
        src = room:askForChoosePlayers(player, targets, 1, 1, "#yingmou-choose::"..to.id, self.name, false, true)[1]
      end
      src = room:getPlayerById(src)
      local cards = table.filter(src:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
      if #cards > 0 then
        cards = table.reverse(cards)
        for i = #cards, 1, -1 do
          if src.dead or to.dead or to:isKongcheng() then
            break
          end
          if table.contains(src:getCardIds("h"), cards[i]) then
            local card = Fk:getCardById(cards[i])
            if not src:isProhibited(to, card) then
              room:useCard({
                from = src.id,
                tos = {{to.id}},
                card = card,
                extraUse = true,
              })
            end
          end
        end
      else
        local n = src:getHandcardNum() - player:getHandcardNum()
        if n > 0 then
          room:askForDiscard(src, n, n, false, self.name, false)
        end
      end
    end
  end,
}
tymou__zhouyu:addSkill(ronghuo)
tymou__zhouyu:addSkill(yingmou)
Fk:loadTranslationTable{
  ["tymou__zhouyu"] = "谋周瑜",
  ["#tymou__zhouyu"] = "炽谋英隽",
  --["illustrator:tymou__zhouyu"] = "",
  ["ronghuo"] = "融火",
  [":ronghuo"] = "锁定技，当你因执行火【杀】或【火攻】的效果而对一名角色造成伤害时，你令伤害值+X（X为势力数-1）。",
  ["yingmou"] = "英谋",
  [":yingmou"] = "转换技，每回合限一次，当你对其他角色使用牌结算后，你可以选择其中一个目标角色，阳：你将手牌摸至与其相同（至多摸五张），然后视为对其使用"..
  "一张【火攻】；阴：令一名手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌，若没有则将手牌弃至与你相同。",
  ["#yingmou_yang-invoke"] = "英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】",
  ["#yingmou_yin-invoke"] = "英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌",
  ["#yingmou-choose"] = "英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害锦囊牌",

  ["$ronghuo1"] = "火莲绽江矶，炎映三千弱水。",
  ["$ronghuo2"] = "奇志吞樯橹，潮平百万寇贼。",
  ["$yingmou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
  ["$yingmou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
  ["~tymou__zhouyu"] = "人生之艰难，犹如不息之长河……",
}

local tymou__lusu = General(extension, "tymou__lusu", "wu", 3)
local mingshil = fk.CreateTriggerSkill{
  name = "mingshil",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local mingshil_trigger = fk.CreateTriggerSkill{
  name = "#mingshil_trigger",
  events = {fk.AfterDrawNCards},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("mingshil", Player.HistoryPhase) > 0 and player:getHandcardNum() > 2 and
      table.find(player.room:getOtherPlayers(player), function(p) return not p.dead end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "mingshil_active", "#mingshil-give", false)
    local to, cards
    if success then
      to = room:getPlayerById(dat.targets[1])
      cards = dat.cards
    else
      to = table.random(room:getOtherPlayers(player))
      cards = table.random(player:getCardIds("h"), 3)
    end
    player:showCards(cards)
    cards = table.filter(cards, function(id) return table.contains(player:getCardIds("h"), id) end)
    if to.dead or #cards == 0 then return end
    local card = U.askforChooseCardsAndChoice(to, cards, {"OK"}, "mingshil", "#mingshil-choose", nil, 1, 1)
    room:moveCardTo(Fk:getCardById(card[1]), Card.PlayerHand, to, fk.ReasonPrey, "mingshil", nil, true, to.id)
  end,
}
local mingshil_active = fk.CreateActiveSkill{
  name = "mingshil_active",
  card_num = 3,
  target_num = 1,
  card_filter  = function (self, to_select, selected)
    return #selected < 3 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter  = function (self, to_select, selected, selected_cards, card)
    return #selected == 0 and to_select ~= Self.id
  end,
}
local mengmou = fk.CreateTriggerSkill{
  name = "mengmou",
  anim_type = "switch",
  switch_skill_name = "mengmou",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and player:getMark("mengmou1-turn") == 0 and move.to and not player.room:getPlayerById(move.to).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        elseif move.to == player.id and player:getMark("mengmou2-turn") == 0 and move.from and not player.room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local dat = {}
    for _, move in ipairs(data) do
      if move.from == player.id and player:getMark("mengmou1-turn") == 0 and move.to and not player.room:getPlayerById(move.to).dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            dat = {move.to, "mengmou1-turn"}
          end
        end
      elseif move.to == player.id and player:getMark("mengmou2-turn") == 0 and move.from and not player.room:getPlayerById(move.from).dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            dat = {move.from, "mengmou2-turn"}
          end
        end
      end
    end
    self:doCost(event, nil, player, dat)
  end,
  on_cost = function(self, event, target, player, data)
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return player.room:askForSkillInvoke(player, self.name, nil, "#mengmou-yang::"..data[1]..":"..player.hp)
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#mengmou-yin::"..data[1]..":"..player.hp)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data[1])
    room:setPlayerMark(player, data[2], 1)
    room:doIndicate(player.id, {to.id})
    local n = player.hp
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        room:setPlayerMark(to, MarkEnum.BypassTimesLimit.."tmp", 1)
        local use = room:askForUseCard(to, "slash", "slash", "#mengmou-slash:::"..i..":"..n, true)
        room:setPlayerMark(to, MarkEnum.BypassTimesLimit.."tmp", 0)
        if use then
          use.extraUse = true
          room:useCard(use)
          if use.damageDealt then
            for _, p in ipairs(room.players) do
              if use.damageDealt[p.id] then
                count = count + use.damageDealt[p.id]
              end
            end
          end
        else
          break
        end
      end
      if not to.dead and to:isWounded() and count > 0 then
        room:recover({
          who = to,
          num = math.min(to:getLostHp(), count),
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local cardResponded = room:askForResponse(to, "slash", "slash", "#mengmou-ask:::"..i..":"..n, false)
        if cardResponded then
          count = i
          room:responseCard({
            from = to.id,
            card = cardResponded,
          })
        else
          break
        end
      end
      if not to.dead and n > count then
        room:loseHp(to, n - count, self.name)
      end
    end
  end,
}
Fk:addSkill(mingshil_active)
mingshil:addRelatedSkill(mingshil_trigger)
tymou__lusu:addSkill(mingshil)
tymou__lusu:addSkill(mengmou)
Fk:loadTranslationTable{
  ["tymou__lusu"] = "谋鲁肃",
  ["#tymou__lusu"] = "鸿谋翼远",
  --["illustrator:tymou__lusu"] = "",
  ["mingshil"] = "明势",
  [":mingshil"] = "摸牌阶段，你可以多摸两张牌，然后展示三张手牌并令一名其他角色获得其中一张。",
  ["mengmou"] = "盟谋",
  [":mengmou"] = "转换技，每回合各限一次，当你获得其他角色的手牌后，或当其他角色获得你的手牌后，你可以令该角色执行（其中X为你的体力值）：<br>"..
  "阳：使用X张【杀】，每造成1点伤害回复1点体力；<br>阴：打出X张【杀】，每少打出一张失去1点体力。",
  ["mingshil_active"] = "明势",
  ["#mingshil-give"] = "明势：展示三张手牌，令一名其他角色获得其中一张",
  ["#mingshil-choose"] = "明势：获得其中一张牌",
  ["#mengmou-yang"] = "盟谋：你可以令 %dest 使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin"] = "盟谋：你可以令 %dest 打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-slash"] = "盟谋：你可以连续使用【杀】，造成伤害后你回复体力（第%arg张，共%arg2张）",
  ["#mengmou-ask"] = "盟谋：你需连续打出【杀】，每少打出一张你失去1点体力（第%arg张，共%arg2张）",

  ["$mingshil1"] = "联刘以抗曹，此可行之大势。",
  ["$mingshil2"] = "强敌在北，唯协力可御之。",
  ["$mengmou1"] = "合左抑右，定两家之盟。",
  ["$mengmou2"] = "求同存异，邀英雄问鼎。",
  ["~tymou__lusu"] = "虎可为之用，亦可为之伤……",
}


local tymou__simayi = General(extension, "tymou__simayi", "wei", 3)
local pingliao = fk.CreateTriggerSkill{
  name = "pingliao",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return player:inMyAttackRange(p)
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local tos = TargetGroup:getRealTargets(data.tos)
    local drawcard = false
    local targets2 = {}
    for _, p in ipairs(targets) do
      local card = room:askForResponse(p, self.name, ".|.|heart,diamond|.|.|basic", "#pingliao-ask:" .. player.id, true)
      if card then
        room:responseCard{
          from = p.id,
          card = card
        }
        if not table.contains(tos, p.id) then
          drawcard = true
        end
      elseif table.contains(tos, p.id) then
        table.insert(targets2, p)
      end
    end
    for _, p in ipairs(targets2) do
      room:setPlayerMark(p, "@@pingliao-turn", 1)
    end
    if player.dead then return false end
    if drawcard then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
    end
  end,
}
local pingliao_prohibit = fk.CreateProhibitSkill{
  name = "#pingliao_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@pingliao-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
local quanmou = fk.CreateActiveSkill{
  name = "quanmou",
  anim_type = "switch",
  switch_skill_name = "quanmou",
  card_num = 0,
  target_num = 1,
  prompt = function ()
    return Self:getSwitchSkillState("quanmou", false) == fk.SwitchYang and "#quanmou-Yang" or "#quanmou-Yin"
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and not table.contains(U.getMark(Self, "quanmou_targets-phase"), to_select) then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not target:isNude() and Self:inMyAttackRange(target)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "quanmou_targets-phase")
    table.insert(mark, target.id)
    room:setPlayerMark(player, "quanmou_targets-phase", mark)

    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang
    local from_name = "tymou__simayi"
    local to_name = "tymou__simayi"
    if isYang then
      to_name = "tymou2__simayi"
    else
      from_name = "tymou2__simayi"
    end
    if player.general == from_name then
      player.general = to_name
      room:broadcastProperty(player, "general")
    end
    if player.deputyGeneral == from_name then
      player.deputyGeneral = to_name
      room:broadcastProperty(player, "deputyGeneral")
    end

    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#quanmou-give::"..player.id)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
    if player.dead or target.dead then return false end
    room:setPlayerMark(target, "@quanmou-phase", isYang and "yang" or "yin")
    local mark_name = "quanmou_" .. (isYang and "yang" or "yin") .. "-phase"
    mark = U.getMark(player, mark_name)
    table.insert(mark, target.id)
    room:setPlayerMark(player, mark_name, mark)
  end,
}
local quanmou_delay = fk.CreateTriggerSkill{
  name = "#quanmou_delay",
  events = {fk.DamageCaused, fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or player.phase ~= Player.Play or player ~= target then return false end
    if event == fk.DamageCaused then
      return table.contains(U.getMark(player, "quanmou_yang-phase"), data.to.id)
    elseif event == fk.Damage then
      return table.contains(U.getMark(player, "quanmou_yin-phase"), data.to.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    if event == fk.DamageCaused then
      local mark = U.getMark(player, "quanmou_yang-phase")
      table.removeOne(mark, data.to.id)
      room:setPlayerMark(player, "quanmou_yang-phase", mark)
      room:notifySkillInvoked(player, "quanmou", "defensive")
      if player:getSwitchSkillState("quanmou", false) == fk.SwitchYang then
        player:broadcastSkillInvoke("quanmou")
      end
      return true
    elseif event == fk.Damage then
      local mark = U.getMark(player, "quanmou_yin-phase")
      table.removeOne(mark, data.to.id)
      room:setPlayerMark(player, "quanmou_yin-phase", mark)
      room:notifySkillInvoked(player, "quanmou", "offensive")
      if player:getSwitchSkillState("quanmou", false) == fk.SwitchYin then
        player:broadcastSkillInvoke("quanmou")
      end
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and p ~= data.to
      end)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 3, "#quanmou-damage", "quanmou")
      if #targets == 0 then return false end
      room:sortPlayersByAction(targets)
      for _, id in ipairs(targets) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = "quanmou",
          }
        end
      end
    end
  end,
}
pingliao:addRelatedSkill(pingliao_prohibit)
quanmou:addRelatedSkill(quanmou_delay)
tymou__simayi:addSkill(pingliao)
tymou__simayi:addSkill(quanmou)

local tymou2__simayi = General(extension, "tymou2__simayi", "wei", 3)
tymou2__simayi.hidden = true
tymou2__simayi:addSkill("pingliao")
tymou2__simayi:addSkill("quanmou")

Fk:loadTranslationTable{
  ["tymou__simayi"] = "谋司马懿",
  ["#tymou__simayi"] = "韬谋韫势",
  ["illustrator:tymou__simayi"] = "米糊PU",
  ["pingliao"] = "平辽",
  [":pingliao"] = "锁定技，<font color='red'>当你使用【杀】指定目标时，不公开指定的目标（暂时无法生效）。</font>"..
  "你攻击范围内的其他角色依次选择是否打出一张红色基本牌。"..
  "若此【杀】的目标未打出基本牌，其本回合无法使用或打出手牌；若有至少一名非目标打出基本牌，你摸两张牌且此阶段使用【杀】的次数上限+1。",
  ["quanmou"] = "权谋",
  [":quanmou"] = "转换技，出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，"..
  "阳：防止你此阶段下次对其造成的伤害；阴：你此阶段下次对其造成伤害后，可以对至多三名该角色外的其他角色各造成1点伤害。",

  ["#pingliao-ask"] = "平辽：%from 使用了一张【杀】，你可以打出一张红色基本牌",
  ["@@pingliao-turn"] = "平辽",
  ["#quanmou-Yang"] = "发动 权谋（阳），选择攻击范围内的一名角色",
  ["#quanmou-Yin"] = "发动 权谋（阴），选择攻击范围内的一名角色",
  ["#quanmou-give"] = "权谋：选择一张牌交给 %dest ",
  ["@quanmou-phase"] = "权谋",
  ["#quanmou_delay"] = "权谋",
  ["#quanmou-damage"] = "权谋：你可以选择1-3名角色，对这些角色各造成1点伤害",

  --阳形态
  ["$pingliao1"] = "烽烟起大荒，戎军远役，问不臣者谁？",
  ["$pingliao2"] = "挥斥千军之贲，长驱万里之远。",
  ["$quanmou1"] = "洛水为誓，皇天为证，吾意不在刀兵。",
  ["$quanmou2"] = "以谋代战，攻形不以力，攻心不以勇。",
  ["~tymou__simayi"] = "以权谋而立者，必失大义于千秋……",

  --阴形态
  ["tymou2__simayi"] = "谋司马懿",
  ["#tymou2__simayi"] = "韬谋韫势",
  ["illustrator:tymou2__simayi"] = "鬼画府",
  ["$pingliao_tymou2__simayi1"] = "率土之滨皆为王臣，辽土亦居普天之下。",
  ["$pingliao_tymou2__simayi2"] = "青云远上，寒锋试刃，北雁当寄红翎。",
  ["$quanmou_tymou2__simayi1"] = "鸿门之宴虽歇，会稽之胆尚悬，孤岂姬、项之辈？",
  ["$quanmou_tymou2__simayi2"] = "昔藏青锋于沧海，今潮落，可现兵！",
  ["~tymou2__simayi"] = "人立中流，非已力可向，实大势所迫……",
}

--冢虎狼顾：曹爽
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
  ["#ty__caoshuang"] = "托孤傲臣",
  ["illustrator:ty__caoshuang"] = "鬼画府",

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
