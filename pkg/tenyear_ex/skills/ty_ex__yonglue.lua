local ty_ex__yonglue = fk.CreateSkill {
  name = "ty_ex__yonglue"
}

Fk:loadTranslationTable{
  ['ty_ex__yonglue'] = '勇略',
  ['#ty_ex__yonglue-invoke'] = '勇略：你可以弃置 %dest 判定区一张牌',
  [':ty_ex__yonglue'] = '其他角色的判定阶段开始时，你可以弃置其判定区里的一张牌，然后若该角色：在你的攻击范围内，你摸一张牌；在你的攻击范围外，视为你对其使用一张【杀】。',
  ['$ty_ex__yonglue1'] = '兵势勇健，战胜攻取，无不如志！',
  ['$ty_ex__yonglue2'] = '雄才大略，举无遗策，威震四海！',
}

ty_ex__yonglue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty_ex__yonglue) and target ~= player and target.phase == Player.Judge and #target:getCardIds("j") > 0
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__yonglue.name,
      prompt = "#ty_ex__yonglue-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local card = #target:getCardIds("j") == 1 and target:getCardIds("j")[1] or
    room:askToChooseCard(player, {
      target = target,
      flag = "j",
      skill_name = ty_ex__yonglue.name
    })
    room:throwCard({card}, ty_ex__yonglue.name, target, player)
    if player.dead or target.dead then return end
    if player:inMyAttackRange(target) then
      player:drawCards(1, ty_ex__yonglue.name)
    else
      room:useVirtualCard("slash", nil, player, target, ty_ex__yonglue.name, true)
    end
  end,
})

return ty_ex__yonglue
