local wurong = fk.CreateSkill {
  name = "ty_ex__wurong",
}

Fk:loadTranslationTable{
  ["ty_ex__wurong"] = "怃戎",
  [":ty_ex__wurong"] = "出牌阶段限一次，你可以与一名其他角色同时展示一张手牌：若你展示的是【杀】且该角色不是【闪】，你对其造成1点伤害；"..
  "你展示的不是【杀】且该角色是【闪】，你获得其一张牌。",

  ["#ty_ex__wurong"] = "怃戎：与一名角色同时展示一张手牌，根据牌名执行效果",
  ["#ty_ex__wurong-show"] = "怃戎：选择一张展示的手牌",

  ["$ty_ex__wurong1"] = "策略以入算，果烈以立威！",
  ["$ty_ex__wurong2"] = "诈与和亲，不攻可得！",
}

wurong:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__wurong",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(wurong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local result = room:askToJointCards(player, {
      players = {player, target},
      min_num = 1,
      max_num = 1,
      include_equip = false,
      cancelable = false,
      skill_name = wurong.name,
      prompt = "#ty_ex__wurong-show",
    })
    local fromCard, toCard = result[player][1], result[target][1]
    player:showCards(result[player])
    target:showCards(result[target])
    if target.dead then return end
    if Fk:getCardById(fromCard).trueName == "slash" and Fk:getCardById(toCard).name ~= "jink" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = wurong.name,
      }
    end
    if Fk:getCardById(fromCard).trueName ~= "slash" and Fk:getCardById(toCard).name == "jink" then
      if not player.dead and not target:isNude() then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = wurong.name,
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player, wurong.name)
      end
    end
  end,
})

return wurong
