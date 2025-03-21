local cansi = fk.CreateSkill {
  name = "cansi"
}

Fk:loadTranslationTable{
  ['cansi'] = '残肆',
  ['#cansi-choose'] = '残肆：选择一名角色，令其回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】',
  ['#cansi_draw'] = '残肆',
  [':cansi'] = '锁定技，准备阶段，你选择一名其他角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】，其每因此受到1点伤害，你摸两张牌。',
  ['$cansi1'] = '君不入地狱，谁入地狱？',
  ['$cansi2'] = '众生皆苦，唯渡众生于极乐。',
}

cansi:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cansi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = cansi.name
      })
      if player.dead then return false end
    end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      prompt = "#cansi-choose",
      skill_name = cansi.name,
      cancelable = false,
      targets = table.map(targets, function(id) return player.room:getPlayerById(id) end)
    })
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1].id)
    else
      to = room:getPlayerById(table.random(targets))
    end
    if to:isWounded() then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = cansi.name
      })
    end
    for _, card_name in ipairs({"slash", "duel", "fire_attack"}) do
      if player.dead or to.dead then break end
      local card = Fk:cloneCard(card_name)
      card.skillName = cansi.name
      if player:canUseTo(card, to, { bypass_times = true, bypass_distances = true }) then
        room:useCard({
          from = player.id,
          tos = {{to.id}},
          card = card,
          extraUse = true,
          extra_data = {cansi_source = player.id, cansi_target = to.id}
        })
      end
    end
  end,
})

cansi:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  main_skill_name = "cansi",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(cansi.name) or not data.card then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event then
      local use = use_event.data[1]
      return use.card == data.card and use.extra_data and
        use.extra_data.cansi_source == player.id and use.extra_data.cansi_target == target.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if not player:hasSkill(cansi.name) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("cansi")
    player:drawCards(2, cansi.name)
  end,
})

return cansi
