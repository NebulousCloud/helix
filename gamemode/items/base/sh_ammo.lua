
ITEM.name = "Ammo Base"
ITEM.model = "models/Items/BoxSRounds.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.ammo = "pistol" -- type of the ammo
ITEM.ammoAmount = 30 -- amount of the ammo
ITEM.description = "A Box that contains %s of Pistol Ammo"
ITEM.category = "Ammunition"
ITEM.useSound = "items/ammo_pickup.wav"

function ITEM:GetDescription()
	local rounds = self:GetData("rounds", self.ammoAmount)
	return Format(self.description, rounds)
end

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		draw.SimpleText(
			item:GetData("rounds", item.ammoAmount), "DermaDefault", w - 5, h - 5,
			color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black
		)
	end
end

ITEM.functions.use = {
	name = "Load",
	tip = "useTip",
	icon = "icon16/add.png",
	OnRun = function(item)
		local rounds = item:GetData("rounds", item.ammoAmount)

		item.player:GiveAmmo(rounds, item.ammo)
		item.player:EmitSound(item.useSound, 110)

		return true
	end,
}

ITEM.functions.Split = {
	name = "Split",
	tip = "Splits the ammo in half.",
	icon = "icon16/arrow_divide.png",
	OnRun = function(item)
		local client = item.player
		local rounds = item:GetData("rounds", item.ammoAmount)

		local status, _ = client:GetCharacter():GetInventory():Add(item.uniqueID, 1, {rounds = math.ceil(rounds / 2)})

		-- Bail out if the item does not fit
		if (!status) then
			client:NotifyLocalized("noFit")
			return false
		end

		item:SetData("rounds", math.floor(rounds / 2))

		client:EmitSound(item.useSound, 110)

		return false
	end,
	OnCanRun = function(item)
		return item:GetData("rounds", item.ammoAmount) > 1
	end
}

-- Called after the item is registered into the item tables.
function ITEM:OnRegistered()
	if (ix.ammo) then
		ix.ammo.Register(self.ammo)
	end
end
