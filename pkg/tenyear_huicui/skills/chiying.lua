local chiying = fk.CreateSkill {
  name = "chiying",
}

Fk:loadTranslationTable{
  ["chiying"] = "驰应",
  [":chiying"] = "出牌阶段限一次，你可以选择一名体力值不大于你的角色，其可以弃置其攻击范围内任意名其他角色各一张牌。"..
  "若选择的角色不为你，其获得其中的基本牌。",

  ["#chiying"] = "驰应：选择一名角色，其可以弃置攻击范围内其他角色各一张牌",
  ["#chiying-choose"] = "驰应：你可以弃置攻击范围内任意名角色各一张牌",
  ["#chiying-discard"] = "驰应：弃置 %dest 一张牌",

  ["$chiying1"] = "今诱老贼来此，必折其父子于上方谷。",
  ["$chiying2"] = "列柳城既失，当下唯死守阳平关。",
}

chiying:addEffect("active", {
  anim_type = "control",
  prompt = "#chiying",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chiying.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.hp <= player.hp
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return target:inMyAttackRange(p) and not p:isNude()
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(target, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#chiying-choose",
      skill_name = chiying.name,
      cancelable = true,
    })
    if #tos == 0 then return end
    room:sortByAction(tos)
    local ids = {}
    for _, p in ipairs(tos) do
      if target.dead then return end
      if not p.dead and not p:isNude() then
        local card = room:askToChooseCard(target, {
          target = p,
          flag = "he",
          skill_name = chiying.name,
          prompt = "#chiying-discard::" .. p.id,
        })
        room:throwCard(card, chiying.name, p, target)
        if target ~= player and card and Fk:getCardById(card).type == Card.TypeBasic then
          table.insertIfNeed(ids, card)
        end
      end
    end
    if #ids == 0 or target.dead then return end
    ids = table.filter(ids, function(id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids == 0 then return end
    room:moveCardTo(ids, Card.PlayerHand, target, fk.ReasonJustMove, chiying.name, nil, true, target)
  end,
})

return chiying
