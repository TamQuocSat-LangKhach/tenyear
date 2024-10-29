local extension = Package("tenyear_yj23")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_yj23"] = "十周年-一将2023",
}

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
        if not player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) then
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
    and #TargetGroup:getRealTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForDiscard(player, 1, 1, true, self.name, false)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_to = data.to
    end
  end,
}
local cuguo_trigger = fk.CreateTriggerSkill{
  name = "#cuguo_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if data.from and data.from == player.id and not player.dead then
      if (data.extra_data or {}).cuguo_to then
        return true
      elseif table.contains(data.card.skillNames, "cuguo") then
        return (data.extra_data or {}).cuguo_negative
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (data.extra_data or {}).cuguo_to then
      local to = room:getPlayerById(data.extra_data.cuguo_to)
      if not to.dead then
        room:useVirtualCard(data.card.name, nil, player, to, "cuguo", true)
      end
    else
      room:loseHp(player, 1, "cuguo")
    end
  end,

  refresh_events = {fk.CardEffectCancelledOut},
  can_refresh = function (self, event, target, player, data)
    return data.from == player.id and table.contains(data.card.skillNames, "cuguo")
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_negative = true
    end
  end,
}
tongwei:addRelatedSkill(tongwei_trigger)
cuguo:addRelatedSkill(cuguo_trigger)
xiahoumao:addSkill(tongwei)
xiahoumao:addSkill(cuguo)
Fk:loadTranslationTable{
  ["xiahoumao"] = "夏侯楙",
  ["#xiahoumao"] = "束甲之鸟",
  ["designer:xiahoumao"] = "伯约的崛起",
  ["tongwei"] = "统围",
  [":tongwei"] = "出牌阶段限一次，你可以指定一名其他角色并重铸两张牌。若如此做，其使用下一张牌结算后，若此牌点数介于你上次此法重铸牌点数之间，"..
  "你视为对其使用一张【杀】或【过河拆桥】。",
  ["cuguo"] = "蹙国",
  [":cuguo"] = "锁定技，当你对一名角色使用的牌被抵消后，若你本回合未发动此技能，你须弃置一张牌，令你于此牌结算后视为对该角色使用一张牌名相同的牌，若此牌仍被抵消，你失去1点体力。",
  ["#tongwei"] = "统围：你可以重铸两张牌并指定一名其他角色",
  ["@tongwei"] = "统围",
  ["#tongwei_trigger"] = "统围",
  ["#tongwei-choice"] = "统围：选择视为对 %dest 使用的牌",

  ["$tongwei1"] = "今统虎贲十万，必困金龙于斯。",
  ["$tongwei2"] = "昔年将军七出长坂，今尚能饭否？",
  ["$cuguo1"] = "本欲开疆拓土，奈何丧师辱国。",
  ["$cuguo2"] = "千里锦绣之地，皆亡逆贼之手。",
  ["~xiahoumao"] = "志大才疏，以致今日之祸……",
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
  on_cost = function (self, event, target, player, data)
    return (event == fk.DamageCaused) or player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
      room:throwCard(ids, self.name, player, player)
    else
      player:drawCards(2, self.name, nil, "@@kangli-inhand")
    end
  end,
}
sunli:addSkill(kangli)
Fk:loadTranslationTable{
  ["sunli"] = "孙礼",
  ["#sunli"] = "百炼公才",
  ["designer:sunli"] = "老酒馆的猫",
  ["illustrator:sunli"] = "错落宇宙",

  ["kangli"] = "伉厉",
  [":kangli"] = "当你造成或受到伤害后，你可以摸两张牌，然后你下次造成伤害时弃置这些牌。",
  ["@@kangli-inhand"] = "伉厉",

  ["$kangli1"] = "地界纷争皋陶难断，然图藏天府，坐上可明。",
  ["$kangli2"] = "正至歉岁，难征百姓于役，望陛下明鉴。",
  ["~sunli"] = "国无矩不立，何谓之方圆……",
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
        if target == player and data.card.suit ~= Card.NoSuit and player:getMark("@qingbei-round") ~= 0 then
          return U.IsUsingHandcard(player, data)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.RoundStart then
      local room = player.room
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
      local choices = room:askForChoices(player, suits, 1, 4, self.name, "#qingbei-choice", true)
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
  ["#chenshi"] = "裨将可期",
  ["designer:chenshi"] = "绯瞳",
  ["illustrator:chenshi"] = "游漫美绘",

  ["qingbei"] = "擎北",
  [":qingbei"] = "每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张有花色的手牌后，摸本轮〖擎北〗选择过的花色数的牌。",
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
      room:setPlayerMark(player, "@zhenfengf", 0)
      if math.abs(tonumber(choice) - n) > 1 then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end,
}
feiyao:addSkill(zhenfengf)
Fk:loadTranslationTable{
  ["feiyao"] = "费曜",
  ["#feiyao"] = "后将军",
  ["designer:feiyao"] = "米陶诺斯",
  ["illustrator:feiyao"] = "青雨",
  ["zhenfengf"] = "镇锋",
  [":zhenfengf"] = "每回合限一次，一名其他角色于其回合内使用牌时，若其手牌数不大于体力值，你可以猜测其手牌中与此牌类别相同的牌数。"..
  "若你猜对，你摸X张牌并视为对其使用一张【杀】（X为你连续猜对次数且最多为5）；若猜错且差值大于1，则视为其对你使用一张【杀】。",
  ["#zhenfengf-invoke"] = "镇锋：是否发动“镇锋”，猜测 %dest 手牌？",
  ["#zhenfengf-choice"] = "镇锋：猜测 %dest 手牌中的%arg数",
  ["@zhenfengf"] = "镇锋",

  ["$zhenfengf1"] = "河西诸贼作乱，吾当驱万里之远。",
  ["$zhenfengf2"] = "可折诸葛之锋而御者，独我其谁！",
  ["~feiyao"] = "姜维！你果然是蜀军内应！",
}

