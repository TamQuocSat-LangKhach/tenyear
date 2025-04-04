local chuanxin = fk.CreateSkill {
  name = "ty__chuanxin",
}

Fk:loadTranslationTable{
  ["ty__chuanxin"] = "穿心",
  [":ty__chuanxin"] = "当你于出牌阶段内使用【杀】或【决斗】对目标角色造成伤害时，你可以防止此伤害。若如此做，该角色选择一项："..
  "1.弃置装备区内的所有牌，然后失去1点体力；2.弃置两张手牌，然后非锁定技失效直到回合结束。",

  ["#ty__chuanxin-invoke"] = "穿心：是否防止对 %dest 造成的伤害，令其选择一项？",
  ["ty__chuanxin1"] = "弃置所有装备，失去1点体力",
  ["ty__chuanxin2"] = "弃置两张手牌，本回合非锁定技失效",
  ["@@ty__chuanxin-turn"] = "穿心",

  ["$ty__chuanxin1"] = "一箭穿心，哪里可逃？",
  ["$ty__chuanxin2"] = "穿心之痛，细细品吧，哈哈哈哈！",
}

chuanxin:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(chuanxin.name) and player.phase == Player.Play and
      data.card and table.contains({"slash", "duel"}, data.card.trueName) and player.room.logic:damageByCardEffect()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chuanxin.name,
      prompt = "#ty__chuanxin-invoke::"..data.to.id
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local all_choices = {"ty__chuanxin1", "ty__chuanxin2"}
    local choices = table.clone(all_choices)
    if #data.to:getCardIds("e") == 0 then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(data.to, {
      choices = choices,
      skill_name = chuanxin.name,
      all_choices = all_choices,
    })
    if choice == "ty__chuanxin1" then
      data.to:throwAllCards("e", chuanxin.name)
      if not data.to.dead then
        room:loseHp(data.to, 1, chuanxin.name)
      end
    else
      room:askToDiscard(data.to, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = chuanxin.name,
        cancelable = false
      })
      if not data.to.dead then
        room:setPlayerMark(data.to, "@@ty__chuanxin-turn", 1)
        room:addPlayerMark(data.to, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      end
    end
  end,
})

return chuanxin
