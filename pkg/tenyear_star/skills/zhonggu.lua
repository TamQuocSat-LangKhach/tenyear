local zhonggu = fk.CreateSkill {
  name = "zhonggu$"
}

Fk:loadTranslationTable{ }

zhonggu:addEffect(fk.DrawNCards, {
  mute = true,
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhonggu.name)
    local n = #table.filter(room.alive_players, function(p) return p.kingdom == "qun" end)
    if room:getBanner("RoundCount") >= n then
      room:notifySkillInvoked(player, zhonggu.name, "drawcard")
      data.n = data.n + 2
    else
      room:notifySkillInvoked(player, zhonggu.name, "negative")
      data.n = data.n - 1
    end
  end,
})

return zhonggu
