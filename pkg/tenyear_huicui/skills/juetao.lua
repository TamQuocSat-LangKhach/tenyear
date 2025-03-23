local juetao = fk.CreateSkill {
  name = "juetao"
}

Fk:loadTranslationTable{
  ['juetao'] = '决讨',
  ['#juetao-choose'] = '决讨：你可以指定一名其他角色，连续对你或其使用牌堆底牌直到不能使用！',
  ['#juetao-ask'] = '决讨：是否使用%arg',
  ['#juetao-second'] = '决讨：选择你使用%arg的副目标',
  ['#juetao-use'] = '决讨：是否对 %dest 使用%arg',
  ['#juetao-target'] = '决讨：选择你使用%arg的目标',
  [':juetao'] = '限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。',
  ['$juetao1'] = '登车拔剑起，奋跃搏乱臣！',
  ['$juetao2'] = '陵云决心意，登辇讨不臣！'
}

juetao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juetao.name) and player.phase == Player.Play
      and player.hp == 1 and player:usedSkillTimes(juetao.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#juetao-choose",
      skill_name = juetao.name
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    while true do
      if player.dead or to.dead then return end
      local id = U.turnOverCardsFromDrawPile(player, -1, juetao.name)[1]
      local card = Fk:getCardById(id, true)
      local canUse = player:canUse(card, { bypass_times = true, bypass_distances = true }) and not player:prohibitUse(card)
      local tos
      if canUse then
        local targets = {}
        for _, p in ipairs({player, to}) do
          if not player:isProhibited(p, card) then
            if card.skill:modTargetFilter(p.id, {}, player, card, false) then
              table.insert(targets, p.id)
            end
          end
        end
        if #targets > 0 then
          if card.skill:getMinTargetNum() == 0 then
            if not card.multiple_targets then
              if table.contains(targets, player.id) then
                tos = {player.id}
              end
            else
              tos = targets
            end
            if not room:askToSkillInvoke(player, {
              skill_name = juetao.name,
              prompt = "#juetao-ask:::"..card:toLogString()
            }) then
              tos = nil
            end
          elseif card.skill:getMinTargetNum() == 2 then
            if table.contains(targets, to.id) then
              local seconds = {}
              for _, second in ipairs(room:getOtherPlayers(to, false)) do
                if card.skill:modTargetFilter(second.id, {to.id}, player, card, false) then
                  table.insert(seconds, second.id)
                end
              end
              if #seconds > 0 then
                local temp = room:askToChoosePlayers(player, {
                  targets = seconds,
                  min_num = 1,
                  max_num = 1,
                  prompt = "#juetao-second:::"..card:toLogString(),
                  skill_name = juetao.name
                })
                if #temp > 0 then
                  tos = {to.id, temp[1]}
                end
              end
            end
          else
            if #targets == 1 then
              if room:askToSkillInvoke(player, {
                skill_name = juetao.name,
                prompt = "#juetao-use::"..targets[1]..":"..card:toLogString()
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
        room:useCard({
          card = card,
          from = player.id,
          tos = table.map(tos, function(p) return {p} end),
          skillName = juetao.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:cleanProcessingArea({id}, juetao.name)
        return
      end
    end
  end,
})

return juetao
