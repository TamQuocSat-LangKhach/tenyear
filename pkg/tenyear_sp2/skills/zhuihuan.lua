local zhuihuan = fk.CreateSkill {
  name = "zhuihuan"
}

Fk:loadTranslationTable{
  ['zhuihuan'] = '追还',
  ['#zhuihuan-choose'] = '追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌',
  ['#zhuihuan_delay'] = '追而还之！',
  [':zhuihuan'] = '结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色：若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。',
  ['$zhuihuan1'] = '伤人者，追而还之！',
  ['$zhuihuan2'] = '追而还击，皆为因果。',
}

zhuihuan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhuihuan) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#zhuihuan-choose",
      skill_name = zhuihuan.name,
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    player.room:addPlayerMark(player.room:getPlayerById(event:getCostData(skill)), zhuihuan.name, 1)
  end,
})

zhuihuan:addEffect(fk.EventPhaseStart, {
  name = "#zhuihuan_delay",
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Start and player:getMark("zhuihuan") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "zhuihuan", 0)
    local mark = player:getTableMark("zhuihuan_record")
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return table.contains(mark, p.id)
    end)
    room:setPlayerMark(player, "zhuihuan_record", 0)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        if p.hp > player.hp then
          room:damage({
            from = player,
            to = p,
            damage = 2,
            damageType = fk.NormalDamage,
            skillName = "zhuihuan"
          })
        else
          local cards = table.filter(p:getCardIds(Player.Hand), function (id)
            return not p:prohibitDiscard(Fk:getCardById(id))
          end)
          cards = table.random(cards, 2)
          if #cards > 0 then
            room:throwCard(cards, "zhuihuan", p, p)
          end
        end
      end
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("zhuihuan") ~= 0 and data.from
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "zhuihuan_record", data.from.id)
  end,
})

return zhuihuan
