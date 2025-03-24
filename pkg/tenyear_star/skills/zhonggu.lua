local zhonggu = fk.CreateSkill {
  name = "zhonggu",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhonggu"] = "冢骨",
  [":zhonggu"] = "主公技，锁定技，若游戏轮数不小于群势力角色数，你摸牌阶段摸牌数+2，否则-1。",

  ["$zhonggu1"] = "既登九五之尊位，何惧为冢中之枯骨？",
  ["$zhonggu2"] = "天下英雄多矣，大浪淘沙，谁不老冢中？",
}

zhonggu:addEffect(fk.DrawNCards, {
  mute = true,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhonggu.name)
    local n = #table.filter(room.alive_players, function(p)
      return p.kingdom == "qun"
    end)
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
