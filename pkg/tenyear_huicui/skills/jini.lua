local jini = fk.CreateSkill {
  name = "jini",
}

Fk:loadTranslationTable{
  ["jini"] = "击逆",
  [":jini"] = "当你受到伤害后，你可以重铸任意张手牌（每回合以此法重铸的牌数不能超过你的体力上限），若你以此法获得了【杀】，"..
  "你可以对伤害来源使用一张无距离限制且不可响应的【杀】。",

  ["#jini1-invoke"] = "击逆：重铸至多%arg张手牌",
  ["#jini2-invoke"] = "击逆：重铸至多%arg张手牌，若摸到了【杀】，你可以对 %dest 使用一张不可响应的【杀】",
  ["#jini-slash"] = "击逆：你可以对 %dest 使用一张不可响应的【杀】",

  ["$jini1"] = "备劲弩强刃，待恶客上门。",
  ["$jini2"] = "逆贼犯境，诸君当共击之。",
}

jini:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jini.name) and not player:isKongcheng() and
      player:getMark("jini-turn") < player.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp - player:getMark("jini-turn")
    local prompt = "#jini1-invoke:::"..n
    if data.from and data.from ~= player and not data.from.dead then
      prompt = "#jini2-invoke::"..data.from.id..":"..n
    end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = n,
      skill_name = jini.name,
      cancelable = true,
      prompt = prompt,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    cards = room:recastCard(cards, player, jini.name)
    if player.dead then return end
    room:addPlayerMark(player, "jini-turn", #cards)
    if not data.from or data.from == player or data.from.dead or
      not player:canUseTo(Fk:cloneCard("slash"), data.from, {bypass_distances = true, bypass_times = true}) then return end
    if table.find(cards, function(id)
      return Fk:getCardById(id).trueName == "slash"
    end) then
      local use = room:askToUseCard(player, {
        pattern = "slash",
        skill_name = "slash",
        prompt = "#jini-slash::"..data.from.id,
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          exclusive_targets = {data.from.id},
        }
      })
      if use then
        use.disresponsiveList = table.simpleClone(room.players)
        room:useCard(use)
      end
    end
  end,
})

return jini
