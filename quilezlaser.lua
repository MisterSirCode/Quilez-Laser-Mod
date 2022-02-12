local laserColors = {
	{1, 0.3, 0.3},
	{0.6, 0.3, 1},
	{1, 0.6, 0.3}
}
local brightness = {
    {8, 5, 5},
    {5, 6, 8},
    {8, 6, 5}
}
local laserNames = {
	"Classic Quilez Plasma Laser",
	"Pressurized Cold Plasma Laser",
	"Low Power Infrared Laser"
}
local toolpos = Transform(Vec(0.8, -0.6, -1.0), QuatEuler(0, 0, 0))
local tool = {
    printname = "Quilez Laser",
    group = 6,
    ammo = 10000
}
local maxDist = 1000

function updateLaserMode()
	SetInt("savegame.mod.laserMode", GetInt("savegame.mod.laserMode") + 1)
	if (GetInt("savegame.mod.laserMode") > #laserNames) then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function shootLaser(body, shape, origin, dir, currentLength, deflectorsHit)
	QueryRequire("physical")
	if shape ~= 0 then
		QueryRejectShape(shape)
	end
	if body ~= 0 then
		QueryRejectBody(body)
	end
	local hit, hitDist, hitNormal, hitShape = QueryRaycast(origin, dir, maxDist, 0.0, true)
	local length = maxDist
	if hit then
		length = hitDist
	end
	local hitPoint = VecAdd(origin, VecScale(dir, length))
	local t = Transform(VecLerp(origin, hitPoint, 0.5))
	local xAxis = VecNormalize(VecSub(hitPoint, origin))
	local zAxis = VecNormalize(VecSub(origin, GetCameraTransform().pos))
	t.rot = QuatAlignXZ(xAxis, zAxis)
	DrawSprite(laserSpriteOg, t, length, 0.05 + math.random() * 0.01, 8, 4, 4, 1, true, true)
	local col = laserColors[GetInt("savegame.mod.laserMode")]
	DrawSprite(laserSpriteOg, t, length, 0.5, col[1], col[2], col[3], 1, true, true)
	local hitBody = GetShapeBody(hitShape)
	if HasTag(hitBody, "mirror2") and currentLength < maxDist then
		local alreadyHit = false
		for i = 1, #deflectorsHit do
			if deflectorsHit[i] == hitBody then
				alreadyHit = true
				break
			end
		end
		if not alreadyHit then
			deflectorsHit[#deflectorsHit+1] = hitBody
			local t = GetBodyTransform(hitBody)
			local refDir = TransformToParentVec(t, Vec(0, 0, 1))
			SetShapeEmissiveScale(hitShape, 1)
			return shootLaser(hitBody, hitShape, t.pos, refDir, currentLength + length, deflectorsHit)
		end
	end
	local hitBody = GetShapeBody(hitShape)
	if HasTag(hitBody, "mirror") and currentLength < maxDist then
		local refDir = VecSub(dir, VecScale(hitNormal, VecDot(hitNormal, dir) * 2))
		return shootLaser(hitBody, hitShape, hitPoint, refDir, currentLength + length, deflectorsHit)
	end
	return currentLength + length, hitPoint, hitBody, hitShape
end

function drawlaser(pos1, pos2, color, size)
    visual.drawline(laserSprite, pos1, pos2, {
        r = color[1], 
        g = color[2], 
        b = color[3],
        additive = true,
        width = size
    })
end

function tool:Initialize()
	laserReady = 0
	laserFireTime = 0
	laserLoop = LoadLoop("MOD/assets/laser-loop.ogg")
	laserHitLoop = LoadLoop("MOD/assets/laser-hit-loop.ogg")
	laserSprite = LoadSprite("MOD/assets/laser.png")
	laserSpriteOg = LoadSprite("MOD/assets/laserog.png")
	laserDist = 0
	laserHitScale = 0
	deflectors = FindBodies("mirror2", true)
	if GetInt("savegame.mod.laserMode") == 0 then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function tool:Animate()
    local ar = self.armature
    local target = PLAYER:GetCamera():Raycast(maxDist, -1)
    local TinT = self:GetPredictedTransform():ToLocal(target.hitpos)
    ar:SetBoneTransform("root", Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), TinT)))
end

function tool:Deploy()
end

function tool:Holster()
end

function tool:GetTarget()
end

function tool:LeftClick()
end

function tool:RightClick()
end

function tool:LeftClickReleased()
end

function tool:RightClickReleased()
end

function tool:Tick(dt)
	QueryRequire("physical")
    SetToolTransform(toolpos)
    local target = PLAYER:GetCamera():Raycast(maxDist, -1)
    -- local target = self:GetBoneGlobalTransform('root'):Raycast(maxDist, -1)
    if InputPressed("alt") then
        updateLaserMode()
    end
    if InputDown('lmb') then
        local col = laserColors[GetInt("savegame.mod.laserMode")]
        local brt = brightness[GetInt("savegame.mod.laserMode")]
        local newCol = {};
        PointLight(target.hitpos, col[1], col[2], col[3], 1)
        PointLight(target.hitpos, brt[1], brt[2], brt[3], 0.01)
        PointLight(self:GetBoneGlobalTransform('tip').pos, col[1], col[2], col[3], 1)
        drawlaser(self:GetBoneGlobalTransform('nozzle').pos, target.hitpos, col, 0.5)
        drawlaser(self:GetBoneGlobalTransform('nozzle').pos, target.hitpos, brt, 0.05)
        local body = GetShapeBody(target.shape)
        local dir = VecNormalize(VecSub(target.hitpos, self:GetBoneGlobalTransform('nozzle').pos))
        if HasTag(body, "mirror2") then
			local alreadyHit = false
			for i = 1, #deflectorsHit do
				if deflectorsHit[i] == hitBody then
					alreadyHit = true
					break
				end
			end
			if not alreadyHit then
				deflectorsHit[#deflectorsHit+1] = hitBody
				local t = GetBodyTransform(hitBody)
				local refDir = TransformToParentVec(t, Vec(0, 0, 1))
				SetShapeEmissiveScale(hitShape, 1)
				local length, hitPoint, hitBody, hitShape = shootLaser(hitBody, hitShape, t.pos, refDir, currentLength + length, deflectorsHit)
			end
        else
        end
		if GetInt("savegame.mod.laserMode") == 1 then
			MakeHole(target.hitpos, 0.5, 0.3, 0.1, true)
			SpawnFire(target.hitpos)
		elseif GetInt("savegame.mod.laserMode") == 2 then
			local curPos = target.hitpos
			for i=1, 5 do
				curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
				MakeHole(curPos, 0.5, 0.4, 0.3, true)
			end
		else
			local curPos = target.hitpos
			for i=1, 5 do
				curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
				SpawnFire(curPos)
				emitSmoke(curPos, 1.0)
			end
		end
    end
end

tool.model = {
    prefab = [[
<prefab version="0.9.2">
    <group id_="473592032" open_="true" name="laser" pos="0.0 0.0 0.0" rot="0.0 0.0 0.0">
        <group id_="2048256128" open_="true" name="base" pos="0.0 0.0 0.0">
            <vox id_="1640400640" pos="-0.025 -0.175 0.175" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserbase" scale="0.5"/>
        </group>
        <location id_="1100482176" name="nozzle" pos="0.0 0.0 0.275"/>
        <location id_="2067721472" name="tip" pos="0.0 0.0 -0.525"/>
    </group>
</prefab>
    ]],
    objects = {
        {'laserbase', Vec(7, 12, 7)}, -- these sizes were swapped (and the 12 was a 20)
    }
}

RegisterToolUMF('quilezlaser', tool)