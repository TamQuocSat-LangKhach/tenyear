local quanmou = fk.CreateSkill {
  name = "quanmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["quanmou"] = "权谋",
  [":quanmou"] = "转换技，游戏开始时可自选阴阳状态。出牌阶段每名角色限一次，你可以令攻击范围内的一名其他角色交给你一张牌，"..
  "阳：防止你此阶段下次对其造成的伤害；阴：你此阶段下次对其造成伤害后，可以对至多三名该角色外的其他角色各造成1点伤害。",

  ["#quanmou-yang"] = "权谋：令一名角色交给你一张牌，防止此阶段下次对其造成的伤害",
  ["#quanmou-yin"] = "权谋：令一名角色交给你一张牌，此阶段下次对其造成伤害后，可以再对三名角色造成1点伤害",
  ["#quanmou-give"] = "权谋：选择一张牌交给 %dest ",
  ["@quanmou-phase"] = "权谋",
  ["#quanmou-damage"] = "权谋：你可以对至多三名角色各造成1点伤害！",

  ["$quanmou1"] = "洛水为誓，皇天为证，吾意不在刀兵。",
  ["$quanmou2"] = "以谋代战，攻形不以力，攻心不以勇。",
}

local U = require "packages/utility/utility"

quanmou:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player)
    return "#quanmou-"..player:getSwitchSkillState(quanmou.name, false, true)
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("quanmou_targets-phase"), to_select.id) and
      not to_select:isNude() and player:inMyAttackRange(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "quanmou_targets-phase", target.id)
    U.SetSwitchSkillState(player, quanmou.name, player:getSwitchSkillState(quanmou.name, false))
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      prompt = "#quanmou-give::" .. player.id,
      skill_name = quanmou.name,
      cancelable = false,
    })
    room:obtainCard(player, card, false, fk.ReasonGive, target)
    if player.dead or target.dead then return end
    local switch_state = player:getSwitchSkillState(quanmou.name, true, true)
    room:setPlayerMark(target, "@quanmou-phase", switch_state)
    local mark_name = "quanmou_" .. switch_state .. "-phase"
    room:addTableMark(player, mark_name, target.id)
  end,
})

quanmou:addEffect(fk.DamageCaused, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Play and
      table.contains(player:getTableMark("quanmou_yang-phase"), data.to.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    room:removeTableMark(player, "quanmou_yang-phase", data.to.id)
    data:preventDamage()
  end,
})

quanmou:addEffect(fk.Damage, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Play and
      table.contains(player:getTableMark("quanmou_yin-phase"), data.to.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.to, "@quanmou-phase", 0)
    room:removeTableMark(player, "quanmou_yin-phase", data.to.id)
    local targets = table.filter(room:getOtherPlayers(data.to, false), function (p)
      return p ~= player
    end)
    if #targets == 0 then return false end
    targets = room:askToChoosePlayers(player, {
      skill_name = quanmou.name,
      min_num = 1,
      max_num = 3,
      targets = targets,
      prompt = "#quanmou-damage",
      cancelable = true,
    })
    if #targets == 0 then return false end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = quanmou.name,
        }
      end
    end
  end,
})

quanmou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quanmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::quanmou:yang", "tymou_switch:::quanmou:yin" },
      skill_name = quanmou.name,
      prompt = "#tymou_switch-choice:::quanmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, quanmou.name, choice)
  end,
})

return quanmou
