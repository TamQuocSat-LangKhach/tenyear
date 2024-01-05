local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年-限定专属2",
}

--计将安出：程昱 王允 蒋干 赵昂 刘晔 杨弘 郤正 桓范 刘琦
local ty__chengyu = General(extension, "ty__chengyu", "wei", 3)
local ty__shefu = fk.CreateTriggerSkill{
  name = "ty__shefu",
  anim_type = "control",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isNude()
      else
        return target ~= player and player.phase == Player.NotActive and data.card.type ~= Card.TypeEquip and U.IsUsingHandcard(target, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#ty__shefu-cost")
      if #cards > 0 then
        self.cost_data = cards[1]
        return true
      end
    else
      local index
      local mark = U.getMark(player, self.name)
      for i = 1, #mark, 1 do
        if data.card.trueName == mark[i][2] then
          index = i
          break
        end
      end
      if index and room:askForSkillInvoke(player, self.name, nil, "#ty__shefu-invoke::"..target.id..":"..data.card.name) then
        self.cost_data = index
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:addToPile(self.name, self.cost_data, false, self.name)
      local names = {}
      local mark = U.getMark(player, self.name)
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type ~= Card.TypeEquip then
          table.insertIfNeed(names, card.trueName)
        end
      end
      for _, v in ipairs(mark) do
        table.removeOne(names, v[2])
      end
      if #names > 0 then
        local name = room:askForChoice(player, names, self.name)
        table.insert(mark, {self.cost_data, name})
        room:setPlayerMark(player, self.name, mark)
      end
    else
      local index = self.cost_data
      local mark = U.getMark(player, self.name)
      local throw = mark[index][1]
      table.remove(mark, index)
      room:setPlayerMark(player, self.name, mark)
      if target.phase ~= Player.NotActive then
        room:setPlayerMark(target, "@@ty__shefu-turn", 1)
      end
      room:moveCards({
        from = player.id,
        ids = {throw},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = self.name, arg2 = data.card:toLogString() }
    end
  end,
}
local ty__shefu_invalidity = fk.CreateInvaliditySkill {
  name = "#ty__shefu_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@ty__shefu-turn") > 0 and not skill.attached_equip and not skill.name:endsWith("&")
  end
}
ty__shefu:addRelatedSkill(ty__shefu_invalidity)
ty__chengyu:addSkill(ty__shefu)
local ty__benyu = fk.CreateTriggerSkill{
  name = "ty__benyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if #player:getCardIds("he") > data.from:getHandcardNum() then
      local num = data.from:getHandcardNum() + 1
      local discard = room:askForDiscard(player, num, 9999, true, self.name, true, ".", "#ty__benyu-discard::"..data.from.id..":"..num,true)
      if #discard >= num then
        self.cost_data = {"discard", discard}
        return true
      end
    end
    local x = math.min(data.from:getHandcardNum(), 5)
    if player:getHandcardNum() < x and room:askForSkillInvoke(player, self.name, nil, "#ty__benyu-draw:::"..x) then
      self.cost_data = {"draw"}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data[1] == "discard" then
      player.room:throwCard(self.cost_data[2], self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
}
ty__chengyu:addSkill(ty__benyu)
Fk:loadTranslationTable{
  ["ty__chengyu"] = "程昱",
  ["ty__shefu"] = "设伏",
  [":ty__shefu"] = "①结束阶段，你可以记录一个未被记录的基本牌或锦囊牌的牌名并扣置一张牌，称为“伏兵”；<br>"..
  "②当其他角色于你回合外使用手牌时，你可以移去一张记录牌名相同的“伏兵”，令此牌无效（若此牌有目标角色则改为取消所有目标），然后若此时是该角色的回合内，其本回合所有技能失效。",
  ["ty__benyu"] = "贲育",
  [":ty__benyu"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至X张（最多摸至5张）；2.弃置至少X+1张牌，然后对伤害来源造成1点伤害（X为伤害来源的手牌数）。",
  ["#ty__shefu-cost"] = "设伏：你可以将一张牌扣置为“伏兵”",
  ["#ty__benyu-discard"] = "贲育：你可以弃置至少%arg牌，对 %dest 造成1点伤害",
  ["#ty__benyu-draw"] = "贲育：你可以摸至 %arg 张牌",
  ["@@ty__shefu-turn"] = "设伏封技",
  ["#ty__shefu-invoke"] = "设伏：可以令 %dest 使用的 %arg 无效",
  ["#CardNullifiedBySkill"] = "由于 %arg 的效果，%from 使用的 %arg2 无效",

  ["$ty__shefu1"] = "吾已埋下伏兵，敌兵一来，管教他瓮中捉鳖。",
  ["$ty__shefu2"] = "我已设下重重圈套，就等敌军入彀矣。",
  ["$ty__benyu1"] = "助曹公者昌，逆曹公者亡！",
  ["$ty__benyu2"] = "愚民不可共济大事，必当与智者为伍。",
  ["~ty__chengyu"] = "吾命休矣，何以仰报圣恩于万一……",
}

local wangyun = General(extension, "ty__wangyun", "qun", 4)
local ty__lianji = fk.CreateActiveSkill{
  name = "ty__lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt= "#ty__lianji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.sub_type == Card.SubtypeWeapon then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        for _, id in ipairs(Fk:getAllCardIds()) do
          if Fk:getCardById(id).name == "seven_stars_sword" then
            card = Fk:getCardById(id)
            room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
            break
          end
        end
      end
      if not target:isProhibited(target, card) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead then return end
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    local use = room:askForUseCard(target, "slash", "slash", "#ty__lianji-slash:"..player.id, true, {exclusive_targets = targets})
    if use then
      room:setPlayerMark(player, "ty__lianji1", 1)
      use.extraUse = true
      room:useCard(use)
      if not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        local to = table.filter(TargetGroup:getRealTargets(use.tos), function(id) return not room:getPlayerById(id).dead end)
        if #to == 0 then return end
        if #to > 1 then
          to = room:askForChoosePlayers(target, to, 1, 1, "#ty__lianji-give", self.name, false)
        end
        to = room:getPlayerById(to[1])
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, target.id)
      end
    else
      room:setPlayerMark(player, "ty__lianji2", 1)
      room:useVirtualCard("slash", nil, player, target, self.name, true)
      if not player.dead and not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, target.id)
      end
    end
  end,
}
local ty__moucheng = fk.CreateTriggerSkill{
  name = "ty__moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("ty__lianji1") > 0 and player:getMark("ty__lianji2") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty__lianji|jingong", nil, true, false)
  end,
}
wangyun:addSkill(ty__lianji)
wangyun:addSkill(ty__moucheng)
wangyun:addRelatedSkill("jingong")
Fk:loadTranslationTable{
  ["ty__wangyun"] = "王允",
  ["ty__lianji"] = "连计",
  [":ty__lianji"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色，令其使用牌堆中的一张武器牌。然后该角色选择一项：1.对除你以外的一名角色"..
  "使用一张【杀】，并将武器牌交给其中一名目标角色；2.视为你对其使用一张【杀】，并将武器牌交给你。",
  ["ty__moucheng"] = "谋逞",
  [":ty__moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗的两个选项都被选择过，则你失去〖连计〗，获得〖矜功〗。",
  ["#ty__lianji"] = "连计：弃置一张手牌，令一名角色使用牌堆中的一张武器牌并使用【杀】",
  ["#ty__lianji-slash"] = "连计：你需使用一张【杀】，否则 %src 视为对你使用【杀】",
  ["#ty__lianji-give"] = "连计：你需将武器交给其中一名目标角色",

  ["$ty__lianji1"] = "连环相扣，周密不失。",
  ["$ty__lianji2"] = "切记，此计连不可断。",
  ["$ty__moucheng1"] = "除贼安国，利于天下。",
  ["$ty__moucheng2"] = "董贼已擒，长安可兴。",
  ["$jingong_ty__wangyun1"] = "得民称赞，此功当邀。",
  ["$jingong_ty__wangyun2"] = "吾能擒董贼，又何惧怕？",
  ["~ty__wangyun"] = "奉先，你居然弃我而逃！",
}

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getHandcardNum() >= player.hp then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    room:doBroadcastNotify("ShowToast", Fk:translate("#daoshu_chose") .. Fk:translate(choice))
    local card = room:askForCardChosen(player, target, "h", self.name)
    room:obtainCard(player, card, true, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString(true) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      local suit = Fk:getCardById(card):getSuitString(true)
      table.removeOne(suits, suit)
      suits = table.map(suits, function(s) return s:sub(5) end)
      local others = table.filter(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id):getSuitString(true) ~= suit end)
      if #others > 0 then
        local cards = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..table.concat(suits, ","),
          "#daoshu-give::"..target.id..":"..suit)
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
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得其一张手牌。若此牌与你选择的花色："..
  "相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给其一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#daoshu_chose"] = "蒋干盗书选择了",
  ["#daoshu-give"] = "盗书：交给 %dest 一张非%arg手牌",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
  ["$daoshu1"] = "得此文书，丞相定可高枕无忧。",
  ["$daoshu2"] = "让我看看，这是什么机密。",
  ["~jianggan"] = "丞相，再给我一次机会啊！",
}

