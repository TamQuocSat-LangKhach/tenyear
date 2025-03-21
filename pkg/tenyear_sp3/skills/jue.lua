local jue = fk.CreateSkill {
  name = "jue"
}

Fk:loadTranslationTable{
  ['jue'] = '举讹',
  ['#jue-choose'] = '你可以发动 举讹，选择一名其他角色，视为对其随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）',
  ['#jue-invoke'] = '你可以发动 举讹，视为对 %dest 随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）',
  [':jue'] = '每轮限一次，一名角色的结束阶段，你可以视为随机对其使用【过河拆桥】、【杀】或【五谷丰登】共计X次（X为弃牌堆里于此回合内因弃置而移至此区域的牌数且至多为其体力上限，若其为你，改为你选择一名其他角色）。',
  ['$jue1'] = '尔等一家之言，难堵天下悠悠之口。',
  ['$jue2'] = '区区黄门而敛财千万，可诛其九族。',
}

jue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jue.name) and not target.dead and target.phase == Player.Finish
      and player:usedSkillTimes(jue.name, Player.HistoryRound) < 1 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
        return false
      end, end_id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        event:setCostData(self, #cards)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self)
    if target == player then
      local targets = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#jue-choose:::" .. tostring(x),
        skill_name = jue.name
      })
      if #targets > 0 then
        event:setCostData(self, {targets[1], x})
        return true
      end
    else
      x = math.min(x, target.maxHp)
      local invokeParams = {
        skill_name = jue.name,
        prompt = "#jue-invoke::" .. target.id .. ":" .. tostring(x)
      }
      if room:askToSkillInvoke(player, invokeParams) then
        room:doIndicate(player.id, {target.id})
        event:setCostData(self, {target.id, x})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    local x = math.min(event:getCostData(self)[2], to.maxHp)
    for i = 1, x, 1 do
      local cards = {}
      for _, name in ipairs({"slash", "dismantlement", "amazing_grace"}) do
        local card = Fk:cloneCard(name)
        card.skillName = jue.name
        if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
          table.insert(cards, card)
        end
      end
      if #cards == 0 then break end
      local tos = {{to.id}}
      local card = table.random(cards)
      if card.trueName == "amazing_grace" and not player:isProhibited(player, card) then
        table.insert(tos, {player.id})
      end
      room:useCard{
        from = player.id,
        tos = tos,
        card = card,
        extraUse = true
      }
      if player.dead or to.dead then break end
    end
  end,
})

return jue
