local jue = fk.CreateSkill {
  name = "jue",
}

Fk:loadTranslationTable{
  ["jue"] = "举讹",
  [":jue"] = "每轮限一次，一名角色的结束阶段，你可以视为随机对其使用【过河拆桥】、【杀】或【五谷丰登】共计X次（X为本回合因弃置而进入弃牌堆的牌数，"..
  "至多为其体力上限）；若为你，改为你选择一名其他角色。",

  ["#jue-choose"] = "举讹：选择一名角色，视为对其使用随机【过河拆桥】【杀】或【五谷丰登】",
  ["#jue-invoke"] = "举讹：是否视为对 %dest 使用%arg张随机【过河拆桥】【杀】或【五谷丰登】？",

  ["$jue1"] = "尔等一家之言，难堵天下悠悠之口。",
  ["$jue2"] = "区区黄门而敛财千万，可诛其九族。",
}

jue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jue.name) and not target.dead and target.phase == Player.Finish and
      player:usedSkillTimes(jue.name, Player.HistoryRound) < 1 then
      if target == player then
        if #player.room:getOtherPlayers(player, false) == 0 then return end
      end
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return table.contains(player.room.discard_pile, id)
      end)
      if #cards > 0 then
        event:setCostData(self, {choice = #cards})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self).choice
    if target == player then
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#jue-choose:::"..x,
        skill_name = jue.name,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = x})
        return true
      end
    else
      x = math.min(x, target.maxHp)
      if room:askToSkillInvoke(player, {
        skill_name = jue.name,
        prompt = "#jue-invoke::"..target.id..":"..x,
      }) then
        event:setCostData(self, {tos = {target}, choice = x})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local x = math.min(event:getCostData(self).choice, to.maxHp)
    for _ = 1, x, 1 do
      local names = {}
      for _, name in ipairs({"slash", "dismantlement", "amazing_grace"}) do
        local card = Fk:cloneCard(name)
        card.skillName = jue.name
        if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
          table.insert(names, name)
        end
      end
      if #names == 0 then break end
      local tos = {to}
      local name = table.random(names)
      if name == "amazing_grace" and not player:isProhibited(player, Fk:cloneCard(name)) then
        table.insert(tos, player)
      end
      room:useVirtualCard(name, nil, player, tos, jue.name, true)
      if player.dead or to.dead then break end
    end
  end,
})

return jue
