local fengmin = fk.CreateSkill {
  name = "fengmin"
}

Fk:loadTranslationTable{
  ['fengmin'] = '丰愍',
  [':fengmin'] = '锁定技，一名角色于其回合内失去装备区的牌后，你摸其装备区空位数的牌。若此技能发动次数大于你已损失体力值，本回合失效。',
}

fengmin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return move.from and player.room:getPlayerById(move.from).phase ~= Player.NotActive and
              #player.room:getPlayerById(move.from):getCardIds("e") < 5
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(5 - #player.room.current:getCardIds("e"), skill.name)
    if player:usedSkillTimes(skill.name, Player.HistoryTurn) > player:getLostHp() and player:hasSkill(skill.name, true) then
      player.room:invalidateSkill(player, skill.name, "-turn")
    end
  end,
})

return fengmin
