local ty__zhengnan = fk.CreateSkill {
  name = "ty__zhengnan"
}

Fk:loadTranslationTable{
  ['ty__zhengnan'] = '征南',
  [':ty__zhengnan'] = '每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个：〖武圣〗，〖当先〗和〖制蛮〗（若技能均已获得，则改为摸三张牌）。',
  ['$ty__zhengnan1'] = '南征之役，愿效死力。',
  ['$ty__zhengnan2'] = '南征之险恶，吾已有所准备。',
}

ty__zhengnan:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty__zhengnan.name) and (player:getMark(ty__zhengnan.name) == 0 or not table.contains(player:getMark(ty__zhengnan.name), target.id))
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local mark = player:getMark(ty__zhengnan.name)
    if mark == 0 then mark = {} end
    table.insert(mark, target.id)
    room:setPlayerMark(player, ty__zhengnan.name, mark)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty__zhengnan.name
      })
    end
    local choices = {"ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1, ty__zhengnan.name)
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = ty__zhengnan.name,
        prompt = "#zhengnan-choice",
        detailed = true,
      })
      room:handleAddLoseSkills(player, choice, nil)
      if choice == "ty_ex__dangxian" then
        room:setPlayerMark(player, "ty_ex__fuli", 1)  --直接获得升级后的当先
      end
    else
      player:drawCards(3, ty__zhengnan.name)
    end
  end,
})

return ty__zhengnan
