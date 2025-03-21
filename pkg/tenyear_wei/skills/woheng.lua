local woheng = fk.CreateSkill {
  name = "woheng",
}

Fk:loadTranslationTable{
  ["woheng"] = "斡衡",
  [":woheng"] = "出牌阶段或当你受到伤害后，你可以令一名其他角色摸或弃置X张牌（X为你本轮发动此技能次数）。然后若其手牌数与你不同或X大于3，"..
  "你摸两张牌且此技能本回合失效。",

  ["#woheng"] = "斡衡：你可以令一名角色摸或弃置%arg张牌",
  ["woheng_draw"] = "摸牌",
  ["woheng_discard"] = "弃牌",

  ["$woheng1"] = "壁立以千仞，非蚍蜉可撼。",
  ["$woheng2"] = "朕德载后土，焉不容天下风雨。",
}

woheng:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#woheng:::"..(player:usedSkillTimes(woheng.name, Player.HistoryRound) + 1)
  end,
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox {choices = { "woheng_draw", "woheng_discard" } },
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target  = effect.tos[1]
    local n = player:usedSkillTimes(woheng.name, Player.HistoryRound)
    if self.interaction.data == "woheng_draw" then
      target:drawCards(n, woheng.name)
    else
      room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = woheng.name,
        cancelable = false,
      })
    end
    if player.dead then return end
    if target:getHandcardNum() ~= player:getHandcardNum() or n > 3 then
      room:invalidateSkill(player, woheng.name, "-turn")
      player:drawCards(2, woheng.name)
    end
  end,
})

woheng:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(woheng.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = woheng.name,
      prompt = "#woheng:::"..(player:usedSkillTimes(woheng.name, Player.HistoryRound) + 1),
      cancelable = true,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local tos = event:getCostData(self).tos
    local skill = Fk.skills[woheng.name]
    skill.interaction = skill.interaction or {}
    skill.interaction.data = event:getCostData(self).interaction
    skill:onUse(player.room, {
      from = player,
      tos = tos,
    })
  end,
})

return woheng
