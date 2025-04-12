local yonglue = fk.CreateSkill {
  name = "ty_ex__yonglue",
}

Fk:loadTranslationTable{
  ["ty_ex__yonglue"] = "勇略",
  [":ty_ex__yonglue"] = "其他角色的判定阶段开始时，你可以弃置其判定区里的一张牌，然后若该角色：在你的攻击范围内，你摸一张牌；"..
  "在你的攻击范围外，视为你对其使用一张【杀】。",

  ["#ty_ex__yonglue-invoke"] = "勇略：你可以弃置 %dest 判定区一张牌",

  ["$ty_ex__yonglue1"] = "兵势勇健，战胜攻取，无不如志！",
  ["$ty_ex__yonglue2"] = "雄才大略，举无遗策，威震四海！",
}

yonglue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yonglue.name) and target ~= player and target.phase == Player.Judge and
      #target:getCardIds("j") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yonglue.name,
      prompt = "#ty_ex__yonglue-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "j",
      skill_name = yonglue.name,
    })
    room:throwCard(card, yonglue.name, target, player)
    if player.dead or target.dead then return end
    if player:inMyAttackRange(target) then
      player:drawCards(1, yonglue.name)
    else
      room:useVirtualCard("slash", nil, player, target, yonglue.name, true)
    end
  end,
})

return yonglue
