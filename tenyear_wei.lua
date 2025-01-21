local extension = Package("tenyear_wei")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_wei"] = "十周年-威",
  ["ty_wei"] = "威",
}

local zhangliao = General(extension, "ty_wei__zhangliao", "qun", 4)
local yuxi = fk.CreateTriggerSkill{
  name = "yuxi",
  anim_type = "drawcard",
  events = {fk.DamageCaused, fk.DamageInflicted},
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name, nil, "@@yuxi-inhand")
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@yuxi-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
}
local yuxi_targetmod = fk.CreateTargetModSkill{
  name = "#yuxi_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@yuxi-inhand") > 0
  end,
}
local porong = fk.CreateTriggerSkill{
  name = "porong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[self.name]  --先随便弄个记录，之后再改
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#porong-invoke")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    data.additionalEffect = (data.additionalEffect or 0) + 1
    local targets = {}
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      if p:getLastAlive() ~= player then
        table.insert(targets, p:getLastAlive().id)
      end
      if p ~= player then
        table.insert(targets, p.id)
      end
      if p:getNextAlive() ~= player then
        table.insert(targets, p:getNextAlive().id)
      end
    end
    if #targets == 0 then return end
    room:doIndicate(player.id, targets)
    for _, id in ipairs(targets) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p:isKongcheng() then
        local card = room:askForCardChosen(player, p, "h", self.name, "#porong-prey::"..p.id)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card then
      if player:getMark(self.name) > 0 and data.card.trueName == "slash" then
        data.extra_data = data.extra_data or {}
        data.extra_data.combo_skill = data.extra_data.combo_skill or {}
        data.extra_data.combo_skill[self.name] = true
      else
        room:setPlayerMark(player, self.name, 1)
      end
    else
      room:setPlayerMark(player, self.name, 0)
    end
  end,
}
yuxi:addRelatedSkill(yuxi_targetmod)
zhangliao:addSkill(yuxi)
zhangliao:addSkill(porong)
Fk:loadTranslationTable{
  ["ty_wei__zhangliao"] = "威张辽",
  ["#ty_wei__zhangliao"] = "威锐镇西风",
  ["illustrator:ty_wei__zhangliao"] = "鬼画府",

  ["yuxi"] = "驭袭",
  [":yuxi"] = "你造成或受到伤害时，摸一张牌，以此法获得的牌无次数限制。",
  ["porong"] = "破戎",
  [":porong"] = "连招技（伤害牌+【杀】），你可以获得此【杀】目标和其相邻角色各一张手牌，并令此【杀】额外结算一次。",
  ["@@yuxi-inhand"] = "驭袭",
  ["#porong-invoke"] = "破戎：是否令此【杀】额外结算一次，并获得目标及其相邻角色各一张手牌？",
  ["#porong-prey"] = "破戎：获得 %dest 一张手牌",

  ["$yuxi1"] = "任他千军来，我只一枪去！",
  ["$yuxi2"] = "长枪雪恨，斩尽胡马！",
  ["$porong1"] = "胡未灭，家何为？",
  ["$porong2"] = "诸君且听，这雁门虎啸！",
  ["~ty_wei__zhangliao"] = "血染战袍，虽死犹荣，此心无憾！",
}

