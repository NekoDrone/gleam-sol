import envoy
import gleam/dynamic
import gleam/list
import gleam/pgo
import gleam/result

pub fn setup_db() -> pgo.Connection {
  let assert Ok(db) = open_db_connection()
  let assert Ok(_) = create_db(db)
  db
}

fn open_db_connection() -> Result(pgo.Connection, Nil) {
  use db_url <- result.try(envoy.get("DATABASE_URL"))
  use config <- result.try(pgo.url_config(db_url))
  Ok(pgo.connect(config))
}

fn create_db(db: pgo.Connection) -> Result(_, pgo.QueryError) {
  let query =
    "
		CREATE TABLE IF NOT EXISTS users (
    	user_string VARCHAR(50) NOT NULL UNIQUE,
    	did_string CHAR(24) NOT NULL UNIQUE
    );
		"

  pgo.execute(query, db, [], dynamic.dynamic)
}

pub fn find_did_from_user(username: String) -> Result(String, Nil) {
  let assert Ok(db) = open_db_connection()
  let query =
    "
  SELECT did_string
  FROM users
  WHERE user_string = $1
  ORDER BY username
  LIMIT 1;
  "
  let assert Ok(response) =
    pgo.execute(query, db, [pgo.text(username)], dynamic.string)

  response.rows
  |> list.first
}
