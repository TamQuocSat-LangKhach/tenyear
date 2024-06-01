local extension = Package("tenyear_other")
extension.extensionName = "tenyear"
--extension.game_modes_whitelist = { "m_1v2_mode" }

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_other"] = "十周年-其他",
  ["tycl"] = "典",
  ["child"] = "儿童节",
}

local longwang = General(extension, "longwang", "god", 3)
local ty__longgong = fk.CreateTriggerSkill{
  name = "ty__longgong",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
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
    if Self:prohibitDiscard(Fk:getCardById(to_select)) then
      return false
    end

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
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
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
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
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
  on_cost = Util.TrueFunc,
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
  ["@@lw_dawu"] = "雾",
  ["#sitian_trigger"] = "司天",

  ["$ty__longgong1"] = "停手，大哥！给东西能换条命不？",
  ["$ty__longgong2"] = "冤家宜解不宜结。",
  ["$ty__longgong3"] = "莫要伤了和气。",
  ["$ty__sitian1"] = "观众朋友大家好，欢迎收看天气预报！",
  ["$ty__sitian2"] = "这一喷嚏，不知要掀起多少狂风暴雨。",
  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

local wuzixu = General(extension, "wuzixu", "god", 4)
local ty__nutao = fk.CreateTriggerSkill{
  name = "ty__nutao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TargetSpecified then
        return data.card.type == Card.TypeTrick and data.firstTarget and
          table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
      else
        return player.phase == Player.Play and data.damageType == fk.ThunderDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function(id)
        return id ~= player.id and not room:getPlayerById(id).dead end)
      local to = room:getPlayerById(table.random(targets))
      room:doIndicate(player.id, {to.id})
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      room:addPlayerMark(player, "@ty__nutao-phase", 1)
    end
  end,
}
local ty__nutao_targetmod = fk.CreateTargetModSkill{
  name = "#ty__nutao_targetmod",
  residue_func = function(self, player, skill, scope, card, to)
    if card and card.trueName == "slash" and player:getMark("@ty__nutao-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@ty__nutao-phase")
    end
  end,
}
ty__nutao:addRelatedSkill(ty__nutao_targetmod)
wuzixu:addSkill(ty__nutao)
Fk:loadTranslationTable{
  ["wuzixu"] = "涛神",
  ["ty__nutao"] = "怒涛",
  [":ty__nutao"] = "锁定技，当你使用锦囊牌指定目标后，你随机对一名其他目标角色造成1点雷电伤害；当你于出牌阶段造成雷电伤害后，你本阶段使用【杀】次数上限+1。",
  ["@ty__nutao-phase"] = "怒涛",
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
local shixian_pairs = {
  {"slash", "archery_attack", "vine", "enemy_at_the_gates", "glittery_armor", "shangyang_reform"},
  {"steel_lance", "wd_crossbow_tank", "wd_stop_thirst"},
  {"looting"},
  {"dark_armor", "underhanding"},
  {"redistribute", "defeating_the_double", "floating_thunder", "wd_save_energy"},
  {"peach", "blade", "spear", "dismantlement", "guding_blade", "daggar_in_smile", "seven_stars_sword", 
    "crafty_escape", "reinforcement", "await_exhausted", "triblade", "wd_seven_stars_sword"},
  {"ex_nihilo", "duel", "huailiu", "analeptic", "wd_run"},
  {"jink", "lightning", "qinggang_sword", "double_swords", "ice_sword", "zhuahuangfeidian", "dayuan",
    "supply_shortage", "fan", "iron_chain", "black_chain", "five_elements_fan", "chasing_near", "n_brick", "six_swords", "qin_dragon_sword"},
  {"collateral", "savage_assault", "eight_diagram", "nioh_shield", "drowning", "horsetail_whisk", "wd_drowning", "wd_gold"},
  {"snatch", "substituting", "moon_spear", "wd_rice"},
  {"amazing_grace", "kylin_bow", "jueying", "zixing", "fire_attack", "breastplate", "raid_and_frontal_attack",
    "abandoning_armor", "paranoid", "befriend_attacking", "wd_breastplate", "wd_let_off_enemy"},
  {"god_salvation", "nullification", "halberd", "silver_lion", "unexpectation", "foresight", "honey_trap",
    "avoiding_disadvantages", "diversion", "time_flying", "known_both", "wd_sun_moon_halberd"},
  {"indulgence", "crossbow", "axe", "chitu", "dilu", "wonder_map", "taigong_tactics", "poison", 
    "replace_with_a_fake", "sincere_treat", "wenhe_chaos", "n_relx_v", "peace_spell", "golden_comb", "jade_comb", "rhino_comb",
    "celestial_calabash", "talisman", "wd_baihu", "wd_lure_in_deep"},
}
--a ia ua：杀，万箭齐发，藤甲，兵临城下，烂银甲，商鞅变法
--o e uo：衠钢槊，连弩战车，望梅止渴
--ie ve：趁火打劫
--ai uai：黑光铠，瞒天过海
--ei ui：调剂盐梅，以半击倍，浮雷，养精蓄锐
--ao iao：桃，青龙偃月刀，丈八蛇矛，过河拆桥，古锭刀，笑里藏刀，七宝刀，金蝉脱壳，增兵减灶，以逸待劳，三尖两刃刀，七星刀
--ou iu：无中生有，决斗，骅骝，酒，走
--an ian uan van：闪，闪电，青釭剑，雌雄双股剑，寒冰剑，爪黄飞电，大宛，兵粮寸断，朱雀羽扇，铁索连环，乌铁锁链，五行鹤翎扇，逐近弃远，砖，吴六剑，真龙长剑
--en in un vn：借刀杀人，南蛮入侵，八卦阵，仁王盾，水淹七军，太极拂尘，金
--ang iang uang：顺手牵羊，李代桃僵，银月枪，粮
--eng ing ong ung：五谷丰登，麒麟弓，绝影，紫骍，火攻，护心镜，奇正相生，弃甲曳兵，草木皆兵，远交近攻，欲擒故纵
--i er v：桃园结义，无懈可击，方天画戟，白银狮子，出其不意，洞烛先机，美人计，违害就利，声东击西，斗转星移，知己知彼，日月戟
--u：乐不思蜀，诸葛连弩，贯石斧，赤兔，的卢，天机图，太公阴符，毒，偷梁换柱，推心置腹，文和乱武，悦刻五，太平要术，金梳，琼梳，犀梳，灵宝仙葫，冲应神符，白鹄，诱敌深入
local shixian = fk.CreateTriggerSkill{
  name = "shixian",
  anim_type = "special",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
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
      return player:hasSkill(self, true) and player:getMark("shixian_name") ~= 0
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
      if player:hasSkill(self, true) then
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
    return target == player and player:hasSkill(self) and player.phase == player.Draw and not player:isKongcheng()
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
    local room = player.room
    local id = self.cost_data
    local mark = type(player:getMark("tongliao")) == "table" and player:getMark("tongliao") or {}
    table.insertIfNeed(mark, id)
    room:setPlayerMark(player, "tongliao", mark)
    room:setCardMark(Fk:getCardById(id), "@@tongliao-inhand", 1)
  end,
}
local tongliao_delay = fk.CreateTriggerSkill{
  name = "#tongliao_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead or type(player:getMark("tongliao")) ~= "table" then return false end
    local mark = player:getMark("tongliao")
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tongliao", "drawcard")
    player:broadcastSkillInvoke("tongliao")
    local mark = player:getMark("tongliao")
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark, info.cardId) then
            x = x + Fk:getCardById(info.cardId).number
          end
        end
      end
    end
    room:setPlayerMark(player, "tongliao", #mark > 0 and mark or 0)
    if x > 0 then
      room:drawCards(player, x, "tongliao")
    end
  end,
}
local wudao = fk.CreateTriggerSkill{
  name = "wudao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip then
      local mark = U.getMark(player, "@wudao-turn")
      if table.contains(mark, data.card:getTypeString().."_char") then
        return data.card.sub_type ~= Card.SubtypeDelayedTrick
      else
        local use_e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if not use_e then return false end
        local events = player.room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          local e = events[i]
          local use = e.data[1]
          if use.from == player.id then
            if e.id < use_e.id then
              return use.card.type == data.card.type
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return table.contains(U.getMark(player, "@wudao-turn"), data.card:getTypeString().."_char") or
    player.room:askForSkillInvoke(player, self.name, nil, "#wudao-invoke:::"..data.card:getTypeString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "@wudao-turn")
    local type_name = data.card:getTypeString().."_char"
    if table.contains(mark, type_name) then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      end
    else
      table.insert(mark, type_name)
      room:setPlayerMark(player, "@wudao-turn", mark)
    end
  end,
}
tongliao:addRelatedSkill(tongliao_delay)
khan:addSkill(tongliao)
khan:addSkill(wudao)
Fk:loadTranslationTable{
  ["khan"] = "小约翰可汗",
  ["tongliao"] = "通辽",
  [":tongliao"] = "摸牌阶段结束时，你可以将手牌中点数最小的一张牌标记为“通辽”。当你失去“通辽”牌后，你摸X张牌（X为“通辽”牌的点数）。",
  ["wudao"] = "悟道",
  [":wudao"] = "每回合每种类别限一次，当你使用基本牌或锦囊牌时，若此牌与你使用的上一张牌类别相同，你可以令此牌结算结束后，你本回合使用此类型的牌不能被响应且造成的伤害+1。",
  ["#tongliao-invoke"] = "通辽：你可以将一张点数最小的手牌标记为“通辽”牌",
  ["@@tongliao-inhand"] = "通辽",
  ["#tongliao_delay"] = "通辽",
  ["#wudao-invoke"] = "悟道：你可以令当前结算结束后，本回合你使用 %arg 伤害+1且不可被响应",
  ["@wudao-turn"] = "悟道",

  ["$tongliao1"] = "发动偷袭。",
  ["$tongliao2"] = "不够心狠手辣，怎配江山如画。",
  ["$tongliao3"] = "必须出重拳，而且是物理意义上的出重拳。",
  ["$wudao1"] = "众所周知，能力越大，能力也就越大。",
  ["$wudao2"] = "龙争虎斗彼岸花，约翰给你一个家。",
  ["$wudao3"] = "唯一能够打破命运牢笼的，只有我们自己。",
  ["~khan"] = "留得青山在，老天爷饿不死瞎家雀。",
}

local zhutiexiong = General(extension, "zhutiexiong", "god", 3)
local bianzhuang_choices = {
  --standard
  {"lvbu","wushuang"},{"nos__madai","nos__qianxi"},{"lingju","jieyuan"},
  --ol
  {"quyi","fuji"}, {"caoying","lingren"}, {"ol__lvkuanglvxiang","qigong"},
  {"ol__tianyu","saodi"}, {"xiahouxuan","huanfu"}, {"ol__simashi","yimie"},
  {"ol_ex__huangzhong","ol_ex__liegong"}, {"ol_ex__pangde","ol_ex__jianchu"},
  {"zhaoji","qin__shanwu"}, {"ol__dingfeng","ol__duanbing"}, {"ol_ex__jiaxu","ol_ex__wansha"},
  {"ol__fanchou","ol__xingluan"}, {"yingzheng","qin__yitong"}, {"ol__dengzhi","xiuhao"},
  {"qinghegongzhu","zengou"}, {"ol__wenqin","guangao"}, {"olz__zhonghui","xieshu"},{"olmou__yuanshao", "shenliy"},
  --offline
  {"es__chendao","jianglie"},
  --mini
  {"mini__weiyan","mini__kuanggu"},
  --mobile
  {"mobile__gaolan", "dengli"}, {"mobile__wenyang","quedi"}, {"m_ex__xusheng","m_ex__pojun"},{"m_ex__sunluban","m_ex__zenhui"},
  --mougong
  {"mou__machao", "mou__tieji"},{"mou__zhurong","mou__lieren"},
  --overseas
  {"yuejiu","os__cuijin"}, {"os__tianyu","os__zhenxi"}, {"os__fuwan","os__moukui"},{"zhangwei","os__huzhong"},
  {"os__zangba","os__hengjiang"}, {"os__wuban","os__jintao"}, {"os__haomeng","os__gongge"},
  {"wangyue","os__yulong"}, {"liyan","os__zhenhu"}, {"os__wujing","os__fenghan"},
  {"os_ex__caoxiu","os_ex__qingxi"}, {"os__mayunlu","os__fengpo"},
  --tenyear
  {"ty__baosanniang","ty__wuniang"}, {"wangshuang","zhuilie"}, {"ty__huangzu","xiaojun"},
  {"wm__zhugeliang","qingshi"}, {"mangyachang","jiedao"}, {"caimaozhangyun","jinglan"},
  {"zhaozhong","yangzhong"}, {"sunlang","benshi"}, {"yanrou","choutao"}, {"panghui","yiyong"},
  {"ty__huaxin","wanggui"}, {"guanhai","suoliang"}, {"ty_ex__zhangchunhua","ty_ex__jueqing"},
  {"ty_ex__panzhangmazhong","ty_ex__anjian"}, {"ty_ex__masu","ty_ex__zhiman"},
  {"wenyang","lvli"}, {"ty__luotong","jinjian"},{"tymou__simayi","pingliao"},
  --jsrg
  {"js__sunjian","juelie"}, {"js__zhujun","fendi"}, {"js__liubei","zhenqiao"}, {"js__lvbu","wuchang"},
  --yjtw
  {"tw__xiahouba","tw__baobian"},
  --wandian
  {"wd__hanlong","wd__ciqiu"}, {"wd__furongfuqian","wd__fenkai"},
  --tuguo
  {"tg__xuzhi", "tg__fenwei"}, {"tg__zhuyi","tg__danding"},
}
local bianzhuang = fk.CreateActiveSkill{
  name = "bianzhuang",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = "#bianzhuang",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:usedSkillTimes(self.name, Player.HistoryGame) > 3 and 3 or 2
    local all_choices = table.filter(bianzhuang_choices, function (c)
      return Fk.generals[c[1]] ~= nil and Fk.skills[c[2]] ~= nil
    end)
    local choices = table.random(all_choices, n)
    local generals = table.map(choices, function(c) return c[1] end)
    local skills = table.map(choices, function(c) return {c[2]} end)

    local result = player.room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
      generals, skills, 1, 1, "#bianzhuang-choice", false
    })
    local skill = skills[1][1]
    if result ~= "" then
      skill = json.decode(result)[1]
    end
    local general_name = table.find(generals, function (g, i)
      return skills[i][1] == skill
    end)
    local general = Fk.generals[general_name]

    local bianzhuang_info = {player.general, player.gender, player.kingdom}
    player.general = general_name
    room:broadcastProperty(player, "general")
    player.gender = general.gender
    room:broadcastProperty(player, "gender")
    player.kingdom = general.kingdom
    room:broadcastProperty(player, "kingdom")
    local acquired = (not player:hasSkill(skill, true))
    if acquired then
      room:handleAddLoseSkills(player, skill, nil, false)
    end

    U.askForUseVirtualCard(room, player, "slash", nil, self.name, "#bianzhuang-slash:::"..skill, false, true, true, true)

    if acquired then
      room:handleAddLoseSkills(player, "-"..skill, nil, false)
    end
    player.general = bianzhuang_info[1]
    room:broadcastProperty(player, "general")
    player.gender = bianzhuang_info[2]
    room:broadcastProperty(player, "gender")
    player.kingdom = bianzhuang_info[3]
    room:broadcastProperty(player, "kingdom")
  end,
}
local bianzhuang_record = fk.CreateTriggerSkill{
  name = "#bianzhuang_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeEquip and player:usedSkillTimes("bianzhuang", Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("bianzhuang", 0, Player.HistoryPhase)
  end,
}
bianzhuang:addRelatedSkill(bianzhuang_record)
zhutiexiong:addSkill(bianzhuang)
Fk:loadTranslationTable{
  ["zhutiexiong"] = "朱铁雄",
  ["bianzhuang"] = "变装",
  [":bianzhuang"] = "出牌阶段限一次，你可以从两名武将中选择一个进行变装，然后视为使用一张【杀】（无距离和次数限制），根据变装此【杀】获得额外效果。"..
  "当你使用装备牌后，重置本阶段〖变装〗发动次数。当你发动三次〖变装〗后，本局游戏你进行变装时增加一个选项。",
  ["#bianzhuang"] = "变装：你可以进行“变装”！然后视为使用一张【杀】",
  ["bianzhuang_viewas"] = "变装",
  ["#bianzhuang-slash"] = "变装：视为使用一张【杀】，附带“%arg”的技能效果！",
  ["#bianzhuang-choice"] = "变装：选择你“变装”获得的技能效果",

  ["$bianzhuang1"] = "须知少日凌云志，曾许人间第一流。",
  ["$bianzhuang2"] = "愿尽绵薄之力，盼国风盛行。",
  ["~zhutiexiong"] = "那些看似很可笑的梦，是我们用尽全力守护的光……",
}

