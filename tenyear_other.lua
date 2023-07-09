local extension = Package("tenyear_other")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_other"] = "十周年-其他",
}

local longwang = General(extension, "longwang", "god", 3)
local ty__longgong = fk.CreateTriggerSkill{
  name = "ty__longgong",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and not data.from.dead and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#longgong-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|.|.|.|.|equip")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = data.from.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    return true
  end,
}
local ty__sitian = fk.CreateActiveSkill{
  name = "ty__sitian",
  anim_type = "offensive",
  card_num = 2,
  target_num = 0,
  can_use = function(self, player)
    return player:getHandcardNum() > 1
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Hand and #selected < 2 then
      if #selected == 1 then
        return Fk:getCardById(to_select).suit ~= Fk:getCardById(selected[1]).suit
      end
      return true
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local choices = table.random({"sitian1", "sitian2", "sitian3", "sitian4", "sitian5"}, 2)
    local choice = room:askForChoice(player, choices, self.name, "#ty__sitian-choice", true)
    local targets = room:getOtherPlayers(player)
    if choice ~= "sitian4" then
      room:doIndicate(player.id, table.map(targets, function(p) return p.id end))
    end
    if choice == "sitian1" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = self.name
          }
        end
      end
    end
    if choice == "sitian2" then
      for _, p in ipairs(targets) do
        if not p.dead then
          local judge = {
            who = p,
            reason = "lightning",
            pattern = ".|2~9|spade",
          }
          room:judge(judge)
          local result = judge.card
          if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
            room:damage{
              to = p,
              damage = 3,
              card = effect.card,
              damageType = fk.ThunderDamage,
              skillName = self.name,
            }
          end
        end
      end
    end
    if choice == "sitian3" then
      for _, p in ipairs(targets) do
        if not p.dead then
          if #p.player_cards[Player.Equip] > 0 then
            p:throwAllCards("e")
          else
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
    if choice == "sitian4" then
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end), 1, 1,
        "#sitian-choose", self.name, true)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
        if not to:isKongcheng() then
          to:throwAllCards("h")
        else
          room:loseHp(to, 1, self.name)
        end
      end
    end
    if choice == "sitian5" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:setPlayerMark(p, "@@lw_dawu", 1)
        end
      end
    end
  end,
}
local sitian_trigger = fk.CreateTriggerSkill{
  name = "#sitian_trigger",
  mute = true,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@lw_dawu") > 0 and data.card.type == Card.TypeBasic
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@lw_dawu", 0)
    return true
  end,
}
ty__sitian:addRelatedSkill(sitian_trigger)
longwang:addSkill(ty__longgong)
longwang:addSkill(ty__sitian)
Fk:loadTranslationTable{
  ["longwang"] = "东海龙王",
  ["ty__longgong"] = "龙宫",
  [":ty__longgong"] = "每回合限一次，当你受到伤害时，你可以防止此伤害，改为令伤害来源随机获得牌堆中的一张装备牌。",
  ["ty__sitian"] = "司天",
  [":ty__sitian"] = "出牌阶段，你可以弃置两张不同花色的手牌，然后改变天气（从两个选项中选择一项）：<br>烈日：对其他角色各造成1点火焰伤害；<br>"..
  "雷电：所有其他角色各进行一次【闪电】判定；<br>大浪：所有其他角色弃置装备区所有牌（没有装备则失去1点体力）；<br>"..
  "暴雨：弃置一名角色所有手牌（没有手牌则失去1点体力）；<br>大雾：所有其他角色使用的下一张基本牌无效。",
  ["#longgong-invoke"] = "龙宫：你可以防止你受到的伤害，令 %dest 随机获得一张装备牌。",
  ["#ty__sitian-choice"] = "司天：选择执行的一项",
  ["#sitian-choose"] = "暴雨：令一名角色弃置所有手牌，若其没有手牌则改为失去1点体力。",
  ["sitian1"] = "烈日",
  [":sitian1"] = "对其他角色各造成1点火焰伤害",
  ["sitian2"] = "雷电",
  [":sitian2"] = "所有其他角色各进行一次【闪电】判定",
  ["sitian3"] = "大浪",
  [":sitian3"] = "所有其他角色弃置装备区所有牌（没有装备则失去1点体力）",
  ["sitian4"] = "暴雨",
  [":sitian4"] = "弃置一名角色所有手牌（没有手牌则失去1点体力）",
  ["sitian5"] = "大雾",
  [":sitian5"] = "所有其他角色使用的下一张基本牌无效",
  ["@@lw_dawu"] = "大雾",

  ["$ty__longgong1"] = "停手，大哥！给东西能换条命不？",
  ["$ty__longgong2"] = "冤家宜解不宜结。",
  ["$ty__longgong3"] = "莫要伤了和气。",
  ["$ty__sitian1"] = "观众朋友大家好，欢迎收看天气预报！",
  ["$ty__sitian2"] = "这一喷嚏，不知要掀起多少狂风暴雨。",
  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

local libai = General(extension, "libai", "god", 3)
local jiuxian = fk.CreateViewAsSkill{
  name = "jiuxian",
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain", "redistribute"}
    return #selected == 0 and table.contains(names, Fk:getCardById(to_select).trueName)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("analeptic")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local jiuxian_targetmod = fk.CreateTargetModSkill{
  name = "#jiuxian_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill("jiuxian") and card.trueName == "analeptic" and scope == Player.HistoryTurn
  end,
}
local shixian_pairs = {{"slash", "archery_attack", "vine", "enemy_at_the_gates"},
  {"indulgence", "crossbow", "axe", "chitu", "dilu", "wonder_map", "taigong_tactics"},
  {"dark_armor", "underhanding"},
  {"peach", "blade", "spear", "dismantlement", "guding_blade", "daggar_in_smile", "seven_stars_sword"},
  {"ex_nihilo", "duel", "huailiu", "analeptic"},
  {"jink", "lightning", "qinggang_sword", "double_swords", "ice_sword", "zhuahuangfeidian", "dayuan",
    "supply_shortage", "fan", "iron_chain", "black_chain", "five_elements_fan", "chasing_near"},
  {"collateral", "savage_assault", "eight_diagram", "nioh_shield", "drowning"},
  {"amazing_grace", "kylin_bow", "jueying", "zixing", "fire_attack", "breastplate", "raid_and_frontal_attack"},
  {"god_salvation", "nullification", "halberd", "silver_lion", "unexpectation", "foresight", "honey_trap"},
}
--a ia ua：杀，万箭齐发，藤甲，兵临城下，
--o e uo：乐不思蜀，诸葛连弩，贯石斧，赤兔，的卢，天机图，太公阴符，
--ie ve
--ai uai：黑光铠，瞒天过海
--ei ui：调剂盐梅
--ao iao：桃，青龙偃月刀，丈八蛇矛，过河拆桥，古锭刀，笑里藏刀，七宝刀，
--ou iu：无中生有，决斗，骅骝，酒，
--an ian uan van：闪，闪电，青釭剑，雌雄双股剑，寒冰剑，爪黄飞电，大宛，兵粮寸断，朱雀羽扇，铁索连环，乌铁锁链，五行鹤翎扇，逐近弃远，
--en in un vn：借刀杀人，南蛮入侵，八卦阵，仁王盾，水淹七军
--ang iang uang：顺手牵羊
--eng ing ong ung：五谷丰登，麒麟弓，绝影，紫骍，火攻，护心镜，奇正相生，
--i er v：桃园结义，无懈可击，方天画戟，白银狮子，出其不意，洞烛先机，美人计，
--u
local shixian = fk.CreateTriggerSkill{
  name = "shixian",
  anim_type = "special",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@shixian-turn") == 0 then
      room:setPlayerMark(player, "@shixian-turn", data.card.trueName)
      return
    else
      if data.card.trueName == player:getMark("@shixian-turn") then
        self:doCost(event, target, player, data)
      else
        local name = player:getMark("@shixian-turn")
        room:setPlayerMark(player, "@shixian-turn", data.card.trueName)
        for _, p in ipairs(shixian_pairs) do
          if table.contains(p, name) and table.contains(p, data.card.trueName) then
            self:doCost(event, target, player, data)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shixian-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not table.contains({"jink", "nullification"}, data.card.trueName) and
      not (data.card.trueName == "peach" and player:isWounded()) then
      data.extra_data = data.extra_data or {}
      data.extra_data.shixian = data.extra_data.shixian or true
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.AfterCardUseDeclared, fk.AfterCardsMove, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return data.extra_data and data.extra_data.shixian
    elseif event == fk.AfterCardUseDeclared then
      return player == target
    elseif event == fk.AfterCardsMove then
      return player:hasSkill(self.name, true) and player:getMark("shixian_name") ~= 0
    elseif event == fk.TurnEnd then
      return player:getMark("shixian_name") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      player.room:doCardUseEffect(data)
      data.extra_data.shixian = false
      return false
    elseif event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "shixian_name", data.card.trueName)
    elseif event == fk.TurnEnd then
      room:setPlayerMark(player, "shixian_name", 0)
    elseif event == fk.AfterCardsMove then
      local no_change = true
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            room:setCardMark(Fk:getCardById(info.cardId), "@@shixian_rhyme", 0)
          end
        end
        if move.to == player.id and move.toArea == Card.PlayerHand then
          no_change = false
        end
      end
      if no_change then return false end
    end
    local lastcardname = player:getMark("shixian_name")
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local cardname = card.trueName
      local marked = 0
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(shixian_pairs) do
          if table.contains(p, cardname) and table.contains(p, lastcardname) then
            marked = 1
            break
          end
        end
      end
      if marked ~= card:getMark("@@shixian_rhyme") then
        room:setCardMark(card, "@@shixian_rhyme", marked)
      end
    end
  end,
}
jiuxian:addRelatedSkill(jiuxian_targetmod)
libai:addSkill(jiuxian)
libai:addSkill(shixian)
Fk:loadTranslationTable{
  ["libai"] = "李白",
  ["jiuxian"] = "酒仙",
  [":jiuxian"] = "你使用【酒】无次数限制，你可将多目标锦囊牌当【酒】使用。",
  ["shixian"] = "诗仙",
  [":shixian"] = "你使用一张牌时，若此牌与你本回合使用的上一张牌押韵，你可以摸一张牌并令此牌额外执行一次效果。",
  ["@shixian-turn"] = "诗仙",
  ["#shixian-invoke"] = "诗仙：%arg押韵！你可以摸一张牌并令此牌额外执行一次效果！",

  ["@@shixian_rhyme"] = "押韵",

  ["$jiuxian1"] = "地若不爱酒，地应无酒泉。",
  ["$jiuxian2"] = "天若不爱酒，酒星不在天。",
  ["$shixian1"] = "武侯立岷蜀，壮志吞咸京。",
  ["$shixian2"] = "鱼水三顾合，风云四海生。",
  ["~libai"] = "谁识卧龙客，长吟愁鬓斑。",
}

