local extension = Package("tenyear_ex")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_ex"] = "十周年-界限突破",
   ["ty_ex"] = "新服界",
}

local caozhi = General(extension, "ty_ex__caozhi", "wei", 3)
local ty_ex__jiushi = fk.CreateViewAsSkill{
  name = "ty_ex__jiushi",
  anim_type = "support",
  pattern = "analeptic",
  card_filter = function(self, to_select, selected)
    return false
  end,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, cards)
    if not Self.faceup then return end
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
}
local ty_ex__jiushi_record = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.ty_ex__jiushi
  end,
  on_trigger = function(self, event, target, player, data)
    data.ty_ex__jiushi = false
    self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.ty_ex__jiushi = true
  end,
}
local ty_ex__jiushi_buff = fk.CreateTriggerSkill{
  name = "#ty_ex__jiushi_buff",
  mute = true,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__jiushi") and data.card.name == "analeptic"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex_jiushi_buff",1)
  end,

  refresh_events ={fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_ex_jiushi_buff") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex_jiushi_buff", 0)
  end,
}
local jiushi_targetmod = fk.CreateTargetModSkill{
  name = "#jiushi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("ty_ex__jiushi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@ty_ex_jiushi_buff")
    end
  end,
}
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_record)
ty_ex__jiushi:addRelatedSkill(ty_ex__jiushi_buff)
ty_ex__jiushi:addRelatedSkill(jiushi_targetmod)
caozhi:addSkill("luoying")
caozhi:addSkill(ty_ex__jiushi)
Fk:loadTranslationTable{
  ["ty_ex__caozhi"] = "界曹植",
  ["ty_ex__jiushi"] = "酒诗",
  [":ty_ex__jiushi"] = "①若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。②当你的武将牌背面朝上，你受到伤害时，"..
  "你可在伤害结算后翻面。③当你使用【酒】时，你令你使用【杀】次数上限+1，直到你的下个回合结束。",
  ["#ty_ex__jiushi_record"] = "酒诗",
  ["@ty_ex_jiushi_buff"] = "酒诗",
  ["$ty_ex__jiushi1"] = "暂无",
  ["$ty_ex__jiushi2"] = "暂无",
  ["~ty_ex__caozhi"] = "暂无",
}

local zhangchunhua = General(extension, "ty_ex__zhangchunhua", "wei", 3, 3, General.Female)
local ty_ex__jueqing_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__jueqing_trigger",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not data.chain
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jueqing-invoke::"..data.to.id..":"..data.damage..":"..data.damage)
  end,
  on_use = function(self, event, target, player, data)
     player.room:loseHp(player, data.damage, self.name)
    data.damage = data.damage * 2
  end,
}
local ty_ex__jueqing = fk.CreateTriggerSkill{
  name = "ty_ex__jueqing",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes("#ty_ex__jueqing_trigger", Player.HistoryGame) >0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local ty_ex__shangshi_discard = fk.CreateTriggerSkill{
  name = "#ty_ex__shangshi_discard",
  anim_type = "negative",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill("ty_ex__shangshi") and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#shangshi-invoke")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
  end,
}
local ty_ex__shangshi = fk.CreateTriggerSkill{
  name = "ty_ex__shangshi",
  anim_type = "drawcard",
  events = {fk.HpChanged, fk.MaxHpChanged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getHandcardNum() < player:getLostHp() then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          return move.from == player.id
        end
      else
        return target == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), self.name)
  end,
}
ty_ex__jueqing:addRelatedSkill(ty_ex__jueqing_trigger)
ty_ex__shangshi:addRelatedSkill(ty_ex__shangshi_discard)
zhangchunhua:addSkill(ty_ex__jueqing)
zhangchunhua:addSkill(ty_ex__shangshi)
Fk:loadTranslationTable{
  ["ty_ex__zhangchunhua"] = "界张春华",
  ["ty_ex__jueqing"] = "绝情",
  ["#ty_ex__jueqing_trigger"] = "绝情",
  [":ty_ex__jueqing"] = "①每局限一次，当你造成伤害时，你可以失去同于伤害值点体力令此伤害翻倍。②锁定技，若你已发动过绝情①，你造成的伤害均视为体力流失。",
  ["ty_ex__shangshi"] = "伤逝",
  ["#ty_ex__shangshi_discard"] = "伤逝",
  [":ty_ex__shangshi"] = "①当你受到伤害时，你可以弃置一张手牌；②每当你的手牌数小于你已损失的体力值时，可立即将手牌数补至等同于你已损失的体力值。",
  ["#shangshi-invoke"] = "伤逝:是否弃置一张手牌？",
  ["#jueqing-invoke"] = "绝情:是否令即将对%dest造成的%arg点伤害翻倍？然后你失去%arg2点体力",
  
  ["$ty_ex__jueqing1"] = "不知情之所起，亦不知情之所终。",
  ["$ty_ex__jueqing2"] = "唯有情字最伤人！",
  ["$ty_ex__shangshi1"] = "半生韶华随流水，思君不见撷落花。",
  ["$ty_ex__shangshi2"] = "西风知我意，送我三尺秋。",
  ["~ty_ex__zhangchunhua"] = "仲达负我！",
}

