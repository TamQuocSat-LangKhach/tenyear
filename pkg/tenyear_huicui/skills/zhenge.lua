local zhenge = fk.CreateSkill {
  name = "zhenge",
}

Fk:loadTranslationTable{
  ["zhenge"] = "枕戈",
  [":zhenge"] = "准备阶段，你可以令一名角色的攻击范围+1（加值至多为5），然后若其他角色都在其的攻击范围内，你可以令其视为对另一名"..
  "你选择的角色使用一张【杀】。",

  ["#zhenge-choose"] = "枕戈：你可以令一名角色的攻击范围+1（至多+5）",
  ["@zhenge"] = "枕戈",
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为 %dest 对其使用【杀】",

  ["$zhenge1"] = "常备不懈，严阵以待。",
  ["$zhenge2"] = "枕戈待旦，日夜警惕。",
}

zhenge:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenge.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#zhenge-choose",
      skill_name = zhenge.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:getMark("@zhenge") < 5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local slash = Fk:cloneCard("slash")
    slash.skillName = zhenge.name
    if to.dead or player.dead or to:prohibitUse(slash) then return end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to, false)) do
      if to:inMyAttackRange(p) then
        if not to:isProhibited(p, slash) then
          table.insert(targets, p)
        end
      else
        return false
      end
    end
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhenge-slash::"..to.id,
      skill_name = zhenge.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:useVirtualCard("slash", nil, to, tos[1], zhenge.name, true)
    end
  end,
})

zhenge:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@zhenge")
  end,
})

return zhenge
