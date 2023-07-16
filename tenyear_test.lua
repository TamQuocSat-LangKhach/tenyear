local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

--嵇康 曹不兴

Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，你使用牌时，若弃牌堆中的红色牌数量多于黑色牌，你回复1点体力；"..
  "黑色牌数量多于红色牌，你可以弃置一名其他角色区域内的一张牌；牌数较少的颜色与你使用牌的颜色相同，你获得一个“灵”标记。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "限定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌时，根据此牌的失去方式执行以下效果：使用-此牌不能被响应；打出-摸一张牌；弃置-回复1点体力；其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合发动〖踏寂〗时随机额外执行一种效果。",
}

local sunhuan = General(extension, "sunhuan", "wu", 4)
local niji = fk.CreateTriggerSkill{
  name = "niji",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.type ~= Card.TypeEquip
    elseif event == fk.EventPhaseStart then
      return target.phase == Player.Finish and not player:isKongcheng() and
        table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player.room:askForSkillInvoke(player, self.name, nil, "#niji-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      local id = player:drawCards(1, self.name)[1]
      if room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand then
        room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 1)
      end
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
      if player:hasSkill(self.name) and #cards >= player.hp then
        local pattern = "^(jink,nullification)|.|.|.|.|.|"..table.concat(cards, ",")
        local use = room:askForUseCard(player, "", pattern, "#niji-use", true)
        if use then
          room:useCard(use)
        end
      end
      if not player.dead then
        cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand") > 0 end)
        room:throwCard(cards, self.name, player, player)
      end
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@niji-inhand", 0)
    end
  end,
}
sunhuan:addSkill(niji)
Fk:loadTranslationTable{
  ["sunhuan"] = "孙桓",
  ["niji"] = "逆击",
  [":niji"] = "当你成为非装备牌的目标后，你可以摸一张牌，本回合结束阶段弃置这些牌。若将要弃置的牌数不小于你的体力值，你可以先使用其中一张牌。",
  ["@@niji-inhand"] = "逆击",
  ["#niji-invoke"] = "逆击：你可以摸一张牌，本回合结束阶段弃置之",
  ["#niji-use"] = "逆击：即将弃置所有“逆击”牌，你可以先使用其中一张牌",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("moyu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target ~= Self and target:getMark("moyu-turn") == 0 and not target:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    room:addPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-use::"..player.id..":"..player:usedSkillTimes(self.name), true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      use.additionalDamage = (use.additionalDamage or 0) + player:usedSkillTimes(self.name) - 1
      use.card.extra_data = use.card.extra_data or {}
      table.insert(use.card.extra_data, self.name)
      room:useCard(use)
    end
  end,
}
local moyu_record = fk.CreateTriggerSkill{
  name = "#moyu_record",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.extra_data and table.contains(data.card.extra_data, "moyu")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "moyu-turn", 1)
  end,
}
moyu:addRelatedSkill(moyu_record)
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以对你使用一张无距离限制且伤害值为X的【杀】"..
  "（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-use"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target:getMark("@@xinzhong") > 0 then
      if #target.player_cards[Player.Hand] <= 3 then
        target:throwAllCards("h")
      else
        room:askForDiscard(target, 3, 3, false, self.name, false, ".", "#jizhong-discard2")
      end
    else
      if #target.player_cards[Player.Hand] < 3 then
        room:setPlayerMark(target, "@@xinzhong", 1)
      else
        local cards = room:askForDiscard(target, 3, 3, false, self.name, true, ".", "#jizhong-discard1")
        if #cards == 0 then
          room:setPlayerMark(target, "@@xinzhong", 1)
        end
      end
    end
  end,
}
local jucheng = fk.CreateTriggerSkill{
  name = "jucheng",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          return room:askForSkillInvoke(player, self.name, data, "#jucheng-use")
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#jucheng-get")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local guangshi = fk.CreateTriggerSkill{
  name = "guangshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start and
      table.every(player.room:getOtherPlayers(player), function (p)
        return p:getMark("@@xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(jucheng)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其不是“信众”，则其选择一项：1.成为“信众”；"..
  "2.弃置三张手牌；若其是“信众”，则其弃置三张手牌（不足则全弃）。",
  ["jucheng"] = "聚逞",
  [":jucheng"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你失去1点体力并摸两张牌。",
  ["@@xinzhong"] = "信众",
  ["#jizhong-discard1"] = "集众：你需弃置三张手牌，否则成为“信众”",
  ["#jizhong-discard2"] = "集众：你需弃置三张手牌",
  ["#jucheng-use"] = "聚逞：你可以令所有“信众”视为对其使用此牌",
  ["#jucheng-get"] = "聚逞：你可以获得其区域内一张牌",
}

local dongwan = General(extension, "dongwan", "qun", 3, 3, General.Female)
local shengdu = fk.CreateTriggerSkill{
  name = "shengdu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#shengdu-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local n = target:getMark(self.name)
    player.room:setPlayerMark(target, self.name, 0)
    for i = 1, n, 1 do
      player:drawCards(data.n, self.name)  --yes! do n times!
    end
  end,
}
local xianjiao = fk.CreateActiveSkill{
  name = "xianjiao",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
      else
        return false
      end
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("slash", effect.cards, player, target, self.name, false)
  end,
}
local xianjiao_record = fk.CreateTriggerSkill{
  name = "#xianjiao_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "xianjiao")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xianjiao")
    else
      local room = player.room
      for _, p in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local to = room:getPlayerById(p)
        if data.card.extra_data and table.contains(data.card.extra_data, "xianjiao") then
          room:loseHp(to, 1, self.name)
        else
          room:addPlayerMark(to, "shengdu", 1)
        end
      end
    end
  end,
}
xianjiao:addRelatedSkill(xianjiao_record)
dongwan:addSkill(shengdu)
dongwan:addSkill(xianjiao)
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名其他角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
  ["xianjiao"] = "献绞",
  [":xianjiao"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。"..
  "若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
}

--袁胤 高翔

--桓范 孟优 陈泰 孙綝 孙瑜 郤正 乐綝 张曼成
Fk:loadTranslationTable{
  ["huanfan"] = "桓范",
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。"..
  "若你未获得或未使用，则横置你与其武将牌，然后其观看你的手牌。",
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到1点伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。"..
  "（X为你已损失的体力值）",
}

Fk:loadTranslationTable{
  ["sunchen"] = "孙綝",
  ["zigu"] = "自固",
  [":zigu"] = "出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。",
  ["zuowei"] = "作威",
  [":zuowei"] = "当你于回合内使用牌时，若你当前手牌数：大于X，你可以令此牌不可响应；等于X，你可以对一名其他角色造成1点伤害；小于X，"..
  "你可以摸两张牌并令本回合此技能失效。（X为你装备区内的牌数且至少为1）",
}

Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数小于其体力上限，你可以令其选择一项：1.将手牌摸至体力上限（至多摸五张），然后"..
  "本回合出牌阶段使用【杀】次数上限-1；2.本回合使用的牌被抵消后你摸一张牌。",
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上回合的角色出牌阶段使用的最后一张基本牌或普通锦囊牌使用；"..
  "出牌阶段结束时，你可以令下回合的角色于其出牌阶段开始时可以将一张牌当你本阶段使用的最后一张基本牌或普通锦囊牌使用。",
}

Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌完全相同，你可以摸X张牌（X为此牌目标数）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同且均与你不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无次数限制。",
}