local masu = General(extension, "ty_ex__masu", "shu", 3)
local ty_ex__sanyao = fk.CreateActiveSkill{
  name = "ty_ex__sanyao",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#ty_ex__sanyao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return true
  end,
  target_filter = function(self, to_select, selected, selected_cards)  --FIXME：需要feasible
    if #selected < #selected_cards then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return table.every(Fk:currentRoom().alive_players, function(p) return p.hp <= target.hp end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end
}
local ty_ex__zhiman = fk.CreateTriggerSkill{
  name = "ty_ex__zhiman",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__zhiman-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    if not data.to:isAllNude() then
      local card = room:askForCardChosen(player, data.to, "hej", self.name)
      room:obtainCard(player.id, card, true, fk.ReasonPrey)
    end
    return true
  end
}
masu:addSkill(ty_ex__sanyao)
masu:addSkill(ty_ex__zhiman)
Fk:loadTranslationTable{
  ["ty_ex__masu"] = "界马谡",
  ["ty_ex__sanyao"] = "散谣",
  [":ty_ex__sanyao"] = "出牌阶段限一次，你可以弃置任意张牌，然后对体力值最多的等量名其他角色造成1点伤害",
  ["ty_ex__zhiman"] = "制蛮",
  [":ty_ex__zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，然后获得其区域内一张牌。",
  ["#ty_ex__sanyao"] = "散谣：弃置任意张牌，对等量名体力值最多的其他角色各造成1点伤害",
  ["#ty_ex__zhiman-invoke"] = "制蛮：你可以防止对 %dest 造成的伤害，然后获得其区域内的一张牌",
}

local lingtong = General(extension, "ty_ex__lingtong", "wu", 4)
local ty_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ty_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      else
        return target == player and player.phase == Player.Discard and player:getMark("ty_ex__xuanfeng-phase") > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.every(player.room:getOtherPlayers(player), function (p) return p:isNude() end) then return end
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetsx = {}
    for i = 1, 2, 1 do
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), function (p) return p.id end)
      if #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__xuanfeng-choose", self.name, true)
        if #tos > 0 then
          room:doIndicate(player.id, tos)
          local card = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
          room:throwCard({card}, self.name, room:getPlayerById(tos[1]), player)
           if player.phase ~= Player.NotActive then
               table.insert(targetsx, tos[1])
           end
        end
      end
    end
    if #targetsx > 0 then
      local tos = room:askForChoosePlayers(player, targetsx, 1, 1, "#ty_ex__xuanfeng-damage", self.name, true)
      if #tos > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(tos[1]),
          damage = 1,
           skillName = self.name,
        }
      end
    else return end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "ty_ex__xuanfeng-phase", #move.moveInfo)
      end
    end
  end,
}
local ex__yongjin = fk.CreateActiveSkill{
  name = "ex__yongjin",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  card_filter = function()
    return false
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i = 1, 3, 1 do
      if #room:canMoveCardInBoard() == 0 or player.dead then break end
      local to = room:askForChooseToMoveCardInBoard(player, "#ex__yongjin-choose", self.name, true, "e")
      if #to == 2 then
        room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name, "e")
      else
        break
      end
    end
  end,
}
lingtong:addSkill(ty_ex__xuanfeng)
lingtong:addSkill(ex__yongjin)
Fk:loadTranslationTable{
  ["ty_ex__lingtong"] = "界凌统",
  ["ty_ex__xuanfeng"] = "旋风",
  [":ty_ex__xuanfeng"] = "当你失去装备区里的牌，或于弃牌阶段弃掉两张或更多的牌时，你可以依次弃置一至两名角色的共计两张牌。"..
  "若此时是你的回合内，则你可以对其中一名角色造成1点伤害。",
  ["#ty_ex__xuanfeng-choose"] = "旋风：你可以依次弃置一至两名角色的共计两张牌",
  ["#ty_ex__xuanfeng-damage"] = "旋风：你可以对其中一名角色造成一点伤害。",
  ["ex__yongjin"] = "勇进",
  [":ex__yongjin"] = "限定技，出牌阶段，你可以依次移动场上至多三张装备牌。",
  ["#ex__yongjin-choose"] = "勇进：你可以移动场上的一张装备牌",
  ["$ty_ex__xuanfeng1"] = "风动扬帆起，枪出敌军溃！",
  ["$ty_ex__xuanfeng2"] = "御风而动，敌军四散！",
  ["$ex__yongjin1"] = "鏖兵卫主，勇足以却敌！",
  ["$ex__yongjin2"] = "勇不可挡，进则无退！",
  ["~ty_ex__lingtong"] = "泉下弟兄，统来也！",
}

