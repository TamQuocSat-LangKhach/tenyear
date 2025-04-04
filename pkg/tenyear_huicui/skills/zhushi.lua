local zhushi = fk.CreateSkill {
  name = "zhushi",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",

  ["#zhushi-invoke"] = "助势：是否令 %src 摸一张牌？",

  ["$zhushi1"] = "可有爱卿愿助朕讨贼？",
  ["$zhushi2"] = "泱泱大魏，忠臣俱亡乎？",
}

zhushi:addEffect(fk.HpRecover, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhushi.name) and target ~= player and
      target.kingdom == "wei" and not target.dead and
      not table.contains(player:getTableMark("zhushi-turn"), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhushi.name,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "zhushi-turn", target.id)
    if room:askToSkillInvoke(target, {
      skill_name = zhushi.name,
      prompt = "#zhushi-invoke:"..player.id,
    }) then
      player:drawCards(1, zhushi.name)
    end
  end,
})

zhushi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "zhushi-turn", 0)
end)

return zhushi
