local jianghuo = fk.CreateSkill {
  name = "jianghuo",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["jianghuo"] = "降祸",
  [":jianghuo"] = "觉醒技，回合开始时，若所有存活角色本局游戏均受到过伤害，你将所有“凛”移至你的武将牌上，摸“凛”等量的牌，"..
  "然后加1点体力上限，失去〖凛界〗，获得〖立世〗。",

  ["$jianghuo1"] = "",
  ["$jianghuo2"] = "",
}

jianghuo:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianghuo.name) and
      player:usedSkillTimes(jianghuo.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room.alive_players, function(p)
      return #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == p
      end, Player.HistoryGame) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      local n = p:getMark("@zhonghui_piercing")
      if n > 0 then
        room:removePlayerMark(p, "@zhonghui_piercing", n)
        room:addPlayerMark(player, "@zhonghui_piercing", n)
      end
    end
    if player:getMark("@zhonghui_piercing") > 0 then
      player:drawCards(player:getMark("@zhonghui_piercing"), jianghuo.name)
      if player.dead then return end
    end
    room:changeMaxHp(player, 1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-linjiez|lishi")
  end,
})

return jianghuo