local cl__caocao = General(extension, "tycl__caocao", "wei", 4)
local tycl__jianxiong = fk.CreateTriggerSkill{
  name = "tycl__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(self.name, Player.HistoryGame), 5)
    player:drawCards(n, self.name)
    if not player.dead and data.card and U.hasFullRealCard(room, data.card) then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
  end,
}
cl__caocao:addSkill(tycl__jianxiong)
Fk:loadTranslationTable{
  ["tycl__caocao"] = "经典曹操",
  ["tycl__jianxiong"] = "奸雄",
  [":tycl__jianxiong"] = "当你受到伤害后，你可以摸一张牌，并获得造成伤害的牌。当你发动此技能后，摸牌数+1（至多为5）。",
  ["$tycl__jianxiong"] = "宁教我负天下人休教天下人负我！",
  ["~tycl__caocao"] = "霸业未成未成啊！",
}

local cl__liubei = General(extension, "tycl__liubei", "shu", 4)
local tycl__rende = fk.CreateActiveSkill{
  name = "tycl__rende",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#tycl__rende",
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target:getMark("tycl__rende-phase") == 0 and target:getHandcardNum() > 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "tycl__rende-phase", 1)
    local cards = room:askForCardsChosen(player, target, 2, 2, "h", self.name)
    room:obtainCard(player.id, cards, false, fk.ReasonPrey)
    if player.dead then return end
    local mark = player:getMark("tycl__rende")
    if mark == 0 then
      mark = U.getAllCardNames("b")
      room:setPlayerMark(player, "tycl__rende", mark)
    end
    if #mark == 0 then return end
    U.askForUseVirtualCard(room, player, mark, nil, self.name, "#tycl__rende-ask", true, false, false, false)
  end,
}
cl__liubei:addSkill(tycl__rende)
Fk:loadTranslationTable{
  ["tycl__liubei"] = "经典刘备",
  ["#tycl__liubei"] = "乱世的枭雄",
  ["illustrator:tycl__liubei"] = "Kayak",
  ["tycl__rende"] = "章武",
  [":tycl__rende"] = "出牌阶段每名其他角色限一次，你可以获得一名其他角色两张手牌，然后视为使用一张基本牌。",
  ["#tycl__rende"] = "章武：获得一名其他角色两张手牌，然后视为使用一张基本牌",
  ["$tycl__rende1"] = "惟贤惟德能服于人。",
  ["$tycl__rende2"] = "以德服人。",
  ["~tycl__liubei"] = "这就是桃园吗？",

  ["#tycl__rende-ask"] = "章武：你可视为使用一张基本牌",
}

