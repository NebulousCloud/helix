--[[
	Purpose: Quick library to add phrases based off a key or retrieve it.
	Used throughout the framework to make language customization easier,
	rather than searching through the files.
--]]

nut.lang = nut.lang or {}
nut.lang.phrases = nut.lang.phrases or {}

--[[
	Purpose: Adds a phrase that can be identified by a key to the list
	of phrases.
--]]
function nut.lang.Add(key, value, language)
	language = language or "english"

	nut.lang.phrases[language] = nut.lang.phrases[language] or {}
	nut.lang.phrases[language][key] = value
end

--[[
	Purpose: Returns the corresponding phrase based off the key, substituting
	%s in phrases with the arguments provided. If the translation doesn't exist,
	it will return <missing translation>.

	Example:
		nut.lang.Add("praise", "%s is awesome, just like %s.")
		print(nut.lang.Get("praise", "NutScript", "pie"))

		Would return:
			> NutScript is awesome, just like pie.
--]]
function nut.lang.Get(key, ...)
	local language = nut.config.language or "english"

	if (nut.lang.phrases[language] and nut.lang.phrases[language][key]) then
		return string.format(nut.lang.phrases[language][key], ...)
	else
		return "<missing "..key..">"
	end
end

--[[
	Quick function to return the lowercase form of a phrase.
--]]
function nut.lang.GetLower(key, ...)
	return string.lower(nut.lang.Get(key, ...))
end