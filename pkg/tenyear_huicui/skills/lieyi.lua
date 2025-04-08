local lieyi = fk.CreateSkill {
  name = "lieyi",
}

Fk:loadTranslationTable{
  ["lieyi"] = "烈医",
  [":lieyi"] = "出牌阶段限一次，你可以展示所有“疠”并选择一名其他角色，并依次对其使用所有“疠”（无距离次数限制），不可使用的置入弃牌堆。"..
  "然后若该角色未因此进入濒死状态，你失去1点体力。",

  ["#lieyi"] = "烈医：你可以对一名角色使用所有“疠”！",
  ["jiping_li"] = "疠",
  ["#lieyi-use"] = "烈医：选择一张“疠”对 %dest 使用（若无法使用则置入弃牌堆）",
  ["#lieyi-second"] = "烈医：选择%arg的副目标",

  ["$lieyi1"] = "君有疾在身，不治将恐深。",
  ["$lieyi2"] = "汝身患重疾，当以虎狼之药去之。",
}

lieyi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#lieyi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lieyi.name, Player.HistoryPhase) == 0 and #player:getPile("jiping_li") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, "lieyi_using-phase", 1)
    room:showCards(player:getPile("jiping_li"))
    local yes = true
    while #player:getPile("jiping_li") > 0 and not player.dead and not target.dead do
      if target.dead then break end
      local id = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|jiping_li",
        prompt = "#lieyi-use::" .. target.id,
        skill_name = "jiping_li",
        cancelable = false,
        expand_pile = "jiping_li",
      })[1]
      local card = Fk:getCardById(id)
      if player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) then
        if card.skill:getMinTargetNum(player) == 2 then
          local seconds = {}
          for _, second in ipairs(room:getOtherPlayers(target, false)) do
            if card.skill:modTargetFilter(player, second, {target}, card) then
              table.insert(seconds, second)
            end
          end
          if #seconds > 0 then
            local second = room:askToChoosePlayers(player, {
              targets = seconds,
              min_num = 1,
              max_num = 1,
              prompt = "#lieyi-second:::" .. card:toLogString(),
              skill_name = lieyi.name,
              cancelable = false,
            })[1]
            room:useCard{
              from = player,
              tos = {target},
              card = card,
              subTos = {second},
            }
          end
        else
          local use = {
            from = player,
            tos = {target},
            card = card,
            extra_data = {
              lieyi_use = player,
            }
          }
          room:useCard(use)
          if use.extra_data.lieyi_dying then
            yes = false
          end
        end
      else
        room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lieyi.name, nil, true, player)
      end
    end
    if player.dead then return end
    if #player:getPile("jiping_li") > 0 then
      room:moveCardTo(player:getPile("jiping_li"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lieyi.name, nil, true, player)
    end
    room:setPlayerMark(player, "lieyi_using-phase", 0)
    if yes and not player.dead then
      room:loseHp(player, 1, lieyi.name)
    end
  end,
})

lieyi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    if data.damage and data.damage.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data
        return use.extra_data and use.extra_data.lieyi_use == player
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.lieyi_dying = true
    end
  end,
})

return lieyi