local cl__sunquan = General(extension, "tycl__sunquan", "wu", 4)
local tycl__zhiheng = fk.CreateActiveSkill{
  name = "tycl__zhiheng",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + Self:getMark("@tycl__zhiheng-phase")
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local hand = player:getCardIds(Player.Hand)
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:drawCards(player, #effect.cards + (more and 1 or 0), self.name)
  end
}
local tycl__zhiheng_record = fk.CreateTriggerSkill{
  name = "#tycl__zhiheng_record",

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("tycl__zhiheng") and player.phase == Player.Play and data.to ~= player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("tycl__zhiheng_record-phase")
    if mark == 0 then mark = {} end
    if not table.contains(mark, data.to.id) then
      table.insert(mark, data.to.id)
      room:setPlayerMark(player, "tycl__zhiheng_record-phase", mark)
      room:addPlayerMark(player, "@tycl__zhiheng-phase", 1)
    end
  end,
}
tycl__zhiheng:addRelatedSkill(tycl__zhiheng_record)
cl__sunquan:addSkill(tycl__zhiheng)
Fk:loadTranslationTable{
  ["tycl__sunquan"] = "经典孙权",
  ["tycl__zhiheng"] = "制衡",
  [":tycl__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，额外摸1张牌。出牌阶段对每名角色限一次，"..
  "当你对其他角色造成伤害后，此技能本阶段可发动次数+1。",
  ["@tycl__zhiheng-phase"] = "制衡",
  ["$tycl__zhiheng"] = "容我三思",
  ["~tycl__sunquan"] = "父亲大哥仲谋愧矣。",
}

local sunwukong = General(extension, "sunwukong", "god", 3)
local jinjing = fk.CreateTriggerSkill{
  name = "jinjing",
  frequency = Skill.Compulsory,
  refresh_events = {fk.EventAcquireSkill},
  can_refresh = function (self, event, target, player, data)
    return data == self and player == target
  end,
  on_refresh = function (self, event, target, player, data)
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      player:addBuddy(p)
    end
  end,
}
sunwukong:addSkill(jinjing)
local ruyi = fk.CreateActiveSkill{
  name = "ruyi",
  prompt = "#ruyi",
  frequency = Skill.Compulsory,
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin { from = 1, to = 4 }
  end,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@ruyi", self.interaction.data)
  end,
}
local ruyi_attackrange = fk.CreateAttackRangeSkill{
  name = "#ruyi_attackrange",
  fixed_func = function (self, player)
    if player:hasSkill(ruyi) and player:getMark("@ruyi") ~= 0 then
      return player:getMark("@ruyi")
    end
  end,
}
local ruyi_filter = fk.CreateFilterSkill{
  name = "#ruyi_filter",
  card_filter = function(self, card, player)
    return player:hasSkill(ruyi) and card.sub_type == Card.SubtypeWeapon and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "ruyi"
    return c
  end,
}
local ruyi_targetmod = fk.CreateTargetModSkill{
  name = "#ruyi_targetmod",
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(ruyi) and player:getMark("@ruyi") <= 1 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase
  end,
}
local ruyi_trigger = fk.CreateTriggerSkill{
  name = "#ruyi_trigger",
  mute = true,
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared, fk.EventAcquireSkill, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      return data == ruyi and target == player and player.room:getTag("RoundCount")
    elseif event == fk.GameStart then
      return player:hasShownSkill(ruyi, true)
    end
    if player == target and player:hasSkill(ruyi) and data.card.trueName == "slash" then
      if event == fk.AfterCardUseDeclared then
        return player:getMark("@ruyi") == 2 or player:getMark("@ruyi") == 3
      else
        return player:getMark("@ruyi") == 4 and #U.getUseExtraTargets(player.room, data) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill or event == fk.GameStart then
      room:setPlayerMark(player, "@ruyi", 3)
      if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
        room:abortPlayerArea(player, Player.WeaponSlot)
      end
    else
      if player:getMark("@ruyi") == 2 then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif player:getMark("@ruyi") == 3 then
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      else
        local to = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data),
        1, 1, "#ruyi-choose:::"..data.card:toLogString(), ruyi.name, true)
        if #to > 0 then
          table.insert(data.tos, to)
        end
      end
    end
  end,
}
ruyi:addRelatedSkill(ruyi_attackrange)
ruyi:addRelatedSkill(ruyi_filter)
ruyi:addRelatedSkill(ruyi_targetmod)
ruyi:addRelatedSkill(ruyi_trigger)
sunwukong:addSkill(ruyi)
local cibeis = fk.CreateTriggerSkill{
  name = "cibeis",
  anim_type = "drawcard",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and player ~= data.to then
      return not table.contains(U.getMark(player, "cibeis-turn"), data.to.id)
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#cibeis-invoke:"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local mark = U.getMark(player, "cibeis-turn")
    table.insert(mark, data.to.id)
    player.room:setPlayerMark(player, "cibeis-turn", mark)
    player:drawCards(5, self.name)
    return true
  end,
}
sunwukong:addSkill(cibeis)
Fk:loadTranslationTable{
  ["sunwukong"] = "孙悟空",
  ["jinjing"] = "金睛",
  [":jinjing"] = "锁定技，其他角色的手牌对你可见（此技能失效或失去后仍生效）。",
  ["ruyi"] = "如意",
  [":ruyi"] = "锁定技，你手牌中的武器牌均视为【杀】，你废除武器栏。你的攻击范围基数为3，出牌阶段限一次，你可以调整攻击范围（1~4）。若你的攻击范围基数为：1，使用【杀】无次数限制；2，使用【杀】伤害+1；3，使用【杀】无法响应；4，使用【杀】可额外选择一个目标。",
  ["@ruyi"] = "如意",
  ["#ruyi"] = "如意：选择你的攻击范围",
  ["#ruyi_filter"] = "如意",
  ["#ruyi_trigger"] = "如意",
  ["#ruyi-choose"] = "如意：%arg 可额外选择一个目标",
  ["cibeis"] = "慈悲",
  [":cibeis"] = "每回合每名角色限一次，当你对其他角色造成伤害时，你可以防止此伤害，摸五张牌。",
  ["#cibeis-invoke"] = "慈悲：你可以防止对 %src 造成伤害，摸五张牌",
  ["$ruyi1"] = "俺老孙来也！",
  ["$ruyi2"] = "吃俺老孙一棒！",
  ["$cibeis1"] = "生亦何欢，死亦何苦。",
  ["$cibeis2"] = "我欲成佛，天下无魔；我欲成魔，佛奈我何？",
  ["~sunwukong"] = "曾经有一整片蟠桃园在我面前，失去后才追悔莫及……",
}

