local extension = Package("tenyear_yj23")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_yj23"] = "十周年-一将2023",
}

--夏侯楙 孙礼 陈式 费曜
local xiahoumao = General(extension, "xiahoumao", "wei", 4)
local tongwei = fk.CreateActiveSkill{
  name = "tongwei",
  anim_type = "control",
  card_num = 2,
  target_num = 1,
  prompt = "#tongwei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n1 = Fk:getCardById(effect.cards[1]).number
    local n2 = Fk:getCardById(effect.cards[2]).number
    room:recastCard(effect.cards, player, self.name)
    if player.dead or target.dead then return end
    if n1 > n2 then
      n1, n2 = n2, n1
    end
    room:setPlayerMark(target, "@tongwei", n1..","..n2)
    room:setPlayerMark(player, "tongwei_"..target.id, {n1, n2})
  end,
}
local tongwei_trigger = fk.CreateTriggerSkill{
  name = "#tongwei_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    return player:getMark("tongwei_"..target.id) ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n1, n2 = player:getMark("tongwei_"..target.id)[1], player:getMark("tongwei_"..target.id)[2]
    room:setPlayerMark(target, "@tongwei", 0)
    room:setPlayerMark(player, "tongwei_"..target.id, 0)
    if n1 < data.card.number and data.card.number < n2 then
      player:broadcastSkillInvoke("tongwei")
      room:notifySkillInvoked(player, "tongwei")
      local names = {"slash", "dismantlement"}
      for i = 2, 1, -1 do
        local card = Fk:cloneCard(names[i])
        if not U.canUseCardTo(room, player, target, card, false, false) then
          table.remove(names, i)
        end
      end
      if #names == 0 then return end
      local choice = room:askForChoice(player, names, "tongwei", "#tongwei-choice::"..target.id)
      room:useVirtualCard(choice, nil, player, target, "tongwei", true)
    end
  end,
}
local cuguo = fk.CreateTriggerSkill{
  name = "cuguo",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and data.from == player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForDiscard(player, 1, 1, true, self.name, false)
    if data.tos and table.find(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).dead end) then
      room:useVirtualCard(data.card.name, nil, player,
        table.map(TargetGroup:getRealTargets(data.tos), function(id) return room:getPlayerById(id) end), self.name, true)
    end
  end,
}
local cuguo_trigger = fk.CreateTriggerSkill{
  name = "#cuguo_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return data.from and data.from == player.id and table.contains(data.card.skillNames, "cuguo") and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, "cuguo")
  end,
}
tongwei:addRelatedSkill(tongwei_trigger)
cuguo:addRelatedSkill(cuguo_trigger)
xiahoumao:addSkill(tongwei)
xiahoumao:addSkill(cuguo)
Fk:loadTranslationTable{
  ["xiahoumao"] = "夏侯楙",
  ["tongwei"] = "统围",
  [":tongwei"] = "出牌阶段限一次，你可以指定一名其他角色并重铸两张牌。若如此做，其使用下一张牌结算后，若此牌点数介于你上次此法重铸牌点数之间，"..
  "你视为对其使用一张【杀】或【过河拆桥】。",
  ["cuguo"] = "蹙国",
  [":cuguo"] = "锁定技，当你每回合使用牌首次被抵消后，你需弃置一张牌，此牌对目标角色再结算一次；此牌结算后，若仍被抵消，你失去1点体力。",
  ["#tongwei"] = "统围：你可以重铸两张牌并指定一名其他角色",
  ["@tongwei"] = "统围",
  ["#tongwei-choice"] = "统围：选择视为对 %dest 使用的牌",
}