local zhaoang = General(extension, "zhaoang", "wei", 3, 4)
local zhongjie = fk.CreateTriggerSkill{
  name = "zhongjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    not data.damage and not target.dead and target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#zhongjie-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local sushou = fk.CreateTriggerSkill{
  name = "sushou",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and player.hp > 0 and not target.dead and
    table.every(player.room.alive_players, function (p)
      return p == target or p:getHandcardNum() < target:getHandcardNum()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#sushou-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, x, self.name)
    end
    if player == target then return false end
    local cards = target:getCardIds(Player.Hand)
    if #cards < 2 then return false end
    cards = table.random(cards, #cards // 2)
    local handcards = player:getCardIds(Player.Hand)
    cards = U.askForExchange(player, "needhand", "wordhand", cards, handcards, "#sushou-exchange::"..target.id .. ":" .. tostring(x), x)
    if #cards == 0 then return false end
    handcards = table.filter(cards, function (id)
      return table.contains(handcards, id)
    end)
    cards = table.filter(cards, function (id)
      return not table.contains(handcards, id)
    end)
    U.swapCards(room, player, player, target, handcards, cards, self.name)
  end,
}

zhaoang:addSkill(zhongjie)
zhaoang:addSkill(sushou)

Fk:loadTranslationTable{
  ["zhaoang"] = "赵昂",
  ["zhongjie"] = "忠节",
  [":zhongjie"] = "每轮限一次，当一名角色因失去体力而进入濒死状态时，你可以令其回复1点体力并摸一张牌。",
  ["sushou"] = "夙守",
  [":sushou"] = "一名角色的出牌阶段开始时，若其手牌数是全场唯一最多的，你可以失去1点体力并摸X张牌。"..
  "若此时不是你的回合内，你观看当前回合角色一半数量的手牌（向下取整），你可以用至多X张手牌替换其中等量的牌。（X为你已损失的体力值）",

  ["#zhongjie-invoke"] = "你可以对%dest发动 忠节，令其回复1点体力并摸一张牌",
  ["#sushou-invoke"] = "你可以对%dest发动 夙守",
  ["#sushou-exchange"] = "夙守：选择要交换你与%dest的至多%arg张手牌",

  ["$zhongjie1"] = "气节之士，不可不救。",
  ["$zhongjie2"] = "志士遭祸，应施以援手。",
  ["$sushou1"] = "敌众我寡，怎可少谋？",
  ["$sushou2"] = "临城据守，当出奇计。",
  ["~zhaoang"] = "援军为何迟迟不至？",
}

local liuye = General(extension, "ty__liuye", "wei", 3)
local poyuan_catapult = {{"ty__catapult", Card.Diamond, 9}}
local poyuan = fk.CreateTriggerSkill{
  name = "poyuan",
  anim_type = "control",
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (event == fk.GameStart or (event == fk.TurnStart and target == player)) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
        return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, poyuan_catapult, "poyuan_catapult"), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and U.canMoveCardIntoEquip(player, catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#poyuan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#poyuan-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local to = room:getPlayerById(self.cost_data)
      local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, poyuan_catapult, "poyuan_catapult"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        U.moveCardIntoEquip (room, player, catapult, self.name, true, player)
      end
    end
  end,
}
local huace = fk.CreateViewAsSkill{
  name = "huace",
  interaction = function()
    local names = {}
    local mark = Self:getMark("huace2")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card:isCommonTrick() and card.trueName ~= "nullification" and card.name ~= "adaptation" and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local huace_record = fk.CreateTriggerSkill{
  name = "#huace_record",

  refresh_events = {fk.AfterCardUseDeclared, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.AfterCardUseDeclared and data.card:isCommonTrick()) or event == fk.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getMark("huace1")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.trueName)
      room:setPlayerMark(player, "huace1", mark)
    else
      room:setPlayerMark(player, "huace2", player:getMark("huace1"))
      room:setPlayerMark(player, "huace1", 0)
    end
  end,
}
huace:addRelatedSkill(huace_record)
liuye:addSkill(poyuan)
liuye:addSkill(huace)
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br>"..
  "<font color='grey'>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制，"..
  "使用的【酒】使【杀】伤害基数值增加的效果+1。你回合外使用或打出基本牌时摸一张牌。离开你装备区时销毁。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",
  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",

  ["$poyuan1"] = "砲石飞空，坚垣难存。",
  ["$poyuan2"] = "声若霹雳，人马俱摧。",
  ["$huace1"] = "筹画所料，无有不中。",
  ["$huace2"] = "献策破敌，所谋皆应。",
  ["~ty__liuye"] = "功名富贵，到头来，不过黄土一抔……",
}

local yanghong = General(extension, "yanghong", "qun", 3)
local function IsNext(from, to)
  if from.dead or to.dead then return false end
  if from.next == to then return true end
  local temp = table.simpleClone(from.next)
  while true do
    if temp.dead then
      temp = temp.next
    else
      return temp == to
    end
  end
end
local ty__jianji = fk.CreateActiveSkill{
  name = "ty__jianji",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if not target:isNude() and #selected < Self:getAttackRange() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          if IsNext(target, Fk:currentRoom():getPlayerById(id)) or IsNext(Fk:currentRoom():getPlayerById(id), target) then
            return true
          end
        end
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    for _, id in ipairs(effect.tos) do
      room:askForDiscard(room:getPlayerById(id), 1, 1, true, self.name, false, ".")
    end
    if #effect.tos < 2 then return end
    local n = 0
    for _, id in ipairs(effect.tos) do
      local num = #room:getPlayerById(id).player_cards[Player.Hand]
      if num > n then
        n = num
      end
    end
    local src = table.filter(effect.tos, function(id) return #room:getPlayerById(id).player_cards[Player.Hand] == n end)
    src = room:getPlayerById(table.random(src))
    table.removeOne(effect.tos, src.id)
    local targets = table.filter(effect.tos, function(id) return not src:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(src, effect.tos, 1, 1, "#ty__jianji-choose", self.name, true)
    if #to > 0 then
      room:useVirtualCard("slash", nil, src, room:getPlayerById(to[1]), self.name, true)
    end
  end,
}
local yuanmo = fk.CreateTriggerSkill{
  name = "yuanmo",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askForChoice(player, {"yuanmo_add", "yuanmo_minus"}, self.name)
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#yuanmo-choose", self.name, true)
        if #tos > 0 then
          for _, id in ipairs(tos) do
            room:doIndicate(player.id, {id})
            local card = room:askForCardChosen(player, room:getPlayerById(id), "he", self.name)
            room:obtainCard(player.id, card, false, fk.ReasonPrey)
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local yuanmo_attackrange = fk.CreateAttackRangeSkill{
  name = "#yuanmo_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
}
yuanmo:addRelatedSkill(yuanmo_attackrange)
yanghong:addSkill(ty__jianji)
yanghong:addSkill(yuanmo)
Fk:loadTranslationTable{
  ["yanghong"] = "杨弘",
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后其中手牌最多的角色可以视为对其中另一名角色使用【杀】。",
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",
  ["#ty__jianji-choose"] = "间计：你可以视为对其中一名角色使用【杀】",
  ["#yuanmo1-invoke"]= "远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌",
  ["#yuanmo2-invoke"]= "远谟：你可以令攻击范围+1",
  ["@yuanmo"] = "远谟",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得任意名角色各一张牌",

  ["$ty__jianji1"] = "备枭雄也，布虓虎也，当间之。",
  ["$ty__jianji2"] = "二虎和则我亡，二虎斗则我兴。",
  ["$yuanmo1"] = "强敌不可战，弱敌不可恕。",
  ["$yuanmo2"] = "孙伯符羽翼已丰，主公当图刘备。",
  ["~yanghong"] = "主公为何不听我一言？",
}

local xizheng = General(extension, "xizheng", "shu", 3)
local danyi = fk.CreateTriggerSkill{
  name = "danyi",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget then
      local room = player.room
      local targets = AimGroup:getAllTargets(data.tos)
      local use_event = room.logic:getCurrentEvent()
      local last_tos = {}
      U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        if e.id < use_event.id then
          local use = e.data[1]
          if use.from == player.id then
            last_tos = TargetGroup:getRealTargets(use.tos)
            return true
          end
        end
      end, 0)
      if #last_tos == 0 then return false end
      local x = #table.filter(room.alive_players, function (p)
        return table.contains(targets, p.id) and table.contains(last_tos, p.id)
      end)
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,
}
local wencan = fk.CreateActiveSkill{
  name = "wencan",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#wencan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select).hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if not room:askForUseActiveSkill(p, "wencan_active", "#wencan-discard:"..player.id, true) then
          room:setPlayerMark(p, "@@wencan-turn", 1)
        end
      end
    end
  end,
}
local wencan_active = fk.CreateActiveSkill{
  name = "wencan_active",
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if not Self:prohibitDiscard(card) and card.suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return card.suit ~= Fk:getCardById(selected[1]).suit
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, "wencan", player, player)
  end,
}
local wencan_targetmod = fk.CreateTargetModSkill{
  name = "#wencan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and
    to and to:getMark("@@wencan-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and to and to:getMark("@@wencan-turn") > 0
  end,
}
Fk:addSkill(wencan_active)
wencan:addRelatedSkill(wencan_targetmod)
xizheng:addSkill(danyi)
xizheng:addSkill(wencan)
Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌有相同的目标，你可以摸X张牌（X为这些目标的数量）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无距离和次数限制。",
  ["#wencan"] = "文灿：选择至多两名体力值不同的角色，其弃牌或你对其使用牌无限制",
  ["@@wencan-turn"] = "文灿",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无限制",

  ["$danyi1"] = "满城锦绣，何及笔下春秋？",
  ["$danyi2"] = "一心向学，不闻窗外风雨。",
  ["$wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
  ["$wencan2"] = "众星灿于九天，犹雅文耀于万世。",
  ["~xizheng"] = "此生有涯，奈何学海无涯……",
}

local huanfan = General(extension, "huanfan", "wei", 3)
local jianzheng = fk.CreateActiveSkill{
  name = "jianzheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local availableCards = table.filter(cards, function(id)
      local card = Fk:getCardById(id)
      return not player:prohibitUse(card) and player:canUse(card)
    end)
    local get, _ = U.askforChooseCardsAndChoice(player, availableCards, {"OK"}, self.name, "#jianzheng-choose", {"Cancel"}, 1, 1, cards)
    local yes = false
    if #get > 0 then
      local id = get[1]
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
      if not player.dead and table.contains(player:getCardIds("h"), id) then
        local card = Fk:getCardById(id)
        local use = U.askForUseRealCard(room, player, {id}, ".", self.name, "#jianzheng-use:::"..card:toLogString())
        if use then
          if table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
            yes = true
          end
        end
      end
    end
    if yes then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
      if not player.dead and not target.dead and not player:isKongcheng() then
        U.viewCards(target, player:getCardIds("h"), self.name)
      end
    end
  end,
}
local fumou = fk.CreateTriggerSkill{
  name = "fumou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#fumou-choose:::"..player:getLostHp(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = {}
        if #room:canMoveCardInBoard() > 0 then
          table.insert(choices, "fumou1")
        end
        if not p:isKongcheng() then
          table.insert(choices, "fumou2")
        end
        if #p:getCardIds("e") > 0 then
          table.insert(choices, "fumou3")
        end
        if #choices == 0 then
          --continue
        else
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "fumou1" then
            local targets = room:askForChooseToMoveCardInBoard(p, "#fumou-move", self.name, false)
            room:askForMoveCardInBoard(p, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
          elseif choice == "fumou2" then
            p:throwAllCards("h")
            if not p.dead then
              p:drawCards(2, self.name)
            end
          elseif choice == "fumou3" then
            p:throwAllCards("e")
            if p:isWounded() then
              room:recover({
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name
              })
            end
          end
        end
      end
    end
  end,
}
huanfan:addSkill(jianzheng)
huanfan:addSkill(fumou)
Fk:loadTranslationTable{
  ["huanfan"] = "桓范",
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。"..
  "若此牌指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。",
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。"..
  "（X为你已损失的体力值）",
  ["#jianzheng-choose"] = "谏诤：选择一张使用",
  ["#jianzheng-use"] = "谏诤：你可以使用%arg",
  ["#fumou-choose"] = "腹谋：你可以令至多%arg名角色依次选择执行一项",
  ["fumou1"] = "移动场上一张牌",
  ["fumou2"] = "弃置所有手牌，摸两张牌",
  ["fumou3"] = "弃置所有装备，回复1点体力",
  ["#fumou-move"] = "腹谋：请选择要移动装备的角色",

  ["$jianzheng1"] = "将军今出洛阳，恐难再回。",
  ["$jianzheng2"] = "贼示弱于外，必包藏祸心。",
  ["$fumou1"] = "某有良谋，可为将军所用。",
  ["$fumou2"] = "吾负十斗之囊，其盈一石之智。",
  ["~huanfan"] = "有良言而不用，君何愚哉……",
}

local ty__liuqi = General(extension, "ty__liuqi", "qun", 3)
ty__liuqi.subkingdom = "shu"
local ty__wenji = fk.CreateTriggerSkill{
  name = "ty__wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, "#ty__wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ty__wenji-give::"..player.id)
    local mark = U.getMark(player, "@ty__wenji-turn")
    table.insertIfNeed(mark, Fk:getCardById(card[1]):getTypeString().."_char")
    room:setPlayerMark(player, "@ty__wenji-turn", mark)
    room:obtainCard(player, card[1], false, fk.ReasonGive)
  end,
}
local ty__wenji_record = fk.CreateTriggerSkill{
  name = "#ty__wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local mark = U.getMark(player, "@ty__wenji-turn")
      return table.contains(mark, data.card:getTypeString().."_char")
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local ty__tunjiang = fk.CreateTriggerSkill{
  name = "ty__tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local used = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        if in_play then
          local use = e.data[1]
          if use.from == target.id and use.tos then
            if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
              return true
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return #used == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,
}
ty__wenji:addRelatedSkill(ty__wenji_record)
ty__liuqi:addSkill(ty__wenji)
ty__liuqi:addSkill(ty__tunjiang)
Fk:loadTranslationTable{
  ["ty__liuqi"] = "刘琦",
  ["ty__wenji"] = "问计",
  [":ty__wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌类别相同的牌不能被其他角色响应。",
  ["ty__tunjiang"] = "屯江",
  [":ty__tunjiang"] = "结束阶段，若你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#ty__wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#ty__wenji-give"] = "问计：你需交给 %dest 一张牌",
  ["@ty__wenji-turn"] = "问计",

  ["$ty__wenji1"] = "琦，愿听先生教诲。",
  ["$ty__wenji2"] = "先生，此计可有破解之法？",
  ["$ty__tunjiang1"] = "这浑水，不蹚也罢。",
  ["$ty__tunjiang2"] = "荆州风云波澜动，唯守江夏避险峻。",
  ["~ty__liuqi"] = "这荆州，终究容不下我。",
}

--笔舌如椽：陈琳 杨修 骆统 王昶 程秉 杨彪 阮籍
local ty__chenlin = General(extension, "ty__chenlin", "wei", 3)
local ty__songci = fk.CreateActiveSkill{
  name = "ty__songci",
  anim_type = "control",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local mark = U.getMark(player, self.name)
    return table.find(Fk:currentRoom().alive_players, function(p) return not table.contains(mark, p.id) end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local mark = U.getMark(Self, self.name)
    return #selected == 0 and not table.contains(mark, to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local mark = U.getMark(player, self.name)
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if #target.player_cards[Player.Hand] <= target.hp then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name, 1)
      target:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name, 2)
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,
}
local ty__songci_trigger = fk.CreateTriggerSkill{
  name = "#ty__songci_trigger",
  mute = true,
  main_skill = ty__songci,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    local mark = U.getMark(player, "ty__songci")
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
    and table.every(player.room.alive_players, function (p) return table.contains(mark, p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ty__songci", "drawcard")
    player:broadcastSkillInvoke("ty__songci", 3)
    player:drawCards(1, "ty__songci")
  end,
}
ty__chenlin:addSkill("bifa")
ty__songci:addRelatedSkill(ty__songci_trigger)
ty__chenlin:addSkill(ty__songci)
Fk:loadTranslationTable{
  ["ty__chenlin"] = "陈琳",
  ["ty__songci"] = "颂词",
  [":ty__songci"] = "①出牌阶段，你可以选择一名角色（每名角色每局游戏限一次），若该角色的手牌数：不大于体力值，其摸两张牌；大于体力值，其弃置两张牌。②弃牌阶段结束时，若你对所有存活角色均发动过“颂词”，你摸一张牌。",
  ["#ty__songci_trigger"] = "颂词",

  ["$ty__songci1"] = "将军德才兼备，大汉之栋梁也！",
  ["$ty__songci2"] = "汝窃国奸贼，人人得而诛之！",
  ["$ty__songci3"] = "义军盟主，众望所归！",
  ["~ty__chenlin"] = "来人……我的笔呢……",
}

local yangxiu = General(extension, "ty__yangxiu", "wei", 3)
local ty__danlao = fk.CreateTriggerSkill{
  name = "ty__danlao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__danlao-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local ty__jilei = fk.CreateTriggerSkill{
  name = "ty__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__jilei-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local mark = data.from:getMark("@ty__jilei")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, choice .. "_char")
    room:setPlayerMark(data.from, "@ty__jilei", mark)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
}
local ty__jilei_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jilei_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    if type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    if type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    local mark = player:getMark("@ty__jilei")
    return type(mark) == "table" and table.contains(mark, card:getTypeString() .. "_char")
  end,
}
ty__jilei:addRelatedSkill(ty__jilei_prohibit)
yangxiu:addSkill(ty__danlao)
yangxiu:addSkill(ty__jilei)
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",
  ["#ty__danlao-invoke"] = "啖酪：你可以摸一张牌，令 %arg 对你无效",
  ["#ty__jilei-invoke"] = "鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？",
  ["@ty__jilei"] = "鸡肋",
  
  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

local luotong = General(extension, "ty__luotong", "wu", 3)
local renzheng = fk.CreateTriggerSkill{
  name = "renzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DamageFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if data.extra_data and data.extra_data.renzheng_invoke then
        return true
      end
      if data.to:getMark("renzheng-phase") > 0 then
        player.room:setPlayerMark(data.to, "renzheng-phase", 0)--FIXME: 伪实现！！！
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.PreDamage, fk.AfterSkillEffect, fk.Damaged},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreDamage then
      data.extra_data = data.extra_data or {}
      data.extra_data.renzheng = data.damage
      player.room:setPlayerMark(data.to, "renzheng-phase", 1)--FIXME
    elseif event == fk.AfterSkillEffect then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
      if e then
        local dat = e.data[1]
        if dat.extra_data and dat.extra_data.renzheng and dat.damage < dat.extra_data.renzheng then
          dat.extra_data.renzheng_invoke = true
        end
      end
    elseif event == fk.Damaged then
      player.room:setPlayerMark(data.to, "renzheng-phase", 0)--FIXME
    end
  end,
}
local jinjian = fk.CreateTriggerSkill{
  name = "jinjian",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jinjian1-invoke::"..data.to.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 1 then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    else
      room:notifySkillInvoked(player, self.name, "negative")
      data.damage = data.damage - 1
    end
  end,
}
local jinjian_trigger = fk.CreateTriggerSkill{
  name = "#jinjian_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 0 then
      return player.room:askForSkillInvoke(player, "jinjian", nil, "#jinjian2-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("jinjian")
    if player:usedSkillTimes(self.name, Player.HistoryTurn) % 2 == 1 then
      room:notifySkillInvoked(player, "jinjian", "defensive")
      data.damage = data.damage - 1
    else
      room:notifySkillInvoked(player, "jinjian", "negative")
      data.damage = data.damage + 1
    end
  end,
}
jinjian:addRelatedSkill(jinjian_trigger)
luotong:addSkill(renzheng)
luotong:addSkill(jinjian)
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["renzheng"] = "仁政",  --这两个烂大街的技能名大概率撞车叭……
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",
  ["jinjian"] = "进谏",
  [":jinjian"] = "当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，"..
  "若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。",
  ["#jinjian1-invoke"] = "进谏：你可以令对 %dest 造成的伤害+1",
  ["#jinjian2-invoke"] = "进谏：你可以令受到的伤害-1",

  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
  ["$jinjian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$jinjian2"] = "为将者死战，为臣者死谏！",
  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:askForDiscard(player, 1, player.maxHp, true, self.name, false, ".", "#ty__kaiji-discard:::"..player.maxHp)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("pingxi-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("pingxi-turn")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..player:getMark("pingxi-turn"), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p:isNude() then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard({card}, self.name, p, player)
      end
    end
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        player.room:addPlayerMark(player, "pingxi-turn", #move.moveInfo)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸等于体力上限张数的牌；阴：你可以弃置至多等于体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌，然后视为对这些角色各使用一张【杀】。",
  ["#ty__kaiji-discard"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",

  ["$ty__kaiji1"] = "谋虑渊深，料远若近。",
  ["$ty__kaiji2"] = "视昧而察，筹不虚运。",
  ["$pingxi1"] = "地有常险，守无常势。",
  ["$pingxi2"] = "国有常众，战无常胜。",
  ["~ty__wangchang"] = "志存开济，人亡政息……",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  prompt = function ()
    return "#jingzao-active:::" + tostring(3 + Self:getMark("jingzao-turn"))
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") > -3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao-turn")
    if n < 1 then return false end
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })

    local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id).trueName end), ",")
    if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
      room:addPlayerMark(player, "jingzao-turn", 1)
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      return
    end

    local to_get = {}
    while #cards > 0 do
      local id = table.random(cards)
      table.insert(to_get, id)
      local name = Fk:getCardById(id).trueName
      cards = table.filter(cards, function (id2)
        return Fk:getCardById(id2).trueName ~= name
      end)
    end
    room:setPlayerMark(player, "jingzao-turn", player:getMark("jingzao-turn") - #to_get)
    room:moveCardTo(to_get, Player.Hand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and (data.card:isCommonTrick() or
      data.card.trueName == "slash") and player:getMark("enyu-turn") ~= 0 and
      #table.filter(player:getMark("enyu-turn"), function(name) return name == data.card.trueName end) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
    and (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "enyu-turn")
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "enyu-turn", mark)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；"..
  "2.令你随机获得这些牌中牌名不同的牌各一张，每获得一张，此技能本回合亮出的牌数-1。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-active"] = "发动 经造，选择一名其他角色，亮出牌堆顶的%arg张卡牌",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令%src获得其中不同牌名各一张",

  ["$jingzao1"] = "闭门绝韦编，造经教世人。",
  ["$jingzao2"] = "著文成经，可教万世之人。",
  ["$enyu1"] = "君以国士待我，我必国士报之。",
  ["$enyu2"] = "吾本乡野腐儒，幸隆君之大恩。",
  ["~chengbing"] = "著经未成，此憾事也……",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local ty__zhaohan_delay = fk.CreateTriggerSkill{
  name = "#ty__zhaohan_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes(ty__zhaohan.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:isKongcheng() end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true, true)
    end
    if #targets > 0 then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, false, self.name, false, ".", "#zhaohan-give::" .. targets[1])
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#zhaohan-discard")
    end
  end,
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#jinjie-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, self.name)

    if player.dead or target.dead or not target:isWounded() or player:getMark("jinjie-round") > 0 then return false end
    local x = player:usedSkillTimes(self.name, Player.HistoryRound)
    if x > player:getHandcardNum() then return false end
    local room = player.room
    local round_event = room.logic:getCurrentEvent():findParent(GameEvent.Round)
    if round_event == nil then return false end
    local end_id = round_event.id
    local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
    for _, e in ipairs(events) do
      if e.id <= end_id then break end
      local current_player = e.data[1]
      if current_player == player then
        room:setPlayerMark(player, "jinjie-round", 1)
        return false
      end
    end

    if #room:askForDiscard(player, x, x, false, self.name, true, ".", "#jinjie-discard::"..target.id..":"..x) > 0 then
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      return not player:prohibitUse(slash) and table.find(player.room.alive_players, function (p)
        return (p.hp > player.hp or p:getHandcardNum() > player:getHandcardNum()) and not player:isProhibited(p, slash)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if (p.hp > player.hp or p:getHandcardNum() > player:getHandcardNum()) and not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
  end,
}
ty__zhaohan:addRelatedSkill(ty__zhaohan_delay)
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "一名角色进入濒死状态时，你可以令其摸一张牌，然后若本轮你还没有进行回合，你可以弃置X张手牌令其回复1点体力（X为本轮此技能的发动次数）。",
  ["jue"] = "举讹",
  [":jue"] = "准备阶段，你可以视为对一名体力值或手牌数大于你的角色使用一张【杀】。",
  ["#ty__zhaohan_delay"] = "昭汉",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色交给其两张手牌，或点“取消”则你弃置两张牌",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌交给 %dest",
  ["#jinjie-invoke"] = "你可以发动 尽节，令 %dest 摸一张牌",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "你可以发动 举讹，视为对一名体力值或手牌数大于你的角色使用一张【杀】",

  ["$ty__zhaohan1"] = "此心昭昭，惟愿汉明。",
  ["$ty__zhaohan2"] = "天曰昭德！天曰昭汉！",
  ["$jinjie1"] = "大汉养士百载，今乃奉节之时。",
  ["$jinjie2"] = "尔等皆忘天地君亲师乎？",
  ["$jue1"] = "尔等一家之言，难堵天下悠悠之口。",
  ["$jue2"] = "区区黄门而敛财千万，可诛其九族。",
  ["~ty__yangbiao"] = "愧无日磾先见之明，犹怀老牛舐犊之爱……",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local names = {}
    local mark = Self:getMark("zhaowen-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local c = Fk:cloneCard(card.name)
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, c) and not Self:prohibitUse(c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))) then
          if mark == 0 or (not table.contains(mark, card.trueName)) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-turn") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  main_skill = zhaowen,
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("zhaowen") and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, "zhaowen", nil, "#zhaowen-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player:getCardIds("h"))
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen-turn", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return end
    return player:getMark("zhaowen-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhaowen-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen-turn", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-turn", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiudun-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand", "#jiudun-card:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank == 0 then
      player:drawCards(1, self.name)
      room:useVirtualCard("analeptic", nil, player, player, self.name, false)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target.phase == Player.NotActive and player.drank > 0
      else
        return player:getMark(self.name) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, self.name, player.drank)
    else
      player.drank = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      room:broadcastProperty(player, "drank")
    end
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "你的【酒】效果不会因回合结束而消失。当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",
  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen-turn"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
  ["~ruanji"] = "诸君，欲与我同醉否？",
}