local nezha = General(extension, "nezha", "god", 3)
local santou = fk.CreateTriggerSkill{
  name = "santou",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (player.hp >= 3 and data.from and player:getMark("santou_"..data.from.id.."-turn") > 0) or
      (player.hp == 2 and data.damageType ~= fk.NormalDamage) or
      (player.hp == 1 and data.card and data.card.color == Card.Red) then
      room:loseHp(player, 1, self.name)
    end
    if not player.dead and data.from then
      room:setPlayerMark(player, "santou_"..data.from.id.."-turn", 1)
    end
    return true
  end,

  refresh_events = {fk.GameStart},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true) and player.maxHp > 3
  end,
  on_refresh = function (self, event, target, player, data)
    player.maxHp = 3
    player.hp = math.min(player.hp, 3)
    player.room:broadcastProperty(player, "maxHp")
    player.room:broadcastProperty(player, "hp")
  end,
}
local faqi = fk.CreateTriggerSkill{
  name = "faqi",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
    and player.phase == Player.Play and data.card.type == Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "faqi_viewas", "#faqi-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(self.cost_data)
    local card_name = dat.interaction
    local card = Fk:cloneCard(card_name)
    card.skillName = self.name
    local mark = U.getMark(player, "faqi-turn")
    table.insert(mark, card_name)
    room:setPlayerMark(player, "faqi-turn", mark)
    room:useCard{
      from = player.id,
      tos = table.map(dat.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
local faqi_viewas = fk.CreateViewAsSkill{
  name = "faqi_viewas",
  interaction = function()
    local names, all_names = {}, {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        table.insertIfNeed(all_names, card.name)
        if not table.contains(U.getMark(Self, "faqi-turn"), card.name) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names,}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "faqi"
    return card
  end,
}
Fk:addSkill(faqi_viewas)
nezha:addSkill(santou)
nezha:addSkill(faqi)
Fk:loadTranslationTable{
  ["nezha"] = "哪吒",
  ["santou"] = "三头",
  [":santou"] = "锁定技，防止你受到的所有伤害。"..
  "<br>若你体力值不小于3且你本回合已因此技能防止过该伤害来源的伤害，你失去1体力；"..
  "<br>若你体力值为2且防止的伤害为属性伤害，你失去1体力；"..
  "<br>若你体力值为1且防止的伤害为红色牌造成的伤害，你失去1体力。"..
  "<br>（村）游戏开始时，若你的体力上限大于3，调整为3。",
  ["faqi"] = "法器",
  [":faqi"] = "出牌阶段，当你使用装备牌后，你可以视为使用一张普通锦囊牌（每回合每种牌名限一次）。",
  ["faqi_viewas"] = "法器",
  ["#faqi-invoke"] = "法器：你可以视为使用一张普通锦囊牌",

  ["$santou1"] = "任尔计策奇略，我自随机应对。",
  ["$santou2"] = "三相显圣，何惧雷劫地火？",
  ["$faqi1"] = "脚踏风火轮，金印翻天，剑辟阴阳！",
  ["$faqi2"] = "手执火尖枪，红绫混天，乾坤难困我！",
  ["~nezha"] = "莲藕花开，始知三清……",
}

local tycl__sunce = General(extension, "tycl__sunce", "wu", 4)
local shuangbi = fk.CreateActiveSkill{
  name = "shuangbi",
  anim_type = "offensive",
  min_card_num = 0,
  target_num = 0,
  prompt = function (self)
    local n = math.min(#Fk:currentRoom().alive_players, Self.maxHp)
    if self.interaction.data == "ex__zhouyu" then
      return "#shuangbi1:::"..n
    elseif self.interaction.data == "godzhouyu" then
      return "#shuangbi2:::"..n
    elseif self.interaction.data == "tymou__zhouyu" then
      return "#shuangbi3:::"..n
    end
  end,
  interaction = function()
    return UI.ComboBox {choices = {"ex__zhouyu", "godzhouyu", "tymou__zhouyu"}}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, to_select, selected, selected_targets)
    if self.interaction.data == "godzhouyu" then
      return #selected < math.min(#Fk:currentRoom().alive_players, Self.maxHp) and
        not Self:prohibitDiscard(Fk:getCardById(to_select))
    else
      return false
    end
  end,
  feasible = function (self, selected, selected_cards)
    if self.interaction.data == "godzhouyu" then
      return #selected_cards > 0 and #selected_cards <= math.min(#Fk:currentRoom().alive_players, Self.maxHp)
    else
      return #selected_cards == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
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
      player:drawCards(n, self.name)
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, n)
    elseif self.interaction.data == "godzhouyu" then
      n = #effect.cards
      room:throwCard(effect.cards, self.name, player, player)
      room:delay(2000)
      for _ = 1, n, 1 do
        local targets = room:getOtherPlayers(player)
        if #targets == 0 then break end
        local to = table.random(targets)
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    elseif self.interaction.data == "tymou__zhouyu" then
      for i = 1, n, 1 do
        if player.dead or U.askForUseVirtualCard(room, player, {"fire__slash", "fire_attack"}, nil,
        self.name, "#shuangbi-use:::"..i..":"..n, true, true, false, true) == nil then break end
      end
    end
    if player.dead then return end
    if orig_info[1] == "deputy" then
      player.deputyGeneral = orig_info[2]
      room:broadcastProperty(player, "deputyGeneral")
    else
      player.general = orig_info[2]
      room:broadcastProperty(player, "general")
    end
  end,
}

tycl__sunce:addSkill(shuangbi)
Fk:loadTranslationTable{
  ["tycl__sunce"] = "双璧孙策",
  ["shuangbi"] = "双璧",
  [":shuangbi"] = "出牌阶段限一次，你可以<font color='red'>选择一名周瑜助战</font>：<br>界周瑜：摸X张牌，本回合手牌上限+X；<br>神周瑜：弃置至多X张牌，"..
  "随机造成等量的火焰伤害；<br>谋周瑜：视为使用X张火【杀】或【火攻】。<br>（X为存活角色数，至多为你的体力上限）",
  ["#shuangbi1"] = "双璧：摸%arg张牌且本回合手牌上限增加",
  ["#shuangbi2"] = "双璧：弃置至多%arg张牌，随机造成等量火焰伤害",
  ["#shuangbi3"] = "双璧：视为使用%arg张火【杀】或【火攻】",
  ["#shuangbi-use"] = "双璧：你可以视为使用火【杀】或【火攻】（第%arg张，共%arg2张）！",
  ["shuangbi_viewas"] = "双璧",
}

local wuyi = General(extension, "tycl__wuyi", "shu", 4)
local benxiPool = {
  {"mou__mingren", 1},
  {"longyuan", 1},
  {"os__fenwang", 1},
  {"shuyong", 1},
  {"dengli", 1},
  {"ty__zhengnan", 2},
  {"qingbei", 2},
  {"duorui", 2},
  {"jixian", 2},
  {"sijun", 2},
  {"zongfan", 2},
  {"chanshuang", 1},
  {"sp__youdi", 1},
  {"jishan", 1},
  {"qice", 1},
  {"ty_ex__yonglue", 2},
  {"pizhi", 1},
  {"quanmou", 1},
  {"fuxun", 1},
  {"os_ex__yuzhang", 1},
  {"minze", 1},
  {"porui", 2},
  {"qingtan", 1},
  {"choulue", 2},
  {"qizhi", 2},
  {"fujian", 2},
  {"xiuwen", 2},
  {"zhaoluan", 1},
  {"yisuan", 1},
  {"xiaowu", 1},
  {"fangdu", 2},
  {"ty__shefu", 1},
  {"os__juexing", 1},
  {"weiwu", 2},
  {"daigong", 2},
  {"zhaohan", 1},
  {"ol__wuji", 1},
  {"ol__hongyuan", 1},
  {"daiyan", 2},
  {"xiantu", 2},
}
local benxi = fk.CreateTriggerSkill{
  name = "tycl__benxi",
  anim_type = "switch",
  frequency = Skill.Compulsory,
  switch_skill_name = "tycl__benxi",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    if isYang then
      local sData = table.random(benxiPool)
      player:chat(string.format("$%s:%d", sData[1], sData[2]))
      room:setPlayerMark(player, "@tycl__benxi", sData[1])
    else
      local skill = player:getMark("@tycl__benxi")
      if not Fk.skills[skill] then return end
      if player:hasSkill(skill, true) then
        local targets = table.map(room.alive_players, Util.IdMapper)
        local tgt = room:askForChoosePlayers(player, targets, 1, 1,
          "#tycl__benxi:::" .. skill, self.name, false)[1]
        room:damage{
          from = player,
          to = room:getPlayerById(tgt),
          damage = 1,
          skillName = self.name,
        }
      else
        room:handleAddLoseSkills(player, skill)
        local skills = U.getMark(player, self.name)
        table.insert(skills, skill)
        room:setPlayerMark(player, self.name, skills)
      end
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, table.concat(
      table.map(player:getMark(self.name), function(str)
        return "-" .. str
      end), "|"))
    room:setPlayerMark(player, self.name, 0)
  end,
}
wuyi:addSkill(benxi)
Fk:loadTranslationTable{
  ["tycl__wuyi"] = "名将吴懿",
  ["tycl__benxi"] = "奔袭",
  [":tycl__benxi"] = "锁定技，转换技，当你失去手牌后，阳：随机念一句含有wuyi的技能台词；" ..
    "阴：获得你上次以此法念出台词的技能直到你下回合开始，若已拥有则改为对一名角色造成一点伤害。",
  ["@tycl__benxi"] = "奔袭",
  ["#tycl__benxi"] = "奔袭: 抽到了已经拥有的技能 %arg，改为对一名角色造成一点伤害",
}

local goddianwei = General(extension, "goddianwei", "god", 4)
Fk:loadTranslationTable{
  ["goddianwei"] = "神典韦",
  ["#goddianwei"] = "袒裼暴虎",
  ["~goddianwei"] = "战死沙场，快哉快哉！",
}

local juanjia = fk.CreateTriggerSkill{
  name = "juanjia",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, { Player.ArmorSlot })
    room:addPlayerEquipSlots(player, { Player.WeaponSlot })
  end,
}
Fk:loadTranslationTable{
  ["juanjia"] = "捐甲",
  [":juanjia"] = "锁定技，游戏开始时，你废除防具栏，然后获得一个额外的武器栏。<br>" ..
  "<font color='gray'>注：UI未适配多武器栏，需要等待游戏软件版本更新，请勿反馈显示问题。</font>",

  ["$juanjia1"] = "尚攻者弃守，其提双刃、斩万敌。",
  ["$juanjia2"] = "舍衣释力，提兵趋敌。",
}

