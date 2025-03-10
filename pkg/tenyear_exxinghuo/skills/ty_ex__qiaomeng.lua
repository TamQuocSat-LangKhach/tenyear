local ty_ex__qiaomeng = fk.CreateSkill {
  name = "ty_ex__qiaomeng"
}

Fk:loadTranslationTable{
  ['ty_ex__qiaomeng'] = '趫猛',
  ['#ty_ex__qiaomeng-choose'] = '趫猛：弃置一名其他目标角色的一张牌',
  [':ty_ex__qiaomeng'] = '当你使用黑色牌指定目标后，你可以弃置其中一名其他目标角色的一张牌，若此牌为：锦囊牌，此黑色牌不能被响应；装备牌，你改为获得之。',
  ['$ty_ex__qiaomeng1'] = '猛士骁锐，可慑百蛮失蹄！',
  ['$ty_ex__qiaomeng2'] = '锐士志猛，可凭白手夺马！',
}

ty_ex__qiaomeng:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__qiaomeng.name) and data.card and data.card.color == Card.Black and data.firstTarget
      and table.find(AimGroup:getAllTargets(data.tos), function(pid)
        return pid ~= player.id and not player.room:getPlayerById(pid):isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function(pid)
      return pid ~= player.id and not room:getPlayerById(pid):isNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.map(targets, Util.IdMapper),
      prompt = "#ty_ex__qiaomeng-choose",
      skill_name = ty_ex__qiaomeng.name
    })
    if #tos > 0 then
      event:setCostData(self, tos[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local cid = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = ty_ex__qiaomeng.name
    })
    local card = Fk:getCardById(cid, true)
    if card.type == Card.TypeEquip then
      room:obtainCard(player, cid, false, fk.ReasonPrey)
    else
      room:throwCard({cid}, ty_ex__qiaomeng.name, to, player)
      if card.type == Card.TypeTrick then
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      end
    end
  end,
})

return ty_ex__qiaomeng
