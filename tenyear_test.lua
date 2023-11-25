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

--马铁 车胄 韩嵩 诸葛梦雪 诸葛若雪

local dongzhao = General(extension, "ty__dongzhao", "wei", 3)
local yijia = fk.CreateTriggerSkill{
  name = "yijia",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:distanceTo(target) <= 1 and
      table.find(player.room:getOtherPlayers(target), function(p)
        return table.find(p:getCardIds("e"), function(id)
          return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
        end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(target), function(p)
      return table.find(p:getCardIds("e"), function(id)
        return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
      end)
    end), Util.IdMapper)
    while room:askForSkillInvoke(player, self.name, nil, "#yijia-invoke::"..target.id) do
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#yijia-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = table.filter(to:getCardIds("e"), function(id)
      return #target:getAvailableEquipSlots(Fk:getCardById(id).sub_type) > 0
    end)
    local id = room:askForCardsChosen(player, target, 1, 1, {card_data = {{to.general, cards}}}, self.name, "#yijia-move::"..target.id)[1]
    local orig = table.filter(room.alive_players, function(p) return p:inMyAttackRange(target) end)
    U.moveCardIntoEquip(room, target, id, self.name, true, player)
    if player.dead or #orig == 0 then return end
    if table.find(orig, function(p) return not p:inMyAttackRange(target) end) then
      player:drawCards(1, self.name)
    end
  end,
}
local dingji = fk.CreateTriggerSkill{
  name = "dingji",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room.alive_players, function(p) return p:getHandcardNum() ~= 5 end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p) return p:getHandcardNum() ~= 5 end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#dingji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = to:getHandcardNum() - 5
    if n < 0 then
      to:drawCards(-n, self.name)
    else
      room:askForDiscard(to, n, n, false, self.name, false, ".", "#dingji-discard:::"..n)
    end
    if to.dead then return end
    to:showCards(to:getCardIds("h"))
    if to.dead or to:isKongcheng() then return end
    if table.every(player:getCardIds("h"), function(id)
      return not table.find(player:getCardIds("h"), function(id2)
        return id ~= id2 and Fk:getCardById(id).trueName == Fk:getCardById(id2).trueName
      end)
    end) then
      if not table.find(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return (card.type == Card.TypeBasic or card:isCommonTrick()) and to:canUse(card)
      end) then return end
      local success, dat = room:askForUseActiveSkill(to, "dingji_viewas", "#dingji-use", true)
      if success then
        local card = Fk.skills["dingji_viewas"]:viewAs(dat.cards)
        card.skillName = self.name
        room:useCard{
          from = target.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    end
  end,
}
local dingji_viewas = fk.CreateViewAsSkill{
  name = "dingji_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Self:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and Self:canUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "dingji"
    return card
  end,
}
Fk:addSkill(dingji_viewas)
dongzhao:addSkill(yijia)
dongzhao:addSkill(dingji)
Fk:loadTranslationTable{
  ["ty__dongzhao"] = "董昭",
  ["yijia"] = "移驾",
  [":yijia"] = "你距离1以内的角色受到伤害后，你可以将场上一张装备牌移动至其装备区（替换原装备），若其因此脱离了一名角色的攻击范围，你摸一张牌。",
  ["dingji"] = "定基",
  [":dingji"] = "准备阶段，你可以令一名角色将手牌数调整至五，然后其展示所有手牌，若牌名均不同，其可以视为使用其中一张基本牌或普通锦囊牌。",
  ["#yijia-invoke"] = "移驾：你可以将场上一张装备移至 %dest 的装备区（替换原装备）",
  ["#yijia-choose"] = "移驾：选择被移动装备的角色",
  ["#yijia-move"] = "移驾：选择移动给 %dest 的装备",
  ["#dingji-choose"] = "定基：你可以令一名角色将手牌数调整至五",
  ["#dingji-discard"] = "定基：请弃置%arg张手牌，若剩余牌牌名均不同，你可视为使用其中一张",
  ["dingji_viewas"] = "定基",
  ["#dingji-use"] = "定基：你可以视为使用手牌中一张基本牌或普通锦囊牌",
}

return extension
