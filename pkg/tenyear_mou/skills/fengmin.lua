local fengmin = fk.CreateSkill {
  name = "fengmin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengmin"] = "丰愍",
  [":fengmin"] = "锁定技，一名角色于其回合内失去装备区的牌后，你摸其装备区空位数的牌。若此技能发动次数大于你已损失体力值，本回合失效。",
}

fengmin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengmin.name) then
      for _, move in ipairs(data) do
        if move.from and player.room.current == move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return move.from:hasEmptyEquipSlot()
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, sub_type in ipairs({3, 4, 5, 6, 7}) do
      n = n + #room.current:getAvailableEquipSlots(sub_type) - #room.current:getEquipments(sub_type)
    end
    player:drawCards(n, fengmin.name)
    if player:usedSkillTimes(fengmin.name, Player.HistoryTurn) > player:getLostHp() and player:hasSkill(fengmin.name, true) then
      player.room:invalidateSkill(player, fengmin.name, "-turn")
    end
  end,
})

return fengmin
