local jini = fk.CreateSkill {
  name = "jini"
}

Fk:loadTranslationTable{
  ['jini'] = '击逆',
  ['#jini1-invoke'] = '击逆：你可以重铸至多%arg张手牌',
  ['#jini2-invoke'] = '击逆：你可以重铸至多%arg张手牌，若摸到了【杀】，你可以对 %dest 使用一张无距离限制且不可响应的【杀】',
  ['#jini-slash'] = '击逆：你可以对 %dest 使用一张无距离限制且不可响应的【杀】',
  [':jini'] = '当你受到伤害后，你可以重铸任意张手牌（每回合以此法重铸的牌数不能超过你的体力上限），若你以此法获得了【杀】，你可以对伤害来源使用一张无距离限制且不可响应的【杀】。',
  ['$jini1'] = '备劲弩强刃，待恶客上门。',
  ['$jini2'] = '逆贼犯境，诸君当共击之。',
}

jini:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jini.name) and not player:isKongcheng() and player:getMark("jini-turn") < player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.maxHp - player:getMark("jini-turn")
    local prompt = "#jini1-invoke:::"..n
    if data.from and data.from ~= player and not data.from.dead then
      prompt = "#jini2-invoke::"..data.from.id..":"..n
    end
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = n,
      pattern = ".",
      skill_name = jini.name,
      cancelable = true,
      prompt = prompt
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #event:getCostData(self)
    room:moveCards({
      ids = event:getCostData(self),
      from = player.id,
      toArea = Card.DiscardPile,
      skillName = jini.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = target.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = player.id,
      card = event:getCostData(self),
      arg = jini.name,
    }
    local cards = player:drawCards(n, jini.name)
    room:addPlayerMark(player, "jini-turn", n)
    if player.dead or not data.from or data.from == player or data.from.dead then return end
    if table.find(cards, function(id) return Fk:getCardById(id, true).trueName == "slash" end) then
      local use = room:askToUseCard(player, {
        pattern = "slash",
        skill_name = "slash",
        prompt = "#jini-slash::"..data.from.id,
        cancelable = true,
        extra_data = {must_targets = {data.from.id}, bypass_distances = true, bypass_times = true}
      })
      if use then
        use.disresponsiveList = {data.from.id}
        room:useCard(use)
      end
    end
  end,
})

return jini
