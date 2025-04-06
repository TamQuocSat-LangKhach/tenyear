local juetao = fk.CreateSkill {
  name = "juetao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名其他角色，依次使用牌堆底的牌直到你无法使用，这些牌不能指定"..
  "除你和该角色以外的角色为目标。",

  ["#juetao-choose"] = "决讨：指定一名其他角色，连续对你或其使用牌堆底牌直到不能使用！",
  ["#juetao-ask"] = "决讨：是否使用%arg？",
  ["#juetao-use"] = "决讨：是否对 %dest 使用%arg？",
  ["#juetao-target"] = "决讨：选择你使用%arg的目标",

  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！"
}

juetao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juetao.name) and player.phase == Player.Play and
      player.hp == 1 and player:usedSkillTimes(juetao.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#juetao-choose",
      skill_name = juetao.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    while not player.dead and not to.dead do
      local id = room:getNCards(1, "bottom")[1]
      room:turnOverCardsFromDrawPile(player, {id}, juetao.name)
      local card = Fk:getCardById(id)
      local tos, subTos
      if player:canUse(card, { bypass_times = true, bypass_distances = true }) and not player:prohibitUse(card) then
        local targets = {}
        for _, p in ipairs({player, to}) do
          if not player:isProhibited(p, card) then
            if card.skill:modTargetFilter(player, p, {}, card, {bypass_times = true, bypass_distances = true}) then
              table.insert(targets, p)
            end
          end
        end
        if #targets > 0 then
          if card.skill:getMinTargetNum(player) == 0 then
            if not card.multiple_targets then
              if table.contains(targets, player) then
                tos = {player}
              end
            else
              tos = targets
            end
            if not room:askToSkillInvoke(player, {
              skill_name = juetao.name,
              prompt = "#juetao-ask:::"..card:toLogString(),
            }) then
              tos = nil
            end
          elseif card.skill:getMinTargetNum(player) == 2 then
            if table.contains(targets, to) then
              subTos = {player}
            end
          else
            if #targets == 1 then
              if room:askToSkillInvoke(player, {
                skill_name = juetao.name,
                prompt = "#juetao-use::"..targets[1].id..":"..card:toLogString()
              }) then
                tos = targets
              end
            else
              local temp = room:askToChoosePlayers(player, {
                targets = targets,
                min_num = 1,
                max_num = #targets,
                prompt = "#juetao-target:::"..card:toLogString(),
                skill_name = juetao.name
              })
              if #temp > 0 then
                tos = temp
              end
            end
          end
        end
      end
      if tos then
        room:useCard{
          card = card,
          from = player,
          tos = tos,
          skillName = juetao.name,
          extraUse = true,
          subTos = subTos,
        }
      else
        room:delay(800)
        room:cleanProcessingArea({id}, juetao.name)
        return
      end
    end
  end,
})

return juetao
