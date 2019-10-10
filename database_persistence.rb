require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname:"todos")
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement} : #{params}"
    @db.exec_params(statement, params)
  end
  
  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)
    return nil if result.ntuples == 0
    tuple = result.tuple(0)

    todos_arr = find_todos_for_list(tuple["id"].to_i)

    {id: tuple["id"], name: tuple["name"], todos: todos_arr }
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
      todos_arr = find_todos_for_list(tuple["id"].to_i)
      {id: tuple["id"], name: tuple["name"], todos: todos_arr }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    sql = "DELETE FROM todos WHERE list_id = $1;"
    sql2 = "DELETE FROM lists WHERE id = $1;"
    query(sql, id)
    query(sql2, id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, todo_name, list_id)
    #list = find_list(list_id)
    #id = next_element_id(list[:todos])
    #list[:todos] << { id: id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id)
    #list = find_list(list_id)
    #list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, new_status, todo_id, list_id)
    #list = find_list(list_id)
    #todo = list[:todos].find { |t| t[:id] == todo_id }
    #todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2;"
    query(sql, 't', list_id)
    #list = find_list(list_id)
    #list[:todos].each do |todo|
    #  todo[:completed] = true
    #end
  end

  private

  def find_todos_for_list(id)
    sql_todos = "SELECT * FROM todos WHERE list_id = $1;"
    result_todos = query(sql_todos, id)

    todos_arr = result_todos.map do |todo_tuple|
      {
        id: todo_tuple["id"].to_i,  
        name: todo_tuple["name"],  
        completed: todo_tuple["completed"] == "t"  
      }
    end
  end

end

