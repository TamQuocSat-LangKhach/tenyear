local tunan = fk.CreateSkill {
  name = "tunan"
}

Fk:loadTranslationTable{
  ['tunan'] = '图南',
  ['#tunan'] = '图南：令一名角色观看牌堆顶牌，其可以使用此牌或将此牌当【杀】使用',
  ['tunan1'] = '使用%arg（无距离限制）',
  ['tunan2'] = '将%arg当【杀】使用',
  ['#tunan2-use'] = '图南：将%arg当【杀】使用',
  [':tunan'] = '出牌阶段限一次，你可令一名其他角色观看牌堆顶一张牌，然后该角色选择一项：1.使用此牌（无距离限制）；2.将此牌当【杀】使用。',
  ['$tunan1'] = '敢问丞相，何时挥师南下？',
  ['$tunan2'] = '攻伐之道，一念之间。',
}

tunan:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#tunan",
  can_use = function(self, player)
    return player:usedSkillTimes(tunan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect, event)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(1)
    local card = Fk:getCardById(cards[1])
    local choices = {}  --选项一无距离限制，选项二有距离限制，不能用interaction……
    if U.getDefaultTargets(target, card, false, true) then
      table.insert(choices, "tunan1:::"..card:toLogString())
    end
    local slash = Fk:cloneCard("slash")
    slash.skillName = tunan.name
    slash:addSubcard(card)
    if U.getDefaultTargets(target, slash, true, false) then
      table.insert(choices, "tunan2:::"..card:toLogString())
    end
    if #choices == 0 then
      return
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = tunan.name,
      all_choices = {"tunan1:::" .. card:toLogString(), "tunan2:::" .. card:toLogString()}
    })
    if choice[6] == "1" then
      room:askToUseRealCard(target, {
        pattern = cards,
        skill_name = tunan.name,
        expand_pile = cards,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
        },
        cancelable = false
      })
    else
      U.askForUseVirtualCard(room, target, "slash", cards, tunan.name, "#tunan2-use:::"..card:toLogString(), false, true, false, true)
    end
  end,
})

return tunan
