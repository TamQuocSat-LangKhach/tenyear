local dufeng = fk.CreateSkill {
  name = "dufeng"
}

Fk:loadTranslationTable{
  ['dufeng'] = '独锋',
  ['dufeng_loseHp'] = '失去1点体力',
  ['dufeng_abort'] = '废除一个装备栏',
  ['#dufeng-abort'] = '独锋：请选择一个装备栏废除',
  [':dufeng'] = '锁定技，出牌阶段开始时，你选择至少一项：1.失去1点体力；2.废除一个装备栏。然后你摸X张牌，并将你的攻击范围和出牌阶段使用【杀】的次数上限改为X（X为你已损失的体力值与已废除的装备栏数之和，且至多为你的体力上限）。',
  ['$dufeng1'] = '不畏死者，都随我来！',
  ['$dufeng2'] = '大功当前，小损又何妨！',
}

dufeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(dufeng.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choiceList = { "dufeng_loseHp" }
    if #player:getAvailableEquipSlots() > 0 then
      table.insert(choiceList, "dufeng_abort")
    end

    local choices = room:askToChoices(player, {
      choices = choiceList,
      min_num = 1,
      max_num = 2,
      skill_name = dufeng.name,
      all_choices = { "dufeng_loseHp", "dufeng_abort" }
    })

    local toAbort
    if table.contains(choices, "dufeng_abort") then
      toAbort = room:askToChoice(player, {
        choices = player:getAvailableEquipSlots(),
        skill_name = dufeng.name,
        prompt = "#dufeng-abort"
      })
    end

    if table.contains(choices, "dufeng_loseHp") then
      room:loseHp(player, 1, dufeng.name)
    end
    if not player:isAlive() then
      return false
    end

    if toAbort then
      room:abortPlayerArea(player, toAbort)
    end

    local num = math.min(player:getLostHp() + #player.sealedSlots, player.maxHp)
    if player:isAlive() and num > 0 then
      player:drawCards(num, dufeng.name)
      room:setPlayerMark(player, "dufeng_buff", num)
    end
  end,
})

dufeng:addEffect('atkrange', {
  fixed_func = function(self, from)
    if from:getMark("dufeng_buff") > 0 then
      return from:getMark("dufeng_buff")
    end
  end,
})

dufeng:addEffect('targetmod', {
  residue_func = function(self, player, skillObj, scope)
    if skillObj.trueName == "slash_skill" and player:getMark("dufeng_buff") > 0 and scope == Player.HistoryPhase then
      return player:getMark("dufeng_buff") - 1
    end
  end,
})

return dufeng
