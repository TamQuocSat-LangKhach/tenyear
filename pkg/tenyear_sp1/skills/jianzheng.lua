local jianzheng = fk.CreateSkill {
  name = "jianzheng"
}

Fk:loadTranslationTable{
  ['jianzheng'] = '谏诤',
  ['#jianzheng-prompt'] = '谏诤：你可观看一名其他角色的手牌，且可以获得并使用其中一张',
  ['#jianzheng-choose'] = '谏诤：选择一张使用',
  ['#jianzheng-use'] = '谏诤：请使用%arg',
  [':jianzheng'] = '出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。若此牌指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。',
  ['$jianzheng1'] = '将军今出洛阳，恐难再回。',
  ['$jianzheng2'] = '贼示弱于外，必包藏祸心。',
}

jianzheng:addEffect('active', {
  name = "jianzheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  prompt = "#jianzheng-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(jianzheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local availableCards = table.filter(cards, function(id)
      local card = Fk:getCardById(id)
      return U.getDefaultTargets(player, card, true, false)
    end)
    local get, _ = U.askforChooseCardsAndChoice(player, availableCards, {"OK"}, jianzheng.name, "#jianzheng-choose", {"Cancel"}, 1, 1, cards)
    local yes = false
    if #get > 0 then
      local id = get[1]
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if not player.dead and table.contains(player:getCardIds("h"), id) and U.getDefaultTargets(player, card, true, false) then
        local use = room:askToUseRealCard(player, {
          pattern = {id},
          skill_name = jianzheng.name,
          prompt = "#jianzheng-use:::"..card:toLogString(),
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
        })
        if use and table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
          yes = true
        end
      end
    end
    if yes then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
      if not player.dead and not target.dead and not player:isKongcheng() then
        U.viewCards(target, player:getCardIds("h"), jianzheng.name, "$ViewCardsFrom:"..player.id)
      end
    end
  end,
})

return jianzheng