goddianwei:addSkill(juanjia)

local getArm = function(room, armName)
  local arm
  for _, id in ipairs(room.void) do
    if Fk:getCardById(id).name == armName then
      room:setCardMark(Fk:getCardById(id), MarkEnum.DestructOutMyEquip, 1)
      arm = id
      break
    end
  end
  if not arm then
    local card = room:printCard(armName, Card.NoSuit, 0)
    room:setCardMark(card, MarkEnum.DestructOutMyEquip, 1)
    arm = card.id
  end
  return arm
end

local qiexie = fk.CreateTriggerSkill{
  name = "qiexie",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Start and
      player:hasEmptyEquipSlot(Card.SubtypeWeapon)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local availableGenerals = room:getTag("qiexieGenerals") or {}
    if #availableGenerals == 0 then
      for _, general in ipairs(room.general_pile) do
        if
          table.find(
            Fk.generals[general]:getSkillNameList(),
            function(skillName)
              local skill = Fk.skills[skillName]
              return
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
            end
          )
        then
          table.insert(availableGenerals, general)
        end
      end

      if #availableGenerals == 0 then
        return false
      end

      room:setTag("qiexieGenerals", availableGenerals)
    end

    availableGenerals = table.filter(
      room:getTag("qiexieGenerals") or {},
      function(general)
        return
          table.contains(room.general_pile, general) and
          not table.contains({ player.general, player.deputyGeneral }, general)
      end
    )

    if #availableGenerals > 0 then
      availableGenerals = table.random(availableGenerals, 5)
      local weaponEmpty = #player:getAvailableEquipSlots(Card.SubtypeWeapon) - #player:getEquipments(Card.SubtypeWeapon)
      local hasLeftArm = table.find(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name == "goddianwei_left_arm" end
      )
      local hasRightArm = table.find(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name == "goddianwei_right_arm" end
      )

      if weaponEmpty < 1 and not (hasLeftArm and hasRightArm) then
        return false
      end

      if hasLeftArm or hasRightArm then
        weaponEmpty = 1
      else
        weaponEmpty = math.min(2, weaponEmpty)
      end

      local result = player.room:askForCustomDialog(
        player,
        self.name,
        "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml",
        {
          availableGenerals,
          {"OK"},
          "#qiexie-choose",
          {},
          1,
          weaponEmpty,
        }
      )

      local names
      if result == "" then
        names = { cards = math.random(availableGenerals) }
      else
        names = json.decode(result).cards
      end

      if #names > 0 then
        for i = 1, #names do
          local generalName = names[i]
          hasLeftArm = table.find(
            player:getCardIds("e"),
            function(id) return Fk:getCardById(id).name == "goddianwei_left_arm" end
          )
          hasRightArm = table.find(
            player:getCardIds("e"),
            function(id) return Fk:getCardById(id).name == "goddianwei_right_arm" end
          )
          if hasLeftArm and hasRightArm then
            break
          elseif hasLeftArm then
            room:setPlayerMark(player, "@qiexie_right", { generalName, Fk.generals[generalName].maxHp })
            table.removeOne(room.general_pile, generalName)
            local skillList = {}
            for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
              local skill = Fk.skills[skillName]
              if
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
              then
                table.insert(skillList, skillName)
              end
            end
            if #skillList > 0 then
              room:setPlayerMark(player, "qiexie_right_skills", skillList)
            end

            local rightArm = getArm(room, "goddianwei_right_arm")
            room:moveCardIntoEquip(player, rightArm, self.name, false)
          else
            room:setPlayerMark(player, "@qiexie_left", { generalName, Fk.generals[generalName].maxHp })
            table.removeOne(room.general_pile, generalName)
            local skillList = {}
            for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
              local skill = Fk.skills[skillName]
              if
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
              then
                table.insert(skillList, skillName)
              end
            end
            if #skillList > 0 then
              room:setPlayerMark(player, "qiexie_left_skills", skillList)
            end

            local leftArm = getArm(room, "goddianwei_left_arm")
            room:moveCardIntoEquip(player, leftArm, self.name, false)
          end
        end
      end
    end
  end,
}
local qiexieFilter = fk.CreateFilterSkill{
  name = "#qiexie_filter",
  equip_skill_filter = function(self, skill, player)
    if player then
      local leftSkills = U.getMark(player, "qiexie_left_skills")
      local rightSkills = U.getMark(player, "qiexie_right_skills")
      if table.contains(leftSkills, skill.name) then
        return "goddianwei_left_arm"
      elseif table.contains(rightSkills, skill.name) then
        return "goddianwei_right_arm"
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["qiexie"] = "挈挟",
  [":qiexie"] = "锁定技，准备阶段开始时，若你有空置的武器栏，则你随机观看武将牌堆中五张武将牌" ..
  "（须带有描述中含有“【杀】”且不具有除锁定技以外标签的技能），将其中至少一张当武器牌置入装备区" ..
  "（称为【左膀】和【右臂】，无花色点数，攻击范围为对应武将牌的体力上限，效果为其符合上述条件的技能，" ..
  "离开你的装备区时销毁）。",
  ["#qiexie-choose"] = "请选择武将牌作为你的装备牌（右键或长按查看技能）",
  ["@qiexie_left"] = "左膀",
  ["@qiexie_right"] = "右臂",

  ["$qiexie1"] = "今挟双戟搏战，定护主公太平。",
  ["$qiexie2"] = "吾乃典韦是也，谁敢向前？谁敢向前！",
}

