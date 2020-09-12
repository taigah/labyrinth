### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ b0519aa4-f4dd-11ea-3748-19876e66528d
begin
	using Pkg
	Pkg.add([
		"Images",
		"ImageIO",
		"FileIO",
		"VideoIO",
		"PlutoUI",
		"Colors"
	])
	using Images
	using ImageFiltering
	using PlutoUI
	using Random
	using Colors
	using FileIO
	using VideoIO
end

# ╔═╡ 11312c8a-f4f6-11ea-1e7a-69f9c50eea22
function labyrinth_is_connex(labyrinth)
	height, width = size(labyrinth)
	all(
		labyrinth[j,i] == -1 || labyrinth[j,i] == labyrinth[2,2]
		for j in 2:height-1, i in 2:width-1
	)
end

# ╔═╡ f44afbda-f4fe-11ea-0155-4db3c0d9a431
function is_wall_vertical(wall)
	return wall[1] % 2 == 1
end

# ╔═╡ 55afa084-f4fe-11ea-3d59-1dc2cca575e6
function adjacent_cells(wall)
	vertical = is_wall_vertical(wall)
	Δ = vertical ? [1,0] : [0,1]
	
	wall + Δ, wall - Δ
end

# ╔═╡ 8c0820f8-f4fd-11ea-1871-bd590da06b10
function remove_wall(labyrinth, wall)
	vertical = is_wall_vertical(wall)

	labyrinth_size = size(labyrinth)[1]
	
	cell1, cell2 = adjacent_cells(wall)
	cell1_value, cell2_value = labyrinth[cell1...], labyrinth[cell2...]
	
	# on change toutes les cellules de valeur cell1_value en cell2_value
	for j in 2:1:labyrinth_size-1, i in 2:1:labyrinth_size-1
		if labyrinth[j, i] == cell1_value
			labyrinth[j, i] = cell2_value
		end
	end

	labyrinth[wall...] = cell2_value
end

# ╔═╡ fe3c0eb4-f516-11ea-13e8-3d3b2abab4ff


# ╔═╡ 852945fc-f505-11ea-1ba0-c7d6c3efb157
html"""
<button id="start">Start</button>
<button id="stop">Stop</button>
<script>
const range = document.querySelector('input[type="range"]')
let running = false
let intv = null
document.getElementById('start').addEventListener('click', () => {
	if (running) return
	running = true
	intv = setInterval(() => {
		if (range.value === range.max) return clearInterval(intv)
		range.value = parseInt(range.value, 10) + 1
		range.dispatchEvent(new CustomEvent('input'))
	}, 20)
})
document.getElementById('stop').addEventListener('click', () => {
	clearInterval(intv)
	running = false
})
</script>
"""

# ╔═╡ e9be7878-f50c-11ea-28db-5bb9b4f4ae72
function cell_neighbors(labyrinth, cell)
	[
		cell + Δ
		for Δ in [ [1,0], [-1,0], [0,1], [0,-1] ]
		if labyrinth[(cell + Δ)...] != -1
	]
end

# ╔═╡ 04c90b48-f511-11ea-2156-f91ff0bb6670
function get_trails_from(labyrinth, initial = [2,2]; to = nothing)
	trails = fill(-1, size(labyrinth))
	trails[initial...] = 0
	visited = Set([ initial ])
	current_nodes = [ initial ]
	dist = 0
	while true
		dist += 1
		next_nodes = [
			neighbor
			for neighbor in vcat([ cell_neighbors(labyrinth, c) for c in current_nodes ]...)
			if neighbor ∉ visited
		]
		if isempty(next_nodes)
			break
		end
		if to ∈ next_nodes
			break
		end
		visited = union(visited, Set(next_nodes))
		for c in next_nodes
			trails[c...] = dist
		end
		current_nodes = next_nodes
	end
	trails
end

