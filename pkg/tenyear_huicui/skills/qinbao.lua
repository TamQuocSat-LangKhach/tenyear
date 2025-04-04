local qinbao = fk.CreateSkill {
  name = "qinbao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qinbao"] = "侵暴",
  [":qinbao"] = "锁定技，手牌数不小于你的其他角色不能响应你使用的【杀】或普通锦囊牌。",

  ["$qinbao1"] = "赤箓护身，神鬼莫当。",
  ["$qinbao2"] = "头裹黄巾，代天征伐。",
}

qinbao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinbao.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
      if p:getHandcardNum() >= player:getHandcardNum() then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

return qinbao
