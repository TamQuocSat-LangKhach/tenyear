local weimeng = fk.CreateSkill {
  name = "weimeng",
}

Fk:loadTranslationTable{
  ["weimeng"] = "危盟",
  [":weimeng"] = "出牌阶段限一次，你可以获得一名其他角色至多X张手牌，然后交给其等量的牌（X为你的体力值）。若你给出的牌点数之和："..
  "大于获得的牌，你摸一张牌；小于获得的牌，你弃置其区域内一张牌。",

  ["#weimeng"] = "危盟：获得一名角色至多%arg张牌，交还等量牌，根据点数执行效果",
  ["#weimeng-give"] = "危盟：交还 %dest %arg张牌，若点数大于%arg2则摸一张牌，若小于则弃置其一张牌",

  ["$weimeng1"] = "此礼献于友邦，共赴兴汉大业！",
  ["$weimeng2"] = "吴有三江之守，何故委身侍魏？"
}

weimeng:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#weimeng:::"..player.hp
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(weimeng.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = room:askToChooseCards(player, {
      target = target,
      min = 1,
      max = player.hp,
      flag = "h",
      skill_name = weimeng.name,
    })
    local n1 = 0
    for _, id in ipairs(cards) do
      n1 = n1 + Fk:getCardById(id).number
    end
    room:obtainCard(player, cards, false, fk.ReasonPrey, player, weimeng.name)
    if player.dead or player:isNude() or target.dead then return end
    local cards2 = player:getCardIds("he")
    if #player:getCardIds("he") > #cards then
      cards2 = room:askToCards(player, {
        min_num = #cards,
        max_num = #cards,
        include_equip = true,
        skill_name = weimeng.name,
        prompt = "#weimeng-give::"..target.id..":"..#cards..":"..n1,
        cancelable = false,
      })
    end
    local n2 = 0
    for _, id in ipairs(cards2) do
      n2 = n2 + Fk:getCardById(id).number
    end
    room:obtainCard(target, cards2, false, fk.ReasonGive, player, weimeng.name)
    if n1 < n2 then
      if not player.dead then
        player:drawCards(1, weimeng.name)
      end
    elseif n1 > n2 then
      if not (player.dead or target.dead or target:isAllNude()) then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "hej",
          skill_name = weimeng.name,
        })
        room:throwCard(id, weimeng.name, target, player)
      end
    end
  end,
})

return weimeng
