local silue = fk.CreateSkill {
  name = "silue",
}

Fk:loadTranslationTable{
  ["silue"] = "私掠",
  [":silue"] = "游戏开始时，你选择一名其他角色为“私掠”角色。<br>“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>"..
  "“私掠”角色受到伤害后，你需对伤害来源使用一张【杀】（无距离限制），否则你弃置一张手牌。",

  ["#silue-choose"] = "私掠：选择一名其他角色为“私掠”角色",
  ["@silue"] = "私掠",
  ["#silue-prey"] = "私掠：是否获得 %dest 的一张牌？",
  ["#silue-card"] = "私掠：获得 %dest 的一张牌",
  ["#silue-slash"] = "私掠：你需对 %dest 使用一张【杀】，否则弃置一张手牌",

  ["$silue1"] = "劫尔之富，济我之贫！",
  ["$silue2"] = "徇私而动，劫财掠货。",
}

silue:addLoseEffect(function (self, player, is_death)
  if not player:hasSkill("shuaijie", true) then
    local room = player.room
    room:setPlayerMark(player, "@silue", 0)
    room:setPlayerMark(player, silue.name, 0)
  end
end)

silue:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(silue.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = silue.name,
      prompt = "#silue-choose",
      cancelable = false,
    })[1]
    room:setPlayerMark(player, "@silue", to.general)
    room:setPlayerMark(player, silue.name, to.id)
  end,
})

silue:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(silue.name) and target and player:getMark(silue.name) == target.id and
      not data.to.dead and not table.contains(player:getTableMark("silue-turn"), data.to.id) then
      if data.to ~= player then
        return not data.to:isNude()
      else
        return #player:getCardIds("e") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = silue.name,
      prompt = "#silue-prey::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "silue-turn", data.to.id)
    local id = room:askToChooseCard(player, {
      target = data.to,
      flag = data.to == player and "e" or "he",
      skill_name = silue.name,
      prompt = "#silue-card::"..data.to.id,
    })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, silue.name)
  end,
})

silue:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(silue.name) and player:getMark(silue.name) == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not (not data.from or data.from.dead or data.from == player) then
      local use = room:askToUseCard(player, {
        skill_name = silue.name,
        pattern = "slash",
        prompt = "#silue-slash::"..data.from.id,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          must_targets = {data.from.id},
        },
      })
      if use then
        room:useCard(use)
        return
      end
    end
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = silue.name,
      cancelable = false,
    })
  end,
})

return silue
