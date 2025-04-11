local biyue = fk.CreateSkill {
  name = "ty_ex__yanzhu"
}

Fk:loadTranslationTable{
  ['ty_ex__yanzhu'] = '宴诛',
  ['@@yanzhudamage'] = '宴诛 受伤+1',
  ['ty_ex__yanzhu_choice1'] = '弃置一张牌',
  ['ty_ex__yanzhu_choice2'] = '令其获得你装备区里所有牌并修改宴诛和兴学',
  ['#ty_ex__yanzhu-choice'] = '宴诛：选择%src弃置一张牌或令%src获得你装备区所有牌并修改“宴诛”和“兴学”',
  ['#ty_ex__yanzhu_trigger'] = '宴诛',
  [':ty_ex__yanzhu'] = '出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌，其下次受到伤害的+1直到其下个回合开始；2.交给你装备区内所有的牌，你修改〖宴诛〗为 “出牌阶段限一次，你可以选择一名其他角色，令其下次受到的伤害+1直到其下个回合开始。”和修改〖兴学〗为“X为你的体力上限”。',
  ['$ty_ex__yanzhu1'] = '觥筹交错，杀人于无形！',
  ['$ty_ex__yanzhu2'] = '子烈设宴，意在汝项上人头！',
}

biyue:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(biyue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if player:getMark(biyue.name) > 0 then
      return #selected == 0 and to_select ~= player.id
    else
      return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:getMark(biyue.name) > 0 then
      room:setPlayerMark(target, "@@yanzhudamage", 1)
      return
    end
    local choices = {"ty_ex__yanzhu_choice1"}
    if #target:getCardIds("e") > 0 then
      table.insert(choices, "ty_ex__yanzhu_choice2")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = biyue.name,
      prompt = "#ty_ex__yanzhu-choice:" .. player.id
    })
    if choice == "ty_ex__yanzhu_choice1" then
      room:setPlayerMark(target, "@@yanzhudamage", 1)
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = biyue.name,
        cancelable = false
      })
    elseif choice == "ty_ex__yanzhu_choice2" then
      room:obtainCard(player.id, target:getCardIds(Player.Equip), true, fk.ReasonGive, target.id)
      room:setPlayerMark(player, biyue.name, 1)
    end
  end,
})

biyue:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@yanzhudamage") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@yanzhudamage") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage", 0)
  end,
})

return biyue
