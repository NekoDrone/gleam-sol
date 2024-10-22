import dot_env as dot

pub fn env_config() {
  dot.new()
  |> dot.set_path("./.env")
  |> dot.set_debug(True)
  |> dot.load
}
