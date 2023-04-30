extends Node2D

@onready
var graphical_matrix = $Matrix.get_children()

# მატრიცის მიმდინარე მდგომარეობა
# მოძრავი კვადრატი აღნიშნულია "*" - ით
var curr_state = [['1','2','3'],['4', '*', '6'],['7', '8', '9']]

# საბოლოო მდგომაეობა (დალაგებული მატრიცა)
var goal = [['1','2','3'],['4', '*', '6'],['7', '8', '9']]

const MATRIX_H_SIZE = 3
const MATRIX_V_SIZE = 3
# გვიჩვენებს პროგრამა ძებნის პროცესშია თუ არა
# true - ძებნის ალგორითმი მუშაობის პროცესშია
# false - ძებნის ალგორითმი გაჩერებულია
var searching = false

var comparisons = 0

func _input(event):
	if event.is_action_pressed("ui_left"):
		curr_state = move_left(curr_state)
		display_matrix(curr_state)
	if event.is_action_pressed("ui_up"):
		curr_state = move_up(curr_state)
		display_matrix(curr_state)		
	if event.is_action_pressed("ui_right"):
		curr_state = move_right(curr_state)
		display_matrix(curr_state)
	if event.is_action_pressed("ui_down"):
		curr_state = move_down(curr_state)
		display_matrix(curr_state)
	
	if event.is_action_pressed("stop"):
		release_buttons()



# სიგანეში ძებნის ალგორითმი
# გადაეცემა მიმდინარე მატრიცა და საბოლოო მატრიცა (ძებნის სამიზნე)
func _bfs(curr_mat, dest_mat):
	# რიგში ვამატებთ შემდეგი პრინციპიტ [მიმდინარე_მატრიცა, მშობელი_მატრიცა]
	# მშობელი_მატრიცა - საიდანაც მივიღეთ მიმდინარე მატრიცა მოძრავი კუბის 1 გადაადგილებით
	var queue:Array = [[copy(curr_mat), null]]
	
	# შევინახავთ ყველა მონახულებულ მატრიცას და მათ მშობელს (ინახება მათი reference)
	var visited:Array = [queue[0]]
	
	comparisons = 0
	
	while searching && !queue.is_empty():
		var currPair = queue.pop_front()
		var curr = currPair[0]
		
		display_matrix(curr)
		$Comparisons.text = "Comp: " + str(comparisons)
		
		await get_tree().process_frame
		
		if equals(curr, dest_mat):
			curr_state = curr
			display_matrix(curr_state)
			break
		
		var adj = get_movement(curr)
		
		var moved
		for i in range(4):
			comparisons += 1;
			if(adj[i] == 1):
				moved = get_move_with_index(i, curr)
				if(!is_matrix_in(visited, moved)):
					var pair = [moved, currPair]
					visited.append(pair)
					queue.append(pair)
	
	# UI ელემენტებისთვის
	release_buttons()


# გვიბრუნებს არის თუ არა გადაცემული მატრიცა სიაში, ასევე ზრდის შედარებების რაოდენობას
func is_matrix_in(list:Array, matrix):
	if list.is_empty():
		return false
	
	for i in range(list.size()):
		if(equals(list[i][0], matrix)):
			return true
	
	return false