Fk:loadTranslationTable{
  ["yuechen"] = "乐綝",
  ["porui"] = "破锐",
  [":porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张基本牌并选择一名此回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，"..
  "然后你交给其X张手牌（X为你的体力值，不足则全给）。",
  ["gonghu"] = "共护",
  [":gonghu"] = "锁定技，当你于回合外失去基本牌后，〖破锐〗最后增加描述“若其没有因此受到伤害，你回复1点体力”；当你于回合外造成或受到伤害后，"..
  "你删除〖破锐〗中交给牌的效果。若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",
}

local zhangmancheng = General(extension, "ty__zhangmancheng", "qun", 4)
local lvecheng = fk.CreateActiveSkill{
  name = "lvecheng",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@lvecheng-turn", player.id)
  end,
}
local lvecheng_targetmod = fk.CreateTargetModSkill{
  name = "#lvecheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return to:getMark("@@lvecheng-turn") ~= 0 and to:getMark("@@lvecheng-turn") == player.id and
      card.trueName == "slash" and scope == Player.HistoryPhase
  end,
}
local lvecheng_trigger = fk.CreateTriggerSkill{
  name = "#lvecheng_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@lvecheng-turn") ~= 0 and player:getMark("@@lvecheng-turn") == target.id and
      target.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("lvecheng")
    room:notifySkillInvoked(target, "lvecheng", "negative")
    room:doIndicate(player.id, {target.id})
    player:showCards(player.player_cards[Player.Hand])
    while table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == "slash" end)
      and not player.dead and not target.dead do
      local use = room:askForUseCard(player, "slash", "slash|.|.|hand", "#lvecheng-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
      if use then
        room:useCard(use)
      else
        break
      end
    end
  end,
}
local zhongji = fk.CreateTriggerSkill{
  name = "zhongji",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:getHandcardNum() < player.maxHp then
      return player:isKongcheng() or
        not table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).suit == data.card.suit end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#zhongji-invoke:::"..(player.maxHp - player:getHandcardNum())..":"..player:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,
}
lvecheng:addRelatedSkill(lvecheng_targetmod)
lvecheng:addRelatedSkill(lvecheng_trigger)
zhangmancheng:addSkill(lvecheng)
zhangmancheng:addSkill(zhongji)
Fk:loadTranslationTable{
  ["ty__zhangmancheng"] = "张曼成",
  ["lvecheng"] = "掠城",
  [":lvecheng"] = "出牌阶段限一次，你可以指定一名其他角色，本回合你对其使用【杀】无次数限制。若如此做，此回合结束阶段，其展示手牌：若其中有【杀】，"..
  "其可以依次对你使用手牌中所有的【杀】。",
  ["zhongji"] = "螽集",
  [":zhongji"] = "当你使用牌时，若你没有该花色的手牌，你可将手牌摸至体力上限并弃置X张牌（X为本回合发动此技能的次数）。",
  ["@@lvecheng-turn"] = "掠城",
  ["#lvecheng-slash"] = "掠城：你可以依次对 %dest 使用手牌中所有【杀】！",
  ["#zhongji-invoke"] = "螽集：你可以摸%arg张牌，然后弃置%arg2张牌",
}

