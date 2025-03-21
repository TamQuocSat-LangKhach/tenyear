local wuxie = fk.CreateSkill {
  name = "wuxie"
}

Fk:loadTranslationTable{
  ['wuxie'] = '无胁',
  ['#wuxie-cost'] = '是否发动 无胁，选择一名其他角色，将你与该角色手牌中的所有伤害牌放到牌堆底',
  ['#wuxie-recover'] = '无胁：可以令一名角色回复1点体力',
  [':wuxie'] = '出牌阶段结束时，你可以选择一名其他角色，你与其各将手牌区中的所有伤害类牌随机置于牌堆底，你可以令以此法失去牌较多的角色回复1点体力。',
  ['$wuxie1'] = '一个弱质女流，安能登辇拔剑？',
  ['$wuxie2'] = '主上既亡，我当为生者计。',
}

wuxie:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and player:hasSkill(wuxie.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#wuxie-cost",
      skill_name = wuxie.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = room:getPlayerById(cost_data.tos[1])
    local card
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      card = Fk:getCardById(id)
      return card.is_damage_card
    end)
    local x = #cards
    if x > 0 then
      table.shuffle(cards)
      room:moveCards{
        ids = cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = wuxie.name,
        drawPilePosition = -1,
        moveVisible = false,
      }
    end
    local y = 0
    if not to.dead then
      cards = table.filter(to:getCardIds(Player.Hand), function (id)
        card = Fk:getCardById(id)
        return card.is_damage_card
      end)
      y = #cards
      if y > 0 then
        table.shuffle(cards)
        room:moveCards{
          ids = cards,
          from = to.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = wuxie.name,
          drawPilePosition = -1,
          moveVisible = false,
        }
      end
    end
    if player.dead then return false end
    local targets = {}
    if x > y then
      if not player:isWounded() then return false end
      targets = {player.id}
    elseif x == y then
      if player:isWounded() then
        targets = {player.id}
      end
      if not to.dead and to:isWounded() then
        table.insert(targets, to.id)
      end
      if #targets == 0 then return false end
    else
      if to.dead or not to:isWounded() then return false end
      targets = {to.id}
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#wuxie-recover",
      skill_name = wuxie.name,
      cancelable = true
    })
    if #tos > 0 then
      room:recover({
        who = room:getPlayerById(tos[1].id),
        num = 1,
        recoverBy = player,
        skillName = wuxie.name
      })
    end
  end,
})

return wuxie