local sunli = General(extension, "sunli", "wei", 4)
local kangli = fk.CreateTriggerSkill{
  name = "kangli",
  anim_type = "masochism",
  events = {fk.Damage, fk.Damaged, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DamageCaused then
        return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
      else
        return player:hasSkill(self)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
      room:throwCard(ids, self.name, player, player)
    else
      local cards = player:drawCards(2, self.name)
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player end)
      if #cards > 0 then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@kangli-inhand", 1)
        end
      end
    end
  end,
}
sunli:addSkill(kangli)
Fk:loadTranslationTable{
  ["sunli"] = "孙礼",
  ["kangli"] = "伉厉",
  [":kangli"] = "当你造成或受到伤害后，你摸两张牌，然后你下次造成伤害时弃置这些牌。",
  ["@@kangli-inhand"] = "伉厉",
}

local chenshi = General(extension, "chenshi", "shu", 4)
local qingbei = fk.CreateTriggerSkill{
  name = "qingbei",
  anim_type = "drawcard",
  events = {fk.RoundStart, fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      elseif event == fk.CardUseFinished then
        if target == player and player:getMark("@qingbei-round") ~= 0 then
          return U.IsUsingHandcard(player, data)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.RoundStart then
      local room = player.room
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}  --妖梦佬救救QwQ
      local choices = room:askForCheck(player, suits, 1, 4, self.name, "#qingbei-choice", true)
      if #choices > 0 then
        self.cost_data = choices
        return true
      end
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    if event == fk.RoundStart then
      player.room:setPlayerMark(player, "@qingbei-round", self.cost_data)
    else
      player:drawCards(#player:getMark("@qingbei-round"), self.name)
    end
  end,
}
local qingbei_prohibit = fk.CreateProhibitSkill{
  name = "#qingbei_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@qingbei-round") ~= 0 and table.contains(player:getMark("@qingbei-round"), card:getSuitString(true))
  end,
}
qingbei:addRelatedSkill(qingbei_prohibit)
chenshi:addSkill(qingbei)
Fk:loadTranslationTable{
  ["chenshi"] = "陈式",
  ["qingbei"] = "擎北",
  [":qingbei"] = "每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张手牌后，摸本轮〖擎北〗选择过的花色数的牌。",
  ["#qingbei-choice"] = "擎北：选择你本轮不能使用的花色",
  ["@qingbei-round"] = "擎北",

  ["$qingbei1"] = "待追上那司马懿，定教他没好果子吃！",
  ["$qingbei2"] = "身若不周，吾一人可作擎北之柱。",
  ["~chenshi"] = "丞相、丞相！是魏延指使我的！",
}

local feiyao = General(extension, "feiyao", "wei", 4)
local zhenfengf = fk.CreateTriggerSkill{
  name = "zhenfengf",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and target:getHandcardNum() <= target.hp and
      not target.dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhenfengf-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 0, target:getHandcardNum(), 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(player, choices, self.name, "#zhenfengf-choice::"..target.id..":"..data.card:getTypeString())
    local n = #table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).type == data.card.type end)
    if tonumber(choice) == n then
      room:addPlayerMark(player, "@zhenfengf", 1)
      player:drawCards(math.min(player:getMark("@zhenfengf"), 5), self.name)
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    else
      room:addPlayerMark(player, "@zhenfengf", 0)
      if math.abs(tonumber(choice) - n) > 1 then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end,
}
feiyao:addSkill(zhenfengf)
Fk:loadTranslationTable{
  ["feiyao"] = "费曜",
  ["zhenfengf"] = "镇锋",
  [":zhenfengf"] = "每回合限一次，一名其他角色于其回合内使用牌时，若其手牌数不大于体力值，你可以猜测其手牌中与此牌类别相同的牌数。"..
  "若你猜对，你摸X张牌并视为对其使用一张【杀】（X为你连续猜对次数且最多为5）；若猜错且差值大于1，则视为其对你使用一张【杀】。",
  ["#zhenfengf-invoke"] = "镇锋：是否发动“镇锋”，猜测 %dest 手牌？",
  ["#zhenfengf-choice"] = "镇锋：猜测 %dest 手牌中的%arg数",
  ["@zhenfengf"] = "镇锋",
}

return extension
