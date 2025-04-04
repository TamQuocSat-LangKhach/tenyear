local wuxie = fk.CreateSkill {
  name = "wuxie",
}

Fk:loadTranslationTable{
  ["wuxie"] = "无胁",
  [":wuxie"] = "出牌阶段结束时，你可以选择一名其他角色，你与其将手牌中所有伤害牌放置在牌堆底，然后你可以令放置牌较多的角色回复1点体力。",

  ["#wuxie-choose"] = "无胁：选择一名角色，将你与其手牌中所有伤害牌置于牌堆底，可以令放置牌较多的角色回复体力",
  ["#wuxie-recover"] = "无胁：你可以令一名角色回复1点体力",

  ["$wuxie1"] = "一个弱质女流，安能登辇拔剑？",
  ["$wuxie2"] = "主上既亡，我当为生者计。",
}

wuxie:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuxie.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#wuxie-choose",
      skill_name = wuxie.name,
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
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    local x = #cards
    if x > 0 then
      table.shuffle(cards)
      room:moveCards{
        ids = cards,
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = wuxie.name,
        drawPilePosition = -1,
        moveVisible = false,
      }
    end
    local y = 0
    if not to.dead then
      cards = table.filter(to:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end)
      y = #cards
      if y > 0 then
        table.shuffle(cards)
        room:moveCards{
          ids = cards,
          from = to,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = wuxie.name,
          drawPilePosition = -1,
          moveVisible = false,
        }
      end
    end
    if player.dead then return end
    local targets = {}
    if x > y then
      if not player:isWounded() then return end
      targets = {player}
    elseif x == y then
      if player:isWounded() then
        targets = {player}
      end
      if not to.dead and to:isWounded() then
        table.insert(targets, to)
      end
      if #targets == 0 then return end
    else
      if to.dead or not to:isWounded() then return end
      targets = {to}
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#wuxie-recover",
      skill_name = wuxie.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:recover{
        who = tos[1],
        num = 1,
        recoverBy = player,
        skillName = wuxie.name,
      }
    end
  end,
})

return wuxie
