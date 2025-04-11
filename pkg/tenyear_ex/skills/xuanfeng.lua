local xuanfeng = fk.CreateSkill {
  name = "ty_ex__xuanfeng",
}

Fk:loadTranslationTable{
  ["ty_ex__xuanfeng"] = "旋风",
  [":ty_ex__xuanfeng"] = "当你失去装备区里的牌后，或当你于弃牌阶段弃置至少两张牌时，若没有角色处于濒死状态，你可以依次弃置一至两名"..
  "其他角色的共计两张牌。若此时是你的回合内，你可以对其中一名角色造成1点伤害。",

  ["#ty_ex__xuanfeng-choose"] = "旋风：你可以依次弃置一至两名其他角色的共计两张牌",
  ["#ty_ex__xuanfeng-damage"] = "旋风：你可以对其中一名角色造成1点伤害",

  ["$ty_ex__xuanfeng1"] = "风动扬帆起，枪出敌军溃！",
  ["$ty_ex__xuanfeng2"] = "御风而动，敌军四散！",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = xuanfeng.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ty_ex__xuanfeng-choose",
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
    local tos = {to}
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = xuanfeng.name,
    })
    room:throwCard(card, xuanfeng.name, to, player)
    if player.dead then return false end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    if #targets > 0 then
      to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__xuanfeng-choose",
      skill_name = xuanfeng.name,
      cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = xuanfeng.name,
        })
        room:throwCard(card, xuanfeng.name, to, player)
        table.insertIfNeed(tos, to)
      end
    end
    if room.current == player and not player.dead then
      tos = table.filter(tos, function (p)
        return not p.dead
      end)
      if #tos > 0 then
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = tos,
          skill_name = xuanfeng.name,
          prompt = "#ty_ex__xuanfeng-damage",
          cancelable = true,
        })
        if #to > 0 then
          room:damage{
            from = player,
            to = to[1],
            damage = 1,
            skillName = xuanfeng.name,
          }
        end
      end
    end
  end,
}

xuanfeng:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xuanfeng.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return table.find(player.room:getOtherPlayers(player, false), function (p)
                return not p:isNude()
              end)
            end
          end
        end
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xuanfeng:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xuanfeng.name) and player.phase == Player.Discard and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                n = n + 1
                if n > 1 then return true end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return n > 1
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return xuanfeng