# ╔═╡ da1431a6-f511-11ea-11d3-4dd938aa0df7
function color_trails(labyrinth, trails)
	labyrinth_with_trails = copy(labyrinth)
	max_dist = maximum(trails)
	for (cell, d) in enumerate(trails)
		if labyrinth[cell...] == -1
			continue
		end
		labyrinth_with_trails[cell...] = d / max_dist
	end
	labyrinth_with_trails
end

# ╔═╡ b821b846-f513-11ea-36a3-cb3270168275
function path_between(labyrinth, c1, c2)
	trails = get_trails_from(labyrinth, c1, to=c2)
	path = [ c2 ]
	current = c2
	while true
		neighbors = cell_neighbors(labyrinth, current)
		next = neighbors[
			argmin([
				trails[nei...] >= 0 ? trails[nei...] : Inf for nei in neighbors
			])
		]
		println(next)
		push!(path, next)
		current = next
		if current == c1
			break
		end
	end
	path
end

# ╔═╡ 3c0884ca-f517-11ea-299a-8fc05d0bd0e5
cell_size = 10

# ╔═╡ d8da4fd2-f507-11ea-1a58-f9c5c435c1d7
begin
	# save labyrinth generation video
# 	props = [:priv_data => ("crf"=>"22","preset"=>"medium")]
# 	encodevideo("video.mp4",steps,framerate=240,AVCodecContextProperties=props)
	
end

# ╔═╡ eb49408e-f4f7-11ea-0430-cd226f13ad34
function value_to_color(x)
	if x == -1
		RGB(0.0,0.0,0.0)
	else
		convert(RGB, HSL(360 * x,0.5,0.5))
	end
end

# ╔═╡ 2f43dc28-f517-11ea-23f4-0fcfb262e70c
function draw_pixel(img, cell, color)
	j,i = cell[1], cell[2]
	img[
		cell_size * (j - 1) + 1 : cell_size * j,
		cell_size * (i - 1) + 1 : cell_size * i
	] .= color
end

# ╔═╡ 4ad59a88-f4de-11ea-1dac-31f55ba473b1
function labyrinth_image(labyrinth)
	labyrinth_height, labyrinth_width = size(labyrinth)
	img_height, img_width = cell_size .* size(labyrinth)
	img = zeros(RGB{N0f8}, img_height, img_width)
	for j in 1:labyrinth_height, i in 1:labyrinth_width
		draw_pixel(img, [j,i], value_to_color(labyrinth[j,i]))
	end
	img
end

# ╔═╡ 6fefcc1a-f4f1-11ea-05d2-b56f34b6e539
function create_labyrinth(labyrinth_size; intermediate_steps=false)
	labyrinth = fill(-1.0, labyrinth_size, labyrinth_size)
	# ouvertures
	for i in 2:2:labyrinth_size-1, j in 2:2:labyrinth_size-1
		labyrinth[j, i] = rand()
	end
	# on détruit des murs jusqu'à ce que le labyrinthe soit connexe
	# on obtient un labyrinthe simple
	walls = shuffle([
		(vertical, vertical ? [n + 1, m] : [m, n + 1])
		for n in 2:2:labyrinth_size-2 for m in 2:2:labyrinth_size-1 for vertical in [true, false]
	])
	steps = [ labyrinth_image(labyrinth) ]
	while !labyrinth_is_connex(labyrinth)
		if isempty(walls)
			# aie !
			break
		end
		(vertical, wall) = pop!(walls)
		cell1, cell2 = adjacent_cells(wall)
		cell1_value, cell2_value = labyrinth[cell1...], labyrinth[cell2...]
		if cell1_value != cell2_value
			remove_wall(labyrinth, wall)
			if intermediate_steps
				push!(steps, labyrinth_image(labyrinth))
			end
		end
	end
	# on détruit alors encore quelques murs pour obtenir un labyrinthe complexe
	for _ in 1:labyrinth_size
		if isempty(walls)
			break
		end
		(vertical, wall) = pop!(walls)
		remove_wall(labyrinth, wall)
		if intermediate_steps
			push!(steps, labyrinth_image(labyrinth))
		end
	end
	if !intermediate_steps
		push!(steps, labyrinth_image(labyrinth))
	end
	steps, labyrinth
