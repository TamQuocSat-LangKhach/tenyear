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
  events = {fk.EventPhaseEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 2, self.name)
    if player.dead or player:getHandcardNum() < 3 or #room.alive_players < 2 then return false end
    local tos, cards = U.askForChooseCardsAndPlayers(room, player, 3, 3,
    table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, ".", "#mingshil-give", "mingshil", false)
    player:showCards(cards)
    cards = table.filter(cards, function(id) return table.contains(player:getCardIds("h"), id) end)
    local to = room:getPlayerById(tos[1])
    if to.dead or #cards == 0 then return end
    local card = U.askforChooseCardsAndChoice(to, cards, {"OK"}, "mingshil", "#mingshil-choose", nil, 1, 1)
    room:moveCardTo(Fk:getCardById(card[1]), Card.PlayerHand, to, fk.ReasonPrey, "mingshil", nil, true, to.id)
  end,
}
local mengmou = fk.CreateTriggerSkill{
  name = "mengmou",
  anim_type = "switch",
  switch_skill_name = "mengmou",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local targets = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand then
          if move.from == player.id and move.to and move.to ~= player.id and not table.contains(targets, move.to) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.to)
                break
              end
            end
          elseif move.to == player.id and move.from and move.from ~= player.id and not table.contains(targets, move.from) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.from)
                break
              end
            end
          end
        end
      end
      local room = player.room
      targets = table.filter(targets, function (id)
        return not room:getPlayerById(id).dead
      end)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.simpleClone(self.cost_data)
    local room = player.room
    local prompt = (player:getSwitchSkillState(self.name, false) == fk.SwitchYang) and "#mengmou-yang" or "#mengmou-yin"
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, prompt.."-invoke::"..targets[1]..":"..player.maxHp) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets[1]
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, prompt.."-choose::"..targets[1]..":"..player.maxHp, self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {to.id})
    local n = player.maxHp
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local use = room:askForUseCard(to, "slash", "slash", "#mengmou-slash:::"..i..":"..n, true, { bypass_times = true })
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

mingshil:addRelatedSkill(mingshil_trigger)
tymou__lusu:addSkill(mingshil)
tymou__lusu:addSkill(mengmou)
Fk:loadTranslationTable{
  ["tymou__lusu"] = "谋鲁肃",
  ["#tymou__lusu"] = "鸿谋翼远",
  --["illustrator:tymou__lusu"] = "",
  ["mingshil"] = "明势",
  [":mingshil"] = "摸牌阶段结束时，你可以摸两张牌，然后展示三张手牌并令一名其他角色获得其中一张。",
  ["mengmou"] = "盟谋",
  [":mengmou"] = "转换技，每回合各限一次，当你获得其他角色的手牌后，或当其他角色获得你的手牌后，你可以令该角色执行（其中X为你的体力上限）：<br>"..
  "阳：使用X张【杀】，每造成1点伤害回复1点体力；<br>阴：打出X张【杀】，每少打出一张失去1点体力。",
  ["#mingshil-give"] = "明势：展示3张手牌，令1名其他角色获得其中1张",
  ["#mingshil-choose"] = "明势：获得其中一张牌",
  ["#mengmou-yang-invoke"] = "你可以发动 盟谋（阳），令 %dest 使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-invoke"] = "你可以发动 盟谋（阴），令 %dest 打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-yang-choose"] = "你可以发动 盟谋（阳），令一名角色使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-choose"] = "你可以发动 盟谋（阴），令一名角色打出%arg张【杀】，每少打出一张其失去1点体力",
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

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data.noIndicate = true
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
  [":pingliao"] = "锁定技，当你使用【杀】时，不公开指定的目标，你攻击范围内的角色依次选择是否打出一张红色基本牌，"..
  "若此【杀】的目标未打出基本牌，其本回合无法使用或打出手牌；若有至少一名非目标打出基本牌，你摸两张牌且此阶段使用【杀】的次数上限+1。",
  ["quanmou"] = "权谋",
  [":quanmou"] = "转换技，出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，"..
  "阳：防止你此阶段下次对其造成的伤害；阴：你此阶段下次对其造成伤害后，可以对至多三名该角色外的其他角色各造成1点伤害。",

  ["#pingliao-ask"] = "平辽：%src 使用了一张【杀】，你可以打出一张红色基本牌",
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

