local ty_ex__anguo = fk.CreateSkill {
  name = "ty_ex__anguo"
}

Fk:loadTranslationTable{
  ['ty_ex__anguo'] = '安国',
  ['#ty_ex__anguo-card'] = '安国：你可以重铸任意张牌',
  [':ty_ex__anguo'] = '出牌阶段限一次，你可以选择一名其他角色，若其手牌数为全场最少，其摸一张牌；体力值为全场最低，回复1点体力；装备区内牌数为全场最少，随机使用一张装备牌。然后若该角色有未执行的效果且你满足条件，你执行之。若双方执行了全部分支，你可以重铸任意张牌。',
  ['$ty_ex__anguo1'] = '非武不可安邦，非兵不可定国。',
  ['$ty_ex__anguo2'] = '天下纷乱，正是吾等用武之时。',
}

ty_ex__anguo:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__anguo.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local types = {"equip", "recover", "draw"}
    for i = 3, 1, -1 do
      if target.dead then break end
      if doty_ex__anguo(target, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    for i = #types, 1, -1 do
      if player.dead then break end
      if doty_ex__anguo(player, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    if #types ==0 and not player.dead and not player:isNude() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        pattern = ".",
        prompt = "#ty_ex__anguo-card",
        skill_name = ty_ex__anguo.name,
        cancelable = true,
      })
      if #cards > 0 then
        room:recastCard(cards, player, ty_ex__anguo.name)
      end
    end
  end,
})

return ty_ex__anguo
