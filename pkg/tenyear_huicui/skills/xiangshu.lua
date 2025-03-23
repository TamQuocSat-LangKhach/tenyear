local xiangshu = fk.CreateSkill {
  name = "xiangshu"
}

Fk:loadTranslationTable{
  ['xiangshu'] = '襄戍',
  ['#xiangshu-invoke'] = '襄戍：你可令一名已受伤角色回复 %arg 点体力并摸 %arg 张牌',
  [':xiangshu'] = '限定技，结束阶段，若你本回合造成过伤害，你可令一名已受伤角色回复X点体力并摸X张牌（X为你本回合造成的伤害值且最多为5）。',
  ['$xiangshu1'] = '得道多襄，为公是瞻！',
  ['$xiangshu2'] = '愿为中原，永戍北疆！',
}

xiangshu:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Limited,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangshu) and player.phase == Player.Finish
      and player:usedSkillTimes(xiangshu.name, Player.HistoryGame) == 0
      and #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) > 0
      and table.find(player.room.alive_players, function(p) return p:isWounded() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getActualDamageEvents(1, function(e)
      if e.data[1].from == player then
        n = n + e.data[1].damage
      end
    end)
    local targets = table.map(table.filter(room.alive_players, function(p) return p:isWounded() end), Util.IdMapper)
    if #targets == 0 then return end
    n = math.min(n, 5)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xiangshu-invoke:::"..n,
      skill_name = xiangshu.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, {to[1].id, n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = room:getPlayerById(cost_data[1])
    local n = cost_data[2]
    room:recover({
      who = to,
      num = math.min(n, to:getLostHp()),
      recoverBy = player,
      skillName = xiangshu.name
    })
    if not to.dead then
      to:drawCards(n, xiangshu.name)
    end
  end,
})

return xiangshu