--豆蔻梢头：花鬘 辛宪英 薛灵芸 芮姬 段巧笑 马伶俐
local huaman = General(extension, "ty__huaman", "shu", 3, 3, General.Female)
local manyi = fk.CreateTriggerSkill{
  name = "manyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "savage_assault" and player.id == data.to
  end,
  on_use = Util.TrueFunc,
}
local mansi = fk.CreateViewAsSkill{
  name = "mansi",
  anim_type = "offensive",
  prompt = "#mansi",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local mansi_trigger = fk.CreateTriggerSkill{
  name = "#mansi_trigger",
  events = {fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("mansi") and data.card and data.card.trueName == "savage_assault"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, "@mansi")
    room:addPlayerMark(player, "@mansi", 1)
    player:broadcastSkillInvoke("mansi")
    room:notifySkillInvoked(player, "mansi", "drawcard")
  end,
}
local souying = fk.CreateTriggerSkill{
  name = "souying",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.tos and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and
      not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local events = {}
      if target == player then
        if TargetGroup:getRealTargets(data.tos)[1] == player.id or room:getCardArea(data.card) ~= Card.Processing then return end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), TargetGroup:getRealTargets(data.tos)[1])
        end, Player.HistoryTurn)
      else
        if TargetGroup:getRealTargets(data.tos)[1] ~= player.id then return end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == target.id and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end, Player.HistoryTurn)
      end
      return #events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", prompt, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    player:broadcastSkillInvoke(self.name)
    if target == player then
      room:notifySkillInvoked(player, self.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}
