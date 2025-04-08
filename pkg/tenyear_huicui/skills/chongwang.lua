local chongwang = fk.CreateSkill {
  name = "chongwang",
}

Fk:loadTranslationTable{
  ["chongwang"] = "崇望",
  [":chongwang"] = "其他角色使用一张基本牌或普通锦囊牌时，若你为上一张牌的使用者，你可以令其获得其使用的牌或令该牌无效。",

  ["chongwang1"] = "%dest获得%arg",
  ["chongwang2"] = "%arg无效",

  ["$chongwang1"] = "乡人所崇者，烈之义行也。",
  ["$chongwang2"] = "诸家争讼曲直，可质于我。",
}

chongwang:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongwang.name) and target ~= player and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local use_events = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < player.room.logic:getCurrentEvent().id then
          return true
        end
      end, 0)
      return #use_events > 0 and use_events[1].data.from == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {
      "chongwang1::"..target.id..":"..data.card:toLogString(),
      "chongwang2:::"..data.card:toLogString(),
      "Cancel",
    }
    local choices = table.simpleClone(all_choices)
    if target.dead or room:getCardArea(data.card) ~= Card.Processing then
      table.remove(choices, 1)
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = chongwang.name,
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).choice:startsWith("chongwang1") then
      player.room:obtainCard(target, data.card, true, fk.ReasonJustMove, target, chongwang.name)
    else
      data.toCard = nil
      data:removeAllTargets()
    end
  end,
})

return chongwang
