local yuanyu = fk.CreateSkill {
  name = "yuanyu",
}

Fk:loadTranslationTable{
  ["yuanyu"] = "怨语",
  [":yuanyu"] = "出牌阶段限一次，你可以摸一张牌并将一张手牌置于武将牌上，称为“怨”，然后选择一名其他角色：你与其弃牌阶段开始时，"..
  "或当该角色造成1点伤害后，其也须放置一张“怨”直到你触发〖夕颜〗。",

  ["#yuanyu"] = "怨语：你可以摸一张牌，然后将一张手牌置为“怨”",
  ["#yuanyu_resent"] = "怨",
  ["#yuanyu-choose"] = "怨语：选择一张手牌置为“怨”，并指定一名其他角色",
  ["@@yuanyu"] = "怨语",
  ["#yuanyu-put"] = "怨语：请将一张手牌置为 %src 的“怨”",
  ["@[yuanyu_resent]"] = "怨",

  ["$yuanyu1"] = "此生最恨者，吴垣孙氏人。",
  ["$yuanyu2"] = "愿为宫外柳，不做建章卿。",
}

Fk:addQmlMark{
  name = "yuanyu_resent",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    local suits = {}
    for _, id in ipairs(value) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    return table.concat(table.map(suits, function(suit)
      return Fk:translate(Card.getSuitString({ suit = suit }, true))
    end), " ")
  end,
  qml_path = "packages/utility/qml/ViewPile"
}

yuanyu:addEffect("active", {
  anim_type = "control",
  prompt = "#yuanyu",
  derived_piles = "#yuanyu_resent",
  can_use = function(self, player)
    return player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) < 1 + player:getMark("yuanyu_extra_times-phase")
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(1, yuanyu.name)
    if player.dead or player:isKongcheng() or #room:getOtherPlayers(player, false) == 0 then return end
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      prompt = "#yuanyu-choose",
      skill_name = yuanyu.name,
      cancelable = false,
    })
    if #to > 0 and card then
      local targetRecorded = player:getTableMark("yuanyu_targets")
      if not table.contains(targetRecorded, to[1].id) then
        table.insert(targetRecorded, to[1].id)
        room:setPlayerMark(player, "yuanyu_targets", targetRecorded)
        room:addPlayerMark(to[1], "@@yuanyu")
      end
      player:addToPile("#yuanyu_resent", card, true, yuanyu.name)
    end
  end,
})

yuanyu:addEffect(fk.Damage, {
  anim_type = "control",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuanyu.name) and target and not target:isKongcheng() and
      table.contains(player:getTableMark("yuanyu_targets"), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      prompt = "#yuanyu-push:" .. player.id,
      skill_name = yuanyu.name,
      cancelable = false,
    })
    player:addToPile("#yuanyu_resent", card, true, yuanyu.name)
  end,
})

yuanyu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu.name) and target.phase == Player.Discard then
      if target == player then
        return table.find(player:getTableMark("yuanyu_targets"), function (id)
          local p = player.room:getPlayerById(id)
          return not p:isKongcheng() and not p.dead end)
      else
        return not target:isKongcheng() and table.contains(player:getTableMark("yuanyu_targets"), target.id)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = {}
    if target == player then
      tos = table.filter(room.alive_players, function (p)
        return table.contains(player:getMark("yuanyu_targets"), p.id)
      end)
    else
      tos = {target}
    end
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getMark("yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          prompt = "#yuanyu-put:" .. player.id,
          skill_name = yuanyu.name,
          cancelable = false,
        })
        player:addToPile("#yuanyu_resent", card, true, yuanyu.name)
      end
    end
  end,
})

yuanyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return #player:getTableMark("@[yuanyu_resent]") ~= #player:getPile("#yuanyu_resent")
  end,
  on_refresh = function(self, event, target, player, data)
    local cards = player:getPile("#yuanyu_resent")
    player.room:setPlayerMark(player, "@[yuanyu_resent]", #cards > 0 and cards or 0)
  end,
})

yuanyu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark("yuanyu_targets") ~= 0 then
    for _, id in ipairs(player:getMark("yuanyu_targets")) do
      room:removePlayerMark(room:getPlayerById(id), "@@yuanyu")
    end
  end
  room:setPlayerMark(player, "yuanyu_targets", 0)
end)

return yuanyu