local zhanyuan = fk.CreateTriggerSkill{
  name = "zhanyuan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mansi") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.gender == General.Male and not p:hasSkill("xili", true) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanyuan-choose", self.name, true)
    if #to > 0 then
      room:handleAddLoseSkills(player, "xili|-mansi", nil, true, false)
      room:handleAddLoseSkills(room:getPlayerById(to[1]), "xili", nil, true, false)
    end
  end,
}
local xili = fk.CreateTriggerSkill{
  name = "xili",
  anim_type = "support",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and target ~= player and
      target:hasSkill(self.name, true, true) and target.phase ~= Player.NotActive and
      not data.to:hasSkill(self.name, true) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xili-invoke:"..data.from.id..":"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage + 1
    if not player.dead then
      player:drawCards(2, self.name)
    end
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
mansi:addRelatedSkill(mansi_trigger)
huaman:addSkill(manyi)
huaman:addSkill(mansi)
huaman:addSkill(souying)
huaman:addSkill(zhanyuan)
huaman:addRelatedSkill(xili)
Fk:loadTranslationTable{
  ["ty__huaman"] = "花鬘",
  ["manyi"] = "蛮裔",
  [":manyi"] = "锁定技，【南蛮入侵】对你无效。",
  ["mansi"] = "蛮嗣",
  [":mansi"] = "出牌阶段限一次，你可以将所有手牌当【南蛮入侵】使用；当一名角色受到【南蛮入侵】的伤害后，你摸一张牌。",
  ["souying"] = "薮影",
  [":souying"] = "每回合限一次，当你使用牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，你可以弃置一张牌获得之；"..
  "当其他角色使用牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，你可以弃置一张牌令此牌对你无效。",
  ["zhanyuan"] = "战缘",
  [":zhanyuan"] = "觉醒技，准备阶段，若你发动〖蛮嗣〗获得不少于七张牌，你加1点体力上限并回复1点体力。然后你可以选择一名男性角色，"..
  "你与其获得技能〖系力〗，你失去技能〖蛮嗣〗。",
  ["xili"] = "系力",
  [":xili"] = "每回合限一次，其他拥有〖系力〗的角色于其回合内对没有〖系力〗的角色造成伤害时，你可以弃置一张牌令此伤害+1，然后你与其各摸两张牌。",
  ["#mansi"] = "蛮嗣：你可以将所有手牌当【南蛮入侵】使用",
  ["@mansi"] = "蛮嗣",
  ["#souying1-invoke"] = "薮影：你可以弃置一张牌，获得此%arg",
  ["#souying2-invoke"] = "薮影：你可以弃置一张牌，令此%arg对你无效",
  ["#zhanyuan-choose"] = "战缘：你可以与一名男性角色获得技能〖系力〗",
  ["#xili-invoke"] = "系力：你可以弃置一张牌，令 %src 对 %dest 造成的伤害+1，你与 %src 各摸两张牌",

  ["$manyi1"] = "蛮族的力量，你可不要小瞧！",
  ["$manyi2"] = "南蛮女子，该当英勇善战！",
  ["$mansi1"] = "多谢父母怜爱。",
  ["$mansi2"] = "承父母庇护，得此福气。",
  ["$souying1"] = "真薮影移，险战不惧！",
  ["$souying2"] = "幽薮影单，只身勇斗！",
  ["$zhanyuan1"] = "势不同，情相随。",
  ["$zhanyuan2"] = "战中结缘，虽苦亦甜。",
  ["$xili1"] = "系力而为，助君得胜。",
  ["$xili2"] = "有我在，将军此战必能一举拿下！",
  ["~ty__huaman"] = "南蛮之地的花，还在开吗……",
}

local xinxianying = General(extension, "ty__xinxianying", "wei", 3, 3, General.Female)
local ty__zhongjian = fk.CreateActiveSkill{
  name = "ty__zhongjian",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < (1 + player:getMark("ty__caishi_twice-turn"))
    and table.find(Fk:currentRoom().alive_players, function(p) return p:getMark("ty__zhongjian_target-turn") == 0 end)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:getMark("ty__zhongjian_target-turn") == 0 end)
    if #targets == 0 then return end
    local choice = room:askForChoice(player, {"ty__zhongjian_draw","ty__zhongjian_dis"}, self.name)    
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty__zhongjian-choose:::"..choice, self.name, false, true)
    local to = room:getPlayerById(#tos > 0 and tos[1] or table.random(targets))
    room:addPlayerMark(to, "ty__zhongjian_target-turn")
    room:addPlayerMark(to, choice)
  end,
}
local ty__zhongjian_trigger = fk.CreateTriggerSkill{
  name = "#ty__zhongjian_trigger",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.Damage then
      return target and not target.dead and target:getMark("ty__zhongjian_dis") > 0
    else
      return not target.dead and target:getMark("ty__zhongjian_draw") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhongjian")
    if event == fk.Damage then
      room:setPlayerMark(target, "ty__zhongjian_dis", 0)
      room:askForDiscard(target, 2, 2, true, "ty__zhongjian", false)
    else
      room:setPlayerMark(target, "ty__zhongjian_draw", 0)
      target:drawCards(2, "ty__zhongjian")
    end
    if not player.dead then
      player:drawCards(1, "ty__zhongjian")
    end
  end,

  refresh_events = {fk.TurnStart, fk.Deathed},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "ty__zhongjian_dis", 0)
      room:setPlayerMark(p, "ty__zhongjian_draw", 0)
    end
  end,
}
ty__zhongjian:addRelatedSkill(ty__zhongjian_trigger)
xinxianying:addSkill(ty__zhongjian)
local ty__caishi = fk.CreateTriggerSkill{
  name = "ty__caishi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target and player.phase == Player.Draw then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local move = e.data[1]
        if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      local move = e.data[1]
      if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    if #ids == 0 then return false end
    local different = table.find(ids, function(id) return Fk:getCardById(id).suit ~= Fk:getCardById(ids[1]).suit end)
    self.cost_data = different
    if different then
      return player:isWounded() and player.room:askForSkillInvoke(player, self.name, nil, "#ty__caishi-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local different = self.cost_data
    if different then
      room:recover({ who = player,  num = 1, skillName = self.name })
      room:addPlayerMark(player, "@@ty__caishi_self-turn")
    else
      room:setPlayerMark(player, "ty__caishi_twice-turn", 1)
    end
  end,
}
local ty__caishi_prohibit = fk.CreateProhibitSkill{
  name = "#ty__caishi_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("@@ty__caishi_self-turn") > 0 and from == to
  end,
}
ty__caishi:addRelatedSkill(ty__caishi_prohibit)
xinxianying:addSkill(ty__caishi)
Fk:loadTranslationTable{
  ["ty__xinxianying"] = "辛宪英",
  ["ty__zhongjian"] = "忠鉴",
  [":ty__zhongjian"] = "出牌阶段限一次，你可以秘密选择以下一项，再秘密选择一名本回合未选择过的角色，直到你的下回合开始：1.当该角色下次造成伤害后，"..
  "其弃置两张牌；2.当该角色下次受到伤害后，其摸两张牌。当〖忠鉴〗被触发时，你摸一张牌。",
  ["ty__zhongjian_draw"] = "其下次受到伤害后，摸两张牌",
  ["ty__zhongjian_dis"] = "其下次造成伤害后，弃置两张牌",
  ["#ty__zhongjian-choose"] = "忠鉴：选择一名角色，%arg",
  ["#ty__zhongjian_trigger"] = "忠鉴",
  ["ty__caishi"] = "才识",
  [":ty__caishi"] = "摸牌阶段结束时，若你本阶段摸的牌：花色相同，本回合〖忠鉴〗改为“出牌阶段限两次”；花色不同，你可以回复1点体力，然后本回合"..
  "你不能对自己使用牌。",
  ["#ty__caishi-invoke"] = "你可以回复1点体力，然后本回合你不能对自己使用牌",
  ["@@ty__caishi_self-turn"] = "才识",

  ["$ty__zhongjian1"] = "闻大忠似奸、大智若愚，不辨之难鉴之。",
  ["$ty__zhongjian2"] = "以眼为镜可正衣冠，以心为镜可鉴忠奸。",
  ["$ty__caishi1"] = "柔指弄弦商羽，缀符成乐，似落珠玉盘。",
  ["$ty__caishi2"] = "素手点墨二三，绘文成卷，集缤纷万千。",
  ["~ty__xinxianying"] = "百无一用是女子。",
}

local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getMark("xialei-turn") > 2 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    local card_ids = {}
    if parent_event ~= nil then
      if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
        local parent_data = parent_event.data[1]
        if parent_data.from == player.id then
          card_ids = room:getSubcardsByRule(parent_data.card)
        end
      elseif parent_event.event == GameEvent.Pindian then
        local pindianData = parent_event.data[1]
        if pindianData.from == player then
          card_ids = room:getSubcardsByRule(pindianData.fromCard)
        else
          for toId, result in pairs(pindianData.results) do
            if player.id == toId then
              card_ids = room:getSubcardsByRule(result.toCard)
              break
            end
          end
        end
      end
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        elseif #card_ids > 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    if #ids == 1 then
      room:moveCards({
        ids = ids,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    else
      local to_return, choice = U.askforChooseCardsAndChoice(player, ids, {"xialei_top", "xialei_bottom"}, self.name, "#xialei-chooose")
      local moveInfos = {
        ids = to_return,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      }
      table.removeOne(ids, to_return[1])
      if #ids > 0 then
        if choice == "xialei_top" then
          for i = #ids, 1, -1 do
            table.insert(room.draw_pile, 1, ids[i])
          end
        else
          for _, id in ipairs(ids) do
            table.insert(room.draw_pile, id)
          end
        end
      end
      room:moveCards(moveInfos)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  prompt = "#anzhi-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id) return room:getCardArea(id) == Card.DiscardPile end)
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), Util.IdMapper), 1, 1, "#anzhi-choose", self.name, true)
      if #to > 0 then
        local get = {}
        if #ids > 2 then
          get = room:askForCardsChosen(player, player, 2, 2, {
            card_data = {
              { self.name, ids }
            }
          }, self.name)
        else
          get = ids
        end
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local anzhi_trigger = fk.CreateTriggerSkill{
  name = "#anzhi_trigger",
  anim_type = "masochism",
  events = {fk.Damaged},
  main_skill = anzhi,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#anzhi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(anzhi.name)
    anzhi:onUse(player.room, {
      from = player.id,
      cards = {},
      tos = {},
    })
  end,
}
anzhi:addRelatedSkill(anzhi_trigger)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  ["#anzhi_trigger"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；"..
  "黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["#xialei-chooose"] = "霞泪：选择一张卡牌获得",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-active"] = "发动暗织，进行判定",
  ["#anzhi-invoke"] = "是否使用暗织，进行判定",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}