end

# ╔═╡ 0287b984-f4de-11ea-37e6-ed96f3f6dcb1
begin
	labyrinth_size = 61
	steps, labyrinth = create_labyrinth(labyrinth_size)
	()
end

# ╔═╡ 55ccaf8a-f503-11ea-268a-4798521c659e
@bind step_index PlutoUI.Slider(1:length(steps))

# ╔═╡ 46a4ae36-f503-11ea-0b35-b5585d98da18
steps[step_index]

# ╔═╡ 7abb84fc-f511-11ea-0492-3904ceef981a
trails = get_trails_from(labyrinth, [10,10])

# ╔═╡ d228d6fa-f515-11ea-0204-3b84886ce13b
begin
	c1 = [20, 2]
	c2 = [20, labyrinth_size - 2]
end

# ╔═╡ cd7f3338-f515-11ea-0a14-3b30797c8a6b
path_trails = get_trails_from(labyrinth, c1, to=c2)

# ╔═╡ d98bb970-f514-11ea-2265-d5b732b34006
path = path_between(labyrinth, c1, c2)

# ╔═╡ abee3e76-f4fc-11ea-23a0-f5c92b5e436f
labyrinth_image(labyrinth)

# ╔═╡ 9daff394-f516-11ea-3008-3975683eac36
labyrinth_image(color_trails(labyrinth, trails))

# ╔═╡ 63c350c4-f516-11ea-2e79-4d5deb457495
begin
	lab_img = labyrinth_image(color_trails(labyrinth, path_trails))
	for c in path
		draw_pixel(lab_img, c, RGB(0.8,0.8,0.8))
	end
	lab_img
end

# ╔═╡ Cell order:
# ╠═b0519aa4-f4dd-11ea-3748-19876e66528d
# ╠═11312c8a-f4f6-11ea-1e7a-69f9c50eea22
# ╠═f44afbda-f4fe-11ea-0155-4db3c0d9a431
# ╠═55afa084-f4fe-11ea-3d59-1dc2cca575e6
# ╠═8c0820f8-f4fd-11ea-1871-bd590da06b10
# ╠═6fefcc1a-f4f1-11ea-05d2-b56f34b6e539
# ╠═0287b984-f4de-11ea-37e6-ed96f3f6dcb1
# ╠═fe3c0eb4-f516-11ea-13e8-3d3b2abab4ff
# ╟─852945fc-f505-11ea-1ba0-c7d6c3efb157
# ╟─55ccaf8a-f503-11ea-268a-4798521c659e
# ╠═46a4ae36-f503-11ea-0b35-b5585d98da18
# ╠═abee3e76-f4fc-11ea-23a0-f5c92b5e436f
# ╠═e9be7878-f50c-11ea-28db-5bb9b4f4ae72
# ╠═04c90b48-f511-11ea-2156-f91ff0bb6670
# ╠═7abb84fc-f511-11ea-0492-3904ceef981a
# ╠═da1431a6-f511-11ea-11d3-4dd938aa0df7
# ╠═9daff394-f516-11ea-3008-3975683eac36
# ╠═b821b846-f513-11ea-36a3-cb3270168275
# ╠═d228d6fa-f515-11ea-0204-3b84886ce13b
# ╠═cd7f3338-f515-11ea-0a14-3b30797c8a6b
# ╠═d98bb970-f514-11ea-2265-d5b732b34006
# ╠═63c350c4-f516-11ea-2e79-4d5deb457495
# ╠═3c0884ca-f517-11ea-299a-8fc05d0bd0e5
# ╟─d8da4fd2-f507-11ea-1a58-f9c5c435c1d7
# ╠═eb49408e-f4f7-11ea-0430-cd226f13ad34
# ╠═2f43dc28-f517-11ea-23f4-0fcfb262e70c
# ╠═4ad59a88-f4de-11ea-1dac-31f55ba473b1
