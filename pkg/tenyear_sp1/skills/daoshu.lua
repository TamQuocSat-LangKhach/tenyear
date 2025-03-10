local daoshu = fk.CreateSkill {
  name = "daoshu"
}

Fk:loadTranslationTable{
  ['daoshu'] = '盗书',
  ['#DaoshuLog'] = '%from 对 %to 发动了 “%arg2”，选择了 %arg',
  ['#daoshu-give'] = '盗书：交给 %dest 一张非%arg手牌',
  [':daoshu'] = '出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得其一张手牌。若此牌与你选择的花色：相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给其一张其他花色的手牌（若没有需展示所有手牌）。',
  ['$daoshu1'] = '得此文书，丞相定可高枕无忧。',
  ['$daoshu2'] = '让我看看，这是什么机密。',
}

daoshu:addEffect('active', {
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(daoshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choice = room:askToChoice(player, {
      choices = suits,
      skill_name = daoshu.name
    })
    room:sendLog{
      type = "#DaoshuLog",
      from = player.id,
      to = effect.tos,
      arg = choice,
      arg2 = daoshu.name,
      toast = true,
    }
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = daoshu.name
    })
    room:obtainCard(player, card, true, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString(true) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = daoshu.name,
      }
      player:addSkillUseHistory(daoshu.name, -1)
    else
      local suit = Fk:getCardById(card):getSuitString(true)
      table.removeOne(suits, suit)
      suits = table.map(suits, function(s) return s:sub(5) end)
      local others = table.filter(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id):getSuitString(true) ~= suit end)
      if #others > 0 then
        local cards = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          pattern = ".|.|"..table.concat(suits, ","),
          prompt = "#daoshu-give::"..target.id..":"..suit,
          skill_name = daoshu.name
        })
        if #cards > 0 then
          cards = cards[1]
        else
          cards = table.random(others)
        end
        room:obtainCard(target, cards, true, fk.ReasonGive)
      else
        player:showCards(player:getCardIds(Player.Hand))
      end
    end
  end,
})

return daoshu
