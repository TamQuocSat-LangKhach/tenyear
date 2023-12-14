local extension = Package("tenyear_mou")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_mou"] = "十周年-谋定天下",
  ["tystar"] = "新服星",
}

local tymou__zhouyu = General(extension, "tymou__zhouyu", "wu", 4)
local ronghuo = fk.CreateTriggerSkill{
  name = "ronghuo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.contains({"fire_attack", "fire__slash"}, data.card.name)
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data.additionalDamage = (data.additionalDamage or 0) + #kingdoms - 1
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
        player:drawCards(to:getHandcardNum() - player:getHandcardNum(), self.name)
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
      if not src.dead then
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
  ["ronghuo"] = "熔火",
  [":ronghuo"] = "锁定技，你的【火攻】和火【杀】伤害基数值改为场上势力数。",
  ["yingmou"] = "英谋",
  [":yingmou"] = "转换技，每回合限一次，当你对其他角色使用牌结算后，你可以选择其中一名其他目标角色，阳：你将手牌摸至与其相同，然后视为对其使用"..
  "一张【火攻】；阴：令一名手牌最多的角色对其使用手牌中所有【杀】和伤害类锦囊，然后该角色（指选择的手牌最多的角色）将手牌弃至与你相同。",
  ["#yingmou_yang-invoke"] = "英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】",
  ["#yingmou_yin-invoke"] = "英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害类锦囊",
  ["#yingmou-choose"] = "英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害类锦囊",
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
}

return extension
