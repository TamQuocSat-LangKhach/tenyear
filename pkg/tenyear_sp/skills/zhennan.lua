local zhennan = fk.CreateSkill {
  name = "ty__zhennan",
}

Fk:loadTranslationTable{
  ["ty__zhennan"] = "镇南",
  [":ty__zhennan"] = "当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。",

  ["#ty__zhennan-choose"] = "镇南：你可以对一名其他角色造成1点伤害",

  ["$ty__zhennan1"] = "遵丞相之志，护南中安乐。",
  ["$ty__zhennan2"] = "哼，又想扰乱南中安宁？",
}

zhennan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhennan.name) and data.card:isCommonTrick() and data.firstTarget and
      #data.use.tos > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__zhennan-choose",
      skill_name = zhennan.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = zhennan.name,
    }
  end,
})

return zhennan
