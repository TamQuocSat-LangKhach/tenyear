local cuirui = fk.CreateSkill {
  name = "cuirui",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["cuirui"] = "摧锐",
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），获得这些角色各一张手牌。",

  ["#cuirui"] = "摧锐：获得至多%arg名角色各一张手牌",

  ["$cuirui1"] = "摧折锐气，未战先衰。",
  ["$cuirui2"] = "挫其锐气，折其旌旗。",
}

cuirui:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#cuirui:::"..player.hp
  end,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(self, player)
    return player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(cuirui.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < player.hp and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    for _, p in ipairs(effect.tos) do
      if player.dead then return end
      if not p.dead and not p:isKongcheng() then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "h",
          skill_name = cuirui.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, cuirui.name)
      end
    end
  end,
})

return cuirui
