local ty__zhennan = fk.CreateSkill {
  name = "ty__zhennan"
}

Fk:loadTranslationTable{
  ['ty__zhennan'] = '镇南',
  ['#ty__zhennan-choose'] = '镇南：你可以对一名其他角色造成1点伤害',
  [':ty__zhennan'] = '当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。',
  ['$ty__zhennan1'] = '遵丞相之志，护南中安乐。',
  ['$ty__zhennan2'] = '哼，又想扰乱南中安宁？',
}

ty__zhennan:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty__zhennan.name) and data.card:isCommonTrick() and data.firstTarget and #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__zhennan-choose",
      skill_name = ty__zhennan.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(event:getCostData(self)),
      damage = 1,
      skillName = ty__zhennan.name,
    }
  end,
})

return ty__zhennan
