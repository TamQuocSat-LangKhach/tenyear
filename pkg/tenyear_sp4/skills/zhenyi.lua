local zhenyi = fk.CreateSkill {
  name = "zhenyi"
}

Fk:loadTranslationTable{
  ['zhenyi'] = '真仪',
  ['#zhenyi2'] = '真仪：你可以弃置♣后土，将一张牌当【桃】使用',
  ['@@faluclub'] = '♣后土',
  ['#zhenyi_trigger'] = '真仪',
  ['@@faluspade'] = '♠紫微',
  ['@@faluheart'] = '<font color=>♥</font>玉清',
  ['@@faludiamond'] = '<font color=>♦</font>勾陈',
  ['#zhenyi1'] = '真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color=>♥5</font>',
  ['#zhenyi3'] = '真仪：你可以弃置<font color=>♥</font>玉清，对 %dest 造成的伤害+1',
  ['#zhenyi4'] = '真仪：你可以弃置<font color=>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张',
  ['zhenyi_spade'] = '将判定结果改为♠5',
  ['zhenyi_heart'] = '将判定结果改为<font color=>♥5</font>',
  [':zhenyi'] = '你可以在以下时机弃置相应的标记来发动以下效果：<br>当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color=>♥5</font>；<br>当你于回合外需要使用【桃】时，你可以弃置“后土”，然后将你的一张牌当【桃】使用；<br>当你造成伤害时，你可以弃置“玉清”，此伤害+1；<br>当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。',
  ['$zhenyi1'] = '不疾不徐，自爱自重。',
  ['$zhenyi2'] = '紫薇星辰，斗数之仪。',
}

-- ViewAsSkill
zhenyi:addEffect('viewas', {
  anim_type = "support",
  pattern = "peach",
  prompt = "#zhenyi2",
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@faluclub", 1)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = zhenyi.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:getMark("@@faluclub") > 0
  end,
})

-- TriggerSkill
zhenyi:addEffect({fk.AskForRetrial, fk.DamageCaused, fk.Damaged}, {
  main_skill = zhenyi,
  mute = true,
  can_trigger = function(self, event, target, player)
    if player:hasSkill(zhenyi.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local prompt
    if event == fk.AskForRetrial then
      prompt = "#zhenyi1::"..target.id
    elseif event == fk.DamageCaused then
      prompt = "#zhenyi3::"..data.to.id
    elseif event == fk.Damaged then
      prompt = "#zhenyi4"
    end
    return room:askToSkillInvoke(player, {
      skill_name = zhenyi.name,
      prompt = prompt,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenyi.name)
    if event == fk.AskForRetrial then
      room:notifySkillInvoked(player, zhenyi.name, "control")
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askToChoice(player, {
        choices = {"zhenyi_spade", "zhenyi_heart"},
        skill_name = zhenyi.name,
      })
      local new_card = Fk:cloneCard(data.card.name, choice == "zhenyi_spade" and Card.Spade or Card.Heart, 5)
      new_card.skillName = zhenyi.name
      new_card.id = data.card.id
      data.card = new_card
      room:sendLog{
        type = "#ChangedJudge",
        from = player.id,
        to = { data.who.id },
        arg2 = new_card:toLogString(),
        arg = zhenyi.name,
      }
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, zhenyi.name, "offensive")
      room:removePlayerMark(player, "@@faluheart", 1)
      data.damage = data.damage + 1
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, zhenyi.name, "masochism")
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhenyi.name,
        })
      end
    end
  end,
})

return zhenyi
