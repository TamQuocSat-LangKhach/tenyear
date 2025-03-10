local jizhong = fk.CreateSkill {
  name = "jizhong"
}

Fk:loadTranslationTable{
  ['jizhong'] = '集众',
  ['#jizhong-active'] = '发动 集众，令一名其他角色摸两张牌，然后其选择成为“信众”或被你获取3张卡牌',
  ['@@xinzhong'] = '信众',
  ['become_xinzhong'] = '成为“信众”',
  ['donate3cardsto'] = '%src获得你的3张牌',
  [':jizhong'] = '出牌阶段限一次，你可以令一名其他角色摸两张牌，其选择：1.成为“信众”；2.令你获得其三张牌。',
  ['$jizhong1'] = '聚八方之众，昭黄天之明。',
  ['$jizhong2'] = '联苦厄黎庶，传大道太平。',
}

jizhong:addEffect('active', {
  anim_type = "control",
  prompt = "#jizhong-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jizhong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, jizhong.name)
    if target.dead or player.dead then return end

    --并不清楚卡牌不足三张时能不能选给牌
    if target:getMark("@@xinzhong") > 0 or
      room:askToChoice(target, {
        choices = {"become_xinzhong", "donate3cardsto:" .. player.id},
        skill_name = jizhong.name,
      }) ~= "become_xinzhong" then
      local cards = target:getCardIds{Player.Hand, Player.Equip}
      if #cards > 3 then
        cards = room:askToChooseCards(player, {
          min = 3,
          max = 3,
          flag = "he",
          skill_name = jizhong.name,
          target = target,
        })
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, jizhong.name, nil, false, player.id)
      end
    else
      room:setPlayerMark(target, "@@xinzhong", 1)
    end
  end,
})

return jizhong
