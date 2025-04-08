local fuli = fk.CreateSkill {
  name = "fulil",
}

Fk:loadTranslationTable{
  ["fulil"] = "抚黎",
  [":fulil"] = "出牌阶段限一次，你可以展示所有手牌，弃置其中一种类别的牌，然后摸X张牌（X为以此法弃置的牌名字数之和，"..
  "至多为场上手牌最多的角色的手牌数），然后你可以令一名角色攻击范围-1直到你下回合开始。若以此法弃置了伤害牌，"..
  "则改为其攻击范围减至0直到你下回合开始。",

  ["#fulil"] = "抚黎：展示所有手牌，弃置一种类别的牌，摸牌名字数之和的牌，然后令一名角色攻击范围减少",
  ["#fulil_ex-choose"] = "抚黎：你可以令一名角色攻击范围减至0直到你下回合开始",
  ["#fulil-choose"] = "抚黎：你可以令一名角色攻击范围-1直到你下回合开始",
  ["@fulil"] = "抚黎 攻击范围",
  ["fulil_0"] = "为0",

  ["$fulil1"] = "民为贵，社稷次之，君为轻。",
  ["$fulil2"] = "民之所欲，天必从之。",
}

fuli:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#fulil",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fuli.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:showCards(player:getCardIds("h"))
    local types = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end
    local choice = room:askToChoice(player, {
      choices = types,
      skill_name = fuli.name,
      all_choices = {"basic", "trick", "equip"}
    })
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getTypeString() == choice and not player:prohibitDiscard(id)
    end)
    if #cards == 0 then return end
    local n = 0
    local update = false
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      n = n + Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len()
      if card.is_damage_card then
        update = true
      end
    end
    room:throwCard(cards, fuli.name, player, player)
    if player.dead then return end
    local max = 0
    for _, p in ipairs(room.alive_players) do
      if max < p:getHandcardNum() then
        max = p:getHandcardNum()
      end
    end
    player:drawCards(math.min(max, n), fuli.name)
    if player.dead then return end

    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = update and "#fulil_ex-choose" or "#fulil-choose",
      skill_name = fuli.name,
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
      local mark = player:getTableMark(fuli.name)
      local info = mark[tostring(to.id)] or "0"
      if update then
        info = "fulil_0"
      elseif info ~= "fulil_0" then
        info = tostring(tonumber(info) - 1)
      end
      mark[tostring(to.id)] = info
      room:setPlayerMark(player, fuli.name, mark)
      if update then
        room:setPlayerMark(to, "@fulil", "fulil_0")
      elseif to:getMark("@fulil") ~= "fulil_0" then
        if to:getMark("@fulil") == 0 then
          room:setPlayerMark(to, "@fulil", "-1")
        else
          n = tostring(tonumber(to:getMark("@fulil")) - 1)
          room:setPlayerMark(to, "@fulil", n)
        end
      end
    end
  end,
})
local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(fuli.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, fuli.name, 0)
    local new_dat = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getMark(fuli.name) ~= 0 then
        for key, value in pairs(p:getMark(fuli.name)) do
          new_dat[key] = new_dat[key] or "0"
          if value == "fulil_0" then
            new_dat[key] = "fulil_0"
          elseif new_dat[key] ~= "fulil_0" then
            new_dat[key] = tostring(tonumber(new_dat[key]) + tonumber(value))
          end
        end
      end
    end
    for _, p in ipairs(room.alive_players) do
      if new_dat[tostring(p.id)] then
        room:setPlayerMark(p, "@fulil", new_dat[tostring(p.id)])
      else
        room:setPlayerMark(p, "@fulil", 0)
      end
    end
  end,
}

fuli:addEffect(fk.TurnStart, spec)
fuli:addEffect(fk.Death, spec)

fuli:addEffect("atkrange", {
  correct_func = function (self, from)
    if from:getMark("@fulil") ~= 0 then
      if from:getMark("@fulil") ~= "fulil_0" then
        return tonumber(from:getMark("@fulil"))
      end
    end
  end,
  final_func = function (self, player)
    if player:getMark("@fulil") == "fulil_0" then
      return 0
    end
  end,
})

return fuli
