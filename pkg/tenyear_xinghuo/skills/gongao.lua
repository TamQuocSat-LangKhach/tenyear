local gongao = fk.CreateSkill {
  name = "ty_ex__gongao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__gongao"] = "功獒",
  [":ty_ex__gongao"] = "锁定技，一名其他角色首次进入濒死状态时，你加1点体力上限，然后回复1点体力。",

  ["$ty_ex__gongao1"] = "百战余生者，唯我大魏虎贲。",
  ["$ty_ex__gongao2"] = "大魏凭武立国，当以骨血为饲。",
}

gongao:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(gongao.name) and target ~= player and
      not table.contains(player:getTableMark(gongao.name), target.id) then
      player.room:addTableMark(player, gongao.name, target.id)
      local dying_events =  player.room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
        return e.data.who == target
      end, Player.HistoryGame)
      return #dying_events == 1 and dying_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover{
        num = 1,
        who = player,
        recoverBy = player,
        skillName = gongao.name,
      }
    end
  end,
})

return gongao
