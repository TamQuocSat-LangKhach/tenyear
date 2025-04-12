local dangxian = fk.CreateSkill {
  name = "ty_ex__dangxian",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player)
    if player:getMark("ty_ex__fuli") > 0 then
      return "ty_ex__dangxian_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["ty_ex__dangxian"] = "当先",
  [":ty_ex__dangxian"] = "锁定技，回合开始时，你执行一个额外的出牌阶段，此阶段开始时你失去1点体力并从弃牌堆获得一张【杀】。",

  [":ty_ex__dangxian_update"] = "锁定技，回合开始时，你执行一个额外的出牌阶段，此阶段开始时，你可以失去1点体力并从弃牌堆获得一张【杀】。",

  ["#ty_ex__dangxian-invoke"] = "当先：你可以失去1点体力，从弃牌堆获得一张【杀】",

  ["$ty_ex__dangxian1"] = "竭诚当先，一举克定！",
  ["$ty_ex__dangxian2"] = "一马当先，奋勇杀敌！",
}

dangxian:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangxian.name)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play, dangxian.name)
  end,
})

dangxian:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangxian.name) and player.phase == Player.Play and
      data.reason == dangxian.name
  end,
  on_cost = function (self, event, target, player, data)
    if player:getMark("ty_ex__fuli") == 0 then
      return true
    else
      return player.room:askToSkillInvoke(player, {
        skill_name = dangxian.name,
        prompt = "#ty_ex__dangxian-invoke",
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, dangxian.name)
    if not player.dead then
      local cards = room:getCardsFromPileByRule("slash", 1, "discardPile")
      if #cards > 0 then
        room:obtainCard(player, cards, true, fk.ReasonJustMove, player, dangxian.name)
      end
    end
  end,
})

dangxian:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "ty_ex__fuli", 0)
end)

return dangxian
