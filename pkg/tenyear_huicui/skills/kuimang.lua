local kuimang = fk.CreateSkill {
  name = "kuimang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuimang"] = "溃蟒",
  [":kuimang"] = "锁定技，当一名角色死亡时，若你对其造成过伤害，你摸两张牌。",

  ["$kuimang1"] = "黄巾流寇，不过如此。",
  ["$kuimang2"] = "黄巾作乱，奉旨平叛！",
}

kuimang:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuimang.name) and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if damage.from == player and damage.to == target then
          return true
        end
      end, Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, kuimang.name)
  end,
})

return kuimang