--冢虎狼顾：王凌、司马师、曹爽

local wangling = General(extension, "tymou__wangling", "wei", 4)
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
      local x = 0
      local mark = U.getMark(player, "@$jichouw")
      for _, name in ipairs(names) do
        if table.insertIfNeed(mark, name) then
          x = x + 1
        end
      end
      if x > 0 then
        room:setPlayerMark(player, "@$jichouw", mark)
      end
      room:moveCards(table.unpack(moveInfos))
      if x > 0 and not player.dead then
        player:drawCards(x, self.name)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$jichouw") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$jichouw", 0)
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
    return #U.getMark(player, "@$jichouw") > 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
  ["tymou__wangling"] = "谋王凌",
  ["#tymou__wangling"] = "风节格尚",
  ["illustrator:tymou__wangling"] = "鬼画府",

  ["jichouw"] = "集筹",
  [":jichouw"] = "出牌阶段结束时，若你于此阶段内使用过的牌的牌名各不相同，你可以将弃牌堆中的这些牌交给你选择的角色各一张。"..
  "然后你摸X张牌（X为其中此前没有以此法给出过的牌名数）。",
  ["ty__mouli"] = "谋立",
  [":ty__mouli"] = "觉醒技，回合结束时，若你因〖集筹〗给出的牌名不同的牌超过了5种，你加1点体力上限，回复1点体力，获得〖自缚〗。",
  ["ty__zifu"] = "自缚",
  [":ty__zifu"] = "锁定技，出牌阶段开始时，你将手牌摸至体力上限（至多摸至5张）。"..
  "若你因此摸牌，你保留手牌中每种牌名的牌各一张，弃置其余的牌。",

  ["#jichouw-distribution"] = "集筹：你可以将本回合使用过的牌交给每名角色各一张",
  ["jichouw_distribution"] = "集筹",
  ["@$jichouw"] = "集筹",
  ["ty__zifu_filter"] = "自缚",
  ["#ty__zifu-select"] = "自缚：选择每种牌名的牌各一张保留，弃置其余的牌",

  ["$jichouw1"] = "备武枕戈，待天下风起之时。",
  ["$jichouw2"] = "定淮联兖，邀群士共襄大义。",
  ["$ty__mouli1"] = "君上暗弱，以致受制于强臣。",
  ["$ty__mouli2"] = "吾闻楚王彪有智勇，可迎之于许都。",
  ["$ty__zifu1"] = "今势穷，吾自缚于斯，请太傅发落。",
  ["$ty__zifu2"] = "凌有罪，公劳师而来，唯系首待斩。",
  ["~tymou__wangling"] = "曹魏之盛，再难复梦……",
}

