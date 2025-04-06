local chaixie = fk.CreateSkill {
  name = "chaixie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chaixie"] = "拆械",
  [":chaixie"] = "锁定技，当你的【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",

  ["$chaixie1"] = "利器经久，拆合自用。",
  ["$chaixie2"] = "损一得十，如鲸落宇。",
}

chaixie:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chaixie.name) and
      data.extra_data and data.extra_data.chaixie_draw and
      table.find(data.extra_data.chaixie_draw, function (dat)
        return dat[1] == player.id
      end)
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, dat in ipairs(data.extra_data.chaixie_draw) do
      if dat[1] == player.id then
        n = n + dat[2]
      end
    end
    player:drawCards(n, chaixie.name)
  end,
})

return chaixie