local khan = General(extension, "khan", "god", 3)
local tongliao = fk.CreateTriggerSkill{
  name = "tongliao",
  anim_type = "special",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == player.Draw and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player.player_cards[Player.Hand], function(id)
      return table.every(player.player_cards[Player.Hand], function(id2)
        return Fk:getCardById(id).number <= Fk:getCardById(id2).number end) end)
    local cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|.|.|.|"..table.concat(ids, ","), "#tongliao-invoke")
    if #cards > 0 then
      self.cost_data = cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setCardMark(Fk:getCardById(self.cost_data), "@@tongliao", 1)
  end,
}
local tongliao_trigger = fk.CreateTriggerSkill{
  name = "#tongliao_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("tongliao") then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.tongliao then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tongliao", "drawcard")
    room:broadcastSkillInvoke("tongliao")
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.extra_data and move.extra_data.tongliao then
        n = n + move.extra_data.tongliao
      end
    end
    player:drawCards(n, "tongliao")
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill("tongliao") then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@tongliao") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@tongliao") > 0 then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@@tongliao", 0)
            n = n + Fk:getCardById(info.cardId).number
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.tongliao = n
        end
      end
    end
  end,
}
local wudao = fk.CreateTriggerSkill{
  name = "wudao",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.CardUseFinished then
        return data.extra_data and data.extra_data.wudao and
          (player:getMark("wudao-turn") == 0 or not table.contains(player:getMark("wudao-turn"), data.extra_data.wudao))
      else
        return player:getMark("wudao-turn") ~= 0 and table.contains(player:getMark("wudao-turn"), data.card:getTypeString())
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wudao-invoke:::"..data.extra_data.wudao)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local mark = player:getMark("wudao-turn")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.extra_data.wudao)
      room:setPlayerMark(player, "@wudao-turn", table.concat(mark, ","))
      room:setPlayerMark(player, "wudao-turn", mark)
    else
      data.disresponsiveList = table.map(room.alive_players, function(p) return p.id end)
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark(self.name)
    if mark ~= 0 and mark == data.card:getTypeString() and data.card.type ~= Card.TypeEquip and
      (player:getMark("wudao-turn") == 0 or not table.contains(player:getMark("wudao-turn"), data.card:getTypeString())) then
      data.extra_data = data.extra_data or {}
      data.extra_data.wudao = data.card:getTypeString()
    end
    player.room:setPlayerMark(player, self.name, data.card:getTypeString())
  end,
}
tongliao:addRelatedSkill(tongliao_trigger)
khan:addSkill(tongliao)
khan:addSkill(wudao)
Fk:loadTranslationTable{
  ["khan"] = "小约翰可汗",
  ["tongliao"] = "通辽",
  [":tongliao"] = "摸牌阶段结束时，你可以将手牌中点数最小的一张牌标记为“通辽”。当你失去“通辽”牌后，你摸X张牌（X为“通辽”牌的点数）。",
  ["wudao"] = "悟道",
  [":wudao"] = "当你连续使用两张相同类型的牌后，你使用此类型的牌伤害+1且不可被响应直到回合结束。",
  ["#tongliao-invoke"] = "通辽：你可以将一张点数最小的手牌标记为“通辽”牌",
  ["@@tongliao"] = "通辽",
  ["#wudao-invoke"] = "悟道：你可以令你使用%arg伤害+1且不可被响应直到当前回合结束",
  ["@wudao-turn"] = "悟道",
}

return extension
