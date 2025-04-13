local yaoming = fk.CreateSkill {
  name = "ty_ex__yaoming",
}

Fk:loadTranslationTable{
  ["ty_ex__yaoming"] = "邀名",
  [":ty_ex__yaoming"] = "每回合每项限一次，当你造成或受到伤害后，你可以选择一项：1.弃置一名其他角色的一张手牌；"..
  "2.令一名其他角色摸一张牌；3.令一名角色弃置至多两张牌，摸等量的牌。",

  ["#ty_ex__yaoming-invoke"] = "邀名：你可以执行本回合未选择的一项",
  ["ty_ex__yaoming1"] = "弃置一名其他角色一张手牌",
  ["ty_ex__yaoming2"] = "令一名其他角色摸一张牌",
  ["ty_ex__yaoming3"] = "令一名角色弃置至多两张牌，摸等量的牌",
  ["#ty_ex__yaoming-discard"] = "邀名：你可以弃置至多两张牌，摸等量的牌",

  ["$ty_ex__yaoming1"] = "养威持重，不营小利。",
  ["$ty_ex__yaoming2"] = "则天而行，作功邀名。",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yaoming.name) and
      #player:getTableMark("ty_ex__yaoming-turn") < 3
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__yaoming_active",
      prompt = "#ty_ex__yaoming-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "ty_ex__yaoming-turn", tonumber(choice[#choice]))
    if choice == "ty_ex__yaoming1" then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = yaoming.name,
      })
      room:throwCard(id, yaoming.name, to, player)
    elseif choice == "ty_ex__yaoming2" then
      to:drawCards(1, yaoming.name)
    elseif choice == "ty_ex__yaoming3" then
      local n = #room:askToDiscard(to, {
        min_num = 1,
        max_num = 2,
        include_equip = true,
        skill_name = yaoming.name,
        cancelable = true,
        prompt = "#ty_ex__yaoming-discard",
      })
      if n > 0 and not to.dead then
        to:drawCards(n, yaoming.name)
      end
    end
  end,
}
yaoming:addEffect(fk.Damage, spec)
yaoming:addEffect(fk.Damaged, spec)

yaoming:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "ty_ex__yaoming-turn", 0)
end)

return yaoming
