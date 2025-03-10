local fuhaiw = fk.CreateSkill {
  name = "fuhaiw"
}

Fk:loadTranslationTable{
  ['fuhaiw'] = '浮海',
  ['#fuhaiw'] = '浮海：选择一名目标，双方各展示一张手牌',
  ['#fuhaiw1-show'] = '浮海：对 %dest 发动“浮海”，展示一张手牌',
  ['#fuhaiw2-show'] = '浮海：请响应 %src 的“浮海”，展示一张手牌',
  [':fuhaiw'] = '出牌阶段对每名角色限一次，你可以展示一张手牌并选择上家或下家，该角色展示一张手牌。若你的牌点数：不小于其，你弃置你展示的牌，然后对其上家或下家重复此流程；小于其，其弃置其展示的牌，然后你与其各摸X张牌（X为你本阶段发动此技能选择过的角色数），本阶段你不能再发动〖浮海〗。',
  ['$fuhaiw1'] = '宦海沉浮，生死难料！',
  ['$fuhaiw2'] = '跨海南征，波涛起浮。',
}

fuhaiw:addEffect('active', {
  anim_type = "special",
  card_num = 0,
  target_num = 1,
  prompt = "#fuhaiw",
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("fuhaiw_invalid-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return (target:getNextAlive() == player or player:getNextAlive() == target) and
        target:getMark("fuhaiw-phase") == 0 and not target:isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local order = player:getNextAlive() == target and "right" or "left"
    while not player.dead do
      room:doIndicate(player.id, {target.id})
      room:addPlayerMark(player, "fuhaiw_count-phase", 1)
      room:setPlayerMark(target, "fuhaiw-phase", 1)
      local card1 = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = fuhaiw.name,
        cancelable = false,
        prompt = "#fuhaiw1-show::"..target.id
      })
      local n1 = Fk:getCardById(card1[1]).number
      player:showCards(card1)
      if player.dead or target.dead or target:isKongcheng() then return end
      local card2 = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = fuhaiw.name,
        cancelable = false,
        prompt = "#fuhaiw2-show:"..player.id
      })
      local n2 = Fk:getCardById(card2[1]).number
      target:showCards(card2)
      if player.dead or target.dead then return end
      if n1 >= n2 then
        if table.contains(player:getCardIds("h"), card1[1]) then
          room:throwCard(card1, fuhaiw.name, player, player)
        end
      else
        if table.contains(target:getCardIds("h"), card2[1]) then
          room:setPlayerMark(player, "fuhaiw_invalid-phase", 1)
          room:throwCard(card2, fuhaiw.name, target, target)
          if not player.dead then
            player:drawCards(player:getMark("fuhaiw_count-phase"), fuhaiw.name)
          end
          if not target.dead then
            target:drawCards(player:getMark("fuhaiw_count-phase"), fuhaiw.name)
          end
          return
        end
      end
      if player:isKongcheng() or player.dead then return end
      if order == "right" then
        target = target:getNextAlive()
      else
        target = target:getLastAlive()
      end
      if target:isKongcheng() or target:getMark("fuhaiw-phase") > 0 then return end
    end
  end,
})

return fuhaiw
