local pingkou = fk.CreateSkill {
  name = "ty_ex__pingkou",
}

Fk:loadTranslationTable{
  ["ty_ex__pingkou"] = "平寇",
  [":ty_ex__pingkou"] = "回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数），然后若你选择的角色数小于X，"..
  "你再选择其中一名角色，令其随机弃置装备区里的一张牌。",

  ["#ty_ex__pingkou-choose"] = "平寇：你可以对至多%arg名角色各造成1点伤害",
  ["#ty_ex__pingkou-discard"] = "平寇：令一名角色随机弃置一张装备",

  ["$ty_ex__pingkou1"] = "群寇蜂起，以军平之。",
  ["$ty_ex__pingkou2"] = "所到之处，寇患皆平。",
}

pingkou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pingkou.name) and
      table.find(data.phase_table, function(phase)
        return phase.who == player and phase.skipped
      end) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(data.phase_table, function(phase)
      return phase.who == player and phase.skipped
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = room:getOtherPlayers(player, false),
      skill_name = pingkou.name,
      prompt = "#ty_ex__pingkou-choose:::" .. n,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = pingkou.name,
        }
      end
    end
    if #tos < event:getCostData(self).choice and not player.dead then
      local targets = table.filter(tos, function(p)
        return #p:getCardIds("e") > 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          prompt = "#ty_ex__pingkou-discard",
          skill_name = pingkou.name,
          cancelable = false,
          targets = targets,
        })[1]
        room:throwCard(table.random(to:getCardIds("e")), pingkou.name, to, to)
      end
    end
  end,
})

return pingkou
