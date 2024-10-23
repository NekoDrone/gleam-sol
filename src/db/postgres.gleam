import envoy
import func/json_helper
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

pub fn find_did_from_user(
  username: String,
  db: pgo.Connection,
) -> Result(String, Nil) {
  let query = "
  SELECT did_string, user_string
  FROM public.users
  WHERE user_string = '" <> username <> "'
  ORDER BY user_string
  LIMIT 1;
  "

  let return_type = dynamic.element(0, dynamic.string)

  let assert Ok(response) = pgo.execute(query, db, [], return_type)

  response.rows
  |> list.first
}

pub fn add_user_to_db(
  user_info: json_helper.AddUserInfo,
  db: pgo.Connection,
) -> Result(_, pgo.QueryError) {
  let query = "
  INSERT INTO users (user_string, did_string)
  VALUES('" <> user_info.username <> "', '" <> user_info.did_string <> "')
  "

  pgo.execute(query, db, [], dynamic.dynamic)
}
