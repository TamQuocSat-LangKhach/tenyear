local kuimang = fk.CreateSkill {
  name = "kuimang"
}

Fk:loadTranslationTable{
  ['kuimang'] = '溃蟒',
  [':kuimang'] = '锁定技，当一名角色死亡时，若你对其造成过伤害，你摸两张牌。',
  ['$kuimang1'] = '黄巾流寇，不过如此。',
  ['$kuimang2'] = '黄巾作乱，奉旨平叛！',
}

kuimang:addEffect(fk.Death, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return #player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      if damage.from == player and damage.to == target then
        return true
      end
    end, nil, 0) > 0
  end,
  on_use = function(self, event, target, player)
    player:drawCards(2, kuimang.name)
  end,
})

return kuimang
