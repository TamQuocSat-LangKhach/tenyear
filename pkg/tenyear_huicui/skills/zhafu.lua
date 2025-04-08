local zhafu = fk.CreateSkill {
  name = "zhafu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhafu"] = "札符",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下个弃牌阶段开始时，其选择保留一张手牌，将其余手牌交给你。",

  ["#zhafu"] = "选择一名其他角色：其下个弃牌阶段选择保留一张手牌，其余手牌交给你",
  ["@@zhafu"] = "札符",
  ["#zhafu-invoke"] = "札符：选择一张保留的手牌，其余手牌全部交给 %src！",

  ["$zhafu1"] = "垂恩广救，慈悲在怀。",
  ["$zhafu2"] = "行符敕鬼，神变善易。",
}

zhafu:addEffect("active", {
  anim_type = "control",
  prompt = "#zhafu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhafu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(target, "@@zhafu", player.id)
  end,
})

zhafu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and table.contains(target:getTableMark("@@zhafu"), player.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(target, "@@zhafu", player.id)
    if target:getHandcardNum() > 1 then
      local card = room:askToCards(target, {
        skill_name = zhafu.name,
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#zhafu-invoke:" .. player.id,
        cancelable = false,
      })
      local cards = table.filter(player:getCardIds("h"), function(id)
        return id ~= card[1]
      end)
      room:obtainCard(player, cards, false, fk.ReasonGive, target, zhafu.name)
    end
  end,
})

return zhafu
