
function ix.util.InstallAnimationMethods(meta)
	local function TweenAnimationThink(object)
		for k, v in pairs(object.tweenAnimations) do
			if (!v.bShouldPlay) then
				continue
			end

			local bComplete = v:update(FrameTime())

			if (v.Think) then
				v:Think(object)
			end

			if (bComplete) then
				v.bShouldPlay = nil

				v:ForceComplete()

				if (v.OnComplete) then
					v:OnComplete(object)
				end

				if (v.bRemoveOnComplete) then
					object.tweenAnimations[k] = nil
				end
			end
		end
	end

	function meta:GetTweenAnimation(index, bNoPlay)
		-- if we don't need to check if the animation is playing we can just return the animation
		if (bNoPlay) then
			return self.tweenAnimations[index]
		else
			for k, v in pairs(self.tweenAnimations or {}) do
				if (k == index and v.bShouldPlay) then
					return v
				end
			end
		end
	end

	function meta:IsPlayingTweenAnimation(index)
		for k, v in pairs(self.tweenAnimations or {}) do
			if (v.bShouldPlay and index == k) then
				return true
			end
		end

		return false
	end

	function meta:StopAnimations(bRemove)
		for k, v in pairs(self.tweenAnimations or {}) do
			if (v.bShouldPlay) then
				v:ForceComplete()

				if (bRemove) then
					self.tweenAnimations[k] = nil
				end
			end
		end
	end

	function meta:CreateAnimation(length, data)
		local animations = self.tweenAnimations or {}
		self.tweenAnimations = animations

		if (self.SetAnimationEnabled) then
			self:SetAnimationEnabled(true)
		end

		local index = data.index or 1
		local bCancelPrevious = data.bCancelPrevious == nil and false or data.bCancelPrevious
		local bIgnoreConfig = SERVER or (data.bIgnoreConfig == nil and false or data.bIgnoreConfig)

		if (bCancelPrevious and self:IsPlayingTweenAnimation()) then
			for _, v in pairs(animations) do
				v:set(v.duration)
			end
		end

		local animation = ix.tween.new(
			((length == 0 and 1 or length) or 1) * (bIgnoreConfig and 1 or ix.option.Get("animationScale", 1)),
			data.subject or self,
			data.target or {},
			data.easing or "linear"
		)

		animation.index = index
		animation.bIgnoreConfig = bIgnoreConfig
		animation.bAutoFire = (data.bAutoFire == nil and true or data.bAutoFire)
		animation.bRemoveOnComplete = (data.bRemoveOnComplete == nil and true or data.bRemoveOnComplete)
		animation.Think = data.Think
		animation.OnComplete = data.OnComplete

		animation.ForceComplete = function(anim)
			anim:set(anim.duration)
		end

		-- @todo don't use ridiculous method chaining
		animation.CreateAnimation = function(currentAnimation, newLength, newData)
			newData.bAutoFire = false
			newData.index = currentAnimation.index + 1

			local oldOnComplete = currentAnimation.OnComplete
			local newAnimation = currentAnimation.subject:CreateAnimation(newLength, newData)

			currentAnimation.OnComplete = function(...)
				if (oldOnComplete) then
					oldOnComplete(...)
				end

				newAnimation:Fire()
			end

			return newAnimation
		end

		if (length == 0 or (!animation.bIgnoreConfig and ix.option.Get("disableAnimations", false))) then
			animation.Fire = function(anim)
				anim:set(anim.duration)
				anim.bShouldPlay = true
			end
		else
			animation.Fire = function(anim)
				anim:set(0)
				anim.bShouldPlay = true
			end
		end

		-- we can assume if we're using this library, we're not going to use the built-in
		-- AnimationTo functions, so override AnimationThink with our own
		self.AnimationThink = TweenAnimationThink

		-- fire right away if autofire is enabled
		if (animation.bAutoFire) then
			animation:Fire()
		end

		self.tweenAnimations[index] = animation
		return animation
	end
end

if (CLIENT) then
	local panelMeta = FindMetaTable("Panel")
	ix.util.InstallAnimationMethods(panelMeta)
end
