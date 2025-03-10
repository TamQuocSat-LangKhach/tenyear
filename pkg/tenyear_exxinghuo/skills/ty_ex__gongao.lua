local ty_ex__gongao = fk.CreateSkill {
  name = "ty_ex__gongao"
}

Fk:loadTranslationTable{
  ['ty_ex__gongao'] = '功獒',
  [':ty_ex__gongao'] = '锁定技，一名其他角色第一次进入濒死状态时，你加1点体力上限，然后回复1点体力。',
  ['$ty_ex__gongao1'] = '待补充',
  ['$ty_ex__gongao2'] = '待补充',
}

ty_ex__gongao:addEffect(fk.EnterDying, {
  anim_type = "support",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if player:hasSkill(ty_ex__gongao.name) and target ~= player then
      local dying_id = target:getMark(ty_ex__gongao.name)
      local cur_event = player.room.logic:getCurrentEvent()
      if dying_id ~= 0 then
        return cur_event.id == dying_id
      else
        local events = player.room.logic.event_recorder[GameEvent.Dying] or Util.DummyTable
        local canInvoke = true
        for i = #events, 1, -1 do
          local e = events[i]
          if e.data[1].who == target.id and e.id ~= cur_event.id then
            canInvoke = false
            break
          end
        end
        if canInvoke then
          player.room:setPlayerMark(target, ty_ex__gongao.name, cur_event.id)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover({ num = 1, skillName = ty_ex__gongao.name, who = player, recoverBy = player })
    end
  end,
})

return ty_ex__gongao