local xuangongzhu = General(extension, "ty__xuangongzhu", "wei", 3, 3, General.Female)
local ty__qimei = fk.CreateActiveSkill{
  name = "ty__qimei",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  prompt = "#ty__qimei-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 or
      (player:getMark("ty__qimei-phase") > 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 1)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:drawCards(2, self.name)
    if not target.dead then
      target:drawCards(2, self.name)
    end
    local cards = {}
    if not player.dead and not player:isNude() then
      local c = room:askForDiscard(player, 2, 2, true, self.name, false)
      table.insertTableIfNeed(cards, c)
    end
    if not target.dead and not target:isNude() then
      local c = room:askForDiscard(target, 2, 2, true, self.name, false)
      table.insertTableIfNeed(cards, c)
    end
    if #cards == 0 then return end
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    if #suits == 1 then
      cards = table.filter(cards, function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      while not player.dead and #cards > 0 do
        local use = U.askForUseRealCard(room, player, cards, ".", self.name, "#ty__qimei-use",
          {expand_pile = cards, bypass_times = false, extraUse = true}, true)
        if use then
          table.removeOne(cards, use.card:getEffectiveId())
          room:useCard(use)
        else
          return
        end
      end
    elseif #suits == 2 then
      if not player.dead then
        player:reset()
      end
      if not target.dead then
        target:reset()
      end
    elseif #suits == 3 then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
    elseif #suits == 4 then
      if not player.dead then
        player:drawCards(1, self.name)
        room:setPlayerMark(player, "ty__qimei-phase", 1)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,
}
local ty__zhuijix = fk.CreateTriggerSkill{
  name = "ty__zhuijix",
  anim_type = "support",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
      "#ty__zhuijix-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local subtype
    while not to.dead do
      while #subtypes > 0 do
        subtype = table.remove(subtypes, 1)
        if to:hasEmptyEquipSlot(subtype) then
          local cards = {}
          local card
          cards = table.filter(room.draw_pile, function(id)
            card = Fk:getCardById(id)
            return card.sub_type == subtype and U.canUseCardTo(room, to, to, card)
          end)
          for _, id in ipairs(room.discard_pile) do
            card = Fk:getCardById(id)
            if card.sub_type == subtype and U.canUseCardTo(room, to, to, card) then
              table.insert(cards, id)
            end
          end
          if #cards > 0 then
            card = cards[math.random(1, #cards)]
            local mark = to:getTableMark(self.name)
            table.insert(mark, card)
            room:setPlayerMark(to, self.name, mark)
            room:useCard{
              from = to.id,
              card = Fk:getCardById(card),
            }
            break
          end
        end
      end
      if #subtypes == 0 then break end
    end
  end,
}
local ty__zhuijix_delay = fk.CreateTriggerSkill{
  name = "#ty__zhuijix_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("ty__zhuijix") ~= 0 and not player.dead then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and table.contains(player:getTableMark("ty__zhuijix"), info.cardId) and
              #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
              local e = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
              if e and e.data[3] == self then  --FIXME：防止顶替装备时重复触发
                return false
              end
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
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and table.contains(player:getTableMark("ty__zhuijix"), info.cardId) and
            #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
            local mark = player:getTableMark("ty__zhuijix")
            table.removeOne(mark, info.cardId)
            room:setPlayerMark(player, "ty__zhuijix", mark)
            room:abortPlayerArea(player, {Util.convertSubtypeAndEquipSlot(Fk:getCardById(info.cardId).sub_type)})
          end
        end
      end
    end
  end,
}
ty__zhuijix:addRelatedSkill(ty__zhuijix_delay)
xuangongzhu:addSkill(ty__qimei)
xuangongzhu:addSkill(ty__zhuijix)
Fk:loadTranslationTable{
  ["ty__xuangongzhu"] = "宣公主",
  --["#ty__xuangongzhu"] = "",
  ["designer:ty__xuangongzhu"] = "谜城惊雨声",
  ["ty__qimei"] = "齐眉",
  [":ty__qimei"] = "出牌阶段限一次，你可以选择一名其他角色，你与其各摸两张牌并各弃置两张牌，根据弃置牌的花色数，你执行以下效果：<br>"..
  "1，你可以依次使用这些牌；<br>2，你与其复原武将牌；<br>3，你与其横置；<br>4，你与其各摸一张牌，然后本回合此技能改为“限两次”。",
  ["ty__zhuijix"] = "追姬",
  [":ty__zhuijix"] = "当你死亡后，你可以令一名角色从牌堆和弃牌堆中随机使用有空余栏位的装备牌，直至其装备区满，若如此做，当其失去以此法使用的"..
  "装备牌后，废除对应的装备栏。",
  ["#ty__qimei-active"] = "齐眉：与一名角色各摸两张牌然后弃两张牌，根据弃牌花色数执行效果",
  ["#ty__qimei-use"] = "齐眉：你可以使用这些牌",
  ["#ty__zhuijix-choose"] = "追姬：你可以令一名角色随机使用装备牌至装备区满",
  ["#ty__zhuijix_delay"] = "追姬",
}

local linghuyu = General(extension, "linghuyu", "wei", 4)
local xuzhi = fk.CreateActiveSkill{
  name = "xuzhi",
  anim_type = "support",
  card_num = 0,
  target_num = 2,
  prompt = "#xuzhi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("xuzhi_times-phase")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() and
      Fk:currentRoom():getPlayerById(to_select):getMark("xuzhi-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    room:setPlayerMark(targets[1], "xuzhi-phase", 1)
    room:setPlayerMark(targets[2], "xuzhi-phase", 1)
    local result = U.askForJointCard(targets, 1, 999, false, self.name, false, nil, "#xuzhi-card")
    U.swapCards(room, player, targets[1], targets[2], result[effect.tos[1]], result[effect.tos[2]], self.name)
    local n1, n2 = #result[effect.tos[1]], #result[effect.tos[2]]
    if n1 == n2 then
      if player.dead then return end
      room:addPlayerMark(player, "xuzhi_times-phase")
      player:drawCards(2, self.name)
    else
      local to = n2 > n1 and targets[2] or targets[1]
      if to.dead then return end
      U.askForUseVirtualCard(room, to, "slash", {}, self.name, "#xuzhi-use", true, true, true, true)
    end
  end,
}
linghuyu:addSkill(xuzhi)
Fk:loadTranslationTable{
  ["linghuyu"] = "令狐愚",
  ["#linghuyu"] = "名愚性浚",
  ["designer:linghuyu"] = "浮兮璃璃",
  ["illustrator:linghuyu"] = "钟於",
  ["~linghuyu"] = "咳咳，我欲谋大事，奈何命不由己。",

  ["xuzhi"] = "蓄志",
  [":xuzhi"] = "出牌阶段限一次，你可以令两名角色同时选择至少一张手牌并交换这些牌，获得牌数较少的角色视为使用一张无距离限制的【杀】；"..
  "若获得牌数相等，你摸两张牌，且可以对本阶段未以此法选择过的角色再发动〖蓄志〗。",
  ["#xuzhi-active"] = "蓄志：选择两名角色，令他们同时选择至少一张手牌并交换",
  ["#xuzhi-card"] = "蓄志：选择至少一张手牌进行交换",
  ["#xuzhi-use"] = "蓄志：你可以视为使用一张无距离限制的【杀】",

  ["$xuzhi1"] = "鹿复现于野，孰不可射乎？",
  ["$xuzhi2"] = "天下之士合纵，欲复攻于秦。",
}

local xukun = General(extension, "xukun", "wu", 4)
local fazhu = fk.CreateTriggerSkill{
  name = "fazhu",
  events = {fk.EventPhaseStart},
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player:getCardIds("hej"), function(id)
        return not Fk:getCardById(id).is_damage_card
      end)
  end,
  on_cost = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fazhu_cards", player:getCardIds("j"))
    local success, dat = player.room:askForUseActiveSkill(player, "fazhu_active", "#fazhu-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data.cards
    if #cards == 0 then return end
    local to_give = room:recastCard(cards, player, self.name)
    to_give = table.filter(to_give, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    local result = room:askForYiji(player, to_give, room.alive_players, self.name, 0, #to_give, "#fazhu-give", "", false, 1)
    local targets = {}
    if table.find(to_give, function (id)
      return table.contains(player:getCardIds("h"), id)
    end) then
      table.insert(targets, player)
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #result[tostring(p.id)] > 0 then
        table.insert(targets, p)
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = room:askForUseCard(p, "slash", "slash", "#fazhu-use", true, {bypass_distances = true, bypass_times = true})
        if use then
          use.extraUse = true
          room:useCard(use)
        end
      end
    end
  end,
}
local fazhu_active = fk.CreateActiveSkill{
  name = "fazhu_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  expand_pile = function(self)
    return Self:getTableMark("fazhu_cards")
  end,
  card_filter = function(self, to_select, selected)
    return not Fk:getCardById(to_select).is_damage_card
  end,
}
Fk:addSkill(fazhu_active)
xukun:addSkill(fazhu)
Fk:loadTranslationTable{
  ["xukun"] = "徐琨",
  ["#xukun"] = "平虏击逆",
  ["designer:xukun"] = "卤香蛋2",
  ["illustrator:xukun"] = "君桓文化",
  ["fazhu"] = "筏铸",
  [":fazhu"] = "准备阶段，你可以重铸你区域内任意张非伤害牌，然后将因此获得的牌交给至多等量名角色各一张，以此法获得牌的角色可以依次使用一张"..
  "【杀】（无距离限制）。",
  ["fazhu_active"] = "筏铸",
  ["#fazhu-invoke"] = "筏铸：你可以重铸任意张非伤害牌，将获得的牌分配给任意角色",
  ["#fazhu-give"] = "筏铸：你可以将这些牌分配给任意角色各一张，获得牌的角色可以使用一张无距离限制的【杀】",
  ["#fazhu-use"] = "筏铸：你可以使用一张【杀】（无距离限制）",

  ["$fazhu1"] = "击风雨于共济，逆流亦溯千帆。",
  ["$fazhu2"] = "泰山轻于大义，每思志士、何惧临渊。",
  ["~xukun"] = "何处……射来的流矢……",
}

local simafu = General(extension, "ty__simafu", "wei", 4)
simafu.subkingdom = "jin"
local beiyu = fk.CreateActiveSkill{
  name = "beiyu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#beiyu-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getHandcardNum() < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    if player.dead or player:isKongcheng() then return end
    local choices = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(choices, Fk:getCardById(id):getSuitString(true))
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#beiyu-choose", false,
      {"log_spade", "log_heart", "log_club", "log_diamond"})
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getSuitString(true) == choice
    end)
    if #cards == 1 then
      room:moveCards({
        ids = cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
        drawPilePosition = -1,
      })
    else
      local result = room:askForGuanxing(player, cards, {}, {0, 0}, self.name, true, {"$Hand", ""})
      room:moveCards({
        ids = result.top,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
        drawPilePosition = -1,
      })
    end
  end,
}
local duchi = fk.CreateTriggerSkill{
  name = "duchi",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      data.from ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name, "bottom")
    if player.dead or player:isKongcheng() then return end
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if player.dead or player:isKongcheng() then return end
    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color or
      Fk:getCardById(id).color == Card.NoColor
    end) then
      table.insertIfNeed(data.nullifiedTargets, player.id)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      end
    end
  end,
}
simafu:addSkill(beiyu)
simafu:addSkill(duchi)
Fk:loadTranslationTable{
  ["ty__simafu"] = "司马孚",
  ["#ty__simafu"] = "仁孝忠德",
  ["designer:ty__simafu"] = "坑坑",

  ["beiyu"] = "备预",
  [":beiyu"] = "出牌阶段限一次，你可以将手牌摸至体力上限，然后将一种花色的所有手牌以任意顺序置于牌堆底。",
  ["duchi"] = "督持",
  [":duchi"] = "每回合限一次，当你成为其他角色使用牌的目标后，你可以从牌堆底摸一张牌并展示所有手牌，若颜色均相同，此牌对你无效。",
  ["#beiyu-active"] = "备预：将手牌摸至体力上限，然后将一种花色的手牌置于牌堆底",
  ["#beiyu-choose"] = "备预：选择一种花色，将所有此花色的手牌置于牌堆底",
}

return extension
