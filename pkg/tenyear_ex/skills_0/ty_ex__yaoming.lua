local ty_ex__yaoming = fk.CreateSkill {
  name = "ty_ex__yaoming"
}

Fk:loadTranslationTable{
  ['ty_ex__yaoming'] = '邀名',
  ['ty_ex__yaoming_active'] = '邀名',
  ['#ty_ex__yaoming-invoke'] = '邀名：你可以执行本回合未选择的一项',
  ['ty_ex__yaoming_throw'] = '弃置一名其他角色的一张手牌',
  ['ty_ex__yaoming_draw'] = '令一名其他角色摸一张牌',
  ['#ty_ex__yaoming-recast'] = '邀名：可以弃置至多两张牌再摸等量的牌',
  [':ty_ex__yaoming'] = '每回合每项限一次，当你造成或受到伤害后，你可以选择一项：1.弃置一名其他角色的一张手牌；2.令一名其他角色摸一张牌；3.令一名角色弃置至多两张牌再摸等量的牌。',
  ['$ty_ex__yaoming1'] = '养威持重，不营小利。',
  ['$ty_ex__yaoming2'] = '则天而行，作功邀名。',
}

ty_ex__yaoming:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__yaoming.name) and (player:getMark("ty_ex__yaoming_throw-turn") == 0
      or player:getMark("ty_ex__yaoming_draw-turn") == 0 or player:getMark("ty_ex__yaoming_recast-turn") == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__yaoming_active",
      prompt = "#ty_ex__yaoming-invoke",
      cancelable = true,
    })
    if dat then
      event:setCostData(self, {dat.interaction, dat.targets[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    local to = room:getPlayerById(event:getCostData(self)[2])
    if choice == "ty_ex__yaoming_throw" then
      local cid = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = ty_ex__yaoming.name,
      })
      room:throwCard({cid}, ty_ex__yaoming.name, to, player)
    elseif choice == "ty_ex__yaoming_draw" then
      to:drawCards(1, ty_ex__yaoming.name)
    else
      local n = #room:askToDiscard(to, {
        min_num = 0,
        max_num = 2,
        include_equip = true,
        skill_name = ty_ex__yaoming.name,
        cancelable = true,
        prompt = "#ty_ex__yaoming-recast",
      })
      if n > 0 and not to.dead then
        to:drawCards(n, ty_ex__yaoming.name)
      end
    end
  end,
})

return ty_ex__yaoming
