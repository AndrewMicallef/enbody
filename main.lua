require 'src.dependancies'

function love.load()

	particles = Particles{ntypes=5, dim=64}
end

function love.update(dt)
	particles:update(dt)
end

function love.draw()
	particles:render()
end


--respond to input
function love.keypressed(k)
	--new world
	if k == "r" then
		--restart, soft or hard
		if love.keyboard.isDown("lctrl") then
			love.event.quit("restart")
		else
			love.load()
		end
	--quit
	elseif k == "q" or k == "escape" then
		--quit out
		love.event.quit()
	end
end