# ა ვარსკვლავიანი ალგორითმი
# გადაეცემა მიმდინარე მატრიცა და საბოლოო მატრიცა (ძებნის სამიზნე)
func _a_star(curr_mat, dest_mat):
	# მატრიცის ნაპოვნი მაგრამ ჯერ დაუმუშავებელი (ყველა მეზობელი არაა ნაპოვნი) მდგომარეობები
	# მასივებში ვინახავთ [მატრიცა, სიღრმე, სრული წონა] წონა არის სიღრმე + დამატებითი (huristic) წონა
	var open: Array = []
	open.clear()
	# მატრიცის ნაპოვნი და დამუშავებული (ყველა მეზობელი ნაპოვნია) მდგომარეობები
	var closed: Array = []
	closed.clear()
	
	comparisons = 0
	
	var counter = 0
	var update_period = 100
	
	open.append([copy(curr_mat), 0, heuristic(curr_mat, dest_mat)])
	
	var adj
	var dist
	var moved
	var matrix_in_open
	var matrix_in_closed
	while searching && !open.is_empty():
		# ინსერტის გამო მინიმალური ელემენტი ყოველთვის პირველი იქნება
		var curr_tuple = open.front()
		var curr = curr_tuple[0]
		
		display_matrix(curr)
		$Comparisons.text = "Comp: " + str(comparisons)
		await get_tree().process_frame
		
		if equals(curr, dest_mat):
			curr_state = curr
			display_matrix(curr)
			open.clear()
			closed.clear()
			break
		
		adj = get_movement(curr)
		
		for i in range(4):
			comparisons += 1
			if(adj[i] == 1):
				moved = get_move_with_index(i, curr)
				dist = curr_tuple[1] + 1
				matrix_in_open = get_matrix_in(open, moved)
				matrix_in_closed = get_matrix_in(closed, moved)
				
				if(matrix_in_open != null):
					comparisons += 1
					if(matrix_in_open[1] <= dist): continue
					matrix_in_open[1] = dist
				elif(matrix_in_closed != null):
					comparisons += 1
					if(matrix_in_closed[1] <= dist): continue
					closed.erase(matrix_in_closed)
					matrix_in_closed[1] = dist
					insert_with_weight(open, matrix_in_closed)
				else:
					insert_with_weight(open, [moved, dist, heuristic(moved, dest_mat)])
		
		closed.append(curr_tuple)
		open.erase(curr_tuple)
	
	# UI ელემენტებისთვის
	release_buttons()

# ითვლის დამატებით წონას მატრიცისთვის
# დამატებითი წონა იყოს მიზნის მატრიცისგან გასხვავებული ფიშკების რაოდენობა
# ანუ სხვა პოზიციაზე როცა დგას ფიშკა +1 წონას
func heuristic(curr, dest):
	var res = 0
	for i in range(MATRIX_V_SIZE):
		for j in range(MATRIX_H_SIZE):
			comparisons += 1
			if curr[i][j] != dest[i][j]:
				res += 1
	return res

# გამოთვლის გადაცემული მატრიცის ყველა მონაცემს (სიღმე და დამატებითი წონა)
# აბრუნებს მატრიცის, სიღრმისა და წონის სამეულს
func calculate_tuple(mat, parent_tuple, dest_mat):
	var depth = parent_tuple[1] + 1
	var heuristic = heuristic(mat, dest_mat)
	return [mat, depth, heuristic]

# გვიბრუნებს იმ სამეულის მისამართს გადაცემულ სიაში რომელიც შეიცავს გადაცემული მატრიცის ტოლ მატრიცას
func get_matrix_in(list, matrix):
	var res = list.filter(func(tuple): return equals(tuple[0], matrix))
	
	if(res.is_empty()):
		return null
	
	return res[0]

# სიაში ამატებს სამეულს ისე რომ არ დაირღვეს წონის მიხედვით დალაგებულობა (პირველი ყოველთვის მინიმალური წონის იქნება)
func insert_with_weight(list: Array, tuple):
	if(list.is_empty()):
		list.append(tuple)
	
	for i in range(list.size()):
		comparisons += 1
		if((list[i][2] + list[i][1]) >= (tuple[2] + tuple[1])):
			list.insert(i, tuple)
			return
	
	list.append(tuple)

# გადაცემული მატრიცისთვის გვიბრუნებს მოძრავი კვადრატის კოორდინატებს
func get_movable_square(mat):
	var row
	var col
	
	for i in range(MATRIX_V_SIZE):
		for j in range(MATRIX_H_SIZE):
			comparisons += 1
			if(mat[i][j] == "*"):
				row = i
				col = j
	
	return Vector2(row, col)

