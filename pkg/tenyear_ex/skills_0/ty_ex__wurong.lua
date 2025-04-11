local ty_ex__wurong = fk.CreateSkill {
  name = "ty_ex__wurong"
}

Fk:loadTranslationTable{
  ['ty_ex__wurong'] = '怃戎',
  ['#ty_ex__wurong-show'] = '怃戎：选择一张展示的手牌',
  [':ty_ex__wurong'] = '出牌阶段限一次，你可以令一名其他角色与你同时展示一张手牌，若：你展示的是【杀】且该角色不是【闪】，你对其造成1点伤害；你展示的不是【杀】且该角色是【闪】，你获得其一张牌。',
  ['$ty_ex__wurong1'] = '策略以入算，果烈以立威！',
  ['$ty_ex__wurong2'] = '诈与和亲，不攻可得！',
}

ty_ex__wurong:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty_ex__wurong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local fromCard = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = ty_ex__wurong.name,
      prompt = "#ty_ex__wurong-show",
    })[1]
    local toCard = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = ty_ex__wurong.name,
      prompt = "#ty_ex__wurong-show",
    })[1]
    player:showCards(fromCard)
    target:showCards(toCard)
    if Fk:getCardById(fromCard).trueName == "slash" and Fk:getCardById(toCard).name ~= "jink" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = ty_ex__wurong.name,
      }
    end
    if Fk:getCardById(fromCard).trueName ~= "slash" and Fk:getCardById(toCard).name == "jink" then
      if not target:isNude() then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = ty_ex__wurong.name,
        })
        room:obtainCard(player, id, false)
      end
    end
  end,
})

return ty_ex__wurong
