local fengxiang = fk.CreateSkill {
  name = "fengxiang"
}

Fk:loadTranslationTable{
  ['fengxiang'] = '封乡',
  [':fengxiang'] = '锁定技，当你受到伤害后，手牌中“隙”唯一最多的角色回复1点体力（没有唯一最多的角色则改为你摸一张牌）；当有角色因手牌数改变而使“隙”唯一最多的角色改变后，你摸一张牌。',
  ['$fengxiang1'] = '北风摧蜀地，王爵换乡侯。',
  ['$fengxiang2'] = '汉皇可负我，我不负父兄。',
}

fengxiang:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = getFengxiangPlayer(room)
    if to ~= 0 then
      room:doIndicate(player.id, {to})
      to = room:getPlayerById(to)
      if to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = fengxiang.name
        })
      end
    else
      player:drawCards(1, fengxiang.name)
    end
  end,
})

fengxiang:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      local to = getFengxiangPlayer(player.room)
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.fengxiang and move.extra_data.fengxiang ~= to then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, fengxiang.name)
  end,
})

fengxiang:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(skill.name, true) then
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
        if move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      move.extra_data = move.extra_data or {}
      move.extra_data.fengxiang = getFengxiangPlayer(player.room)
    end
  end,
})

return fengxiang