local simashi = General(extension, "tymou__simashi", "wei", 3)
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
    local handcards = player:getCardIds(Player.Hand)
    for _, cid in ipairs(cards) do
      local card = Fk:getCardById(cid)
      if table.contains(handcards, cid) and card:getMark("@@expendables-inhand") == 0 then
        room:setCardMark(card, "@@expendables-inhand", 1)
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
    local targets = table.simpleClone(self.cost_data)
    local room = player.room
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#zhenrao-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets[1]
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhenrao-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
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
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      room:setPlayerMark(player, "chenlue-turn", cards)
    end
  end,
}
local chenlue_delay = fk.CreateTriggerSkill{
  name = "#chenlue_delay",
  events = {fk.TurnEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark("chenlue-turn") == 0 then return false end
    local areas = {Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}
    local room = player.room
    local cards = table.filter(U.getMark(player, "chenlue-turn"), function (id)
      return table.contains(areas, room:getCardArea(id))
    end)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:addToPile("#chenlue", table.simpleClone(self.cost_data), true, self.name)
  end,
}
chenlue:addRelatedSkill(chenlue_delay)
simashi:addSkill(sanshi)
simashi:addSkill(zhenrao)
simashi:addSkill(chenlue)
Fk:loadTranslationTable{
  ["tymou__simashi"] = "谋司马师",
  ["#tymou__simashi"] = "唯几成务",
  ["illustrator:tymou__simashi"] = "鬼画府",

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
  ["#zhenrao-invoke"] = "是否发动 震扰，对%dest造成1点伤害",
  ["#chenlue-active"] = "发动 沉略，获得所有被标记的“死士”牌（回合结束后移出游戏）",
  ["#chenlue_delay"] = "沉略",
  ["#chenlue"] = "沉略",

  ["$sanshi1"] = "春雨润物，未觉其暖，已见其青。",
  ["$sanshi2"] = "养士效孟尝，用时可得千臂之助力。",
  ["$zhenrao1"] = "此病需静养，怎堪兵戈铁马之扰。",
  ["$zhenrao2"] = "孤值有疾，竟为文家小儿所扰。",
  ["$chenlue1"] = "怀泰山之重，必立以千仞。",
  ["$chenlue2"] = "万世之勋待取，此乃亮剑之时。",
  ["~tymou__simashi"] = "东兴之败，此我过也，诸将何罪……",
}

local caoshuang = General(extension, "tymou__caoshuang", "wei", 4)
local function doJianzhuan(player, choice, x)
  local room = player.room
  if choice == "jianzhuan1" then
    local targets = room:getOtherPlayers(player, false)
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
  mute = true,
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
      elseif event == fk.EventPhaseEnd and #choices == 0 and #all_choices > 1 then
        self.cost_data = all_choices
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, self.name)
      local choices = table.simpleClone(self.cost_data)
      local x = player:usedSkillTimes(self.name, Player.HistoryPhase)
      local choice = room:askForChoice(player, choices[1], self.name, "#jianzhuan-choice:::"..tostring(x), nil, choices[2])
      room:setPlayerMark(player, choice .. "-phase", 1)
      doJianzhuan(player, choice, x)
    else
      room:notifySkillInvoked(player, self.name, "negative")
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
    else
      if #U.getActualDamageEvents(room, 1, function (e)
        local damage = e.data[1]
        if damage.from == to and damage.to == player then
          return true
        end
      end, nil, 0) > 0 then
        table.insert(mark, data.to)
        room:setPlayerMark(player, "fudou_record", mark)
        return data.card.color == Card.Black
      else
        return data.card.color == Card.Red
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
  ["tymou__caoshuang"] = "谋曹爽",
  ["#tymou__caoshuang"] = "托孤傲臣",
  ["illustrator:tymou__caoshuang"] = "鬼画府",
  ["designer:tymou__caoshuang"] = "韩旭",

  ["jianzhuan"] = "渐专",
  [":jianzhuan"] = "锁定技，当你于出牌阶段内使用牌时，你选择于此阶段内未选择过的一项："..
  "1.令一名其他角色弃置X张牌；2.摸X张牌；3.重铸X张牌；4.弃置X张牌。"..
  "出牌阶段结束时，若选项数大于1且所有选项于此阶段内都被选择过，你随机删除一个选项。（X为你于此阶段内发动过此技能的次数）",
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
  ["$jianzhuan2"] = "吾寄百里之命，当居万丈危楼。",
  ["$fanshi1"] = "垒巨木为寨，发屯兵自守。",
  ["$fanshi2"] = "吾居伊周之位，怎可以罪见黜？",
  ["$fudou1"] = "既作困禽，何妨铤险以覆车？",
  ["$fudou2"] = "据将覆之巢，必作犹斗之困兽。",
  ["~tymou__caoshuang"] = "我度太傅之意，不欲伤我兄弟耳……",
}

