local zhushi = fk.CreateSkill {
  name = "zhushi$"
}

Fk:loadTranslationTable{
  ['zhushi_draw'] = '其摸一张牌',
  ['#zhushi-invoke'] = '助势：你可以令 %src 摸一张牌',
}

zhushi:addEffect(fk.HpRecover, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(zhushi.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(target, {
      choices = {"zhushi_draw", "Cancel"},
      skill_name = zhushi.name,
      prompt = "#zhushi-invoke:"..player.id
    })
    if choice == "zhushi_draw" then
      player:drawCards(1, zhushi.name)
    end
  end,
})

return zhushi