qiexie:addRelatedSkill(qiexieFilter)
goddianwei:addSkill(qiexie)

local cuijue = fk.CreateActiveSkill{
  name = "cuijue",
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  prompt = "#cuijue",
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) < 20
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)

    local farest = 0
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if player ~= p and player:inMyAttackRange(p) then
        local distance = player:distanceTo(p)
        if distance > farest then
          farest = distance
          targets = { p.id }
        elseif distance == farest then
          table.insert(targets, p.id)
        end
      end
    end

    targets = table.filter(targets, function(pId) return not table.contains(U.getMark(player, "cuijue_targeted-turn"), pId) end)

    if #targets == 0 then
      return
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cuijue-choose", self.name, false)
    local cuijueTargeted = U.getMark(player, "cuijue_targeted-turn")
    table.insertIfNeed(cuijueTargeted, tos[1])
    room:setPlayerMark(player, "cuijue_targeted-turn", cuijueTargeted)
    room:damage{
      from = player,
      to = room:getPlayerById(tos[1]),
      damage = 1,
      skillName = self.name,
    }
  end,
}
Fk:loadTranslationTable{
  ["cuijue"] = "摧决",
  [":cuijue"] = "出牌阶段，你可以弃置一张牌，然后对攻击范围内距离最远且本回合未以此法选择过的一名其他角色造成1点伤害。",
  ["#cuijue"] = "摧决：你可弃置一张牌，然后对攻击范围内距离最远且本回合未指定过的角色造成伤害",
  ["#cuijue-choose"] = "摧决：选择其中一名角色对其造成1点伤害",

  ["$cuijue1"] = "当锋摧决，贯遐洞坚。",
  ["$cuijue2"] = "殒身不恤，死战成仁。",
}

