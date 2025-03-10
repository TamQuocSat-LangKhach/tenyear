local heqia = fk.CreateSkill {
  name = "heqia"
}

Fk:loadTranslationTable{
  ['heqia'] = '和洽',
  ['heqia_active'] = '和洽',
  ['#heqia-invoke'] = '和洽：交给一名其他角色至少一张牌，或选择一名角色将至少一张牌交给你',
  ['#heqia-give'] = '和洽：交给 %src 至少一张牌',
  ['heqia_viewas'] = '和洽',
  ['#heqia-use'] = '和洽：你可以将一张手牌当任意基本牌使用，可以指定%arg个目标',
  [':heqia'] = '出牌阶段开始时，你可以选择一项：1.你交给一名其他角色至少一张牌；2.令一名有手牌的其他角色交给你至少一张牌。然后获得牌的角色可以将一张手牌当任意基本牌使用（无距离限制），且此牌目标上限改为X（X为其本次获得的牌数）。',
  ['$heqia1'] = '和洽不基，贵贱无司。',
  ['$heqia2'] = '教化大行，天下和洽。',
}

heqia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(heqia) and player.phase == Player.Play and (not player:isNude() or
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end))
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "heqia_active",
      prompt = "#heqia-invoke",
      cancelable = true,
      no_indicate = false,
    })
    if success and dat then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to
    local to_get
    local cost_data = event:getCostData(self)
    if #cost_data.cards > 0 then
      to = room:getPlayerById(cost_data.targets[1])
      to_get = cost_data.cards
    else
      to = player
      local src = room:getPlayerById(cost_data.targets[1])
      to_get = room:askToCards(src, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = heqia.name,
        cancelable = false,
        prompt = "#heqia-give:"..player.id
      })
    end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonGive, heqia.name, nil, false, player.id)
    if to.dead or to:isKongcheng() then return end
    room:setPlayerMark(to, "heqia-tmp", #to_get)
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "heqia_viewas",
      prompt = "#heqia-use:::"..#to_get,
      cancelable = true
    })
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      room:useCard{
        from = to.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,
})

return heqia
