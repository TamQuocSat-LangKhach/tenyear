local extension = Package("tenyear_star")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：袁术
local yuanshu = General(extension, "tystar__yuanshu", "qun", 4)
local canxi = fk.CreateTriggerSkill{
  name = "canxi",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventAcquireSkill, fk.RoundStart},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventAcquireSkill then
        return target == player and data == self
      elseif event == fk.RoundStart then
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      room:setPlayerMark(player, "canxi_exist_kingdoms", kingdoms)
    elseif event == fk.RoundStart then
      local choice1 = room:askForChoice(player, player:getMark("canxi_exist_kingdoms"), self.name, "#canxi-choice1")
      local choice2 = room:askForChoice(player, {"canxi1", "canxi2"}, self.name, "#canxi-choice2:::"..choice1, true)
      room:setPlayerMark(player, "@"..choice2.."-round", choice1)
    end
  end,
}
local canxi_distance = fk.CreateDistanceSkill{
  name = "#canxi_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getMark("@canxi1-round") == from.kingdom then
        n = n + 1
      end
    end
    return -n
  end,
}
local canxi_trigger = fk.CreateTriggerSkill{
  name = "#canxi_trigger",
  mute = true,
  events = {fk.DamageCaused, fk.HpRecover, fk.PreCardEffect},
  can_trigger = function (self, event, target, player, data)
    if event == fk.DamageCaused then
      return player:getMark("@canxi1-round") ~= 0 and player:getMark("@canxi1-round") == target.kingdom and target:getMark("canxi1-turn") == 0
    elseif event == fk.HpRecover then
      return player:getMark("@canxi2-round") ~= 0 and player:getMark("@canxi2-round") == target.kingdom and not target.dead and
        target:getMark("canxi21-turn") == 0
    elseif event == fk.PreCardEffect then
      if player:getMark("@canxi2-round") ~= 0 and player.id == data.to then
        local p = player.room:getPlayerById(data.from)
        return player:getMark("@canxi2-round") == p.kingdom and p:getMark("canxi22-turn") == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("canxi")
    if event == fk.DamageCaused then
      room:setPlayerMark(target, "canxi1-turn", 1)
      room:notifySkillInvoked(player, "canxi", "offensive")
      data.damage = data.damage + 1
    elseif event == fk.HpRecover then
      room:setPlayerMark(target, "canxi21-turn", 1)
      room:notifySkillInvoked(player, "canxi", "control")
      room:doIndicate(player.id, {target.id})
      room:loseHp(target, 1, "canxi")
    elseif event == fk.PreCardEffect then
      room:setPlayerMark(room:getPlayerById(data.from), "canxi22-turn", 1)
      room:notifySkillInvoked(player, "canxi", "defensive")
      return true
    end
  end,
}
local pizhi = fk.CreateTriggerSkill{
  name = "pizhi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd, fk.BeforeGameOverJudge},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseEnd then
        return target == player and player.phase == Player.Finish and player:getMark("canxi_removed_kingdoms") ~= 0
      elseif event == fk.BeforeGameOverJudge then
        return (player:getMark("@canxi1-round") == target.kingdom or player:getMark("@canxi2-round") == target.kingdom) and
          player:getMark("canxi_exist_kingdoms") ~= 0 and table.contains(player:getMark("canxi_exist_kingdoms"), target.kingdom)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    if event == fk.BeforeGameOverJudge then
      local room = player.room
      local mark = player:getMark("canxi_exist_kingdoms")
      table.removeOne(mark, target.kingdom)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(player, "canxi_exist_kingdoms", mark)
      mark = player:getMark("canxi_removed_kingdoms")
      if mark == 0 then mark = {} end
      table.insert(mark, target.kingdom)
      room:setPlayerMark(player, "canxi_removed_kingdoms", mark)
    end
    player:drawCards(#player:getMark("canxi_removed_kingdoms"), self.name)
  end,
}
local zhonggu = fk.CreateTriggerSkill{
  name = "zhonggu$",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local n = #table.filter(room.alive_players, function(p) return p.kingdom == "qun" end)
    if room:getTag("RoundCount") >= n then
      room:notifySkillInvoked(player, self.name, "drawcard")
      data.n = data.n + 2
    else
      room:notifySkillInvoked(player, self.name, "negative")
      data.n = data.n - 1
    end
  end,
}
canxi:addRelatedSkill(canxi_distance)
canxi:addRelatedSkill(canxi_trigger)
yuanshu:addSkill(canxi)
yuanshu:addSkill(pizhi)
yuanshu:addSkill(zhonggu)
Fk:loadTranslationTable{
  ["tystar__yuanshu"] = "星袁术",
  ["canxi"] = "残玺",
  [":canxi"] = "锁定技，游戏开始时，你获得场上各势力的“玺角”标记。每轮开始时，你选择一个“玺角”势力并选择一个效果生效直到下轮开始：<br>"..
  "「妄生」：该势力角色每回合首次造成伤害+1，计算与其他角色距离-1；<br>「向死」：该势力角色每回合首次回复体力后失去1点体力，"..
  "每回合对你使用的第一张牌无效。",
  ["pizhi"] = "圮秩",
  [":pizhi"] = "锁定技，结束阶段，你摸X张牌；有角色死亡时，若其势力与当前生效的“玺角”势力相同，你失去此“玺角”，然后摸X张牌（X为你已失去的“玺角”数）。",
  ["zhonggu"] = "冢骨",
  [":zhonggu"] = "主公技，锁定技，若游戏轮数不小于群势力角色数，你摸牌阶段摸牌数+2，否则-1。",
  ["#canxi-choice1"] = "残玺：选择本轮生效的“玺角”势力",
  ["#canxi-choice2"] = "残玺：选择本轮对 %arg 势力角色生效的效果",
  ["canxi1"] = "「妄生」",
  [":canxi1"] = "每回合首次造成伤害+1，计算与其他角色距离-1",
  ["@canxi1-round"] = "「妄生」",
  ["canxi2"] = "「向死」",
  [":canxi2"] = "每回合首次回复体力后失去1点体力，每回合对你使用的第一张牌无效",
  ["@canxi2-round"] = "「向死」",
}

--玉衡：曹仁
local caoren = General(extension, "tystar__caoren", "wei", 4)
local sujun = fk.CreateTriggerSkill{
  name = "sujun",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      2 * #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) == player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local lifengc = fk.CreateViewAsSkill{
  name = "lifengc",
  pattern = "slash,nullification",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "nullification"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      Self:getMark("lifengc_"..Fk:getCardById(to_select):getColorString().."-turn") == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng()
  end,
}
local lifengc_trigger = fk.CreateTriggerSkill{
  name = "#lifengc_trigger",

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill("lifengc", true) and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "lifengc_"..data.card:getColorString().."-turn", 1)
  end,
}
lifengc:addRelatedSkill(lifengc_trigger)
caoren:addSkill(sujun)
caoren:addSkill(lifengc)
Fk:loadTranslationTable{
  ["tystar__caoren"] = "星曹仁",
  ["sujun"] = "肃军",
  [":sujun"] = "当你使用一张牌时，若你手牌中基本牌与非基本牌数量相等，你可以摸两张牌。",
  ["lifengc"] = "砺锋",
  [":lifengc"] = "你可以将一张本回合未被使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。",
}

return extension
