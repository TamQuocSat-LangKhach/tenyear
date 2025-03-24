local chengfeng = fk.CreateSkill {
  name = "chengfeng",
}

Fk:loadTranslationTable{
  ["chengfeng"] = "承奉",
  [":chengfeng"] = "每回合限一次，你可以将一张红色“匡祚”牌当【闪】或黑色“匡祚”牌当【无懈可击】对即将对你生效的牌使用，此牌结算后，"..
  "若“匡祚”不足两种颜色，你可以将牌堆顶一张牌置为“匡祚”。",

  ["#chengfeng"] = "承奉：你可以将红色“匡祚”当【闪】、黑色“匡祚”当【无懈可击】对即将对你生效的牌使用",
  ["#chengfeng-put"] = "承奉：是否将牌堆顶一张牌置为“匡祚”？",

  ["$chengfeng1"] = "臣簇于君侧，为耳目，为股肱。",
  ["$chengfeng2"] = "承臣子之任，奉天子之统。",
}

chengfeng:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink,nullification",
  prompt = "#chengfeng",
  expand_pile = "kuangzuo",
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getPile("kuangzuo"), to_select) then
      local _c = Fk:getCardById(to_select)
      local c
      if _c.color == Card.Red then
        c = Fk:cloneCard("jink")
      elseif _c.color == Card.Black then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c)
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card
    if Fk:getCardById(cards[1]).color == Card.Red then
      card = Fk:cloneCard("jink")
    elseif Fk:getCardById(cards[1]).color == Card.Black then
      card = Fk:cloneCard("nullification")
    end
    card.skillName = chengfeng.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      local colors = {}
      for _, id in ipairs(player:getPile("kuangzuo")) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      if #colors < 2 and room:askToSkillInvoke(player, {
        skill_name = chengfeng.name,
        prompt = "#chengfeng-put",
      }) then
        player:addToPile("kuangzuo", room:getNCards(1), true, chengfeng.name, player)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:getMark("chengfeng_activated") > 0 then
      for _, id in ipairs(player:getPile("kuangzuo")) do
        if Fk:getCardById(id).color == Card.Red and #player:getViewAsCardNames(chengfeng.name, {"jink"}, {id}) > 0 then
          return true
        end
        if Fk:getCardById(id).color == Card.Black and #player:getViewAsCardNames(chengfeng.name, {"nullification"}, {id}) > 0 then
          return true
        end
      end
    end
  end,
})

chengfeng:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest and (data.extra_data or {}).chengfeng_effected then
      return player:getMark(chengfeng.name .. "_activated") > 0
    else
      return player:hasSkill(chengfeng.name) and data.eventData and data.eventData.to == player and
        #player:getPile("kuangzuo") > 0 and player:usedSkillTimes(chengfeng.name, Player.HistoryTurn) == 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.afterRequest then
      room:setPlayerMark(player, chengfeng.name .. "_activated", 0)
    else
      room:setPlayerMark(player, chengfeng.name .. "_activated", 1)
      data.extra_data = data.extra_data or {}
      data.extra_data.chengfeng_effected = true
    end
  end,
})

return chengfeng
