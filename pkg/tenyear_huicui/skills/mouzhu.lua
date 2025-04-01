local mouzhu = fk.CreateSkill {
  name = "ty__mouzhu",
}

Fk:loadTranslationTable{
  ["ty__mouzhu"] = "谋诛",
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次执行：将一张手牌交给你，然后若其手牌数小于你，"..
  "其视为对你使用一张【杀】或【决斗】。",

  ["#ty__mouzhu"] = "谋诛：令任意名角色交给你一张手牌，若其手牌数小于你，视为对你使用【杀】或【决斗】",
  ["#ty__mouzhu-give"] = "谋诛：交给 %dest 一张手牌，然后若手牌数小于其，视为对其使用【杀】或【决斗】",
  ["#ty__mouzhu-choice"] = "谋诛：视为对 %dest 使用【杀】或【决斗】！",

  ["$ty__mouzhu1"] = "尔等祸乱朝纲，罪无可赦，按律当诛！",
  ["$ty__mouzhu2"] = "天下人之怨皆系于汝等，还不快认罪伏法？",
}

mouzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__mouzhu",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mouzhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player and (to_select:distanceTo(player) == 1 or to_select.hp == player.hp) and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    for _, target in ipairs(effect.tos) do
      if player.dead then return end
      if not target:isKongcheng() and not target:isKongcheng() then
        local card = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = mouzhu.name,
          cancelable = false,
          prompt = "#ty__mouzhu-give::"..player.id,
        })
        room:obtainCard(player, card, false, fk.ReasonGive, target, mouzhu.name)
        if player.dead then return end
        if not target.dead and player:getHandcardNum() > target:getHandcardNum() then
          local names = table.filter({"slash", "duel"}, function (name)
            return target:canUseTo(Fk:cloneCard(name), player, {bypass_distances = true, bypass_times = true})
          end)
          if #names > 0 then
            local choice = room:askToChoice(target, {
              choices = names,
              skill_name = mouzhu.name,
              prompt = "#ty__mouzhu-choice::"..player.id,
            })
            room:useVirtualCard(choice, nil, target, player, mouzhu.name, true)
          end
        end
      end
    end
  end,
})

return mouzhu
