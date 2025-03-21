local ty_ex__shibei = fk.CreateSkill {
  name = "ty_ex__shibei"
}

Fk:loadTranslationTable{
  ['ty_ex__shibei'] = '矢北',
  [':ty_ex__shibei'] = '锁定技，当你受到伤害后，若此次伤害：是你本回合受到的第一次伤害，你回复1点体力；是你本回合受到的第二次伤害，你失去1点体力。',
  ['$ty_ex__shibei1'] = '主公在北，吾心亦在北！',
  ['$ty_ex__shibei2'] = '宁向北而死，不面南而生。',
}

ty_ex__shibei:addEffect(fk.Damaged, {
  mute = true,
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(ty_ex__shibei.name) then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    local mark = player:getMark("ty_ex__shibei_record-turn")
    if type(mark) ~= "table" then
      mark = {}
    end
    if #mark < 2 and not table.contains(mark, damage_event.id) then
      local damage_ids = {}
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 2, function (e)
        if e.data[1] == player and e.data[3] == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            table.insert(damage_ids, first_damage_event.id)
            return true
          end
        end
        return false
      end, Player.HistoryTurn)
      if #damage_ids > #mark then
        mark = damage_ids
        room:setPlayerMark(player, "ty_ex__shibei_record-turn", mark)
      end
    end
    return table.contains(mark, damage_event.id) and not (mark[1] == damage_event.id and not player:isWounded())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("ty_ex__shibei_record-turn")
    if type(mark) ~= "table" or #mark == 0 then return false end
    local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if not damage_event then return false end
    if mark[1] == damage_event.id then
      player:broadcastSkillInvoke(ty_ex__shibei.name, 1)
      room:notifySkillInvoked(player, ty_ex__shibei.name)
      room:recover{
        who = player,
        num = 1,
        skillName = ty_ex__shibei.name
      }
    end
    if #mark > 1 and mark[2] == damage_event.id then
      player:broadcastSkillInvoke(ty_ex__shibei.name, 2)
      room:notifySkillInvoked(player, ty_ex__shibei.name, "negative")
      room:loseHp(player, 1, ty_ex__shibei.name)
    end
  end,
})

return ty_ex__shibei
