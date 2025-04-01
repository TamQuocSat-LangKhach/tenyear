local jieling = fk.CreateSkill {
  name = "jieling",
}

Fk:loadTranslationTable{
  ["jieling"] = "介绫",
  [":jieling"] = "出牌阶段每种花色限一次，你可以将两张花色不同的手牌当无距离次数限制的【杀】使用。若此【杀】：造成伤害，其失去1点体力；"..
  "没造成伤害，其获得一个“生妒”标记。",

  ["#jieling"] = "介绫：将两张花色不同的手牌当【杀】使用，若造成伤害其失去1点体力，若未造成伤害其获得“生妒”标记",
  ["@jieling-phase"] = "介绫",

  ["$jieling1"] = "来人，送冯氏上路！",
  ["$jieling2"] = "我有一求，请姐姐赴之。",
}

jieling:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#jieling",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 and table.contains(player:getHandlyIds(), to_select) then
      local suit = Fk:getCardById(to_select).suit
      if suit ~= Card.NoSuit and not table.contains(player:getTableMark("jieling-phase"), suit) then
      if #selected == 0 then
        return true
      else
        return suit ~= Fk:getCardById(selected[1]).suit
      end
    end
    end
  end,
  view_as = function (self, player, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = jieling.name
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
    local room = player.room
    for _, id in ipairs(use.card.subcards) do
      room:addTableMark(player, "jieling-phase", Fk:getCardById(id).suit)
    end
  end,
  after_use = function (self, player, use)
    local room = player.room
    for _, p in ipairs(use.tos) do
      if not p.dead then
        if use.damageDealt and use.damageDealt[p] then
          room:loseHp(p, 1, jieling.name)
        elseif table.find(room.alive_players, function (q)
          return q:hasSkill("shengdu", true)
        end) then
          room:addPlayerMark(p, "@shengdu", 1)
        end
      end
    end
  end,
})

jieling:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, jieling.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, jieling.name)
  end,
})

return jieling
