local tianjie = fk.CreateSkill {
  name = "tianjie",
}

Fk:loadTranslationTable{
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",

  ["#tianjie-choose"] = "天劫：你可以对至多三名角色各造成X点雷电伤害（X为其手牌中【闪】数，至少为1）",

  ["$tianjie1"] = "苍天既死，贫道当替天行道。",
  ["$tianjie2"] = "贫道张角，请大汉赴死！",
}

tianjie:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianjie.name) and player:getMark("tianjie-turn") > 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      skill_name = tianjie.name,
      min_num = 1,
      max_num = 3,
      targets = room:getOtherPlayers(player, false),
      prompt = "#tianjie-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        local n = math.max(1, #table.filter(p:getCardIds("h"), function(id)
          return Fk:getCardById(id).trueName == "jink"
        end))
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
    return player:hasSkill(tianjie.name, true) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "tianjie-turn", 1)
  end,
})

return tianjie
