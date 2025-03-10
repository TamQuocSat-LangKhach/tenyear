local ty_ex__huaiyi = fk.CreateSkill {
  name = "ty_ex__huaiyi"
}

Fk:loadTranslationTable{
  ['ty_ex__huaiyi'] = '怀异',
  [':ty_ex__huaiyi'] = '出牌阶段限一次，你可以展示所有手牌。若仅有一种颜色，你摸一张牌，然后此技能本阶段改为“出牌阶段限两次”；若有两种颜色，你弃置其中一种颜色的牌，然后获得至多X名角色各一张牌（X为弃置的手牌数），若你获得的牌大于一张，你失去1点体力。',
  ['$ty_ex__huaiyi1'] = '曹刘可王，孤亦可王！',
  ['$ty_ex__huaiyi2'] = '汉失其鹿，天下豪杰当共逐之。',
}

ty_ex__huaiyi:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__huaiyi.name, Player.HistoryPhase) < 1 + player:getMark("huaiyi-phase") and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = table.clone(player:getCardIds("h"))
    player:showCards(cards)
    local colors = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(colors, Fk:getCardById(id):getColorString())
    end
    if #colors < 2 then
      if player:getMark("huaiyi-phase") == 0 then
        room:setPlayerMark(player, "huaiyi-phase", 1)
      end
      player:drawCards(1, ty_ex__huaiyi.name)
    else
      local color = room:askToChoice(player, {choices = colors, skill_name = ty_ex__huaiyi.name})
      local throw = {}
      for _, id in ipairs(cards) do
        if Fk:getCardById(id):getColorString() == color then
          table.insert(throw, id)
        end
      end
      room:throwCard(throw, ty_ex__huaiyi.name, player, player)
      local targets = room:askToChoosePlayers(player, {targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper), min_num = 1, max_num = #throw, skill_name = ty_ex__huaiyi.name})
      if #targets > 0 then
        local get = {}
        for _, p in ipairs(targets) do
          local id = room:askToChooseCard(player, {target = p, flag = "he", skill_name = ty_ex__huaiyi.name})
          table.insert(get, id)
        end
        for _, id in ipairs(get) do
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
        if #get > 1 and not player.dead then
          room:loseHp(player, 1, ty_ex__huaiyi.name)
        end
      end
    end
  end,
})

return ty_ex__huaiyi
