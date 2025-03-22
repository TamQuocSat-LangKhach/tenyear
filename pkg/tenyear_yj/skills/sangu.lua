local sangu = fk.CreateSkill {
  name = "sangu",
}

Fk:loadTranslationTable{
  ["sangu"] = "三顾",
  [":sangu"] = "结束阶段，你可以依次选择至多三张【杀】或普通锦囊牌（【借刀杀人】、【无懈可击】除外）并指定一名其他角色，"..
  "其下个出牌阶段使用或打出的前X张牌视为你选择的牌（X为你选择的牌数）。若你选择的牌均为本回合你使用过的牌，防止“三顾”牌对你造成的伤害。",

  ["#sangu-choose"] = "三顾：选择一名角色，指定其下个出牌阶段使用前三张牌的牌名",
  ["#sangu-declare"] = "三顾：宣言 %dest 在下个出牌阶段使用或打出的第 %arg 张牌的牌名",
  ["@$sangu"] = "三顾",
  ["@$sangu-phase"] = "三顾",

  ["$sangu1"] = "思报君恩，尽父子之忠。",
  ["$sangu2"] = "欲酬三顾，竭三代之力。",
}

local U = require "packages/utility/utility"

sangu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sangu.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#sangu-choose",
      skill_name = sangu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local all_choices = Fk:getAllCardNames("t")
    table.insert(all_choices, 1, "slash")
    table.removeOne(all_choices, "nullification")
    table.removeOne(all_choices, "collateral")
    local choices = table.simpleClone(all_choices)
    local names = {}
    for i = 1, 3, 1 do
      local choice = U.askForChooseCardNames(room, player, choices, 1, 1, sangu.name,
        "#sangu-declare::"..to.id..":"..i, all_choices, i > 1)
      if #choice == 0 then break end
      table.removeOne(choices, choice[1])
      table.insert(names, choice[1])
    end
    local mark = to:getTableMark("@$sangu")
    table.insertTable(mark, names)
    room:setPlayerMark(to, "@$sangu", mark)

    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        table.removeOne(names, use.card.trueName)
      end
      return false
    end, Player.HistoryTurn)
    if #names == 0 then
      room:addTableMark(player, "sangu_avoid", to.id)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and target.phase == Player.Play and
      player:getMark("@$sangu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@$sangu-phase", player:getMark("@$sangu"))
    room:setPlayerMark(player, "@$sangu", 0)
    for _, p in ipairs(room.alive_players) do
      if room:removeTableMark(p, "sangu_avoid", player.id) then
        room:setPlayerMark(p, "sangu_avoid-phase", player.id)
      end
    end
    player:filterHandcards()
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getTableMark("@$sangu-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$sangu-phase")
    table.remove(mark, 1)
    room:setPlayerMark(player, "@$sangu-phase", #mark > 0 and mark or 0)
    player:filterHandcards()
  end,
}
sangu:addEffect(fk.CardUsing, spec)
sangu:addEffect(fk.CardResponding, spec)

sangu:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, sangu.name) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return end
      return player:getTableMark("sangu_avoid-phase") == use_event.data.from.id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

sangu:addEffect("filter", {
  mute = true,
  card_filter = function(self, to_select, player)
    return #player:getTableMark("@$sangu-phase") > 0 and
      table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard(player:getTableMark("@$sangu-phase")[1], to_select.suit, to_select.number)
    card.skillName = sangu.name
    return card
  end,
})

return sangu
