local qinbao = fk.CreateSkill {
  name = "qinbao"
}

Fk:loadTranslationTable{
  ['qinbao'] = '侵暴',
  [':qinbao'] = '锁定技，手牌数大于等于你的其他角色不能响应你使用的【杀】或普通锦囊牌。',
  ['$qinbao1'] = '赤箓护身，神鬼莫当。',
  ['$qinbao2'] = '头裹黄巾，代天征伐。',
}

qinbao:addEffect(fk.CardUsing, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinbao.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:getHandcardNum() >= player:getHandcardNum() end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
})

return qinbao
