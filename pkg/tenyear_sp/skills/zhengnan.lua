local zhengnan = fk.CreateSkill {
  name = "ty__zhengnan",
}

Fk:loadTranslationTable{
  ["ty__zhengnan"] = "征南",
  [":ty__zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个："..
  "〖武圣〗〖当先〗〖制蛮〗（若均已获得，则改为摸三张牌）。",

  ["$ty__zhengnan1"] = "南征之役，愿效死力。",
  ["$ty__zhengnan2"] = "南征之险恶，吾已有所准备。",
}

zhengnan:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengnan.name) and not table.contains(player:getTableMark(zhengnan.name), target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, zhengnan.name, target.id)
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhengnan.name,
      }
      if player.dead then return end
    end
    local choices = {"ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1, zhengnan.name)
      if player.dead then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhengnan.name,
        prompt = "#zhengnan-choice",
        detailed = true,
      })
      room:handleAddLoseSkills(player, choice)
      if choice == "ty_ex__dangxian" then
        room:setPlayerMark(player, "ty_ex__fuli", 1)  --直接获得升级后的当先
      end
    else
      player:drawCards(3, zhengnan.name)
    end
  end,
})

return zhengnan
