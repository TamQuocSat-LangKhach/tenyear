local shuangren = fk.CreateSkill {
  name = "ty__shuangren",
}

Fk:loadTranslationTable{
  ["ty__shuangren"] = "双刃",
  [":ty__shuangren"] = "出牌阶段开始时，你可以与一名角色拼点。若你赢，你选择与其势力相同的一至两名角色（若选择两名，其中一名须为该角色），"..
  "视为对选择的角色使用一张不计入次数的【杀】；若你没赢，你本阶段不能使用【杀】。",

  ["#ty__shuangren-choose"] = "双刃：与一名角色拼点，若赢，视为对与其势力相同的角色使用【杀】",
  ["#ty__shuangren-slash"] = "双刃：视为至多两名%arg势力角色使用【杀】（若选两名，其中一名须为 %dest",

  ["$ty__shuangren1"] = "这淮阴城下，正是葬汝尸骨的好地界。",
  ["$ty__shuangren2"] = "吾众下大军已至，匹夫，以何敌我？",
}

shuangren:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuangren.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__shuangren-choose",
      skill_name = shuangren.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({to}, shuangren.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      local slash = Fk:cloneCard("slash")
      slash.skillName = shuangren.name
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p.kingdom == to.kingdom and player:canUseTo(slash, p, {bypass_distances = true, bypass_times = true})
      end)
      if #targets == 0 then return end
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "ty__shuangren_active",
        prompt = "#ty__shuangren-slash::"..to.id..":"..to.kingdom,
        cancelable = false,
        extra_data = {
          ty__shuangren = to.id,
        },
      })
      if not (success and dat) then
        dat = {}
        dat.targets = table.random(targets, 1)
      end
      room:useVirtualCard("slash", nil, player, dat.targets, shuangren.name, true)
    else
      room:setPlayerMark(player, "ty__shuangren_prohibit-phase", 1)
    end
  end,
})

shuangren:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("ty__shuangren_prohibit-phase") > 0 and card and card.trueName == "slash"
  end,
})

return shuangren