-- 城孙权

Fk:loadTranslationTable{
  ["ty__duyu"] = "杜预",
  ["jianguo"] = "谏国",
  [":jianguo"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向下取整）；"..
  "令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）",
  ["qingshid"] = "倾势",
  [":qingshid"] = "当你于回合内使用【杀】或锦囊牌指定其他角色为目标后，若此牌是你本回合使用的第X张牌，你可以对其中一名目标角色造成1点伤害（X为你的手牌数）",
}

local ganfurenmifuren = General(extension, "ganfurenmifuren", "shu", 3, 3, General.Female)
local chanjuan = fk.CreateTriggerSkill{
  name = "chanjuan",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and
      (player:getMark("@$chanjuan") == 0 or not table.contains(player:getMark("@$chanjuan"), data.card.trueName))
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, {data.card.name, TargetGroup:getRealTargets(data.tos)[1]})
    self:doCost(event, target, player, data)
    room:setPlayerMark(player, self.name, 0)
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "chanjuan_viewas",
      "#chanjuan-invoke::"..TargetGroup:getRealTargets(data.tos)[1]..":"..data.card.name, true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(player:getMark(self.name)[1])
    local mark = player:getMark("@$chanjuan")
    if mark == 0 then mark = {} end
    table.insert(mark, card.trueName)
    room:setPlayerMark(player, "@$chanjuan", mark)
    if #self.cost_data.targets == 1 and player:getMark(self.name) ~= 0 and self.cost_data.targets[1] == player:getMark(self.name)[2] then
      player:drawCards(1, self.name)
    end
    room:useCard{
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
    }
  end,
}
local chanjuan_viewas = fk.CreateViewAsSkill{
  name = "chanjuan_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if Self:getMark("chanjuan") == 0 then return end
    local card = Fk:cloneCard(Self:getMark("chanjuan")[1])
    card.skillName = "chanjuan"
    return card
  end,
}
local chanjuan_targetmod = fk.CreateTargetModSkill{
  name = "#chanjuan_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "chanjuan")
  end,
}
local xunbie = fk.CreateTriggerSkill{
  name = "xunbie",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = {}
    if not table.find(room.alive_players, function(p) return p.general == "ty__ganfuren" end) then
      table.insert(generals, "ty__ganfuren")
    end
    if not table.find(room.alive_players, function(p) return p.general == "ty__mifuren" end) then
      table.insert(generals, "ty__mifuren")
    end
    if #generals == 0 then
      generals = {"ganfuren"}  --策划就没想过两个都有的情况吗？
    end
    local general = room:askForGeneral(player, generals, 1)
    room:changeHero(player, general, false, false, true)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
  end,
}
local xunbie_trigger = fk.CreateTriggerSkill{
  name = "#xunbie_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("xunbie", Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("xunbie")
    room:notifySkillInvoked(player, "xunbie")
    return true
  end,
}
chanjuan_viewas:addRelatedSkill(chanjuan_targetmod)
Fk:addSkill(chanjuan_viewas)
xunbie:addRelatedSkill(xunbie_trigger)
ganfurenmifuren:addSkill(chanjuan)
ganfurenmifuren:addSkill(xunbie)
Fk:loadTranslationTable{
  ["ganfurenmifuren"] = "甘夫人糜夫人",
  ["chanjuan"] = "婵娟",
  [":chanjuan"] = "你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。每种牌名限一次。",
  ["xunbie"] = "殉别",
  [":xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。",
  ["@$chanjuan"] = "婵娟",
  ["#chanjuan-invoke"] = "婵娟：你可以视为使用【%arg】，若目标为 %dest ，你摸一张牌",
  ["chanjuan_viewas"] = "婵娟",
  ["@@xunbie-turn"] = "殉别",
}

return extension
