local ty_ex__pingkou = fk.CreateSkill {
  name = "ty_ex__pingkou"
}

Fk:loadTranslationTable{
  ['ty_ex__pingkou'] = '平寇',
  ['#ty_ex__pingkou-choose'] = '平寇：你可以对至多%arg名角色各造成1点伤害',
  ['#ty_ex__pingkou-throw'] = '平寇：令一名角色随机弃置装备区里的一张牌',
  [':ty_ex__pingkou'] = '回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数），然后若你选择的角色数小于X，你再选择其中一名角色，令其随机弃置装备区里的一张牌。',
  ['$ty_ex__pingkou1'] = '群寇蜂起，以军平之。',
  ['$ty_ex__pingkou2'] = '所到之处，寇患皆平。',
}

ty_ex__pingkou:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:hasSkill(ty_ex__pingkou.name) and table.find(sixPhases, function(phase) return player.skipped_phases[phase] end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, phase in ipairs(sixPhases) do
      if player.skipped_phases[phase] then
        n = n + 1
      end
    end
    if n == 0 then return false end
    local targets = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      prompt = "#ty_ex__pingkou-choose:::"..n,
      skill_name = ty_ex__pingkou.name,
      cancelable = true,
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    })
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      event:setCostData(self, {tos = targets, num = n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local tos = cost_data.tos
    local n = cost_data.num
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = ty_ex__pingkou.name,
        }
      end
    end
    if #tos < n and not player.dead then
      local targets = table.filter(tos, function(pid)
        return #room:getPlayerById(pid):getCardIds("e") > 0
      end)
      if #targets > 0 then
        local to = room:getPlayerById(room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          prompt = "#ty_ex__pingkou-throw",
          skill_name = ty_ex__pingkou.name,
          cancelable = false,
          targets = targets
        })[1])
        local card = table.random(to:getCardIds("e"), 1)
        room:throwCard(card, ty_ex__pingkou.name, to, to)
      end
    end
  end,
})

return ty_ex__pingkou
