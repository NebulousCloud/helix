nut.currency = nut.currency or {}
nut.currency.symbol = nut.currency.symbol or "$"
nut.currency.singular = nut.currency.singular or "dollar"
nut.currency.plural = nut.currency.plural or "dollars"

function nut.currency.set(symbol, singular, plural)
	nut.currency.symbol = symbol
	nut.currency.singular = singular
	nut.currency.plural = plural
end

function nut.currency.get(amount)
	if (amount == 1) then
		return nut.currency.symbol.."1 "..nut.currency.singular
	else
		return nut.currency.symbol..amount.." "..nut.currency.plural
	end
end

do
	local character = FindMetaTable("Character")

	function character:hasMoney(amount)
		return self:getMoney() >= amount
	end

	function character:giveMoney(amount)
		self:setMoney(self:getMoney() + amount)
	end

	function character:takeMoney(amount)
		self:giveMoney(-amount)
	end
end