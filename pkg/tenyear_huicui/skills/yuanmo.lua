local yuanmo = fk.CreateSkill {
  name = "yuanmo",
}

Fk:loadTranslationTable{
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",

  ["@yuanmo"] = "攻击范围",
  ["#yuanmo-invoke"] = "远谟：是否令你的攻击范围+1？",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得其中任意名角色各一张牌",
  ["#yuanmo-prey"] = "远谟：获得 %dest 一张牌",

  ["$yuanmo1"] = "强敌不可战，弱敌不可恕。",
  ["$yuanmo2"] = "孙伯符羽翼已丰，主公当图刘备。",
}

yuanmo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanmo.name) and player.phase == Player.Finish and
      table.every(player.room:getOtherPlayers(player, false), function(p)
        return not player:inMyAttackRange(p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yuanmo.name,
      prompt = "#yuanmo-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
  end,
})

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {"yuanmo_add", "yuanmo_minus", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if player:getAttackRange() < 1 then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yuanmo.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "yuanmo_add" then
      local orig_targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return player:inMyAttackRange(p)
      end)
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
      local targets = {}
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        if player:inMyAttackRange(p) and not table.contains(orig_targets, p) and not p:isNude() then
          table.insert(targets, p)
        end
      end
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = #targets,
        skill_name = yuanmo.name,
        prompt = "#yuanmo-choose",
      })
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if player.dead then break end
          if not p.dead and not p:isNude() then
            local card = room:askToChooseCard(player, {
              target = p,
              flag = "he",
              skill_name = yuanmo.name,
              prompt = "#yuanmo-prey::" .. p.id,
            })
            room:obtainCard(player, card, false, fk.ReasonPrey, player, yuanmo.name)
          end
        end
      end
    else
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
      player:drawCards(2, yuanmo.name)
    end
  end,
}

yuanmo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanmo.name) and player.phase == Player.Start
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

yuanmo:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanmo.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

yuanmo:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
})

return yuanmo
