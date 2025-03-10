local ty__fenyue = fk.CreateSkill {
  name = "ty__fenyue"
}

Fk:loadTranslationTable{
  ['ty__fenyue'] = '奋钺',
  ['#ty__fenyue'] = '奋钺：与一名角色拼点，若你赢，根据你拼点牌的点数执行效果',
  [':ty__fenyue'] = '出牌阶段限X次（X为与你不同阵营的存活角色数），你可以与一名角色拼点，若你赢，根据你拼点的牌的点数执行以下效果：小于等于K：视为对其使用一张雷【杀】；小于等于9：获得牌堆中的一张【杀】；小于等于5：获得其一张牌。',
  ['$ty__fenyue1'] = '逆贼势大，且扎营寨，击其懈怠。',
  ['$ty__fenyue2'] = '兵有其变，不在众寡。',
}

-- 主动技能效果
ty__fenyue:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#ty__fenyue",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty__fenyue.name, Player.HistoryPhase) < player:getMark("ty__fenyue-phase")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, ty__fenyue.name)
    if pindian.results[target.id].winner == player then
      if pindian.fromCard.number < 6 then
        if not target:isNude() and not player.dead then
          local id = room:askToChooseCard(player, {
            target = target,
            flag = "he",
            skill_name = ty__fenyue.name
          })
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
      if pindian.fromCard.number < 10 and not player.dead then
        local card = room:getCardsFromPileByRule("slash")
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, ty__fenyue.name, nil, true, player.id)
        end
      end
      if pindian.fromCard.number < 14 and not target.dead then
        room:useVirtualCard("thunder__slash", nil, player, target, ty__fenyue.name, true)
      end
    end
  end,
})

-- 触发技能效果
ty__fenyue:addEffect(fk.StartPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(ty__fenyue.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local friends = U.GetFriends(room, player, true, false)
    room:setPlayerMark(player, "ty__fenyue-phase", #room.alive_players - #friends)
  end,
})

return ty__fenyue
