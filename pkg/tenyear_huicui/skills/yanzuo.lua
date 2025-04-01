local yanzuo = fk.CreateSkill {
  name = "yanzuo"
}

Fk:loadTranslationTable{
  ["yanzuo"] = "研作",
  [":yanzuo"] = "出牌阶段限一次，你可以将一张牌置于武将牌上，然后视为使用一张“研作”基本牌或普通锦囊牌。",

  ["#yanzuo"] = "研作：将一张基本牌或普通锦囊牌置为“研作”牌，然后视为使用一张“研作”牌",
  ["#yanzuo-ask"] = "研作：视为使用一张牌",

  ["$yanzuo1"] = "提笔欲续出师表，何日重登蜀道？",
  ["$yanzuo2"] = "我族以诗书传家，苑中未绝琅琅。",
}

yanzuo:addEffect("active", {
  anim_type = "special",
  prompt = "#yanzuo",
  card_num = 1,
  target_num = 0,
  derived_piles = "yanzuo",
  times = function(self, player)
    return player.phase == Player.Play and (1 + player:getMark("zuyin") - player:usedSkillTimes(yanzuo.name, Player.HistoryPhase)) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yanzuo.name, Player.HistoryPhase) < 1 + player:getMark("zuyin")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:addToPile(yanzuo.name, effect.cards, true, yanzuo.name, player)
    if player.dead or #player:getPile(yanzuo.name) == 0 then return end
    local cards = table.filter(room:getBanner(yanzuo.name), function (id)
      return table.find(player:getPile(yanzuo.name), function (id2)
        return Fk:getCardById(id).name == Fk:getCardById(id2).name
      end) ~= nil
    end)
    if #cards > 0 then
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = yanzuo.name,
        prompt = "#yanzuo-ask",
        extra_data = {
          bypass_times = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        local card = Fk:cloneCard(use.card.name)
        card.skillName = yanzuo.name
        room:useCard{
          card = card,
          from = player,
          tos = use.tos,
          extraUse = true,
        }
      end
    end
  end,
})

yanzuo:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  if room:getBanner(yanzuo.name) == nil then
    local ids = {}
    for _, name in ipairs(Fk:getAllCardNames("bt", false, true)) do
      table.insert(ids, room:printCard(name).id)
    end
    room:setBanner(yanzuo.name, ids)
  end
end)

yanzuo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "zuyin", 0)
end)

return yanzuo
