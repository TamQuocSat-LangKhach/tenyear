local shajue = fk.CreateSkill {
  name = "shajue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，你获得一个“暴戾”标记，若其需要超过一张【桃】或【酒】救回，你获得使其进入濒死状态的牌。",

  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",
}

shajue:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shajue.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@baoli") < 3 then
      room:addPlayerMark(player, "@baoli", 1)
    end
    if target.hp < 0 and data.damage and data.damage.card and room:getCardArea(data.damage.card) == Card.Processing then
      room:obtainCard(player, data.damage.card, true, fk.ReasonJustMove, player, shajue.name)
    end
  end
})

return shajue