local ruiji = General(extension, "ty__ruiji", "wu", 4, 4, General.Female)
local wangyuan = fk.CreateTriggerSkill{
  name = "wangyuan",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangyuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id, true)
      if card.type ~= Card.TypeEquip and not table.find(player:getPile("ruiji_wang"), function(c)
        return card.trueName == Fk:getCardById(c, true).trueName end) then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if #names > 0 then
      local card = room:getCardsFromPileByRule(table.random(names))
      player:addToPile("ruiji_wang", card[1], true, self.name)
    end
  end,
}
local lingyin = fk.CreateViewAsSkill{
  name = "lingyin",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("lingyin-turn") > 0
  end,
}
local lingyin_trigger = fk.CreateTriggerSkill{
  name = "#lingyin_trigger",
  mute = true,
  expand_pile = "ruiji_wang",
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self) and player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
      else
        return player:getMark("lingyin-turn") > 0 and not data.chain and data.to ~= player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local n = player.room:getTag("RoundCount")
      local cards = player.room:askForCard(player, 1, n, false, "liying", true,
        ".|.|.|ruiji_wang|.|.", "#lingyin-invoke:::"..tostring(n), "ruiji_wang")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      player:broadcastSkillInvoke("lingyin")
      room:notifySkillInvoked(player, "lingyin", "drawcard")
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
      if #player:getPile("ruiji_wang") == 0 or table.every(player:getPile("ruiji_wang"), function(id)
        return Fk:getCardById(id).color == Fk:getCardById(player:getPile("ruiji_wang")[1]).color end) then
        room:setPlayerMark(player, "lingyin-turn", 1)
      end
    else
      data.damage = data.damage + 1
    end
  end,
}
local liying = fk.CreateTriggerSkill{
  name = "liying",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.Draw and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, info.cardId)
        end
      end
    end
    room:setPlayerMark(player, "liying-phase", mark)
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    local _, ret = player.room:askForUseActiveSkill(player, "liying_active", prompt, true)
    if ret then
      self.cost_data = ret
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ret = self.cost_data
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ret.cards)
    room:obtainCard(room:getPlayerById(ret.targets[1]), dummy, false, fk.ReasonGive)
    if not player.dead then
      player:drawCards(1, self.name)
      if not player.dead and player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
}
local liying_active = fk.CreateActiveSkill{
  name = "liying_active",
  mute = true,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Self:getMark("liying-phase") ~= 0 and table.contains(Self:getMark("liying-phase"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
lingyin:addRelatedSkill(lingyin_trigger)
Fk:addSkill(liying_active)
ruiji:addSkill(wangyuan)
ruiji:addSkill(lingyin)
ruiji:addSkill(liying)
Fk:loadTranslationTable{
  ["ty__ruiji"] = "芮姬",
  ["wangyuan"] = "妄缘",
  [":wangyuan"] = "当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。",
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",
  ["liying"] = "俐影",
  [":liying"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。",
  ["#wangyuan-invoke"] = "妄缘：是否增加一张“妄”？",
  ["ruiji_wang"] = "妄",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，然后若“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用",
  ["liying_active"] = "俐影",
  ["#liying1-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌",
  ["#liying2-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”",

  ["$wangyuan1"] = "小女子不才，愿伴公子余生。",
  ["$wangyuan2"] = "纵有万钧之力，然不斩情丝。",
  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
  ["$liying1"] = "飞影略白鹭，日暮栖君怀。",
  ["$liying2"] = "妾影婆娑，摇曳君心。",
  ["~ty__ruiji"] = "佳人芳华逝，空余孤铃鸣……",
}

local duanqiaoxiao = General(extension, "duanqiaoxiao", "wei", 3, 3, General.Female)
local caizhuang = fk.CreateActiveSkill{
  name = "caizhuang",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    while true do
      player:drawCards(1, self.name)
      local suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= #effect.cards then return end
    end
  end,
}
local huayi = fk.CreateTriggerSkill{
  name = "huayi",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#huayi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
}
local huayi_trigger = fk.CreateTriggerSkill{
  name = "#huayi_trigger",
  mute = true,
  events = {fk.TurnEnd, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@huayi") ~= 0 then
      if event == fk.TurnEnd then
        return target ~= player and player:getMark("@huayi") == "red"
      elseif event == fk.Damaged then
        return target == player and player:getMark("@huayi") == "black"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(1, "huayi")
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(2, "huayi")
    end
  end,
}
huayi:addRelatedSkill(huayi_trigger)
duanqiaoxiao:addSkill(caizhuang)
duanqiaoxiao:addSkill(huayi)
Fk:loadTranslationTable{
  ["duanqiaoxiao"] = "段巧笑",
  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张花色各不相同的牌，然后重复摸牌直到手牌中的花色数等同于弃牌数。",
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，其他角色回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",
  ["#huayi-invoke"] = "华衣：你可以判定，根据颜色直到你下回合开始获得效果",
  ["@huayi"] = "华衣",

  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
  ["~duanqiaoxiao"] = "佳人时光少，君王总薄情……",
}

local malingli = General(extension, "malingli", "shu", 3, 3, General.Female)
local lima = fk.CreateDistanceSkill{
  name = "lima",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          local card_type = Fk:getCardById(id).sub_type
          if card_type == Card.SubtypeOffensiveRide or card_type == Card.SubtypeDefensiveRide then
            n = n + 1
          end
        end
      end
      return -math.max(1, n)
    end
    return 0
  end,
}
local xiaoyin = fk.CreateTriggerSkill{
  name = "xiaoyin",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player == p or player:distanceTo(p) == 1
    end)
    local ids = room:getNCards(n)
    room:moveCards{
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    room:delay(2000)
    local dummy = Fk:cloneCard("dilu")
    for i = #ids, 1, -1 do
      if Fk:getCardById(ids[i]).color == Card.Red then
        dummy:addSubcard(ids[i])
        table.removeOne(ids, ids[i])
      end
    end
    if #dummy.subcards > 0 then
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    local targets = {}
    while #ids > 0 and not player.dead do
      player.special_cards["xiaoyin_active"] = table.simpleClone(ids)
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      room:setPlayerMark(player, "xiaoyin_cards", ids)
      room:setPlayerMark(player, "xiaoyin_targets", targets)
      local success, dat = room:askForUseActiveSkill(player, "xiaoyin_active", "#xiaoyin-give", true)
      room:setPlayerMark(player, "xiaoyin_cards", 0)
      room:setPlayerMark(player, "xiaoyin_targets", 0)
      player.special_cards["xiaoyin_active"] = {}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      if not success then break end
      table.insert(targets, dat.targets[1])
      table.removeOne(ids, dat.cards[1])
      room:getPlayerById(dat.targets[1]):addToPile("xiaoyin", dat.cards[1], true, self.name)
    end
    if #ids > 0 then
      room:moveCards{
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
    end
  end,
}
local xiaoyin_active = fk.CreateActiveSkill{
  name = "xiaoyin_active",
  expand_pile = "xiaoyin_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(U.getMark(Self, "xiaoyin_cards"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local targets = U.getMark(Self, "xiaoyin_targets")
      if #targets == 0 then return true end
      if table.contains(targets, to_select) then return false end
      local target = Fk:currentRoom():getPlayerById(to_select)
      if table.contains(targets, target.next.id) then return true end
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.next == target then
          return table.contains(targets, p.id)
        end
      end
    end
  end,
}
local xiaoyin_trigger = fk.CreateTriggerSkill{
  name = "#xiaoyin_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    if target == player and #player:getPile("xiaoyin") > 0 and data.from and not data.from.dead then
      if data.damageType == fk.FireDamage then
        return not data.from:isNude()
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if data.damageType == fk.FireDamage then
      local types = {}
      for _, id in ipairs(target:getPile("xiaoyin")) do
        table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      end
      local card = player.room:askForDiscard(data.from, 1, 1, true, self.name, true,
      ".|.|.|.|.|"..table.concat(types, ","), "#xiaoyin-damage::"..target.id, true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return player.room:askForSkillInvoke(data.from, "xiaoyin", nil, "#xiaoyin-fire::"..target.id)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.from:hasskill(xiaoyin, true) then
      data.from:broadcastSkillInvoke("xiaoyin")
      room:notifySkillInvoked(data.from, "xiaoyin", "offensive")
    end
    room:doIndicate(data.from.id, {target.id})
    if data.damageType == fk.FireDamage then
      local card_type = Fk:getCardById(self.cost_data[1]).type
      room:throwCard(self.cost_data, "xiaoyin", data.from, data.from)
      local ids = table.filter(target:getPile("xiaoyin"), function(id)
        return Fk:getCardById(id).type == card_type end)
      if #ids > 0 then
        room:moveCards({
          from = target.id,
          ids = table.random(ids, 1),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "xiaoyin",
          specialName = "xiaoyin",
        })
        data.damage = data.damage + 1
      end
    else
      local id = room:askForCardChosen(data.from, target, {
        card_data = {
          { "xiaoyin", target:getPile("xiaoyin") }
        }
      }, "xiaoyin", "#xiaoyin-fire::" .. target.id)
      room:moveCardTo(id, Card.PlayerHand, data.from, fk.ReasonJustMove, self.name, nil, true, data.from.id)
      data.damageType = fk.FireDamage
    end
  end,
}
local huahuo = fk.CreateViewAsSkill{
  name = "huahuo",
  anim_type = "offensive",
  pattern = "fire__slash",
  prompt = "#huahuo",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire__slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    local room = player.room
    local tos = TargetGroup:getRealTargets(use.tos)
    if table.find(tos, function(id) return #room:getPlayerById(id):getPile("xiaoyin") > 0 end) and
      table.find(room:getOtherPlayers(player), function(p) return not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 end) then
      if room:askForSkillInvoke(player, self.name, nil, "#huahuo-invoke") then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 and not player:isProhibited(p, use.card) then
            TargetGroup:pushTargets(use.tos, p.id)
          end
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player, response)
    return false
  end,
}
Fk:addSkill(xiaoyin_active)
xiaoyin:addRelatedSkill(xiaoyin_trigger)
malingli:addSkill(lima)
malingli:addSkill(xiaoyin)
malingli:addSkill(huahuo)
Fk:loadTranslationTable{
  ["malingli"] = "马伶俐",
  ["lima"] = "骊马",
  [":lima"] = "锁定技，场上每有一张坐骑牌，你计算与其他角色的距离-1（至少为1）。",
  ["xiaoyin"] = "硝引",
  [":xiaoyin"] = "准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将任意张黑色牌作为“硝引”放置在等量名连续其他角色的"..
  "武将牌上。有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并随机移去一张此类别的“硝引”牌令此伤害+1；"..
  "不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。",
  ["huahuo"] = "花火",
  [":huahuo"] = "出牌阶段限一次，你可以将一张红色手牌当做不计次数的火【杀】使用。若目标有“硝引”牌，此【杀】可改为指定所有有“硝引”牌的角色为目标。",
  ["xiaoyin_active"] = "硝引",
  ["#xiaoyin_trigger"] = "硝引",
  ["#xiaoyin-give"] = "硝引：将黑色牌作为“硝引”放置在连续的其他角色武将牌上",
  ["#xiaoyin-damage"] = "硝引：你可以弃置一张与 %dest “硝引”同类别的牌，令其受到伤害+1",
  ["#xiaoyin-fire"] = "硝引：你可以获得 %dest 的一张“硝引”，令此伤害改为火焰伤害",
  ["#huahuo"] = "花火：你可以将一张红色手牌当不计次的火【杀】使用，目标可以改为所有有“硝引”的角色",
  ["#huahuo-invoke"] = "花火：是否将目标改为所有有“硝引”的角色？",

  ["$xiaoyin1"] = "鹿栖于野，必能奔光而来。",
  ["$xiaoyin2"] = "磨硝作引，可点心中灵犀。",
  ["$huahuo1"] = "馏石漆取上清，可为胜爆竹之花火。",
  ["$huahuo2"] = "莫道繁花好颜色，此火犹胜二月黄。",
  ["~malingli"] = "花无百日好，人无再少年……",
}

--皇家贵胄：孙皓 士燮 曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 孙瑜 甘夫人糜夫人
local ty__sunhao = General(extension, "ty__sunhao", "wu", 5)
local ty__canshi = fk.CreateTriggerSkill{
  name = "ty__canshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.find(player.room.alive_players, function (p)
      return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    if player.room:askForSkillInvoke(player, self.name, nil, "#ty__canshi-invoke:::"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + self.cost_data
  end,
}
local ty__canshi_delay = fk.CreateTriggerSkill{
  name = "#ty__canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:usedSkillTimes(ty__canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local ty__chouhai = fk.CreateTriggerSkill{
  name = "ty__chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty__canshi:addRelatedSkill(ty__canshi_delay)
ty__sunhao:addSkill(ty__canshi)
ty__sunhao:addSkill(ty__chouhai)
ty__sunhao:addSkill("guiming")
Fk:loadTranslationTable{
  ["ty__sunhao"] = "孙皓",
  ["ty__canshi"] = "残蚀",
  [":ty__canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用【杀】或普通锦囊牌时，你弃置一张牌。",
  ["#ty__canshi_delay"] = "残蚀",
  ["ty__chouhai"] = "仇海",
  [":ty__chouhai"] = "锁定技，当你受到【杀】造成的伤害时，若你没有手牌，此伤害+1。",
  ["#ty__canshi-invoke"] = "残蚀：你可以多摸 %arg 张牌",

  ["$ty__canshi1"] = "天地不仁，当视苍生为刍狗！",
  ["$ty__canshi2"] = "真龙天子，焉能不择人而噬！",
  ["$ty__chouhai1"] = "大好头颅，谁当斫之？哈哈哈！",
  ["$ty__chouhai2"] = "来来来！且试吾颈硬否！",
  ["$guiming_ty__sunhao1"] = "朕奉天承运，谁敢不从！",
  ["$guiming_ty__sunhao2"] = "朕一日为吴皇，则终生为吴皇！",
  ["~ty__sunhao"] = "八十万人齐卸甲，一片降幡出石头。",
}

local ty__shixie = General(extension, "ty__shixie", "qun", 3)
local ty__biluan = fk.CreateTriggerSkill{
  name = "ty__biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      return table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local x = math.min(4, #player.room.alive_players)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__biluan-invoke:::"..x, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local x = math.min(4, #player.room.alive_players)
    local num = tonumber(player:getMark("@ty__shixie_distance"))+x
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__biluan_distance = fk.CreateDistanceSkill{
  name = "#ty__biluan_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
}
ty__biluan:addRelatedSkill(ty__biluan_distance)
ty__shixie:addSkill(ty__biluan)
local ty__lixia = fk.CreateTriggerSkill{
  name = "ty__lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "ty__lixia_draw:"..target.id}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
    else
      target:drawCards(2, self.name)
    end
    local num = tonumber(player:getMark("@ty__shixie_distance"))-1
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__lixia_distance = fk.CreateDistanceSkill{
  name = "#ty__lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num < 0 then
      return num
    end
  end,
}
ty__lixia:addRelatedSkill(ty__lixia_distance)
ty__shixie:addSkill(ty__lixia)
Fk:loadTranslationTable{
  ["ty__shixie"] = "士燮",
  ["ty__biluan"] = "避乱",
  [":ty__biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为全场角色数且至多为4）。",
  ["ty__lixia"] = "礼下",
  [":ty__lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸两张牌。选择完成后，其他角色计算与你的距离-1。",
  ["#ty__biluan-invoke"] = "避乱：你可弃一张牌，令其他角色计算与你距离+%arg",
  ["@ty__shixie_distance"] = "距离",
  ["ty__lixia_draw"] = "令%src摸两张牌",

  ["$ty__biluan1"] = "天下攘攘，难觅避乱之地。",
  ["$ty__biluan2"] = "乱世纷扰，唯避居，方为良策。",
  ["$ty__lixia1"] = "得人才者，得天下。",
  ["$ty__lixia2"] = "礼贤下士，方得民心。",
  ["~ty__shixie"] = "老夫此生，了无遗憾。",
}

local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    local result = room:askForGuanxing(player, cards, {0, player:getLostHp()}, {}, self.name, true, {"qianlong_get", "qianlong_bottom"})
    if #result.top > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(result.top)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #result.bottom > 0 then
      for _, id in ipairs(result.bottom) do
        table.insert(room.draw_pile, id)
      end
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = #result.top,
        arg2 = #result.bottom,
      }
    end
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), Util.IdMapper), 1, 1, "#fensi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = player
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    }
    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local juetao = fk.CreateTriggerSkill{
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player.hp == 1 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#juetao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    while true do
      if player.dead or to.dead then return end
      local id = room:getNCards(1, "bottom")[1]
      room:moveCards({
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      local card = Fk:getCardById(id, true)
      local tos
      if (card.trueName == "slash") or
        ((table.contains({"dismantlement", "snatch", "chasing_near"}, card.name)) and not to:isAllNude()) or
        (table.contains({"fire_attack", "unexpectation"}, card.name) and not to:isKongcheng()) or
        (table.contains({"duel", "savage_assault", "archery_attack", "iron_chain", "raid_and_frontal_attack", "enemy_at_the_gates"}, card.name)) or
        (table.contains({"indulgence", "supply_shortage"}, card.name) and not to:hasDelayedTrick(card.name)) then
        tos = {{to.id}}
      elseif (table.contains({"amazing_grace", "god_salvation"}, card.name)) then
        tos = {{player.id}, {to.id}}
      elseif (card.name == "collateral" and to:getEquipment(Card.SubtypeWeapon)) then
        tos = {{to.id}, {player.id}}
      elseif (card.type == Card.TypeEquip) or
        (card.name == "peach" and player:isWounded()) or
        (card.name == "analeptic") or
        (table.contains({"ex_nihilo", "foresight"}, card.name)) or
        (card.name == "fire_attack" and not player:isKongcheng()) or
        (card.name == "lightning" and not player:hasDelayedTrick("lightning")) then
        tos = {{player.id}}
      end
      if tos and room:askForSkillInvoke(player, self.name, data, "#juetao-use:::"..card:toLogString()) then
        room:useCard({
          card = card,
          from = player.id,
          tos = tos,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:moveCards({
          ids = {id},
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
        })
        return
      end
    end
  end,
}
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["qianlong"] = "潜龙",
  [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。",
  ["fensi"] = "忿肆",
  [":fensi"] = "锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。",
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",
  ["#qianlong-guanxing"] = "潜龙：获得其中至多%arg张牌（获得上方的牌，下方的牌置于牌堆底）",
  ["qianlong_get"] = "获得",
  ["qianlong_bottom"] = "置于牌堆底",
  ["#fensi-choose"] = "忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】",
  ["#juetao-choose"] = "决讨：你可以指定一名角色，连续对其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否使用%arg！",
  ["#zhushi-invoke"] = "助势：你可以令 %src 摸一张牌",
  ["zhushi_draw"] = "其摸一张牌",
  
  ["$qianlong1"] = "鸟栖于林，龙潜于渊。",
  ["$qianlong2"] = "游鱼惊钓，潜龙飞天。",
  ["$fensi1"] = "此贼之心，路人皆知！",
  ["$fensi2"] = "孤君烈忿，怒愈秋霜。",
  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！",
  ["$zhushi1"] = "可有爱卿愿助朕讨贼？",
  ["$zhushi2"] = "泱泱大魏，忠臣俱亡乎？",
  ["~caomao"] = "宁作高贵乡公死，不作汉献帝生……",
}

local liubian = General(extension, "liubian", "qun", 3)
local shiyuan = fk.CreateTriggerSkill{
  name = "shiyuan",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
      (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
      (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, self.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
}
local dushi = fk.CreateTriggerSkill{
  name = "dushi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return not p:hasSkill(self) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#dushi-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:handleAddLoseSkills(room:getPlayerById(to), self.name, nil, true, false)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and p:hasSkill("dushi") and p ~= player end)
    end
  end,
}
local yuwei = fk.CreateTriggerSkill{
  name = "yuwei$",
  frequency = Skill.Compulsory,
}
dushi:addRelatedSkill(dushi_prohibit)
liubian:addSkill(shiyuan)
liubian:addSkill(dushi)
liubian:addSkill(yuwei)
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
  
  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
  ["$dushi1"] = "孤无病，此药无需服。",
  ["$dushi2"] = "辟恶之毒，为最毒。",
  ["~liubian"] = "侯非侯，王非王……",
}

local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish and player:getMark("suifu-turn") > 1 and
      not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suifu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.reverse(target.player_cards[Player.Hand])
    room:moveCards({
      ids = cards,
      from = target.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target == player or target.seat == 1)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "suifu-turn", data.damage)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 10, "#pijing-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    if not table.contains(self.cost_data, player.id) then
      table.insert(self.cost_data, 1, player.id)
    end
    for _, id in ipairs(self.cost_data) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,
}
liuyu:addSkill(suifu)
liuyu:addSkill(pijing)
liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>"..
  "（锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",

  ["$suifu1"] = "以柔克刚，方是良策。",
  ["$suifu2"] = "镇抚边疆，为国家计。",
  ["$pijing1"] = "群寇来袭，愿和将军同御外侮。",
  ["$pijing2"] = "天下不宁，愿与阁下共守此州。",
  ["$zimu"] = "既为汉吏，当遵汉律。",
  ["~ty__liuyu"] = "公孙瓒谋逆，人人可诛！",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Draw
    elseif player:usedSkillTimes(self.name) > 0 and player:getMark("_huishu-turn") == 0 then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
              if turn_event == nil then return false end
              local end_id = turn_event.id
              local x = 0
              U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
                for _, move2 in ipairs(e.data) do
                  if move2.from == player.id and move2.moveReason == fk.ReasonDiscard then
                    for _, info2 in ipairs(move2.moveInfo) do
                      if info2.fromArea == Card.PlayerHand or info2.fromArea == Card.PlayerEquip then
                        x = x + 1
                      end
                    end
                  end
                end
                return false
              end, end_id)
              return x > player:getMark("huishu3") + 2 and table.find(room.discard_pile, function (id)
                return Fk:getCardById(id) ~= Card.TypeBasic
              end)
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return player.room:askForSkillInvoke(player, self.name)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player:drawCards(player:getMark("huishu1") + 3, self.name)
      if player.dead then return false end
      local x = player:getMark("huishu2") + 1
      player.room:askForDiscard(player, x, x, false, self.name, false)
    else
      local room = player.room
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu3") + 2, "discardPile")
      if #cards > 0 then
        room:setPlayerMark(player, "_huishu-turn", 1)
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "huishu1", 0)
    room:setPlayerMark(player, "huishu2", 0)
    room:setPlayerMark(player, "huishu3", 0)
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "@" .. self.name, {3, 1, 2})
    else
      room:setPlayerMark(player, "@" .. self.name, 0)
    end
  end,
}
local yishu = fk.CreateTriggerSkill{
  name = "yishu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:hasSkill(huishu, true) and player.phase ~= Player.Play and
      not huishu:triggerable(event, target, player, data) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local yishu_nums = {
      player:getMark("huishu1") + 3,
      player:getMark("huishu2") + 1,
      player:getMark("huishu3") + 2
    }

    local max_c = math.max(yishu_nums[1], yishu_nums[2], yishu_nums[3])
    local min_c = math.min(yishu_nums[1], yishu_nums[2], yishu_nums[3])

    local to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == max_c then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    local choice = room:askForChoice(player, to_change, self.name, "#yishu-lose")
    local index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] - 1

    room:setPlayerMark(player, "@huishu", yishu_nums)

    to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == min_c and i ~= index then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    choice = room:askForChoice(player, to_change, self.name, "#yishu-add")
    index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] + 2

    room:setPlayerMark(player, "@huishu", yishu_nums)

    room:setPlayerMark(player, "huishu1", yishu_nums[1] - 3)
    room:setPlayerMark(player, "huishu2", yishu_nums[2] - 1)
    room:setPlayerMark(player, "huishu3", yishu_nums[3] - 2)
  end,
}
local ligong = fk.CreateTriggerSkill{
  name = "ligong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:hasSkill(huishu, true) and
    (player:getMark("huishu1") > 1 or player:getMark("huishu2") > 3 or player:getMark("huishu3") > 2)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-yishu", nil)

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return (general.kingdom == "wu" or general.subkingdom == "wu") and general.gender == General.Female
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, 4)

    local skills = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
    end
    local result = player.room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
      generals, skills, 1, 2, "#ligong-choice", true
    })
    local choices = {}
    if result ~= "" then
      choices = json.decode(result)
    end
    if #choices == 0 then
      player:drawCards(3, self.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..table.concat(choices, "|"), nil)
    end
  end,
}
quanhuijie:addSkill(huishu)
quanhuijie:addSkill(yishu)
quanhuijie:addSkill(ligong)
Fk:loadTranslationTable{
  ["quanhuijie"] = "全惠解",
  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，然后从随机四个吴国女性武将中选择至多"..
  "两个技能获得（如果不获得技能则不失去〖慧淑〗并摸三张牌）。",
  ["@huishu"] = "慧淑",
  ["huishu1"] = "摸牌数",
  ["huishu2"] = "摸牌后弃牌数",
  ["huishu3"] = "获得锦囊所需弃牌数",
  ["#yishu-add"] = "易数：请选择增加的一项",
  ["#yishu-lose"] = "易数：请选择减少的一项",
  ["#ligong-choice"] = "离宫：选择至多2个武将技能",

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
}

local dingfuren = General(extension, "dingfuren", "wei", 3, 3, General.Female)
local fengyan = fk.CreateActiveSkill{
  name = "fengyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choices = {}
    if Self:getMark("fengyan1-phase") == 0 then
      table.insert(choices, "fengyan1-phase")
    end
    if Self:getMark("fengyan2-phase") == 0 then
      table.insert(choices, "fengyan2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("fengyan1-phase") == 0 or player:getMark("fengyan2-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "fengyan1-phase" then
        return target.hp <= Self.hp and not target:isKongcheng()
      elseif self.interaction.data == "fengyan2-phase" then
        return target:getHandcardNum() <= Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "fengyan1-phase" then
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|hand", "#fengyan-give:"..player.id)
      room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    elseif self.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local fudao = fk.CreateTriggerSkill{
  name = "fudao",
  anim_type = "support",
  mute = true,
  events = {fk.GameStart, fk.TargetSpecified, fk.Death, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Death then
      if player:hasSkill(self.name, false, (player == target)) then
        local to = player.room:getPlayerById(player:getMark(self.name))
        return to ~= nil and ((player == target and not to.dead) or to == target) and data.damage and data.damage.from and
          not data.damage.from.dead and data.damage.from ~= player and data.damage.from ~= to
      end
      return false
    end
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return ((player == target and player:getMark(self.name) == to.id) or (player == to and player:getMark(self.name) == target.id)) and
          player:getMark("fudao_specified-turn") == 0
      elseif event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 and
          data.card.color == Card.Black
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fudao-choose", self.name, false, true)
      if #tos > 0 then
        room:setPlayerMark(player, self.name, tos[1])
        room:setPlayerMark(player, "@@fudao", 1)
        room:setPlayerMark(room:getPlayerById(tos[1]), "@@fudao", 1)
      end
    elseif event == fk.TargetSpecified then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, "fudao_specified-turn")
      local targets = {player.id, player:getMark(self.name)}
      room:sortPlayersByAction(targets)
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if p and not p.dead then
          room:drawCards(p, 2, self.name)
        end
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(data.damage.from, "@@juelie", 1)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(room:getPlayerById(data.from), "@@fudao-turn", 1)
    end
  end,
}
local fudao_delay = fk.CreateTriggerSkill{
  name = "#fudao_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@fudao") > 0 and data.to:getMark("@@juelie") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, fudao.name, "offensive")
    if player:hasSkill(fudao.name, true) then
      player:broadcastSkillInvoke(fudao.name)
    end
    data.damage = data.damage + 1
  end,
}
local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@fudao-turn") > 0
  end,
}
fudao:addRelatedSkill(fudao_delay)
fudao:addRelatedSkill(fudao_prohibit)
dingfuren:addSkill(fengyan)
dingfuren:addSkill(fudao)
Fk:loadTranslationTable{
  ["dingfuren"] = "丁尚涴",
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；"..
  "若其手牌数小于等于你，你视为对其使用一张无距离和次数限制的【杀】。",
  ["fudao"] = "抚悼",
  ["#fudao_delay"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，"..
  "你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",
  ["fengyan1-phase"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2-phase"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",
  ["@@fudao"] = "抚悼",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@juelie"] = "决裂",
  ["@@fudao-turn"] = "抚悼 不能出牌",

  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？",
  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
  ["~dingfuren"] = "吾儿既丧，天地无光……",
}

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
local fangdu = fk.CreateTriggerSkill{
  name = "fangdu",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local mark_name = "fangdu1_record-turn"
    if data.damageType == fk.NormalDamage then
      if not player:isWounded() then return false end
    else
      if data.from == nil or data.from == player or data.from:isKongcheng() then return false end
      mark_name = "fangdu2_record-turn"
    end
    local x = player:getMark(mark_name)
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if e.data[1] == player and reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            local damage = first_damage_event.data[1]
            if damage.damageType == data.damageType then
              x = first_damage_event.id
              room:setPlayerMark(player, mark_name, x)
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      local id = table.random(data.from.player_cards[Player.Hand])
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end
}
local jiexing = fk.CreateTriggerSkill{
  name = "jiexing",
  anim_type = "drawcard",
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == self.name then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@jiexing-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@jiexing-inhand", 0)
      end
    end
  end,
}
local jiexing_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiexing_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiexing-inhand") > 0
  end,
}
jiexing:addRelatedSkill(jiexing_maxcards)
yuanji:addSkill(fangdu)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌，此牌不计入你本回合的手牌上限。",

  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",
  ["@@jiexing-inhand"] = "节行",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
  ["$jiexing1"] = "女子有节，安能贰其行？",
  ["$jiexing2"] = "坐受雨露，皆为君恩。",
  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuandi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yuandi_discard" then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
  end,
}
local xinyou = fk.CreateActiveSkill{
  name = "xinyou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 2 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
}
local xinyou_record = fk.CreateTriggerSkill{
  name = "#xinyou_record",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 then
      room:askForDiscard(player, 1, 1, true, "xinyou", false)
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过两张牌，结束阶段你失去1点体力；"..
  "若你因此回复体力，结束阶段你弃置一张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}

local sunyu = General(extension, "sunyu", "wu", 3)
local quanshou = fk.CreateTriggerSkill{
  name = "quanshou",
  anim_type = "support",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:getHandcardNum() <= target.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#quanshou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choice = room:askForChoice(target, {"quanshou1", "quanshou2:"..player.id}, self.name, "#quanshou-choice:"..player.id)
    if choice == "quanshou1" then
      room:setPlayerMark(target, "quanshou1-turn", 1)
      local n = math.min(target.maxHp, 5) - target:getHandcardNum()
      if n > 0 then
        target:drawCards(n, self.name)
      end
    else
      room:setPlayerMark(player, "quanshou2-turn", target.id)
    end
  end,
}
local quanshou_trigger = fk.CreateTriggerSkill{
  name = "#quanshou_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("quanshou2-turn") ~= 0 and data.from and data.from == player:getMark("quanshou2-turn")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "quanshou")
  end,
}
local quanshou_targetmod = fk.CreateTargetModSkill{
  name = "#quanshou_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and card.trueName == "slash" and player:getMark("quanshou1-turn") > 0 and scope == Player.HistoryPhase then
      return -1
    end
  end,
}
local shexue = fk.CreateTriggerSkill{
  name = "shexue",
  anim_type = "special",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return player:getMark("shexue-phase") ~= 0 and not player:isNude()
      elseif event == fk.EventPhaseEnd and player:hasSkill(self) then
        local room = player.room
        local name = ""
        room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
          local use = e.data[1]
          if use.from == player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
            name = use.card.name
          end
        end, Player.HistoryPhase)
        if name ~= "" then
          room:setPlayerMark(player, "shexue2-phase", name)
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      self:doCost(event, target, player, data)
    else
      local room = player.room
      local names = table.simpleClone(player:getMark("shexue-phase"))  --tableMark以防同时被发动设学2和设学1
      room:setPlayerMark(player, "shexue-phase", 0)
      for _, name in ipairs(names) do
        if player.dead then return end
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if player:canUse(card) then
          room:setPlayerMark(player, "shexue-tmp", name)
          self:doCost(event, target, player, data)
          room:setPlayerMark(player, "shexue-tmp", 0)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local success, dat = room:askForUseActiveSkill(player, "shexue_viewas", "#shexue-use:::"..player:getMark("shexue-tmp"), true)
      if success then
        self.cost_data = dat
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#shexue-invoke:::"..player:getMark("shexue2-phase"))
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = Fk.skills["shexue_viewas"]:viewAs(self.cost_data.cards)
      card.skillName = self.name
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    else
      local mark = player:getMark("shexue2_invoking")  --tableMark以考虑观微、当先
      if mark == 0 then mark = {} end
      table.insert(mark, player:getMark("shexue2-phase"))
      room:setPlayerMark(player, "shexue2_invoking", mark)
    end
  end,

  refresh_events = {fk.TurnStart, fk.EventPhaseStart},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TurnStart then
      return player:getMark("shexue2_invoking") ~= 0
    else
      return target == player and player.phase == Player.Play
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then  --下回合开始时为其添加mark记录
      room:doIndicate(player.id, {target.id})
      room:notifySkillInvoked(player, self.name, "support")
      local mark = target:getMark("shexue2-turn")  --按描述如果一回合有多个出牌阶段，每个阶段开始时都能发动设学2
      room:setPlayerMark(target, "shexue2-turn", player:getMark("shexue2_invoking"))
      room:setPlayerMark(player, "shexue2_invoking", 0)
    else
      if player:getMark("shexue2-turn") ~= 0 then
        room:setPlayerMark(player, "shexue-phase", player:getMark("shexue2-turn"))
      end
      if player:hasSkill(self) then
        local current_event = room.logic:getCurrentEvent()
        local all_turn_events = room.logic.event_recorder[GameEvent.Turn]
        if type(all_turn_events) == "table" then
          local index = #all_turn_events
          if index > 0 then
            local turn_event = current_event:findParent(GameEvent.Turn)  --抄占梦
            if turn_event ~= nil then
              index = index - 1
            end
            if index > 0 then
              current_event = all_turn_events[index]
              U.getEventsByRule(room, GameEvent.Phase, 1, function(e)  --反查出牌阶段
                if e.data[2] == Player.Play then
                  local current_player = e.data[1]
                  if current_player ~= player then
                    U.getEventsByRule(room, GameEvent.UseCard, 1, function(u)  --反查使用事件
                      local use = u.data[1]
                      if use.from == current_player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
                        local mark = player:getMark("shexue-phase")
                        if mark == 0 then mark = {} end
                        table.insert(mark, use.card.name)
                        room:setPlayerMark(player, "shexue-phase", mark)
                        return true
                      end
                    end, e.id)
                    return true
                  end
                end
              end, current_event.id)
            end
          end
        end
      end
    end
  end,
}
local shexue_viewas = fk.CreateViewAsSkill{
  name = "shexue_viewas",
  interaction = function()
    return UI.ComboBox {choices = {Self:getMark("shexue-tmp")}}
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shexue"
    return card
  end,
}
local shexue_targetmod = fk.CreateTargetModSkill{
  name = "#shexue_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "shexue")
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "shexue")
  end,
}
quanshou:addRelatedSkill(quanshou_trigger)
quanshou:addRelatedSkill(quanshou_targetmod)
Fk:addSkill(shexue_viewas)
shexue:addRelatedSkill(shexue_targetmod)
sunyu:addSkill(quanshou)
sunyu:addSkill(shexue)
Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数不大于体力上限，你可以令其选择一项：1.将手牌摸至体力上限，本回合出牌阶段使用【杀】次数上限-1"..
  "（至多摸五张）；2.其本回合使用牌被抵消后，你摸一张牌。",
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上回合角色出牌阶段使用的最后一张基本牌或普通锦囊牌使用；出牌阶段结束时，你可以令下回合角色于其"..
  "出牌阶段开始时可以将一张牌当你本阶段使用的最后一张基本牌或普通锦囊牌使用（均无距离次数限制）。",
  ["#quanshou-invoke"] = "劝守：是否对 %dest 发动“劝守”？",
  ["#quanshou-choice"] = "劝守：选择 %src 令你执行的一项",
  ["quanshou1"] = "摸牌至体力上限，本回合使用【杀】次数-1",
  ["quanshou2"] = "你本回合使用牌被抵消后，%src摸一张牌",
  ["#shexue-invoke"] = "设学：你可以令下回合角色出牌阶段开始时可以将一张牌当【%arg】使用",
  ["shexue_viewas"] = "设学",
  ["#shexue-use"] = "设学：你可以将一张牌当【%arg】使用",

  ["$quanshou1"] = "曹军势大，不可刚其锋。",
  ["$quanshou2"] = "持重待守，不战而胜十万雄兵。",
  ["$shexue1"] = "虽为武夫，亦需极目汗青。",
  ["$shexue2"] = "武可靖天下，然不能定天下。",
  ["~sunyu"] = "孙氏始得江东，奈何魂归黄泉……",
}

local ganfurenmifuren = General(extension, "ganfurenmifuren", "shu", 3, 3, General.Female)
local chanjuan = fk.CreateTriggerSkill{
  name = "chanjuan",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
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
  card_filter = Util.FalseFunc,
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
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
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
    if #generals > 0 then
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
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
  end,
}
local xunbie_trigger = fk.CreateTriggerSkill{
  name = "#xunbie_trigger",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("xunbie", Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("xunbie")
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
  ["#xunbie_trigger"] = "殉别",
  ["@@xunbie-turn"] = "殉别",

  ["$chanjuan1"] = "姐妹一心，共侍玄德无忧。",
  ["$chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
  ["$xunbie1"] = "既为君之妇，何惧为君之鬼。",
  ["$xunbie2"] = "今临难将罹，唯求不负皇叔。",
  ["~ganfurenmifuren"] = "人生百年，奈何于我十不存一……",
}

local ganfuren = General(extension, "ty__ganfuren", "shu", 3, 3, General.Female)
local ty__shushen = fk.CreateTriggerSkill{
  name = "ty__shushen",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__shushen-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"ty__shushen_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ty__shushen-choice::"..to.id)
    if choice == "ty__shushen_draw" then
      player:drawCards(1, self.name)
      to:drawCards(1, self.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__shenzhi = fk.CreateTriggerSkill{
  name = "ty__shenzhi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:getHandcardNum() > player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ty__shenzhi-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ganfuren:addSkill(ty__shushen)
ganfuren:addSkill(ty__shenzhi)
Fk:loadTranslationTable{
  ["ty__ganfuren"] = "甘夫人",
  ["ty__shushen"] = "淑慎",
  [":ty__shushen"] = "当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。",
  ["ty__shenzhi"] = "神智",
  [":ty__shenzhi"] = "准备阶段，若你手牌数大于体力值，你可以弃置一张手牌并回复1点体力。",
  ["#ty__shushen-choose"] = "淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌",
  ["#ty__shushen-choice"] = "淑慎：选择令 %dest 执行的一项",
  ["ty__shushen_draw"] = "各摸一张牌",
  ["#ty__shenzhi-invoke"] = "神智：你可以弃置一张手牌，回复1点体力",

  ["$ty__shushen1"] = "妾身无恙，相公请安心征战。",
  ["$ty__shushen2"] = "船到桥头自然直。",
  ["$ty__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$ty__shenzhi2"] = "阿斗，相信妈妈，没事的。",
  ["~ty__ganfuren"] = "请替我照顾好阿斗……",
}

local mifuren = General(extension, "ty__mifuren", "shu", 3, 3, General.Female)
local ty__guixiu = fk.CreateTriggerSkill{
  name = "ty__guixiu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TurnStart then
        return player:getMark(self.name) == 0
      else
        return data.name == "ty__cunsi" and player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      player:drawCards(2, self.name)
      room:setPlayerMark(player, self.name, 1)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__cunsi = fk.CreateActiveSkill{
  name = "ty__cunsi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#ty__cunsi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:handleAddLoseSkills(target, "ty__yongjue", nil, true, false)
    if target ~= player then
      player:drawCards(2, self.name)
    end
  end,
}
local ty__yongjue = fk.CreateTriggerSkill{
  name = "ty__yongjue",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__yongjue-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__yongjue_time"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "ty__yongjue_obtain")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "ty__yongjue_time" then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
mifuren:addSkill(ty__guixiu)
mifuren:addSkill(ty__cunsi)
mifuren:addRelatedSkill(ty__yongjue)
Fk:loadTranslationTable{
  ["ty__mifuren"] = "糜夫人",
  ["ty__guixiu"] = "闺秀",
  [":ty__guixiu"] = "锁定技，你获得此技能后的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。",
  ["ty__cunsi"] = "存嗣",
  [":ty__cunsi"] = "限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张牌。",
  ["ty__yongjue"] = "勇决",
  [":ty__yongjue"] = "当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。",
  ["#ty__cunsi"] = "存嗣：你可以令一名角色获得〖勇决〗，若不为你，你摸两张牌",
  ["#ty__yongjue-invoke"] = "勇决：你可以令此%arg不计入使用次数，或获得之",
  ["ty__yongjue_time"] = "不计入次数",
  ["ty__yongjue_obtain"] = "获得之",

  ["$ty__guixiu1"] = "闺楼独看花月，倚窗顾影自怜。",
  ["$ty__guixiu2"] = "闺中女子，亦可秀气英拔。",
  ["$ty__cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$ty__cunsi2"] = "一切，便托付将军了！",
  ["$ty__yongjue1"] = "能救一个是一个！",
  ["$ty__yongjue2"] = "扶幼主，成霸业！",
  ["~ty__mifuren"] = "阿斗被救，妾身……再无牵挂……",
}

--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|heart,diamond"))
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|spade,club"))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name, "#pianchong-choice")
    room:setPlayerMark(player, "@pianchong", choice)
    return true
  end,
}
local pianchong_delay = fk.CreateTriggerSkill{
  name = "#pianchong_delay",
  mute = true,
  events = {fk.TurnStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local color = player:getMark("@pianchong")
    if event == fk.TurnStart then
      return target == player and color ~= 0
    elseif not player.dead and color ~= 0 then
      local times = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if Fk:getCardById(info.cardId):getColorString() == color then
                times = times + 1
              end
            end
          end
        end
      end
      if times > 0 then
        self.cost_data = times
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "@pianchong", 0)
    else
      local pattern
      local color = player:getMark("@pianchong")
      if color == "red" then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
      local n = self.cost_data
      local cards = room:getCardsFromPileByRule(pattern, n)
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
pianchong:addRelatedSkill(pianchong_delay)
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local player = Fk:currentRoom():getPlayerById(Self.id)
      return (player:getMark("zunwei1") == 0 and #player:getCardIds("h") < #target.player_cards[Player.Hand]) or
        (player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip]) or
        (player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp)
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {}
    if player:getMark("zunwei1") == 0 and #player:getCardIds("h") < #target.player_cards[Player.Hand] then
      table.insert(choices, "zunwei1")
    end
    if player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] then
      table.insert(choices, "zunwei2")
    end
    if player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp then
      table.insert(choices, "zunwei3")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zunwei1" then
      player:drawCards(math.min(#target.player_cards[Player.Hand] - #player:getCardIds("h"), 5), self.name)
    elseif choice == "zunwei2" then
      local n = #target.player_cards[Player.Equip] - #player.player_cards[Player.Equip]
      for i = 1, n, 1 do
        local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          for _, type in ipairs(types) do
            if card.sub_type == type and player:getEquipment(type) == nil then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
        end
        if #cards > 0 then
          room:useCard({
            from = player.id,
            tos = {{player.id}},
            card = Fk:getCardById(table.random(cards)),
          })
        end
      end
    elseif choice == "zunwei3" then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), target.hp - player.hp),
        recoverBy = player,
        skillName = self.name}
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，"..
  "2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["@pianchong"] = "偏宠",
  ["#pianchong-choice"] = "偏宠：选择一种颜色，失去此颜色的牌时，摸另一种颜色的牌",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
  ["~guozhao"] = "我的出身，不配为后？",
}

local fanyufeng = General(extension, "fanyufeng", "qun", 3, 3, General.Female)
local bazhan = fk.CreateActiveSkill{
  name = "bazhan",
  anim_type = "switch",
  switch_skill_name = "bazhan",
  prompt = function ()
    return Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang and "#bazhan-Yang" or "#bazhan-Yin"
  end,
  target_num = 1,
  max_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self:getMaxCardNum() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum() and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    local to_check = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_check, effect.cards)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_check)
      room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    elseif not isYang and not target:isKongcheng() then
      to_check = room:askForCardsChosen(player, target, 1, 2, "h", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_check)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_check, function (id)
    return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askForChoice(player, choices, self.name, "#bazhan-support::" .. target.id)
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = self.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
}
local jiaoying = fk.CreateTriggerSkill{
  name = "jiaoying",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
              if to:getMark("@jiaoying-turn") == 0 then
                room:setPlayerMark(to, "@jiaoying-turn", {})
              end
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
    player.room:setPlayerMark(target, "@jiaoying-turn", {"jiaoying_usedcard"})
  end,
}
local jiaoying_delay = fk.CreateTriggerSkill{
  name = "#jiaoying_delay",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      self.cost_data = #jiaoying_targets - #jiaoying_ignores
      if self.cost_data > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = player.room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5 end), Util.IdMapper), 1, x, "#jiaoying-choose:::" .. x, self.name, true)
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5-to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiaoying_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
  prohibit_response = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
}
jiaoying:addRelatedSkill(jiaoying_delay)
jiaoying:addRelatedSkill(jiaoying_prohibit)
fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "然后若这些牌里包括【酒】或<font color='red'>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。",
  ["jiaoying"] = "醮影",
  ["#jiaoying_delay"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，"..
  "若其本回合没有再使用牌，你令一名角色将手牌摸至五张。",
  ["#bazhan-Yang"] = "把盏（阳）：选择一至两张手牌，交给一名其他角色",
  ["#bazhan-Yin"] = "把盏（阴）：选择一名有手牌的其他角色，获得其一至两张手牌",
  ["#bazhan-support"] = "把盏：可以选择令 %dest 回复1点体力或复原武将牌",
  ["#jiaoying-choose"] = "醮影：可选择至多%arg名角色将手牌补至5张",
  ["@jiaoying-turn"] = "醮影",
  ["jiaoying_usedcard"] = "使用过牌",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
  ["~fanyufeng"] = "醮妇再遇良人难……",
}

local ruanyu = General(extension, "ruanyu", "wei", 3)
local xingzuo = fk.CreateTriggerSkill{
  name = "xingzuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    cards = table.reverse(cards)
    --FIXME:从牌堆底获取牌是逆序的……
    local handcards = player:getCardIds(Player.Hand)
    local to_buttom = room:askForPoxi(player, "xingzuo", {
      { "牌堆底", cards },
      { "手牌区", handcards },
    })
    if #to_buttom ~= 3 then
      to_buttom = cards
    end
    local moveInfos = {}
    local drawPilePosition = #room.draw_pile
    for i = 1, 3, 1 do
      local id = to_buttom[i]
      if table.contains(cards, id) then
        table.insert(room.draw_pile, id)
      else
        table.insert(moveInfos, {
          ids = {id},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = drawPilePosition + i,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    cards = table.filter(cards, function (id)
      return not table.contains(to_buttom, id)
    end)
    if #cards == 0 then return false end
    if player.dead then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true)
    else
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
  end,
}
Fk:addPoxiMethod{
  name = "xingzuo",
  card_filter = function(to_select, selected, data)
    return #selected < 3
  end,
  feasible = function(selected, data)
    return #selected == 0 or #selected == 3
  end,
  prompt = function ()
    return "兴作：选择三张卡牌以点击的顺序置于牌堆底"
  end
}
local xingzuo_delay = fk.CreateTriggerSkill{
  name = "#xingzuo_delay",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xingzuo-choose", xingzuo.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xingzuo.name)
    local to = room:getPlayerById(self.cost_data)
    local cards = to:getCardIds(Player.Hand)
    local n = #cards
    room:moveCards({
      from = to.id,
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = xingzuo.name,
      moveVisible = false,
    })
    if not to.dead then
      room:moveCardTo(room:getNCards(3, "bottom"), Card.PlayerHand, to, fk.ReasonExchange, xingzuo.name, nil, false, player.id)
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      cards = table.random(cards, #cards)
      room:moveCards({
        ids = cards,
        fromArea = Card.Processing,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonExchange,
        skillName = xingzuo.name,
        moveVisible = false,
        drawPilePosition = -1,
      })
    end
    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
}

local miaoxian = fk.CreateViewAsSkill{
  name = "miaoxian",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function()
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    local names, all_names = {} , {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcard(blackcards[1])
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insert(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
}
local miaoxian_trigger = fk.CreateTriggerSkill{
  name = "#miaoxian_trigger",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and data.card.color == Card.Red and
      not (data.card:isVirtual() and #data.card.subcards ~= 1)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
}
xingzuo:addRelatedSkill(xingzuo_delay)
miaoxian:addRelatedSkill(miaoxian_trigger)
ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，"..
  "你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",
  ["#xingzuo-invoke"] = "兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌",
  ["#xingzuo_delay"] = "兴作",
  ["#xingzuo-choose"] = "兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力",
  ["#miaoxian_trigger"] = "妙弦",
  ["#miaoxian"] = "妙弦：将手牌中的黑色牌当任意锦囊牌使用",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
  ["~ruanyu"] = "良时忽过，身为土灰。",
}

local yangwan = General(extension, "ty__yangwan", "shu", 3, 3, General.Female)
local youyan = fk.CreateTriggerSkill{
  name = "youyan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoked = true
              end
            end
          else
            local room = player.room
            local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if parentPindianEvent then
              local pindianData = parentPindianEvent.data[1]
              if pindianData.from == player then
                local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoked = true
                  end
                end
              end
              for toId, result in pairs(pindianData.results) do
                if player.id == toId then
                  local leftToCardIds = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoked = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if can_invoked and #suits > 0 then
        self.cost_data = suits
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = self.cost_data
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local zhuihuan = fk.CreateTriggerSkill{
  name = "zhuihuan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#zhuihuan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,
}
local zhuihuan_delay = fk.CreateTriggerSkill{
  name = "#zhuihuan_delay",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("zhuihuan") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "zhuihuan", 0)
    local mark = U.getMark(player, "zhuihuan_record")
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return table.contains(mark, p.id)
    end)
    room:setPlayerMark(player, "zhuihuan_record", 0)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        if p.hp > player.hp then
          room:damage({
            from = player,
            to = p,
            damage = 2,
            damageType = fk.NormalDamage,
            skillName = "zhuihuan"
          })
        else
          local cards = table.filter(p:getCardIds(Player.Hand), function (id)
            return not p:prohibitDiscard(Fk:getCardById(id))
          end)
          cards = table.random(cards, 2)
          if #cards > 0 then
            room:throwCard(cards, "zhuihuan", p, p)
          end
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("zhuihuan") ~= 0 and data.from
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "zhuihuan_record")
    table.insert(mark, data.from.id)
    room:setPlayerMark(player, "zhuihuan_record", mark)
  end,
}
zhuihuan:addRelatedSkill(zhuihuan_delay)
yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。",
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色："..
  "若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。",
  ["#zhuihuan-choose"] = "追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌",
  ["#zhuihuan_delay"] = "追还",

  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
  ["~ty__yangwan"] = "遇人不淑……",
}

local panshu = General(extension, "ty__panshu", "wu", 3, 3, General.Female)
local zhiren = fk.CreateTriggerSkill{
  name = "zhiren",
  anim_type = "control",
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not data.card:isVirtual() and
      (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      if player:getMark("zhiren-turn") == 0 then
        player.room:setPlayerMark(player, "zhiren-turn", 1)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #Fk:translate(data.card.trueName) / 3
    room:askForGuanxing(player, room:getNCards(n), nil, nil, "", false)
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren1-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "e", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren2-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "j", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
    if n > 3 then
      player:drawCards(3, self.name)
    end
  end,
}
local yaner = fk.CreateTriggerSkill{
  name = "yaner",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local to = player.room:getPlayerById(move.from)
              if to:isKongcheng() and to.phase == Player.Play and not to.dead then
                self.cost_data = move.from
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yaner-invoke::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards1 = player:drawCards(2, self.name)
    local cards2 = to:drawCards(2, self.name)
    if Fk:getCardById(cards1[1]).type == Fk:getCardById(cards1[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to:isWounded() and Fk:getCardById(cards2[1]).type == Fk:getCardById(cards2[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
}
panshu:addSkill(zhiren)
panshu:addSkill(yaner)
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌时，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",
  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果",
  ["@@yaner"] = "燕尔",

  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

return extension
