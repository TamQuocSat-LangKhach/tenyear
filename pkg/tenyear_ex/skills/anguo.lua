local anguo = fk.CreateSkill {
  name = "ty_ex__anguo",
}

Fk:loadTranslationTable{
  ["ty_ex__anguo"] = "安国",
  [":ty_ex__anguo"] = "出牌阶段限一次，你可以选择一名其他角色，若其手牌数为全场最少，其摸一张牌；体力值为全场最低，回复1点体力；"..
  "装备区内牌数为全场最少，随机使用一张装备牌。然后若该角色有未执行的效果且你满足条件，你执行之。若双方执行了全部分支，你可以重铸任意张牌。",

  ["#ty_ex__anguo"] = "安国：令一名其他角色执行效果",
  ["#ty_ex__anguo-recast"] = "安国：你可以重铸任意张牌",

  ["$ty_ex__anguo1"] = "非武不可安邦，非兵不可定国。",
  ["$ty_ex__anguo2"] = "天下纷乱，正是吾等用武之时。",
}

local function doAnguo(player, anguo_type, source)
  local room = player.room
  if anguo_type == "draw" then
    if table.every(room.alive_players, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) then
      player:drawCards(1, anguo.name)
      return true
    end
  elseif anguo_type == "recover" then
    if player:isWounded() and table.every(room.alive_players, function (p)
        return p.hp >= player.hp
      end) then
      room:recover{
        who = player,
        num = 1,
        recoverBy = source,
        skillName = anguo.name,
      }
      return true
    end
  elseif anguo_type == "equip" then
    if table.every(room.alive_players, function (p)
        return #p:getCardIds("e") >= #player:getCardIds("e")
      end) then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeEquip and player:canUse(card) and not player:prohibitUse(card) then
          table.insert(cards, card)
        end
      end
      if #cards > 0 then
        room:useCard({
          from = player,
          tos = {player},
          card = table.random(cards),
        })
        return true
      end
    end
  end
  return false
end

anguo:addEffect("active", {
  anim_type = "support",
  prompt = "#ty_ex__anguo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
  return player:usedSkillTimes(anguo.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
  return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local types = {"equip", "recover", "draw"}
    for i = 3, 1, -1 do
      if doAnguo(target, types[i], player) then
        table.removeOne(types, types[i])
        if target.dead then
          break
        end
      end
    end
    for i = #types, 1, -1 do
      if player.dead then break end
      if doAnguo(player, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    if #types == 0 and not player.dead and not player:isNude() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        prompt = "#ty_ex__anguo-recast",
        skill_name = anguo.name,
        cancelable = true,
      })
      if #cards > 0 then
        room:recastCard(cards, player, anguo.name)
      end
    end
  end,
})

return anguo
