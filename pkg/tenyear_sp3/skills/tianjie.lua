local tianjie = fk.CreateSkill {
  name = "tianjie"
}

Fk:loadTranslationTable{
  ['tianjie'] = '天劫',
  ['#tianjie-choose'] = '天劫：你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】数，至少为1）',
  [':tianjie'] = '一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。',
  ['$tianjie1'] = '苍天既死，贫道当替天行道。',
  ['$tianjie2'] = '贫道张角，请大汉赴死！',
}

tianjie:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianjie) then
      if player:getMark(tianjie.name) > 0 then
        player.room:setPlayerMark(player, tianjie.name, 0)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 3,
      prompt = "#tianjie-choose",
      skill_name = tianjie.name,
      cancelable = true
    })
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(self).tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local n = math.max(1, #table.filter(p:getCardIds("h"), function(c) return Fk:getCardById(c).trueName == "jink" end))
        room:damage{
          from = player,
          to = p,
          damage = n,
          damageType = fk.ThunderDamage,
          skillName = tianjie.name,
        }
      end
    end
  end,
})

tianjie:addEffect(fk.AfterDrawPileShuffle, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(tianjie, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, tianjie.name, 1)
  end,
})

return tianjie
