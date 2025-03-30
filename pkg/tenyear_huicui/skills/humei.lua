local humei = fk.CreateSkill {
  name = "humei",
}

Fk:loadTranslationTable{
  ["humei"] = "狐魅",
  [":humei"] = "出牌阶段每项限一次，你可以选择一项，令一名体力值不大于X的角色执行（X为你本阶段造成伤害点数）：1.摸一张牌；2.交给你一张牌；"..
  "3.回复1点体力。",

  ["#humei"] = "狐魅：令一名体力值不大于%arg的角色执行一项",
  ["humei_give"] = "交给你一张牌",
  ["#humei-give"] = "狐魅：请交给 %src 一张牌",

  ["$humei1"] = "尔为靴下之臣，当行顺我之事。",
  ["$humei2"] = "妾身一笑，可倾将军之城否？"
}

humei:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    return "#humei:::"..player:getMark("humei_count-phase")
  end,
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices = {}
    local record = player:getTableMark("humei-phase")
    if not table.contains(record, 1) then
      table.insert(choices, "draw1")
    end
    if not table.contains(record, 2) then
      table.insert(choices, "humei_give")
    end
    if not table.contains(record, 3) then
      table.insert(choices, "recover")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return #player:getTableMark("humei-phase") < 3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select.hp <= player:getMark("humei_count-phase") then
      if self.interaction.data == "draw1" then
        return true
      elseif self.interaction.data == "humei_give" then
        return not to_select:isNude()
      elseif self.interaction.data == "recover" then
        return to_select:isWounded()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if self.interaction.data == "draw1" then
      room:addTableMark(player, "humei-phase", 1)
      target:drawCards(1, humei.name)
    elseif self.interaction.data == "humei_give" then
      room:addTableMark(player, "humei-phase", 2)
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = humei.name,
        prompt = "#humei-give:"..player.id,
        cancelable = false,
      })
      room:obtainCard(player, card, false, fk.ReasonGive, target, humei.name)
    elseif self.interaction.data == "recover" then
      room:addTableMark(player, "humei-phase", 3)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = humei.name,
      }
    end
  end,
})

humei:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(humei.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "humei_count-phase", data.damage)
  end,
})

humei:addAcquireEffect(function (self, player, is_start)
  if player.phase == Player.Play then
    local room = player.room
    local n = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from == player then
        n = n + damage.damage
      end
    end, Player.HistoryPhase)
    room:setPlayerMark(player, "humei_count-phase", n)
  end
end)

return humei
