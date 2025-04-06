local sijian = fk.CreateSkill {
  name = "ty__sijian",
}

Fk:loadTranslationTable{
  ["ty__sijian"] = "死谏",
  [":ty__sijian"] = "当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。",

  ["#ty__sijian-choose"] = "死谏：你可以弃置一名其他角色的一张牌",

  ["$ty__sijian1"] = "且听我最后一言！",
  ["$ty__sijian2"] = "忠言逆耳啊！",
}

sijian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(sijian.name) and player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return table.find(player.room:getOtherPlayers(player, false), function(p)
                return not p:isNude()
              end)
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__sijian-choose",
      skill_name = sijian.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = sijian.name,
    })
    room:throwCard(id, sijian.name, to, player)
  end,
})

return sijian