local wuguotai = General(extension, "ty_ex__wuguotai", "wu", 3, 3, General.Female)
local ty_ex__ganlu = fk.CreateActiveSkill{
  name = "ty_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      if #target1.player_cards[Player.Equip] == 0 and #target2.player_cards[Player.Equip] == 0 then
        return false
      end
      return true
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local target1 = Fk:currentRoom():getPlayerById(effect.tos[1])
    local target2 = Fk:currentRoom():getPlayerById(effect.tos[2])
    local cards1 = table.clone(target1.player_cards[Player.Equip])
    local cards2 = table.clone(target2.player_cards[Player.Equip])
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[1],
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[2],
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    moveInfos = {}

    if not target2.dead then
      local to_ex_cards1 = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing and target2:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards1 > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards1,
          fromArea = Card.Processing,
          to = effect.tos[2],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if not target1.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing and target1:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = effect.tos[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    table.insertTable(cards1, cards2)

    local dis_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dis_cards)
      room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
     local player =room:getPlayerById(effect.from)
    if math.abs(#target1.player_cards[Player.Equip] - #target2.player_cards[Player.Equip]) > player:getLostHp() then
      if player:getHandcardNum() > 2 then
        room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#ty_ex__ganlu-discard")
      else
        player:throwAllCards("h")
      end
    end
  end,
}
local ty_ex__buyi = fk.CreateTriggerSkill{
  name = "ty_ex__buyi",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__buyi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #target.player_cards[Player.Hand] == 1 then
      self.cost_numer = true
    end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      room:throwCard({id}, self.name, target, target)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
      if self.cost_numer ~= nil then
        target:drawCards(1, self.name)
      end
    end
  end,
}
wuguotai:addSkill(ty_ex__ganlu)
wuguotai:addSkill(ty_ex__buyi)
Fk:loadTranslationTable{
  ["ty_ex__wuguotai"] = "界吴国太",
  ["ty_ex__ganlu"] = "甘露",
  [":ty_ex__ganlu"] = "出牌阶段限一次，你可以选择两名角色，交换他们装备区里的所有牌，然后若他们装备区的差大于X，你需弃置两张手牌（X为你已损失体力值）。",
  ["ty_ex__buyi"] = "补益",
  [":ty_ex__buyi"] = "当有角色进入濒死状态时，你可以展示该角色的一张手牌：若此牌不为基本牌，则其弃置此牌并回复1点体力，"..
  "然后若此牌移动前是其唯一的手牌，其摸一张牌。",
  ["#ty_ex__buyi-invoke"] = "补益：你可以展示 %dest 一张手牌，若为非基本牌则弃置并回复1点体力，若弃置前为唯一手牌则其摸一张牌。",
  ["#ty_ex__ganlu-discard"] ="甘露: 请弃置两张手牌",
  ["$ty_ex__ganlu1"] = "男婚女嫁，须当交换文定之物。",
  ["$ty_ex__ganlu2"] = "此真乃吾之佳婿也。",
  ["$ty_ex__buyi1"] = "吾乃吴国之母，何人敢放肆？",
  ["$ty_ex__buyi2"] = "有老身在，汝等尽可放心。",
  ["~ty_ex__wuguotai"] = "卿等，务必用心辅佐仲谋……",
}

local chengong = General(extension, "ty_ex__chengong", "qun", 3)
local ty_ex__mingce = fk.CreateActiveSkill{
  name = "ty_ex__mingce",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).trueName == "slash" or Fk:getCardById(to_select).type == Card.TypeEquip)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty_ex__mingce-choose::"..target.id, self.name, false)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
      local choice = room:askForChoice(target, {"ty_ex__mingce_slash", "draw1"}, self.name)
      if choice == "ty_ex__mingce_slash" then
        local use = {
          from = target.id,
          tos = {{to}},
          card = Fk:cloneCard("slash"),
          skillName = self.name,
          extraUse = true,
        }
        room:useCard(use)
        if use.damageDealt then
          if not player.dead then
            player:drawCards(1, self.name)
          end
          if not target.dead then
            target:drawCards(1, self.name)
          end
        end
      else
        player:drawCards(1, self.name)
        target:drawCards(1, self.name)
      end
    end
  end,
}

