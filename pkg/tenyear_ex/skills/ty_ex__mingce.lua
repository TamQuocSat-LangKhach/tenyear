local ty_ex__mingce = fk.CreateSkill {
  name = "ty_ex__mingce"
}

Fk:loadTranslationTable{
  ['ty_ex__mingce'] = '明策',
  ['#ty_ex__mingce-active'] = '发动 明策，选择一张装备牌或【杀】，选择一名其他角色和出【杀】的目标角色',
  ['ty_ex__mingce_slash'] = '视为使用【杀】',
  ['#ty_ex__mingce-choose'] = '明策：选择视为对%dest使用【杀】，或与%src各摸一张牌',
  [':ty_ex__mingce'] = '出牌阶段限一次，你可以交给一名其他角色一张装备牌或【杀】，其选择一项：1.视为对另一名由你指定的角色使用【杀】，若此【杀】造成伤害，你与其各摸一张牌；2.你与其各摸一张牌。',
  ['$ty_ex__mingce1'] = '阁下若纳此谋，则大业可成也！',
  ['$ty_ex__mingce2'] = '形势如此，将军可按计行事。',
}

ty_ex__mingce:addEffect('active', {
  anim_type = "support",
  prompt = "#ty_ex__mingce-active",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__mingce.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).trueName == "slash" or Fk:getCardById(to_select).type == Card.TypeEquip)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected > 1 then return false end
    if #selected == 0 then
      return to_select ~= player.id
    elseif selected[1] ~= player.id then
      local slash = Fk:cloneCard("slash")
      slash.skillName = ty_ex__mingce.name
      return Fk:currentRoom():getPlayerById(selected[1]):canUseTo(
        slash, Fk:currentRoom():getPlayerById(to_select), { bypass_distances = true, bypass_times = true })
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local to = room:getPlayerById(effect.tos[2])
    room:obtainCard(target, effect.cards, true, fk.ReasonGive, player.id)
    if target.dead then return end
    local choice = room:askToChoice(target, {
      choices = {"ty_ex__mingce_slash", "draw1"},
      skill_name = ty_ex__mingce.name,
      prompt = "#ty_ex__mingce-choose:" .. effect.from .. ":" .. effect.tos[2],
    })
    if choice == "ty_ex__mingce_slash" then
      local slash = Fk:cloneCard("slash")
      slash.skillName = ty_ex__mingce.name
      local use = {
        from = target.id,
        tos = {{effect.tos[2]}},
        card = slash,
        skillName = ty_ex__mingce.name,
        extraUse = true,
      }
      room:useCard(use)
      if use.damageDealt then
        if not player.dead then
          player:drawCards(1, ty_ex__mingce.name)
        end
        if not target.dead then
          target:drawCards(1, ty_ex__mingce.name)
        end
      end
    else
      if not player.dead then
        player:drawCards(1, ty_ex__mingce.name)
      end
      if not target.dead then
        target:drawCards(1, ty_ex__mingce.name)
      end
    end
  end,
})

return ty_ex__mingce