goddianwei:addSkill(cuijue)

local xiaosunquan = General(extension, "child__sunquan", "wu", 3)
Fk:loadTranslationTable{
  ["child__sunquan"] = "小孙权",
  ["#child__sunquan"] = "未知",
  ["~child__sunquan"] = "",
}

local huiwan = fk.CreateTriggerSkill {
  name = "huiwan",
  anim_type = "drawcard",
  events = {fk.BeforeDrawCard},
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(self) and data.num > 0) then
      return false
    end

    local availableNames = table.filter(
      player.room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(U.getMark(player, "huiwan_card_names-turn"), name)
      end
    )

    if #availableNames > 0 then
      return 
        table.find(
          player.room.draw_pile,
          function(id) return table.contains(availableNames, Fk:getCardById(id).trueName) end
        )
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allCardNames = table.filter(
      room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(U.getMark(player, "huiwan_card_names-turn"), name)
      end
    )

    local chioces = {}
    for _, name in ipairs(allCardNames) do
      if table.find(room.draw_pile, function(id) return Fk:getCardById(id).trueName == name end) then
        table.insert(chioces, name)
      end
    end

    local result = room:askForChoices(player, chioces, 1, data.num, self.name, "#huiwan-choice:::" .. data.num)
    if #result > 0 then
      self.cost_data = result
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local namesChosen = table.simpleClone(self.cost_data)
    local cardNamesRecord = U.getMark(player, "huiwan_card_names-turn")
    table.insertTableIfNeed(cardNamesRecord, table.map(namesChosen, function(name) return name end))
    room:setPlayerMark(player, "huiwan_card_names-turn", cardNamesRecord)

    local toDraw = {}
    for i = #room.draw_pile, 1, -1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if table.contains(namesChosen, card.trueName) then
        table.removeOne(namesChosen, card.trueName)
        table.insert(toDraw, card.id)
      end
    end

    if #toDraw > 0 then
      room:obtainCard(player, toDraw, false, fk.ReasonPrey, player.id, self.name)
    end

    data.num = data.num - #toDraw
    return data.num < 1
  end,

  refresh_events = {fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self and not player.room:getTag("huiwanAllCardNames")
  end,
  on_refresh = function(self, event, target, player, data)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(allCardNames, card.trueName)
      end
    end

    player.room:setTag("huiwanAllCardNames", allCardNames)
  end,
}
Fk:loadTranslationTable{
  ["huiwan"] = "会玩",
  [":huiwan"] = "每回合每种牌名限一次，当你摸牌时，你可以选择至多等量牌堆中有的基本牌或普通锦囊牌牌名，然后改为从牌堆中获得你选择的牌。",
  ["#huiwan-choice"] = "会玩：你可选择至多 %arg 个牌名，本次改为摸所选牌名的牌",
}