chengong:addSkill(ty_ex__mingce)
chengong:addSkill("zhichi")
Fk:loadTranslationTable{
  ["ty_ex__chengong"] = "界陈宫",
  ["ty_ex__mingce"] = "明策",
  [":ty_ex__mingce"] = "出牌阶段限一次，你可以交给一名其他角色一张装备牌或【杀】，其选择一项：1.视为对其攻击范围内的另一名由你指定的角色使用【杀】，"..
  "若此【杀】造成伤害则执行选项2；2.你与其各摸一张牌。",
  ["#ty_ex__mingce-choose"] = "明策：选择 %dest 视为使用【杀】的目标",
  ["ty_ex__mingce_slash"] = "视为使用【杀】",
  ["$mingce1"] = "暂无",
  ["$mingce2"] = "暂无",
  ["~ty_ex__chengong"] = "暂无",
}

local wangyi = General(extension, "ty_ex__wangyi", "wei", 4, 4, General.Female)
wangyi:addSkill("zhenlie")
wangyi:addSkill("miji")
Fk:loadTranslationTable{
  ["ty_ex__wangyi"] = "界王异",
}

local liaohua = General(extension, "ty_ex__liaohua", "shu", 4)
local ty_ex__dangxian = fk.CreateTriggerSkill{
  name = "ty_ex__dangxian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseChanging then
        return data.to == Player.Start
      else
        return player.phase == Player.Play and player:getMark("ty_ex__dangxian-phase") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "ty_ex__dangxian-phase", 1)
      player:gainAnExtraPhase(Player.Play)
    else
      room:setPlayerMark(player, "ty_ex__dangxian-phase", 0)
      if player:getMark("ty_ex__fuli") == 0 or room:askForSkillInvoke(player, self.name, nil, "#ty_ex__dangxian-invoke") then
        --为了加强关索，不用技能次数判断
        room:loseHp(player, 1, self.name)
        if not player.dead then
          local cards = room:getCardsFromPileByRule("slash", 1, "discardPile")
          if #cards > 0 then
            room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
          end
        end
      end
    end
  end,
}
local ty_ex__fuli = fk.CreateTriggerSkill{
  name = "ty_ex__fuli",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 1)
    local kingdoms = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if player:getHandcardNum() < #kingdoms then
      player:drawCards(#kingdoms - player:getHandcardNum())
    end
    if #kingdoms > 2 then
      player:turnOver()
    end
  end,
}
liaohua:addSkill(ty_ex__dangxian)
liaohua:addSkill(ty_ex__fuli)
Fk:loadTranslationTable{
  ["ty_ex__liaohua"] = "界廖化",
  ["ty_ex__dangxian"] = "当先",
  [":ty_ex__dangxian"] = "锁定技，回合开始时，你执行一个额外的出牌阶段，此阶段开始时你失去1点体力并从弃牌堆获得一张【杀】。",
  ["ty_ex__fuli"] = "伏枥",
  [":ty_ex__fuli"] = "限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数），然后〖当先〗中失去体力的效果改为可选。"..
  "若X不小于3，你翻面。",
  ["#ty_ex__dangxian-invoke"] = "当先：你可以失去1点体力，从弃牌堆获得一张【杀】",
}

