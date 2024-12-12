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

return extension
