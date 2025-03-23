local yuanmo = fk.CreateSkill {
  name = "yuanmo"
}

Fk:loadTranslationTable{
  ['yuanmo'] = '远谟',
  ['#yuanmo1-invoke'] = '远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌',
  ['#yuanmo2-invoke'] = '远谟：你可以令攻击范围+1',
  ['@yuanmo'] = '远谟',
  ['yuanmo_add'] = '攻击范围+1，获得因此进入攻击范围的角色各一张牌',
  ['yuanmo_minus'] = '攻击范围-1，摸两张牌',
  ['#yuanmo-choose'] = '远谟：你可以获得任意名角色各一张牌',
  ['#yuanmo-prey'] = '远谟：选择 %src 的一张牌获得',
  [':yuanmo'] = '①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。',
  ['$yuanmo1'] = '强敌不可战，弱敌不可恕。',
  ['$yuanmo2'] = '孙伯符羽翼已丰，主公当图刘备。',
}

yuanmo:addEffect({fk.EventPhaseStart, fk.Damaged}, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yuanmo.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askToSkillInvoke(player, {
      skill_name = yuanmo.name,
      prompt = prompt,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askToChoice(player, {
        choices = {"yuanmo_add", "yuanmo_minus"},
        skill_name = yuanmo.name,
      })
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = #targets,
          skill_name = yuanmo.name,
          prompt = "#yuanmo-choose",
        })
        if #tos > 0 then
          room:sortPlayersByAction(tos)
          for _, id in ipairs(tos) do
            if player.dead then break end
            local p = room:getPlayerById(id)
            if not p.dead and not p:isNude() then
              local card = room:askToChooseCard(player, {
                target = p,
                flag = "he",
                skill_name = yuanmo.name,
                prompt = "#yuanmo-prey:" .. id,
              })
              room:obtainCard(player.id, card, false, fk.ReasonPrey)
            end
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, yuanmo.name)
      end
    end
  end,
})

local yuanmo_attackrange = fk.CreateAttackRangeSkill {
  name = "#yuanmo_attackrange",
}

yuanmo_attackrange:addEffect('atkrange', {
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
})

return yuanmo
