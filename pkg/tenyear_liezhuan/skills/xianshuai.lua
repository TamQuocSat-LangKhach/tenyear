local xianshuai = fk.CreateSkill {
  name = "xianshuai"
}

Fk:loadTranslationTable{
  ['xianshuai'] = '先率',
  [':xianshuai'] = '锁定技，一名角色造成伤害后，若此伤害是本轮第一次造成伤害，你摸一张牌。若伤害来源为你，你对受到伤害的角色造成1点伤害。',
  ['$xianshuai1'] = '九州齐喑，首义瞩吾！',
  ['$xianshuai2'] = '雄兵一击，则天下大白！',
}

xianshuai:addEffect(fk.Damage, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xianshuai.name) or target == nil then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = player:getMark("xianshuai_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            x = first_damage_event.id
            room:setPlayerMark(player, "xianshuai_record-round", x)
          end
          return true
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xianshuai.name)
    if player == target and not data.to.dead then
      player.room:damage{
        from = player,
        to = data.to,
        damage = 1,
        skillName = xianshuai.name,
      }
    end
  end,
})

return xianshuai
