local ty__chuanxin = fk.CreateSkill {
  name = "ty__chuanxin"
}

Fk:loadTranslationTable{
  ['ty__chuanxin'] = '穿心',
  ['#ty__chuanxin-invoke'] = '穿心：是否防止对 %dest 造成的伤害，令其选择一项？',
  ['ty__chuanxin1'] = '弃置所有装备，失去1点体力',
  ['ty__chuanxin2'] = '弃置两张手牌，非锁定技失效直到回合结束',
  ['@@ty__chuanxin-turn'] = '穿心',
  [':ty__chuanxin'] = '当你于出牌阶段内使用【杀】或【决斗】对目标角色造成伤害时，你可以防止此伤害。若如此做，该角色选择一项：1.弃置装备区内的所有牌，然后失去1点体力；2.弃置两张手牌，然后非锁定技失效直到回合结束。',
  ['$ty__chuanxin1'] = '一箭穿心，哪里可逃？',
  ['$ty__chuanxin2'] = '穿心之痛，细细品吧，哈哈哈哈！',
}

ty__chuanxin:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(ty__chuanxin.name) and player.phase == Player.Play and
      data.card and table.contains({"slash", "duel"}, data.card.trueName) and player.room.logic:damageByCardEffect()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__chuanxin.name,
      prompt = "#ty__chuanxin-invoke::"..data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = data.to
    local all_choices = {"ty__chuanxin1", "ty__chuanxin2"}
    local choices = table.clone(all_choices)
    if #data.to:getCardIds("e") == 0 then table.remove(choices, 1) end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = ty__chuanxin.name,
      all_choices = all_choices
    })
    if choice == "ty__chuanxin1" then
      target:throwAllCards("e")
      if not target.dead then
        room:loseHp(target, 1, ty__chuanxin.name)
      end
    else
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = ty__chuanxin.name,
        cancelable = false
      })
      if not target.dead then
        room:setPlayerMark(target, "@@ty__chuanxin-turn", 1)
        room:addPlayerMark(target, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      end
    end
    return true
  end,
})

return ty__chuanxin