# გადაცემული მატრიცისთვის აბრუნებს 4 განზომილებიან მატრიცას რომელიც გვეუბნება რომელი მიმართულებით შეიძლია
# მოძრავ კვადრატს მოძრაობა, მატრიცაში წერია 0 თუ მოძრაობა შესაბამისი მიმართულებით არ შეიძლება
# მატრიცის ელემენტები შეესაბამება შემდეგ მიმართულებებს შემდეგი მიმდევრობით:
# x - მარცხნივ, y - ზემოთ, z - მარჯვნივ, w - ქვემოთ
func get_movement(mat):
	var movable = get_movable_square(mat)
	var results: Vector4 = Vector4(0, 0, 0, 0)
	
	comparisons += 4
	# მარცხინვ
	if(movable.y > 0):
		results.x = 1
	
	# ზემოთ
	if(movable.x > 0):
		results.y = 1

	# მარჯვნივ
	if(movable.y < mat[0].size() - 1):
		results.z = 1
	
	# ქვემოთ
	if(movable.x < mat.size() - 1):
		results.w = 1
	
	return results

# გადაცემული მატრიცის მოძრავ კვადრატს ამოძრავებს შესაბამისი მიმართულებით და აბრუნებს შეცვლილ 
# მატრიცას თუ მოძრაობა არ შეიძლება აბრუნებს იგივე მატრიცას
func move_left(mat):
	if(get_movement(mat).x != 1):
		return mat
	
	var res = copy(mat)
	
	var movable = get_movable_square(res)
	
	swap_squares(res, movable, Vector2(movable.x, movable.y - 1))
	
	return res
func move_up(mat):
	if(get_movement(mat).y != 1):
		return mat
	
	var res = copy(mat)
	
	var movable = get_movable_square(res)
	
	swap_squares(res, movable, Vector2(movable.x - 1, movable.y))
	
	return res
func move_right(mat):
	if(get_movement(mat).z != 1):
		return mat
	
	var res = copy(mat)
	
	var movable = get_movable_square(res)
	
	swap_squares(res, movable, Vector2(movable.x, movable.y + 1))
	
	return res
func move_down(mat):
	if(get_movement(mat).w != 1):
		return mat
	
	var res = copy(mat)
	
	var movable = get_movable_square(res)
	
	swap_squares(res, movable, Vector2(movable.x + 1, movable.y))
	
	return res

func get_move_with_index(index, mat):
	var res
	
	match index:
		0: res = move_left(mat)
		1: res = move_up(mat)
		2: res = move_right(mat)
		3: res = move_down(mat)
	return res

# ახდენს გადაცემული მატრიცის ვიზუალურად წარმოდგენას
func display_matrix(mat):
	var k = 0
	for i in range(MATRIX_V_SIZE):
		for j in range(MATRIX_H_SIZE):
			graphical_matrix[k].text = mat[i][j]
			k += 1

# გადაცემულ მატრიცაში ადგილებს უცვლის კუბებს კოორდინატებით square1 და square2
func swap_squares(mat, square1: Vector2, square2: Vector2):
	var tmp = mat[square1.x][square1.y]
	mat[square1.x][square1.y] = mat[square2.x][square2.y]
	mat[square2.x][square2.y] = tmp

# აკოპირებს და აბრუნებს ახალ მატრიცას იმავე მონაცემებით (ღრმა კოპირება)
func copy(mat):
	var result: Array
	for i in range(MATRIX_V_SIZE):
		var subArr:Array = []
		for j in range(MATRIX_H_SIZE):
			subArr.append(mat[i][j])
		result.append(subArr)
	return result

# მატრიცების შედარების ოპერაცია (true - ტოლია, false - სხვა შემთხვევაში)
func equals(mat1, mat2):
	for i in range(MATRIX_V_SIZE):
		for j in range (MATRIX_H_SIZE):
			comparisons += 1
			if(mat1[i][j] != mat2[i][j]): return false
	return true



###### ამის ქვევით UI ელემენტების კონტროლია რაც არ ეხება ალგორითმებს ######
func release_buttons():
	searching = false
	$BFS.disabled = false
	$A_star.disabled = false

func _on_a_star_pressed() -> void:
	if(!searching):
		searching = true
		$BFS.disabled = true
		$A_star.disabled = true
		_a_star(curr_state, goal)

func _on_bfs_pressed() -> void:
	if(!searching):
		searching = true
		$BFS.disabled = true
		$A_star.disabled = true
		_bfs(curr_state, goal)

func _on_reset_pressed() -> void:
	release_buttons()
	$Comparisons.text = "Comp: 0"
	curr_state = copy(goal)
	display_matrix(curr_state)
