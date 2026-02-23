--[[
	GhostCompression.lua - Speed Run Universe

	Compresses ghost replay data for efficient DataStore storage
	Uses delta encoding to reduce size by 60-80%

	CRITICAL FIX: Prevents DataStore quota issues with large ghost recordings
]]

local HttpService = game:GetService("HttpService")

local GhostCompression = {}

-- Maximum ghost data size (100KB recommended, DataStore max is 4MB)
local MAX_GHOST_SIZE = 100000 -- bytes

--[[
	Compresses ghost frames using delta encoding
	@param frames table - Array of frame data {Time, Position, Rotation}
	@return string - JSON-encoded compressed data
]]
function GhostCompression.CompressGhost(frames: {{}}): string
	if not frames or #frames == 0 then
		return "[]"
	end

	local compressed = {}
	local lastPos = Vector3.new(0, 0, 0)
	local lastTime = 0

	for i, frame in ipairs(frames) do
		if i == 1 then
			-- First frame: store full data
			table.insert(compressed, {
				T = frame.Time,
				P = {frame.Position.X, frame.Position.Y, frame.Position.Z},
				-- Rotation simplified (can add if needed)
			})
			lastPos = frame.Position
			lastTime = frame.Time
		else
			-- Delta encoding: store difference from last frame
			local deltaPos = frame.Position - lastPos
			local deltaTime = frame.Time - lastTime

			-- Only store if changed significantly (skip redundant frames)
			if deltaPos.Magnitude > 0.05 or deltaTime > 0.25 then
				table.insert(compressed, {
					DT = math.floor(deltaTime * 100) / 100, -- Round to 0.01s precision
					DP = {
						math.floor(deltaPos.X * 10) / 10, -- Round to 0.1 stud precision
						math.floor(deltaPos.Y * 10) / 10,
						math.floor(deltaPos.Z * 10) / 10
					}
				})

				lastPos = frame.Position
				lastTime = frame.Time
			end
		end
	end

	-- Convert to JSON
	local json = HttpService:JSONEncode(compressed)

	-- Check size
	if #json > MAX_GHOST_SIZE then
		warn(string.format("[GhostCompression] Ghost too large: %d bytes (max: %d)",
			#json, MAX_GHOST_SIZE))

		-- Reduce frame rate by skipping frames
		return GhostCompression.CompressGhostAggressive(frames)
	end

	print(string.format("[GhostCompression] Compressed %d frames to %d bytes (%.1f%% of original)",
		#frames, #json, (#json / (#frames * 50)) * 100)) -- Estimate original size

	return json
end

--[[
	Aggressive compression by reducing frame rate
	@param frames table - Original frames
	@return string - Compressed data
]]
function GhostCompression.CompressGhostAggressive(frames: {{}}): string
	-- Skip every other frame (reduce to 5 FPS from 10 FPS)
	local reduced = {}
	for i = 1, #frames, 2 do
		table.insert(reduced, frames[i])
	end

	print(string.format("[GhostCompression] Reducing frames from %d to %d for size",
		#frames, #reduced))

	return GhostCompression.CompressGhost(reduced)
end

--[[
	Decompresses ghost data back to original format
	@param data string - JSON-encoded compressed data
	@return table - Array of frames
]]
function GhostCompression.DecompressGhost(data: string): {{}}
	if not data or data == "[]" or data == "" then
		return {}
	end

	local success, compressed = pcall(function()
		return HttpService:JSONDecode(data)
	end)

	if not success or not compressed then
		warn("[GhostCompression] Failed to decode ghost data")
		return {}
	end

	local frames = {}
	local currentPos = Vector3.new(0, 0, 0)
	local currentTime = 0

	for i, frame in ipairs(compressed) do
		if frame.P then
			-- Full frame
			currentPos = Vector3.new(unpack(frame.P))
			currentTime = frame.T
		else
			-- Delta frame
			if frame.DP then
				currentPos = currentPos + Vector3.new(unpack(frame.DP))
			end
			currentTime = currentTime + (frame.DT or 0)
		end

		table.insert(frames, {
			Time = currentTime,
			Position = currentPos,
			Rotation = CFrame.new() -- Simplified (rotation not stored)
		})
	end

	return frames
end

--[[
	Gets the compressed size of ghost data
	@param data string - Compressed ghost data
	@return number - Size in bytes
]]
function GhostCompression.GetSize(data: string): number
	return #data
end

--[[
	Validates ghost data size is within limits
	@param data string - Compressed ghost data
	@return boolean - True if size is acceptable
]]
function GhostCompression.ValidateSize(data: string): boolean
	return #data <= MAX_GHOST_SIZE
end

return GhostCompression
