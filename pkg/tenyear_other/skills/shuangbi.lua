local shuangbi = fk.CreateSkill {
  name = "shuangbi",
}

Fk:loadTranslationTable{
  ["shuangbi"] = "双璧",
  [":shuangbi"] = "出牌阶段限一次，你可以<font color='red'>选择一名周瑜助战</font>：<br>"..
  "界周瑜：摸X张牌，本回合手牌上限+X；<br>"..
  "神周瑜：弃置至多X张牌，随机造成等量的火焰伤害；<br>"..
  "谋周瑜：视为使用X张火【杀】或【火攻】。<br>（X为存活角色数，至多为你的体力上限）",

  ["#shuangbi1"] = "双璧：摸%arg张牌且本回合手牌上限增加",
  ["#shuangbi2"] = "双璧：弃置至多%arg张牌，随机造成等量火焰伤害",
  ["#shuangbi3"] = "双璧：视为使用%arg张火【杀】或【火攻】",
  ["#shuangbi-use"] = "双璧：你可以视为使用火【杀】或【火攻】（第%arg张，共%arg2张）！",
}

shuangbi:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player)
    local n = math.min(#Fk:currentRoom().alive_players, player.maxHp)
    if self.interaction.data == "ex__zhouyu" then
      return "#shuangbi1:::"..n
    elseif self.interaction.data == "godzhouyu" then
      return "#shuangbi2:::"..n
    elseif self.interaction.data == "tymou__zhouyu" then
      return "#shuangbi3:::"..n
    end
  end,
  min_card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"ex__zhouyu", "godzhouyu", "tymou__zhouyu"}}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shuangbi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    if self.interaction.data == "godzhouyu" then
      return #selected < math.min(#Fk:currentRoom().alive_players, player.maxHp) and
        not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data == "godzhouyu" then
      return #selected_cards > 0 and #selected_cards <= math.min(#Fk:currentRoom().alive_players, player.maxHp)
    else
      return #selected_cards == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local orig_info = {"deputy", player.deputyGeneral}
    if player.deputyGeneral ~= nil and player.deputyGeneral == "tycl__sunce" then
      orig_info = {"general", player.general}
      player.general = self.interaction.data
      room:broadcastProperty(player, "general")
    else
      player.deputyGeneral = self.interaction.data
      room:broadcastProperty(player, "deputyGeneral")
    end
    local n = math.min(#room.alive_players, player.maxHp)
    if self.interaction.data == "ex__zhouyu" then
      room:delay(2000)
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, n)
      player:drawCards(n, shuangbi.name)
    elseif self.interaction.data == "godzhouyu" then
      n = #effect.cards
      room:throwCard(effect.cards, shuangbi.name, player, player)
      room:delay(2000)
      for _ = 1, n, 1 do
        local targets = room:getOtherPlayers(player, false)
        if #targets == 0 then break end
        local to = table.random(targets)
        room:doIndicate(player, {to})
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = shuangbi.name,
        }
      end
    elseif self.interaction.data == "tymou__zhouyu" then
      for i = 1, n, 1 do
        if player.dead or room:askToUseVirtualCard(player, {
          skill_name = shuangbi.name,
          name = {"fire__slash", "fire_attack"},
          prompt = "#shuangbi-use:::"..i..":"..n,
          cancelable = true,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
        }) == nil then break end
      end
    end
    if orig_info[1] == "deputy" then
      player.deputyGeneral = orig_info[2]
      room:broadcastProperty(player, "deputyGeneral")
    else
      player.general = orig_info[2]
      room:broadcastProperty(player, "general")
    end
  end,
})

return shuangbi
