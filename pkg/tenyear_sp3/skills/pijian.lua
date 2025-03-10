local pijian = fk.CreateSkill {
  name = "pijian"
}

Fk:loadTranslationTable{
  ['pijian'] = '辟剑',
  ['yanzuo'] = '研作',
  ['#pijian-choose'] = '辟剑：请选择一名角色，对其造成2点伤害',
  [':pijian'] = '锁定技，结束阶段，若“研作”牌数不少于存活角色数，你移去这些牌，然后对一名角色造成2点伤害。',
  ['$pijian1'] = '神思凝慧剑，当悬宵小之颈。',
  ['$pijian2'] = '仗剑凌天下，汝忘武侯否！'
}

pijian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(pijian.name) and player.phase == Player.Finish and
      #player:getPile("yanzuo") >= #player.room.alive_players
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:moveCardTo(player:getPile("yanzuo"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, pijian.name, nil, true, player.id)
    if player.dead then return end
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#pijian-choose",
      skill_name = pijian.name,
    })
    room:damage{
      from = player,
      to = room:getPlayerById(to[1]),
      damage = 2,
      skillName = pijian.name,
    }
  end
})

return pijian
