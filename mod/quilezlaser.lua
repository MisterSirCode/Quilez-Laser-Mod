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
local maxLaserDepth = 10
local qlDeflectors = {}

function updateLaserMode()
	SetInt("savegame.mod.laserMode", GetInt("savegame.mod.laserMode") + 1)
	if (GetInt("savegame.mod.laserMode") > #laserNames) then
		SetInt("savegame.mod.laserMode", 1)
	end
end

-- function shootLaser(body, shape, origin, dir, currentLength, deflectorsHit)
-- 	QueryRequire("physical")
-- 	if shape ~= 0 then
-- 		QueryRejectShape(shape)
-- 	end
-- 	if body ~= 0 then
-- 		QueryRejectBody(body)
-- 	end
-- 	local hit, hitDist, hitNormal, hitShape = QueryRaycast(origin, dir, maxDist, 0.0, true)
-- 	local length = maxDist
-- 	if hit then
-- 		length = hitDist
-- 	end
-- 	local hitPoint = VecAdd(origin, VecScale(dir, length))
-- 	local t = Transform(VecLerp(origin, hitPoint, 0.5))
-- 	local xAxis = VecNormalize(VecSub(hitPoint, origin))
-- 	local zAxis = VecNormalize(VecSub(origin, GetCameraTransform().pos))
-- 	t.rot = QuatAlignXZ(xAxis, zAxis)
-- 	DrawSprite(laserSpriteOg, t, length, 0.05 + math.random() * 0.01, 8, 4, 4, 1, true, true)
-- 	local col = laserColors[GetInt("savegame.mod.laserMode")]
-- 	DrawSprite(laserSpriteOg, t, length, 0.5, col[1], col[2], col[3], 1, true, true)
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror2") and currentLength < maxDist then
-- 		local alreadyHit = false
-- 		for i = 1, #deflectorsHit do
-- 			if deflectorsHit[i] == hitBody then
-- 				alreadyHit = true
-- 				break
-- 			end
-- 		end
-- 		if not alreadyHit then
-- 			deflectorsHit[#deflectorsHit+1] = hitBody
-- 			local t = GetBodyTransform(hitBody)
-- 			local refDir = TransformToParentVec(t, Vec(0, 0, 1))
-- 			SetShapeEmissiveScale(hitShape, 1)
-- 			return shootLaser(hitBody, hitShape, t.pos, refDir, currentLength + length, deflectorsHit)
-- 		end
-- 	end
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror") and currentLength < maxDist then
-- 		local refDir = VecSub(dir, VecScale(hitNormal, VecDot(hitNormal, dir) * 2))
-- 		return shootLaser(hitBody, hitShape, hitPoint, refDir, currentLength + length, deflectorsHit)
-- 	end
-- 	return currentLength + length, hitPoint, hitBody, hitShape
-- end

function drawlaserSprite(pos1, pos2, color, size)
    visual.drawline(laserSprite, pos1, pos2, {
        r = color[1], 
        g = color[2], 
        b = color[3],
        additive = true,
        width = size
    })
end

function drawLaser(startpos, endpos, col, brt)
	PointLight(endpos, col[1], col[2], col[3], 1)
	PointLight(endpos, brt[1], brt[2], brt[3], 0.01)
	drawlaserSprite(startpos, endpos, col, 0.5)
	drawlaserSprite(startpos, endpos, brt, 0.05)
end

function drawLaserRecursive(initPos, target, dir, mode, col, brt, dt, depth)
	local curDepth = depth
	local reflected = dir - target.normal * target.normal:Dot(dir) * 2
	if (target.shape:GetBody()):HasTag('mirror2') then
	elseif (target.shape:GetBody()):HasTag('mirror') then
		if depth <= maxLaserDepth then
			drawLaser(initPos, target.hitpos, col, brt)
			local rot = QuatLookAt(target.hitpos, target.hitpos * target.normal)
			local newTarget = (Transformation(target.hitpos, rot)):Raycast(maxDist, 1)
			drawLaser(target.hitpos, newTarget.hitpos, col, brt)
			drawLaserRecursive(newTarget.hitpos, newTarget, reflected, mode, col, brt, dt, depth + 1)
		end
	else
		drawLaser(initPos, target.hitpos, col, brt)
		-- No mirror or deflector, business as usual
		if mode == 1 then
			MakeHole(target.hitpos, 0.5, 0.3, 0.1, true)
			SpawnFire(target.hitpos)
		elseif mode == 2 then
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

function tool:Tick(dt)
	if GetBool("game.player.canusetool") then
		SetToolTransform(toolpos)
		local target = PLAYER:GetCamera():Raycast(maxDist, -1)
		local mode = GetInt("savegame.mod.laserMode")
		if InputPressed("alt") then
			updateLaserMode()
		end
		if InputDown("lmb") then
			local col = laserColors[GetInt("savegame.mod.laserMode")]
			local brt = brightness[GetInt("savegame.mod.laserMode")]
			local length = 0;
			local newCol = {};
			local dir = (target.hitpos - self:GetBoneGlobalTransform('nozzle').pos):Normalize()
			local hitBody = GetEntityHandle(target.shape:GetBody())
			drawLaserRecursive(self:GetBoneGlobalTransform('nozzle').pos, target, dir, mode, col, brt, dt, 0)
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
        {'laserbase', Vec(7, 12, 7)}
    }
}

RegisterToolUMF('quilezlaser', tool)

function draw()
	local mode = GetInt("savegame.mod.laserMode")
	if GetString("game.player.tool") == "quilezlaser" then
		UiAlign("center bottom")
		UiTranslate(UiCenter(), UiHeight() - 100)
		UiFont("bold.ttf", 24)
		UiTextShadow(0, 0, 0, 0.5, 1.5)
		local col = laserColors[mode]
		UiColor(col[1] / 2 + 0.5, col[2] / 2 + 0.5, col[3] / 2 + 0.5)
		UiText(laserNames[mode], true)
		UiFont("bold.ttf", 16)
		UiText("Press ALT to Switch Modes", true)
	end
end