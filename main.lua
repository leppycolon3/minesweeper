assetload = require 'assetload'

function table.find(haystack, needle)
	for i, v in pairs(haystack) do
		if v == needle then return i end
	end
end

function table.size(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

function toggleFullscreen()
	love.window.setFullscreen(not love.window.getFullscreen(), "exclusive")
end

function burp(t)
	for i,v in pairs(t) do
		print("i:",i,"v:",v)
	end
end

function plantmine()
	local newmine = {x = love.math.random(board.width), y = love.math.random(board.height)}
	for _,v in ipairs(board.mines) do
		if v.x == newmine.x and v.y == newmine.y then plantmine() return end
	end
	table.insert(board.mines,newmine)
end

function newgame()
	board.tiles = emptyboard()
	board.mines = {}
	
	for m = 1, minesPopulation do
		plantmine()
	end
end

function emptyboard()
	local b = {}
	for y = 1, board.height do
		b[y] = {}
	end
	return b
end

function isempty()
	for _,v in pairs(board.tiles) do
		if table.size(v) > 0 then return false end
	end
	return true
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(.75,.75,.75)
	
	
	board = {}
	board.x = 0
	board.y = 0
	board.width = 16
	board.height = 12
	board.grid = 16
	board.tiles = {}
	board.mines = {}
	minesPopulation = (board.width*board.height)*0.2
	if minesPopulation == board.width*board.height then
		minesPopulation = minesPopulation - 1
	end
	
	newgame()
	
	textures = {}
	textures[-1] = assld("image","assets/img/tile.png")
	for ya = 0, 8 do
		textures[ya] = assld("image", "assets/img/tile"..ya..".png")
	end
	textures["x"] = assld("image","assets/img/tilemine.png")
	textures["marked"] = assld("image","assets/img/tilemarked.png")
	
	
	
	love.window.setMode(board.width*board.grid, board.height*board.grid)
end

function tile(x,y,state)
	board.tiles[y][x] = state
end

function checktile(x,y)
	local count = 0
	for _,v in ipairs(board.mines) do
		if (v.x >= x-1) and (v.x <= x+1) and (v.y >= y-1) and (v.y <= y+1) then
			count = count + 1
		end
	end
	
	return count
end

function revealtile(x,y)
	if x<1 or y<1 or x>board.width or y>board.height then return end
	local t = board.tiles[y][x]
	if t then
		if t == "marked" then
			table.remove(board.tiles[y],x)
		end
		return
	end
	
	
	local fucked = false
	for _, v in ipairs(board.mines) do
		if v.x == x and v.y == y then
			fucked = true
		end
	end
	
	if fucked then
		tile(x,y,"x")
	else
		count = checktile(x,y)
		tile(x,y,count)
		if count == 0 then
			revealtile(x-1,y-1)
			revealtile(x,y-1)
			revealtile(x+1,y-1)
			revealtile(x-1,y)
			revealtile(x+1,y)
			revealtile(x-1,y+1)
			revealtile(x,y+1)
			revealtile(x+1,y+1)
		end
	end
end

function click(mx, my, butt)
	local inboard = (mx >= board.x) and (mx < board.x+board.width*board.grid) and (my >= board.y) and (my < board.y+board.height*board.grid)
	if inboard then
		x = math.floor(mx/board.grid)+1
		y = math.floor(my/board.grid)+1
		if butt == 2 or love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl") then
			if board.tiles[y][x] == "marked" then
				tile(x,y,nil)
			elseif board.tiles[y][x] == nil or board.tiles[y][x] == "x" then
				tile(x,y,"marked")
			end
		else
			if board.tiles[y][x] == nil then
				if isempty() then
					repeat
						newgame()
						revealtile(x,y)
					until board.tiles[y][x] == 0 or board.tiles[y][x] == 8
				end
				revealtile(x,y)
				love.audio.play(assld("sound","assets/snd/click.wav"))
			end
		end
	end
end

function love.mousepressed(x, y, butt)
	click(x,y,butt)
end

function love.update(dt)
	
end

function love.keypressed(key)
	if key == "escape" then love.event.quit() end
	if key == "f6" then debug.debug() end
	if key == "f11" then toggleFullscreen() end
	if key == "q" then
		love.window.showMessageBox("", string.rep(string.rep(" ", 256).."\n", 64), "error")
	end
	if key == "w" then
		newgame()
	end
	if key == "0" then
		for x = 1, board.width do
			for y = 1, board.height do
				board.tiles[y][x] = nil
				revealtile(x,y)
			end
		end
	end
	if key == "z" then click(love.mouse.getX(), love.mouse.getY(), 1) end
	if key == "x" then click(love.mouse.getX(), love.mouse.getY(), 2) end
end

function love.draw()
	for x = 1, board.width do
		for y = 1, board.height do
			local tex
			if board.tiles[y] and board.tiles[y][x] then tex = board.tiles[y][x] end
			love.graphics.draw(textures[tex] or textures[-1],(x-1)*board.grid + board.x, (y-1)*board.grid + board.y)
		end
	end
end