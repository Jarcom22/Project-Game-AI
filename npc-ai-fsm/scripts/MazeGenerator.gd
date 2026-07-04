extends RefCounted
class_name MazeGenerator
## MazeGenerator.gd
##
## Bikin labirin secara acak (procedural) tiap kali game dimulai, pakai
## algoritma recursive backtracker (randomized DFS). Hasilnya "perfect
## maze": semua sel saling terhubung lewat tepat satu jalur, tidak ada
## jalan buntu yang mubazir atau lingkaran ganda.
##
## Representasi grid: sel jalan (bisa dilewati) ditandai 1, tembok
## ditandai 0. Ukuran grid = (cols*2+1) x (rows*2+1), karena tiap sel
## "ruangan" butuh sel "penghubung" di antaranya buat dijebol jadi jalan.

var cols: int
var rows: int
var width: int
var height: int
var grid: Array = []


func generate(p_cols: int, p_rows: int) -> void:
	cols = p_cols
	rows = p_rows
	width = cols * 2 + 1
	height = rows * 2 + 1

	grid.clear()
	for y in range(height):
		var row := []
		row.resize(width)
		row.fill(0)
		grid.append(row)

	var visited := []
	for y in range(rows):
		var vr := []
		vr.resize(cols)
		vr.fill(false)
		visited.append(vr)

	var stack: Array = []
	var start := Vector2i(0, 0)
	visited[start.y][start.x] = true
	grid[start.y * 2 + 1][start.x * 2 + 1] = 1
	stack.append(start)

	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while stack.size() > 0:
		var current: Vector2i = stack[stack.size() - 1]
		var options: Array = []
		for d in dirs:
			var nx: int = current.x + d.x
			var ny: int = current.y + d.y
			if nx >= 0 and nx < cols and ny >= 0 and ny < rows and not visited[ny][nx]:
				options.append(Vector2i(nx, ny))

		if options.size() > 0:
			var next: Vector2i = options[randi() % options.size()]
			var wall_x: int = current.x * 2 + 1 + (next.x - current.x)
			var wall_y: int = current.y * 2 + 1 + (next.y - current.y)
			grid[wall_y][wall_x] = 1
			grid[next.y * 2 + 1][next.x * 2 + 1] = 1
			visited[next.y][next.x] = true
			stack.append(next)
		else:
			stack.pop_back()


func is_open(x: int, y: int) -> bool:
	if x < 0 or x >= width or y < 0 or y >= height:
		return false
	return grid[y][x] == 1


func bfs_distances(start: Vector2i) -> Dictionary:
	# Jarak (dalam jumlah langkah sel) dari start ke semua sel yang bisa dicapai.
	var dist := {}
	dist[start] = 0
	var queue: Array = [start]
	var head := 0
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for d in dirs:
			var np: Vector2i = cur + d
			if is_open(np.x, np.y) and not dist.has(np):
				dist[np] = dist[cur] + 1
				queue.append(np)
	return dist


func farthest_cell(start: Vector2i) -> Vector2i:
	var dist := bfs_distances(start)
	var best: Vector2i = start
	var best_dist := -1
	for cell in dist.keys():
		if dist[cell] > best_dist:
			best_dist = dist[cell]
			best = cell
	return best


func cell_at_ratio(start: Vector2i, ratio: float) -> Vector2i:
	# Cari sel yang jaraknya kira-kira "ratio" dari jarak terjauh ke start.
	# Dipakai buat naruh kunci kira-kira di tengah jalur menuju exit.
	var dist := bfs_distances(start)
	var max_dist := 0
	for d in dist.values():
		max_dist = max(max_dist, d)

	var target_dist := int(round(max_dist * ratio))
	var best: Vector2i = start
	var best_diff := 999999
	for cell in dist.keys():
		var diff: int = abs(dist[cell] - target_dist)
		if diff < best_diff:
			best_diff = diff
			best = cell
	return best


func random_walk(start: Vector2i, max_steps: int) -> Array:
	# Jalan menyusuri sel yang belum pernah dilewati, buat rute patroli
	# musuh biar tetap nyusur koridor asli labirin (bukan jalan sembarangan).
	var path: Array = [start]
	var visited := {start: true}
	var current := start
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for i in range(max_steps):
		var options: Array = []
		for d in dirs:
			var np: Vector2i = current + d
			if is_open(np.x, np.y) and not visited.has(np):
				options.append(np)
		if options.size() == 0:
			break
		var next: Vector2i = options[randi() % options.size()]
		path.append(next)
		visited[next] = true
		current = next
	return path