local jiangji = General(extension, "tymou__jiangji", "wei", 3)
local shiju = fk.CreateTriggerSkill{
  name = "shiju",

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(self, true) or p == player end) then
      if player:hasSkill("shiju&", true, true) then
        room:handleAddLoseSkills(player, "-shiju&", nil, false, true)
      end
    else
      if not player:hasSkill("shiju&", true, true) then
        room:handleAddLoseSkills(player, "shiju&", nil, false, true)
      end
    end
  end,
}
local shiju_active = fk.CreateActiveSkill{
  name = "shiju&",
  anim_type = "support",
  prompt = "#shiju-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = U.getMark(player, "shiju_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(shiju) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(shiju) and
    not table.contains(U.getMark(Self, "shiju_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:broadcastSkillInvoke("shiju")
    local targetRecorded = U.getMark(player, "shiju_targets-phase")
    table.insertIfNeed(targetRecorded, target.id)
    room:setPlayerMark(player, "shiju_targets-phase", targetRecorded)
    local id = effect.cards[1]
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if target.dead or room:getCardArea(id) ~= Card.PlayerHand or room:getCardOwner(id) ~= target then return end
    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip then return end
    if not (target:canUseTo(card, target) and room:askForSkillInvoke(target, "shiju", nil, "#shiju-use:"..player.id.."::"..card:toLogString())) then return end
    local no_draw = table.every(target:getCardIds(Player.Equip), function (cid)
      return Fk:getCardById(cid).sub_type ~= card.sub_type
    end)
    room:useCard({
      from = target.id,
      tos = {{target.id}},
      card = card,
    })
    if not player.dead and not target.dead then
      local x = #target:getCardIds(Player.Equip)
      if x > 0 then
        x = x + player:getMark("shiju-turn")
        room:setPlayerMark(player, "shiju-turn", x)
        room:setPlayerMark(player, "@shiju-turn", "+" .. tostring(x))
      end
    end
    if no_draw then return end
    if not target.dead then
      room:drawCards(target, 2, self.name)
    end
    if not player.dead then
      room:drawCards(player, 2, self.name)
    end
  end,
}
local shiju_attackrange = fk.CreateAttackRangeSkill{
  name = "#shiju_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("shiju-turn")
  end,
}
local yingshij = fk.CreateTriggerSkill{
  name = "yingshij",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) < 2 and
    data.firstTarget and data.card:isCommonTrick() and not table.contains(data.card.skillNames, self.name) then
      local x, y = player:getMark("yingshij_used-turn"), #player:getCardIds(Player.Equip)
      if x == 2 and y == 0 then return false end
      local room = player.room
      local to
      local targets2 = {}
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
        to = room:getPlayerById(id)
        if not to.dead and (x ~= 2 or #to:getCardIds("he") >= y) then
          if to:getMark("yingshij-turn") == 0 then
            table.insert(targets2, id)
          else
            return true
          end
        end
      end)
      if #targets2 > 0 then
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event ~= nil then
          local turn_event = use_event:findParent(GameEvent.Turn)
          if turn_event ~= nil then
            local all_events = room.logic.event_recorder[GameEvent.UseCard]
            local players = {}
            for i = #all_events, 1, -1 do
              local e = all_events[i]
              if e.id <= turn_event.id then break end
              if e.id < use_event.id then
                table.insertTableIfNeed(players, TargetGroup:getRealTargets(e.data[1].tos))
              end
            end
            for _, id in ipairs(players) do
              to = room:getPlayerById(id)
              if to:getMark("yingshij-turn") == 0 then
                room:setPlayerMark(to, "yingshij-turn", 1)
                if table.removeOne(targets2, id) then
                  table.insert(targets, id)
                end
              end
            end
          end
        end
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#yingshij-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#yingshij-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local x = player:getMark("yingshij_used-turn")
    if x == 0 then
      x = #player:getCardIds(Player.Equip)
      if x > 0 and #room:askForDiscard(to, x, x, true, self.name, true, ".",
      "#yingshij-discard:" .. player.id .. "::"..tostring(x) .. ":" .. data.card:toLogString())> 0 then
        room:setPlayerMark(player, "yingshij_used-turn", 1)
        table.insertIfNeed(data.nullifiedTargets, to.id)
      else
        room:setPlayerMark(player, "yingshij_used-turn", 2)
        data.extra_data = data.extra_data or {}
        data.extra_data.yingshij = {
          from = player.id,
          to = to.id,
          subTargets = data.subTargets
        }
      end
    elseif x == 1 then
      data.extra_data = data.extra_data or {}
      data.extra_data.yingshij = {
        from = player.id,
        to = to.id,
        subTargets = data.subTargets
      }
    elseif x == 2 then
      x = #player:getCardIds(Player.Equip)
      room:askForDiscard(to, x, x, true, self.name, false, ".")
      table.insertIfNeed(data.nullifiedTargets, to.id)
    end
  end,
}
local yingshij_delay = fk.CreateTriggerSkill{
  name = "#yingshij_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.yingshij and not player.dead then
      local use = table.simpleClone(data.extra_data.yingshij)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = "yingshij"
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          self.cost_data = {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          }
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(self.cost_data))
  end,
}
Fk:addSkill(shiju_active)
shiju:addRelatedSkill(shiju_attackrange)
yingshij:addRelatedSkill(yingshij_delay)
jiangji:addSkill(shiju)
jiangji:addSkill(yingshij)
Fk:loadTranslationTable{
  ["tymou__jiangji"] = "谋蒋济",
  ["#tymou__jiangji"] = "策论万机",
  --["illustrator:tymou__jiangji"] = "",
  --["designer:tymou__jiangji"] = "",

  ["shiju"] = "势举",
  [":shiju"] = "其他角色的出牌阶段限一次，其可以将一张牌交给你，若此牌为装备牌，你可以使用之，令其攻击范围于此回合内+X（X为你装备区里的牌数），"..
  "若你于使用此牌之前的装备区里有与此牌副类别相同的牌，你与其各摸两张牌。",
  ["yingshij"] = "应时",
  [":yingshij"] = "当普通锦囊牌指定第一个目标后，若使用者为你，你可以选择一名于此牌被使用之前的当前回合内成为过牌的目标的目标角色，其选择于当前回合内未被选择过的一项："..
  "1.当此牌结算后，你视为对其使用相同牌名的牌；2.弃置X张牌（X为你装备区里的牌数），此牌对其无效。",

  ["shiju&"] = "势举",
  [":shiju&"] = "出牌阶段限一次，你可以将一张牌交给蒋济。",
  ["#shiju-active"] = "发动 势举，选择一张牌交给一名拥有“势举”的角色",
  ["#shiju-use"] = "势举：你可以使用%arg，令%src增加攻击范围",
  ["@shiju-turn"] = "势举范围",
  ["#yingshij-invoke"] = "是否对%dest发动 应时",
  ["#yingshij-choose"] = "是否发动 应时，选择一名目标角色",
  ["#yingshij-discard"] = "应时：弃置%arg张牌，令【%arg2】对你无效，或者点取消则此牌对你额外结算一次",
  ["#yingshij_delay"] = "应时",

  ["$shiju1"] = "借力为己用，可攀青云直上。",
  ["$shiju2"] = "应势而动，事半而功倍。",
  ["$yingshij1"] = "今君失道寡助，何不审时以降？",
  ["$yingshij2"] = "君既掷刀于地，可保富贵无虞。",
  ["~tymou__jiangji"] = "",
}

return extension
