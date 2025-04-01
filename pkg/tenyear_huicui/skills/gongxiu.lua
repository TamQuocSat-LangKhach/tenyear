local gongxiu = fk.CreateSkill {
  name = "gongxiu",
}

Fk:loadTranslationTable{
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；"..
  "2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。",

  ["gongxiu_draw"] = "令“经合”角色各摸一张牌",
  ["gongxiu_discard"] = "令非“经合”角色各弃置一张手牌",

  ["$gongxiu1"] = "福祸与共，业山可移。",
  ["$gongxiu2"] = "修行退智，遂之道也。",
}

gongxiu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongxiu.name) and player.phase == Player.Finish and
      player:usedEffectTimes("jinghe", Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "Cancel" }
    local all_choices = {"gongxiu_draw", "gongxiu_discard", "Cancel"}
    local targets1 = table.filter(room.alive_players, function(p)
      return table.contains(player:getTableMark("jinghe-turn"), p.id)
    end)
    if #targets1 > 0 then
      table.insert(choices, "gongxiu_draw")
    end
    local targets2 = table.filter(room.alive_players, function(p)
      return not table.contains(player:getTableMark("jinghe-turn"), p.id) and not p:isKongcheng()
    end)
    if #targets2 > 0 then
      table.insert(choices, "gongxiu_discard")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = gongxiu.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      local tos = choice == "gongxiu_draw" and targets1 or targets2
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    if event:getCostData(self).choice == "gongxiu_draw" then
      for _, p in ipairs(targets) do
        if not p.dead then
          p:drawCards(1, gongxiu.name)
        end
      end
    else
      for _, p in ipairs(targets) do
        if not p.dead and not p:isKongcheng() then
          room:askToDiscard(p, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = gongxiu.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})

return gongxiu
