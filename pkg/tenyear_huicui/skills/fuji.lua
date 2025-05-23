local fuji = fk.CreateSkill {
  name = "ty__fuji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__fuji"] = "伏骑",
  [":ty__fuji"] = "锁定技，你距离其为1的其他角色不能响应你使用的【杀】或普通锦囊牌。",

  ["$ty__fuji1"] = "既来之，休走之！",
  ["$ty__fuji2"] = "白马？哼！定叫他有来无回！",
}

fuji:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuji.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:distanceTo(p) == 1
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      if player:distanceTo(p) == 1 then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

return fuji
