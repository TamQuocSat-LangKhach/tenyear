local zhuoli = fk.CreateSkill {
  name = "zhuoli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['zhuoli'] = '擢吏',
  [':zhuoli'] = '锁定技，每个回合结束时，若你本回合使用牌或获得牌的张数大于体力值，你加1点体力上限并回复1点体力（体力上限不能超过角色数）。',
  ['$zhuoli1'] = '良子千万，当擢才而用。',
  ['$zhuoli2'] = '任人唯才，不妨寒门入上品。',
}

zhuoli:addEffect(fk.TurnEnd, {
  anim_type = "defensive",
  
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(zhuoli.name) and (player.maxHp < #room.players or player:isWounded()) then
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, player.hp + 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn)
      if #events > player.hp then return true end
      local x = 0
      events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Player.Hand then
            x = x + #move.moveInfo
          end
        end
        return x > player.hp
      end, Player.HistoryTurn)
      return x > player.hp
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.maxHp < #room.players then
      room:changeMaxHp(player, 1)
    end
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhuoli.name
      })
    end
  end,
})

return zhuoli
