local ty_ex__dangxian = fk.CreateSkill {
  name = "ty_ex__dangxian"
}

Fk:loadTranslationTable{
  ['ty_ex__dangxian'] = '当先',
  ['ty_ex__fuli'] = '伏枥',
  ['#ty_ex__dangxian-invoke'] = '当先：你可以失去1点体力，从弃牌堆获得一张【杀】',
  [':ty_ex__dangxian'] = '锁定技，回合开始时，你执行一个额外的出牌阶段，此阶段开始时你失去1点体力并从弃牌堆获得一张【杀】。',
  ['$ty_ex__dangxian1'] = '竭诚当先，一举克定！',
  ['$ty_ex__dangxian2'] = '一马当先，奋勇杀敌！',
}

ty_ex__dangxian:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty_ex__dangxian.name) then
      return data.to == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty_ex__dangxian-phase", 1)
    player:gainAnExtraPhase(Player.Play)
  end,
})

ty_ex__dangxian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty_ex__dangxian.name) then
      return player.phase == Player.Play and player:getMark("ty_ex__dangxian-phase") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty_ex__dangxian-phase", 0)
    if player:getMark("ty_ex__fuli") == 0 or room:askToSkillInvoke(player, { skill_name = ty_ex__dangxian.name, prompt = "#ty_ex__dangxian-invoke" }) then
      --为了加强关索，不用技能次数判断
      room:loseHp(player, 1, ty_ex__dangxian.name)
      if not player.dead then
        local cards = room:getCardsFromPileByRule("slash", 1, "discardPile")
        if #cards > 0 then
          room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
        end
      end
    end
  end,
})

return ty_ex__dangxian