local guanxingzhangbao = General(extension, "ty_ex__guanxingzhangbao", "shu", 4)
local ty_ex__tongxin = fk.CreateAttackRangeSkill{
  name = "ty_ex__tongxin",
  correct_func = function (self, from, to)
    if from:hasSkill(self.name) then
      return 2
    else
      return 0
    end
  end,
}
guanxingzhangbao:addSkill("fuhun")
guanxingzhangbao:addSkill(ty_ex__tongxin)
Fk:loadTranslationTable{
  ["ty_ex__guanxingzhangbao"] = "界关兴张苞",
  ["ty_ex__tongxin"] = "同心",
  [":ty_ex__tongxin"] = "锁定技，你的攻击范围+2。",
}

local chengpu = General(extension, "ty_ex__chengpu", "wu", 4)
local ty_ex__lihuo = fk.CreateTriggerSkill{
  name = "ty_ex__lihuo",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared, fk.TargetSpecifying, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.AfterCardUseDeclared then
        return data.card.name == "slash"
      elseif event == fk.TargetSpecifying then
        return data.card.name == "fire__slash"
      else
        return data.card.trueName == "slash" and data.extra_data and data.extra_data.ty_ex__lihuo == 1 and
          player.room:getCardArea(data.card) == Card.Processing
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__lihuo1-invoke:::"..data.card:toLogString())
    elseif event == fk.TargetSpecifying then
      local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
        return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
        data.card.skill:getDistanceLimit(p, data.card) + player:getAttackRange() >= player:distanceTo(p) and
        not player:isProhibited(p, data.card) end), function(p) return p.id end)
      if #targets == 0 then return false end
      local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#lihuo-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__lihuo2-invoke:::"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local card = Fk:cloneCard("fire__slash")
      card.skillName = self.name
      card:addSubcard(data.card)
      data.card = card
    elseif event == fk.TargetSpecifying then
      table.insert(data.tos, self.cost_data)
    else
      player:addToPile("ty_ex__chengpu_chun", data.card, true, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "ty_ex__lihuo-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__lihuo = player:getMark("ty_ex__lihuo-turn")
  end,
}
local ty_ex__lihuo_record = fk.CreateTriggerSkill{
  name = "#ty_ex__lihuo_record",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty_ex__lihuo") and data.damageDealt
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ty_ex__lihuo", 1)
    room:notifySkillInvoked(player, "ty_ex__lihuo", "negative")
    room:loseHp(player, 1, "ty_ex__lihuo")
  end,
}
local ty_ex__chunlao = fk.CreateTriggerSkill{
  name = "ty_ex__chunlao",
  anim_type = "support",
  expand_pile = "ty_ex__chengpu_chun",
  events = {fk.EventPhaseEnd, fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseEnd then
        return target == player and player.phase == Player.Play and #player:getPile("ty_ex__chengpu_chun") == 0 and not player:isKongcheng()
      else
        return target.dying and #player:getPile("ty_ex__chengpu_chun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if event == fk.EventPhaseEnd then
      cards = room:askForCard(player, 1, #player.player_cards[Player.Hand], false, self.name, true, "slash", "#ty_ex__chunlao-cost")
    else
      cards = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|ty_ex__chengpu_chun|.|.",
        "#ty_ex__chunlao-invoke::"..target.id, "ty_ex__chengpu_chun")
    end
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      player:addToPile("ty_ex__chengpu_chun", self.cost_data, true, self.name)
    else
      room:moveCards({
        from = player.id,
        ids = self.cost_data,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      room:useCard({
        card = Fk:cloneCard("analeptic"),
        from = target.id,
        tos = {{target.id}},
        extra_data = {analepticRecover = true},
        skillName = self.name,
      })
      if player.dead then return end
      if Fk:getCardById(self.cost_data[1]).name == "fire__slash" then
        if player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif Fk:getCardById(self.cost_data[1]).name == "thunder__slash" then
        player:drawCards(2, self.name)
      end
    end
  end,
}
ty_ex__lihuo:addRelatedSkill(ty_ex__lihuo_record)
chengpu:addSkill(ty_ex__lihuo)
chengpu:addSkill(ty_ex__chunlao)
Fk:loadTranslationTable{
  ["ty_ex__chengpu"] = "界程普",
  ["ty_ex__lihuo"] = "疬火",
  [":ty_ex__lihuo"] = "你使用普通【杀】可以改为火【杀】，结算后若此法使用的【杀】造成了伤害，你失去1点体力；你使用火【杀】时，可以增加一个目标。"..
  "你于一个回合内使用的第一张牌结算后，若此牌为【杀】，你可以将之置为“醇”。",
  ["ty_ex__chunlao"] = "醇醪",
  [":ty_ex__chunlao"] = "出牌阶段结束时，若你没有“醇”，你可以将任意张【杀】置为“醇”；当一名角色处于濒死状态时，"..
  "你可以将一张“醇”置入弃牌堆，视为该角色使用一张【酒】；若你此法置入弃牌堆的是：火【杀】，你回复1点体力；雷【杀】，你摸两张牌。",
  ["#ty_ex__lihuo1-invoke"] = "疬火：是否将%arg改为火【杀】？",
  ["#ty_ex__lihuo2-invoke"] = "疬火：你可以将%arg置为“醇”",
  ["ty_ex__chengpu_chun"] = "醇",
  ["#ty_ex__chunlao-cost"] = "醇醪：你可以将任意张【杀】置为“醇”",
  ["#ty_ex__chunlao-invoke"] = "醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",
  ["#ty_ex__lihuo_record"] = "疬火（失去体力）",
}

local zhonghui = General(extension, "ty_ex__zhonghui", "wei", 4)
local ty_ex__quanji = fk.CreateTriggerSkill{
  name = "ty_ex__quanji",
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              self:doCost(event, target, player, data)
            end
          end
        end
      end
    elseif event == fk.Damaged and player:hasSkill(self.name) and target == player then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost then break end
       self:doCost(event, target, player, data)
      end
    else
      return false
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not player:isKongcheng() then
      local card = room:askForCard(player, 1, 1, false, self.name, false)
      player:addToPile("zhonghui_quan", card, false, self.name)
    end
  end,
}
local ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return #player:getPile("zhonghui_quan")
    else
      return 0
    end
  end,
}
local ty_ex__zili = fk.CreateTriggerSkill{
  name = "ty_ex__zili",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    player:drawCards(2, self.name)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "ty_ex__paiyi", nil, true, false)
  end,
}
local ty_ex__paiyi = fk.CreateActiveSkill{
  name = "ty_ex__paiyi",
  anim_type = "control",
  expand_pile = "zhonghui_quan",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(self)
    return self.interaction.data == "ty_ex__paiyi_draw" and 1 or #Self:getPile("zhonghui_quan") - 1
  end,
  interaction = function(self)
    local choiceList = {}
    if Self:getMark("ty_ex__paiyi_draw-phase") == 0 then
      table.insert(choiceList, "ty_ex__paiyi_draw")
    end
    if Self:getMark("ty_ex__paiyi_damage-phase") == 0 then 
      table.insert(choiceList, "ty_ex__paiyi_damage")
    end
    return UI.ComboBox { choices = choiceList }
  end,
  target_filter = function(self, to_select, selected)
    return self.interaction.data == "ty_ex__paiyi_draw" and #selected == 0 or #selected < #Self:getPile("zhonghui_quan")-1
  end,
  can_use = function(self, player)
    return #player:getPile("zhonghui_quan") > 0 and
      (player:getMark("ty_ex__paiyi_draw-phase") == 0 or player:getMark("ty_ex__paiyi_damage-phase") == 0)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "zhonghui_quan"
  end,
  on_use = function(self, room, effect)
      local player = room:getPlayerById(effect.from)
      local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    player:removeCards(Player.Special, effect.cards, self.name)
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    if self.interaction.data == "ty_ex__paiyi_draw" then
     target:drawCards(math.max(#player:getPile("zhonghui_quan"),1), self.name)
    else
      for _, id in ipairs(effect.tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name
          }
        end
      end
    end
  end,
}

ty_ex__quanji:addRelatedSkill(ex__quanji_maxcards)
zhonghui:addSkill(ty_ex__quanji)
zhonghui:addSkill(ty_ex__zili)
zhonghui:addRelatedSkill(ty_ex__paiyi)
Fk:loadTranslationTable{
  ["ty_ex__zhonghui"] = "界钟会",
  ["ty_ex__quanji"] = "权计",
  [":ty_ex__quanji"] = "每当你的牌被其他角色获得或受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。",
  ["ty_ex__zili"] = "自立",
  [":ty_ex__zili"] = "觉醒技，回合开始阶段开始时，若“权”的数量达到3或更多，你须减1点体力上限，然后回复1点体力并摸两张牌，并获得技能〖排异〗。",
  ["ty_ex__paiyi"] = "排异",
  [":ty_ex__paiyi"] = "出牌阶段每项各限一次，你可移去一张“权”并选择一项：①令一名角色摸X张牌。②对至多X名角色各造成1点伤害。（X为“权”数且至少为1）",
  ["ty_ex__paiyi_draw"] = "摸牌",
  ["ty_ex__paiyi_damage"] = "伤害",
}

local guanping = General(extension, "ty_ex__guanping", "shu", 4)
local ty_ex__longyin = fk.CreateTriggerSkill{
  name = "ty_ex__longyin",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty_ex__longyin-invoke::"..target.id) 
     if #cards > 0 then
        self.cost_data = cards
        return true
     end
  end,
  on_use = function(self, event, target, player, data)
    target:addCardUseHistory(data.card.trueName, -1)
    if data.card.color == Card.Red then
      player:drawCards(1, self.name)
    end
     if data.card.number == Fk:getCardById(self.cost_data[1]).number and player:usedSkillTimes("ty_ex__jiezhong", Player.HistoryGame) > 0 then
       player:setSkillUseHistory("ty_ex__jiezhong", 0, Player.HistoryGame)
     end
  end,
}
local ty_ex__jiezhong = fk.CreateTriggerSkill{
  name = "ty_ex__jiezhong",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      math.min(player.maxHp, 5) > player:getHandcardNum() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local draw = math.min(player.maxHp, 5) - player:getHandcardNum()
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__jiezhong-invoke:::"..draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    player:drawCards(n, self.name)
  end,
}
guanping:addSkill(ty_ex__longyin)
guanping:addSkill(ty_ex__jiezhong)
Fk:loadTranslationTable{
  ["ty_ex__guanping"] = "界关平",
  ["ty_ex__longyin"] = "龙吟",
  [":ty_ex__longyin"] = "每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。"..
  "若你以此法弃置的牌点数与此【杀】相同，你重置〖竭忠〗。",
  ["#ty_ex__longyin-invoke"] = "龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制",
  ["ty_ex__jiezhong"] = "竭忠",
  [":ty_ex__jiezhong"] = "限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限（至多为5）。",
  ["#ty_ex__jiezhong-invoke"] = "竭忠：是否发动“竭忠”摸%arg张牌？ ",
}

local huangyueying = General(extension, "ty_ex__huangyueying", "qun", 3, 3, General.Female)
local ty__jiqiao = fk.CreateTriggerSkill{
  name = "ty__jiqiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#ty__jiqiao-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return end
    local n = 0
    for _, id in ipairs(self.cost_data) do
      if Fk:getCardById(id).type == Card.TypeEquip then
        n = n + 2
      else
        n = n + 1
      end
    end
    local cards = room:getNCards(n)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeEquip then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #get > 0 then
      room:delay(1000)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #cards > 0 then
      room:delay(1000)
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local ty__linglong = fk.CreateTriggerSkill{
  name = "ty__linglong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every({Card.SubtypeArmor, Card.SubtypeOffensiveRide, Card.SubtypeDefensiveRide, Card.SubtypeTreasure}, function(type)
        return player:getEquipment(type) == nil end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, function(p) return p.id end)
  end,

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
          if move.to == player.id and move.toArea == Player.Equip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)  --FIXME: 虚拟装备技能应该用statusSkill而非triggerSkill
    if player:getEquipment(Card.SubtypeArmor) == nil and not player:hasSkill("#eight_diagram_skill", true) then  --FIXME: 青釭剑的装备无效mark对技能无效
      player.room:handleAddLoseSkills(player, "#eight_diagram_skill", self, false, true)
    elseif player:getEquipment(Card.SubtypeArmor) ~= nil and player:hasSkill("#eight_diagram_skill", true) then
      player.room:handleAddLoseSkills(player, "-#eight_diagram_skill", nil, false, true)
    end
    if player:getEquipment(Card.SubtypeTreasure) == nil and not player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "qicai", self, false, true)
    elseif player:getEquipment(Card.SubtypeTreasure) ~= nil and player:hasSkill("qicai", true) then
      player.room:handleAddLoseSkills(player, "-qicai", nil, false, true)
    end
  end,
}
local ty__linglong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty__linglong_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("ty__linglong") and
      player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 2
    end
    return 0
  end,
}
ty__linglong:addRelatedSkill(ty__linglong_maxcards)
huangyueying:addSkill(ty__jiqiao)
huangyueying:addSkill(ty__linglong)
huangyueying:addRelatedSkill("qicai")
Fk:loadTranslationTable{
  ["ty_ex__huangyueying"] = "界黄月英",
  ["ty__jiqiao"] = "机巧",
  [":ty__jiqiao"] = "出牌阶段开始时，你可以弃置任意张牌，然后你亮出牌堆顶等量的牌，你弃置的牌中每有一张装备牌，则多亮出一张牌。然后你获得其中的非装备牌。",
  ["ty__linglong"] = "玲珑",
  [":ty__linglong"] = "锁定技，若你的装备区里没有防具牌，你视为装备【八卦阵】；若你的装备区里没有坐骑牌，你的手牌上限+2；"..
  "若你的装备区里没有宝物牌，你视为拥有〖奇才〗。若均满足，你使用的【杀】和普通锦囊牌不能被响应。",
  ["#ty__jiqiao-invoke"] = "机巧：你可以弃置任意张牌，亮出牌堆顶等量牌（每有一张装备牌额外亮出一张），获得非装备牌",
  
  ["$ty__jiqiao1"] = "机关将作之术，在乎手巧心灵。",
  ["$ty__jiqiao2"] = "机巧藏于心，亦如君之容。",
  ["$ty__linglong1"] = "我夫所赠之玫，遗香自长存。",
  ["$ty__linglong2"] = "心有玲珑罩，不殇春与秋。",
  ["~ty_ex__huangyueying"] = "此心欲留夏，奈何秋风起……",
}
return extension
