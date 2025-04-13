local yanzhu = fk.CreateSkill {
  name = "ty_ex__yanzhu",
  dynamic_desc = function (self, player)
    if player:getMark(self.name) > 0 then
      return "ty_ex__yanzhu_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["ty_ex__yanzhu"] = "宴诛",
  [":ty_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌，其下次受到伤害+1直到其下个回合开始；"..
  "2.你获得其装备区内所有的牌，修改〖宴诛〗和〖兴学〗。",

  ["#ty_ex__yanzhu"] = "宴诛：令一名角色选择弃一张牌或交给你所有装备",
  ["#ty_ex__yanzhu_update"] = "宴诛：令一名角色下次受到伤害+1直到其下个回合开始",
  ["#ty_ex__yanzhu-discard"] = "宴诛：弃置一张牌且下次受到伤害+1，或点“取消”%src 获得你所有装备（若没装备则必须弃一张牌）",
  ["@ty_ex__yanzhu_damage"] = "宴诛 受伤+",

  ["$ty_ex__yanzhu1"] = "觥筹交错，杀人于无形！",
  ["$ty_ex__yanzhu2"] = "子烈设宴，意在汝项上人头！",
}

yanzhu:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player, selected_cards, selected_targets)
    if player:getMark(yanzhu.name) == 0 then
      return "#ty_ex__yanzhu"
    else
      return "#ty_ex__yanzhu_update"
    end
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yanzhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if player:getMark(yanzhu.name) > 0 or target:isNude() then
      room:addPlayerMark(target, "@ty_ex__yanzhu_damage", 1)
      return
    end
    local cancelable = #target:getCardIds("e") > 0
    if #room:askToDiscard(target, {
      skill_name = yanzhu.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      cancelable = cancelable,
      prompt = "#ty_ex__yanzhu-discard:" .. player.id
    }) == 0 and cancelable then
      room:setPlayerMark(player, yanzhu.name, 1)
      room:obtainCard(player, target:getCardIds("e"), true, fk.ReasonPrey, player, yanzhu.name)
      return
    end
    if not target.dead then
      room:addPlayerMark(target, "@ty_ex__yanzhu_damage", 1)
    end
  end,
})

yanzhu:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex__yanzhu_damage") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@ty_ex__yanzhu_damage"))
    player.room:setPlayerMark(player, "@ty_ex__yanzhu_damage", 0)
  end,
})

yanzhu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex__yanzhu_damage", 0)
  end,
})

return yanzhu