local sunquan = General(extension, "ty_wei__sunquan", "wu", 4)
local woheng = fk.CreateActiveSkill{
  name = "woheng",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function (self, selected_cards, selected_targets)
    return "#woheng:::"..(Self:usedSkillTimes(self.name, Player.HistoryRound) + 1)
  end,
  interaction = function()
    return UI.ComboBox {choices = { "woheng_draw", "woheng_discard" } }
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target  = room:getPlayerById(effect.tos[1])
    local n = player:usedSkillTimes(self.name, Player.HistoryRound)
    if self.interaction.data == "woheng_draw" then
      target:drawCards(n, self.name)
    else
      room:askForDiscard(target, n, n, true, self.name, false)
    end
    if player.dead then return end
    if target:getHandcardNum() ~= player:getHandcardNum() or n > 3 then
      room:invalidateSkill(player, self.name, "-turn")
      player:drawCards(2, self.name)
    end
  end,
}
local woheng_trigger = fk.CreateTriggerSkill{
  name = "#woheng_trigger",
  mute = true,
  main_skill = woheng,
  events = {fk.Damaged},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(woheng)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local success = player.room:askForUseActiveSkill(player, "woheng",
      "#woheng:::"..(player:usedSkillTimes("woheng", Player.HistoryRound)), true, nil, false)
    if not success then
      player:addSkillUseHistory("woheng", -1)
    end
  end,
}
woheng:addRelatedSkill(woheng_trigger)
sunquan:addSkill(woheng)
Fk:loadTranslationTable{
  ["ty_wei__sunquan"] = "威孙权",
  ["#ty_wei__sunquan"] = "坐断东南",

  ["woheng"] = "斡衡",
  [":woheng"] = "出牌阶段或当你受到伤害后，你可以令一名其他角色摸或弃置X张牌（X为此技能本轮发动次数）。此技能结算后，若其手牌数与你不同或"..
  "X大于3，你摸两张牌且此技能本回合失效。",
  ["#woheng"] = "斡衡：你可以令一名角色摸或弃置%arg张牌",
  ["woheng_draw"] = "摸牌",
  ["woheng_discard"] = "弃牌",
}
local yuhui = fk.CreateTriggerSkill{
  name = "yuhui",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player), function (p)
        return p.kingdom == "wu"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return p.kingdom == "wu"
    end)
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 9, "#yuhui-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, self.cost_data.tos)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local yuhui_trigger = fk.CreateTriggerSkill{
  name = "#yuhui_trigger",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Play and table.contains(player:getTableMark("yuhui"), target.id) and
      not target.dead and not player.dead and not target:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(target, 1, 1, false, "yuhui", true, ".|.|heart,diamond|.|.|basic", "#yuhui-active:"..player.id)
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, player, fk.ReasonGive, "yuhui", nil, false, target.id)
    if target.dead then return end
    local success, dat = room:askForUseActiveSkill(target, "yuhui_active", "#woheng:::1", false, nil, false)
    if success and dat then
      local to = room:getPlayerById(dat.targets[1])
      if dat.interaction == "woheng_draw" then
        to:drawCards(1, "woheng")
      else
        room:askForDiscard(to, 1, 1, true, "woheng", false)
      end
      if target.dead then return end
      if to:getHandcardNum() ~= target:getHandcardNum() then
        target:drawCards(2, "woheng")
      end
    end
  end,
}
local yuhui_active = fk.CreateActiveSkill{
  name = "yuhui_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = { "woheng_draw", "woheng_discard" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected > 0 or not self.interaction.data then return end
    if self.interaction.data == "woheng_draw" then
      return true
    elseif self.interaction.data == "woheng_discard" then
      if to_select == Self.id then
        return table.find(Self:getCardIds("he"), function (id)
          return not Self:prohibitDiscard(id)
        end)
      else
        return not Fk:currentRoom():getPlayerById(to_select):isNude()
      end
    end
  end,
}
Fk:addSkill(yuhui_active)
yuhui:addRelatedSkill(yuhui_trigger)
sunquan:addSkill(yuhui)
Fk:loadTranslationTable{
  ["yuhui"] = "御麾",
  [":yuhui"] = "结束阶段，你可以选择任意名其他吴势力角色，其出牌阶段开始时可以交给你一张红色基本牌并发动一次X为1的〖斡衡〗。",
  ["#yuhui-choose"] = "御麾：选择任意名吴势力角色，其出牌阶段开始时可以交给你一张牌发动“斡衡”",
  ["#yuhui_trigger"] = "御麾",
  ["#yuhui-active"] = "御麾：是否交给 %src 一张红色基本牌，令一名角色摸或弃一张牌？",
  ["yuhui_active"] = "斡衡",
}
local jizheng = fk.CreateTriggerSkill{
  name = "jizheng$",
  attached_skill_name = "jizheng_active&",

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("jizheng-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "jizheng-turn", 0)
  end,
}
local jizheng_active = fk.CreateActiveSkill{
  name = "jizheng_active&",
  mute = true,
  prompt = "#jizheng_active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill("jizheng") and p ~= player
      end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p:hasSkill("jizheng")
    end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    if not target then return end
    room:notifySkillInvoked(player, "jizheng", "support")
    player:broadcastSkillInvoke("jizheng")
    room:doIndicate(effect.from, {target.id})
    if player.kingdom == "wu" then
      room:setPlayerMark(player, "jizheng_wu-turn", 1)
    else
      room:setPlayerMark(player, "jizheng-turn", 1)
    end
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true)
  end,
}
local jizheng_targetmod = fk.CreateTargetModSkill{
  name = "#jizheng_targetmod",
  bypass_distances =  function(self, player, skill)
    return player:getMark("jizheng-turn") > 0 or player:getMark("jizheng_wu-turn") > 0
  end,
}
--jizheng:addRelatedSkill(jizheng_targetmod)
--Fk:addSkill(jizheng_active)
--sunquan:addSkill(jizheng)
Fk:loadTranslationTable{
  ["jizheng"] = "集征",
  [":jizheng"] = "威主技，其他角色出牌阶段限一次，其可以交给你一张牌，则其本回合使用的下一张牌无距离限制（若为吴势力角色，改为本回合使用牌"..
  "无距离限制）。",
  ["jizheng_active"] = "集征",
  [":jizheng_active"] = "出牌阶段限一次，你可以交给威孙权一张牌，则你本回合使用的下一张牌无距离限制（若你为吴势力，改为本回合使用牌"..
  "无距离限制）。",
  ["#jizheng_active"] = "集征：交给威孙权一张牌，本回合你使用下一张牌无距离限制（若你为吴势力，改为本回合无距离限制）",
}

return extension
