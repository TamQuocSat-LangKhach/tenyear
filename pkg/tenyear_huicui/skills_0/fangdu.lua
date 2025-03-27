local fangdu = fk.CreateSkill {
  name = "fangdu"
}

Fk:loadTranslationTable{
  ['fangdu'] = '芳妒',
  [':fangdu'] = '锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。',
  ['$fangdu1'] = '浮萍却红尘，何意染是非？',
  ['$fangdu2'] = '我本无意争春，奈何群芳相妒。',
}

fangdu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(skill.name) or player.phase ~= Player.NotActive then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local mark_name = "fangdu1_record-turn"
    if data.damageType == fk.NormalDamage then
      if not player:isWounded() then return false end
    else
      if data.from == nil or data.from == player or data.from:isKongcheng() then return false end
      mark_name = "fangdu2_record-turn"
    end
    local x = player:getMark(mark_name)
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if e.data[1] == player and reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            local damage = first_damage_event.data[1]
            if damage.damageType == data.damageType then
              x = first_damage_event.id
              room:setPlayerMark(player, mark_name, x)
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = fangdu.name
      }
    else
      local id = table.random(data.from.player_cards[Player.Hand])
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end
})

return fangdu
