local chuanyun = fk.CreateSkill {
  name = "chuanyun"
}

Fk:loadTranslationTable{
  ['chuanyun'] = '穿云',
  ['#chuanyun-invoke'] = '穿云：你可令 %dest 随机弃置一张装备区里的牌',
  [':chuanyun'] = '当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。',
  ['$chuanyun'] = '吾枪所至，人马俱亡！',
}

chuanyun:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chuanyun.name) and data.card.trueName == "slash" 
      and #player.room:getPlayerById(data.to):getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chuanyun.name,
      prompt = "#chuanyun-invoke::" .. data.to
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local card = table.random(to:getCardIds("e"))
    room:throwCard({card}, chuanyun.name, to, to)
  end,
})

return chuanyun
