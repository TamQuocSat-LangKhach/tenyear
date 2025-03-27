local nuanhui = fk.CreateSkill {
  name = "nuanhui"
}

Fk:loadTranslationTable{
  ['nuanhui'] = '暖惠',
  ['#nuanhui-choose'] = '暖惠：选择一名角色，其可以视为使用其装备区内牌张数的基本牌',
  ['#nuanhui-use'] = '暖惠：你可以视为使用基本牌（第%arg张，共%arg2张）',
  [':nuanhui'] = '结束阶段，你可以选择一名角色，该角色可视为使用X张基本牌（X为其装备区牌数且至少为1）。若其使用了同名牌，其弃置装备区所有牌。',
  ['$nuanhui1'] = '暖阳映雪，可照八九之风光。',
  ['$nuanhui2'] = '晓风和畅，吹融附柳之霜雪。',
}

nuanhui:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(nuanhui.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#nuanhui-choose",
      skill_name = nuanhui.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local n = math.max(#to:getCardIds("e"), 1)
    local throwEquip = false
    local names = {}
    for i = 1, n, 1 do
      local use = U.askForUseVirtualCard(room, to, U.getAllCardNames("b"), nil, nuanhui.name,
        "#nuanhui-use:::" .. i .. ":" .. n, true, true, false, true)
      if use then
        if not table.insertIfNeed(names, use.card.trueName) then
          throwEquip = true
        end
        if to.dead then return false end
        n = math.max(#to:getCardIds("e"), 1)
      else
        break
      end
    end
    if throwEquip then
      to:throwAllCards("e")
    end
  end,
})

return nuanhui
