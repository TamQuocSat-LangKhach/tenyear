local fengyan = fk.CreateSkill {
  name = "fengyan",
}

Fk:loadTranslationTable{
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段各限一次，你可以：1.令一名体力值不大于你的其他角色交给你一张手牌；2.视为对一名手牌数不大于你的其他角色"..
  "使用一张【杀】（无距离次数限制）。",

  ["#fengyan"] = "讽言：对一名角色执行一项",
  ["fengyan1"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",

  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？"
}

fengyan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fengyan",
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local all_choices = {"fengyan1", "fengyan2"}
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(player:getTableMark("fengyan-phase"), choice)
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  can_use = function(self, player)
    return #player:getTableMark("fengyan-phase") < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "fengyan1" then
        return to_select.hp <= player.hp and not to_select:isKongcheng()
      elseif self.interaction.data == "fengyan2" then
        return to_select:getHandcardNum() <= player:getHandcardNum() and not player:isProhibited(to_select, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "fengyan-phase", self.interaction.data)
    if self.interaction.data == "fengyan1" then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#fengyan-give:"..player.id,
        skill_name = fengyan.name,
        cancelable = false,
      })
      room:obtainCard(player, card, false, fk.ReasonGive, target)
    else
      room:useVirtualCard("slash", nil, player, target, fengyan.name, true)
    end
  end,
})

fengyan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "fengyan-phase", 0)
end)

return fengyan
