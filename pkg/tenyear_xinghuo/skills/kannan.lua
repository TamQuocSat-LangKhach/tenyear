local kannan = fk.CreateSkill {
  name = "kannan",
}

Fk:loadTranslationTable{
  ["kannan"] = "戡难",
  [":kannan"] = "出牌阶段限X次（X为你的体力值），你可以与一名你于此阶段内未以此法选择过的角色拼点。若你赢，你使用的下一张【杀】伤害值基数+1"..
  "且你于此阶段内不能发动此技能；其赢，其使用的下一张【杀】的伤害值基数+1。",

  ["#kannan"] = "戡难：与一名角色拼点，赢的角色使用下一张【杀】伤害+1",
  ["@kannan"] = "戡难",

  ["$kannan1"] = "俊才之杰，材匪戡难。",
  ["$kannan2"] = "戡，克也，难，攻之。",
}

kannan:addEffect("active", {
  anim_type = "control",
  prompt = "#kannan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kannan.name, Player.HistoryPhase) < player.hp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select) and
      not table.contains(player:getTableMark("kannan-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "kannan-phase", target.id)
    local pindian = player:pindian({target}, kannan.name)
    if pindian.results[target].winner == player then
      if not player.dead then
        room:addPlayerMark(player, "@kannan", 1)
        room:invalidateSkill(player, kannan.name, "-phase")
      end
    elseif pindian.results[target].winner == target then
      if not target.dead then
        room:addPlayerMark(target, "@kannan", 1)
      end
    end
  end,
})

kannan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@kannan") > 0 and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@kannan")
    player.room:setPlayerMark(player, "@kannan", 0)
  end,
})

return kannan
