local kuangzhan = fk.CreateSkill {
  name = "kuangzhan"
}

Fk:loadTranslationTable{
  ['kuangzhan'] = '狂战',
  ['#kuangzhan'] = '狂战：摸牌至体力上限，根据摸牌数拼点',
  ['#kuangzhan-choose'] = '狂战：拼点，若赢，你视为对所有拼点输的角色使用【杀】；若没赢，其视为对你使用【杀】（第%arg次，共%arg2次！）',
  [':kuangzhan'] = '出牌阶段限一次，你可以将手牌摸至体力上限并依次拼点X次（X为你以此法摸牌数），每次拼点若你：赢，你视为对所有本回合拼点未赢的其他角色使用一张【杀】；没赢，其视为对你使用一张【杀】。',
  ['$kuangzhan1'] = '平生不修礼乐，唯擅杀人放火！',
  ['$kuangzhan2'] = '宛城乃曹公掌中之物，谁敢染指？',
}

kuangzhan:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#kuangzhan",
  can_use = function(self, player)
    return player:usedSkillTimes(kuangzhan.name, Player.HistoryPhase) == 0 and player:getHandcardNum() < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player.maxHp - player:getHandcardNum()
    player:drawCards(n, kuangzhan.name)
    for i = 1, n, 1 do
      if player.dead then return end
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return player:canPindian(p) end), Util.IdMapper)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#kuangzhan-choose:::"..i..":"..n,
        skill_name = kuangzhan.name,
        cancelable = false
      })
      to = room:getPlayerById(to[1])
      local pindian = player:pindian({to}, kuangzhan.name)
      if pindian.results[to.id].winner == player then
        local tos = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room.logic:getEventsOfScope(GameEvent.Pindian, 1, function(e)
            local dat = e.data[1]
            if dat.results[p.id] and dat.results[p.id].winner ~= p then
              table.insertIfNeed(tos, p)
            end
            return false
          end, Player.HistoryTurn)
        end
        if #tos > 0 then
          room:useVirtualCard("slash", nil, player, tos, kuangzhan.name, true)
        end
      else
        room:useVirtualCard("slash", nil, to, player, kuangzhan.name, true)
      end
    end
  end,
})

return kuangzhan