xiaosunquan:addSkill(huiwan)

local huanli = fk.CreateTriggerSkill {
  name = "huanli",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and player.phase == Player.Finish) then
      return false
    end

    local aimedList = {}
    local canTrigger = false
    player.room.logic:getEventsOfScope(
      GameEvent.UseCard,
      1,
      function(e)
        local targets = TargetGroup:getRealTargets(e.data[1].tos)
        for _, pId in ipairs(targets) do
          aimedList[pId] = (aimedList[pId] or 0) + 1
          canTrigger = canTrigger or aimedList[pId] > 2
        end
        return false
      end,
      Player.HistoryTurn
    )

    if canTrigger then
      self.cost_data = aimedList
      return true
    end

    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local aimedList = self.cost_data
    local usedTimes = 0
    local lastTarget
    if (aimedList[player.id] or 0) > 2 then
      local tos = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player), Util.IdMapper),
        1,
        1,
        "#huanli_zhangzhao-choose",
        self.name
      )

      if #tos > 0 then
        usedTimes = usedTimes + 1
        lastTarget = tos[1]

        local to = room:getPlayerById(tos[1])
        local zhangzhao = table.filter({ "zhijian", "guzheng" }, function(skill) return not to:hasSkill(skill, true, true) end)
        local skillsExist = U.getMark(to, "@@huanli")
        table.insertTableIfNeed(skillsExist, zhangzhao)
        room:setPlayerMark(to, "@@huanli", skillsExist)

        if #zhangzhao > 0 then
          room:handleAddLoseSkills(to, table.concat(zhangzhao, "|"))
        end
      end
    end

    local availableTargets = {}
    for pId, num in pairs(aimedList) do
      if pId ~= player.id and pId ~= lastTarget and num > 2 then
        table.insert(availableTargets, pId)
      end
    end

    if #availableTargets == 0 then
      return false
    end

    local tos = room:askForChoosePlayers(player, availableTargets, 1, 1, "#huanli_zhouyu-choose", self.name)
    if #tos > 0 then
      usedTimes = usedTimes + 1
      local to = room:getPlayerById(tos[1])
      local zhouyu = table.filter({ "ex__yingzi", "ex__fanjian" }, function(skill) return not to:hasSkill(skill, true, true) end)
      local skillsExist = U.getMark(to, "@@huanli")
      table.insertTableIfNeed(skillsExist, zhouyu)
      room:setPlayerMark(to, "@@huanli", skillsExist)

      if #zhouyu > 0 then
        room:handleAddLoseSkills(to, table.concat(zhouyu, "|"))
      end
    end

    if usedTimes > 1 and not player:hasSkill("ex__zhiheng") then
      room:setPlayerMark(player, "huanli_sunquan-turn", 1)
      player.tag["huanli_sunquan"] = true
      room:handleAddLoseSkills(player, "ex__zhiheng")
    end
  end,
}
local huanliLose = fk.CreateTriggerSkill {
  name = "#huanli_lose",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (
        player:getMark("@@huanli") ~= 0 or
        (player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"])
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@huanli") ~= 0 then
      local huanliSkills = table.simpleClone(U.getMark(player, "@@huanli"))
      room:setPlayerMark(player, "@@huanli", 0)
      if #huanliSkills > 0 then
        room:handleAddLoseSkills(player, table.concat(table.map(huanliSkills, function(skill) return "-" .. skill end), "|"))
      end
    end

    if player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"] then
      player.tag["huanli_sunquan"] = nil
      room:handleAddLoseSkills(player, "-ex__zhiheng")
    end
  end,
}
local huanliNullify = fk.CreateInvaliditySkill {
  name = "#huanli_nullify",
  invalidity_func = function(self, from, skill)
    return
      from:getMark("@@huanli") ~= 0 and
      not table.contains(U.getMark(from, "@@huanli"), skill.name) and
      skill:isPlayerSkill(from)
  end
}
Fk:loadTranslationTable{
  ["huanli"] = "唤理",
  [":huanli"] = "结束阶段开始时，若你于本回合内使用牌指定自己为目标至少三次，你可以令一名其他角色所有技能失效（因本技能而获得的技能除外），" ..
  "且其获得“直谏”和“固政”直到其下回合结束。若你于本回合内使用牌指定同一名其他角色为目标至少三次，你可选择这些角色中的一名（不能选择前者选择的角色），" ..
  "令其所有技能失效（因本技能而获得的技能除外），且其获得“英姿”和“反间”直到其下回合结束。若你两项均执行，则你获得“制衡”直到你下回合结束。",
  ["@@huanli"] = "唤理",
  ["#huanli_lose"] = "唤理",
  ["#huanli_zhangzhao-choose"] = "唤理：你可令一名其他角色技能失效且获得“直谏”“固政”直到其下回合结束",
  ["#huanli_zhouyu-choose"] = "唤理：你可令其中一名角色技能失效且获得“英姿”“反间”直到其下回合结束",
}

huanli:addRelatedSkill(huanliLose)
huanli:addRelatedSkill(huanliNullify)
xiaosunquan:addSkill(huanli)

return extension
