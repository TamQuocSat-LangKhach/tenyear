local ty__sijian = fk.CreateSkill {
  name = "ty__sijian"
}

Fk:loadTranslationTable{
  ['ty__sijian'] = '死谏',
  ['#ty__sijian-ask'] = '死谏：你可弃置一名其他角色的一张牌',
  [':ty__sijian'] = '当你失去手牌后，若你没有手牌，你可弃置一名其他角色的一张牌。',
  ['$ty__sijian1'] = '且听我最后一言！',
  ['$ty__sijian2'] = '忠言逆耳啊！',
}

ty__sijian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__sijian.name) or not player:isKongcheng() then return end
    local ret = false
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            ret = true
            break
          end
        end
      end
    end
    if ret then
      return table.find(player.room.alive_players, function(p) return not p:isNude() end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return not p:isNude() end), Util.IdMapper)
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__sijian-ask",
      skill_name = ty__sijian.name,
      cancelable = true
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = ty__sijian.name
    })
    room:throwCard({id}, ty__sijian.name, to, player)
  end,
})

return ty__sijian
