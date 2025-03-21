local andong = fk.CreateSkill {
  name = "andong",
}

Fk:loadTranslationTable{
  ["andong"] = "安东",
  [":andong"] = "当你受到其他角色造成的伤害时，你可以令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段<font color='red'>♥</font>牌"..
  "不计入手牌上限；2.观看其手牌，若其中有<font color='red'>♥</font>牌则你获得这些牌。",

  ["#andong-invoke"] = "安东：你可以对 %dest 发动“安东”，令选择一项",
  ["andong1"] = "防止对%src造成的伤害，本回合<font color='red'>♥</font>牌不计入手牌上限",
  ["andong2"] = "%src观看你的手牌并获得其中的<font color='red'>♥</font>牌",
  ["#andong-choice"] = "安东：选择 %src 令你执行的一项",

  ["$andong1"] = "勇足以当大难，智涌以安万变。",
  ["$andong2"] = "宽猛克济，方安河东之民。",
}

local U = require "packages/utility/utility"

andong:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(andong.name) and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = andong.name,
      prompt = "#andong-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(data.from, {
      choices = {"andong1:"..player.id, "andong2:"..player.id},
      skill_name = andong.name,
      prompt = "#andong-choice:"..player.id
    })
    if choice:startsWith("andong1") then
      room:setPlayerMark(data.from, "andong-turn", 1)
      data:preventDamage()
    else
      if data.from:isKongcheng() then return end
      U.viewCards(player, data.from:getCardIds("h"), andong.name)
      local cards = table.filter(data.from:getCardIds("h"), function(id)
        return Fk:getCardById(id).suit == Card.Heart
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, andong.name, nil, true, player)
      end
    end
  end,
})
andong:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("andong-turn") > 0 and card.suit == Card.Heart
  end,
})

return andong
