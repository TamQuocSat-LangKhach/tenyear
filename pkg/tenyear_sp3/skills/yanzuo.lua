local yanzuo = fk.CreateSkill {
  name = "yanzuo"
}

Fk:loadTranslationTable{
  ['yanzuo'] = '研作',
  ['#yanzuo'] = '研作：将一张基本牌或普通锦囊牌置为“研作”牌，然后视为使用一张“研作”牌',
  ['zuyin'] = '祖荫',
  ['#yanzuo-ask'] = '研作：视为使用一张牌',
  [':yanzuo'] = '出牌阶段限一次，你可以将一张牌置于武将牌上，然后视为使用一张“研作”基本牌或普通锦囊牌。',
  ['$yanzuo1'] = '提笔欲续出师表，何日重登蜀道？',
  ['$yanzuo2'] = '我族以诗书传家，苑中未绝琅琅。',
}

yanzuo:addEffect('active', {
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  prompt = "#yanzuo",
  derived_piles = "yanzuo",
  times = function(self, player)
    return (player.phase == Player.Play) and (1 + player:getMark("zuyin") - player:usedSkillTimes(yanzuo.name, Player.HistoryPhase)) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yanzuo.name, Player.HistoryPhase) < 1 + player:getMark("zuyin")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:addToPile(yanzuo.name, effect.cards, true, yanzuo.name, player.id)
    if player.dead or #player:getPile(yanzuo.name) == 0 then return end
    if player:getMark(yanzuo.name) == 0 then
      room:setPlayerMark(player, yanzuo.name, U.getUniversalCards(room, "bt"))
    end
    local cards = table.filter(player:getMark(yanzuo.name), function (id)
      return table.find(player:getPile("yanzuo"), function (id2)
        return Fk:getCardById(id).name == Fk:getCardById(id2).name
      end)
    end)
    if #cards > 0 then
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = yanzuo.name,
        prompt = "#yanzuo-ask",
        expand_pile = cards,
        bypass_times = true,
        skip = true,
      })
      if use then
        local card = Fk:cloneCard(use.card.name)
        card.skillName = yanzuo.name
        room:useCard{
          card = card,
          from = player.id,
          tos = use.tos,
          extraUse = true,
        }
      end
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "zuyin", 0)
  end,
})

return yanzuo
