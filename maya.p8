pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- the cheese hunt
-- by maya

function _init()
  define_flags()
  init_player()
  init_cat()
  init_energy()
  init_tile()
  init_camera()
  init_game()
end

function _update()
  if not game.is_over then
    update_position()
    update_orientation()
    update_inventory()
    update_status()
    update_camera()
  end
end

function _draw()
  if game.is_over then
    draw_game_over()
  else
    draw_map()
    draw_camera()
    draw_characters()
  end
end
-->8
-- init

characters = {}

function define_flags()
  flag = {
    blocked = 0,
    food = 1,
    energy = 2,
    cheese = 3
  }
end

function init_player()
  player = {
    x = 60,
    y = 60,
    delta = nil,
    sprite = nil,
    flip_x = false,
    flip_y = false,
    energy = 0,
    cheese = 0,
    update_position = function(self)
      update_sprite_position(self, move_player)
    end,
    draw = function(self)
      spr(self.sprite, self.x, self.y, 1, 1, self.flip_x)
    end
  }
  add(characters, player)
end

function init_cat()
  cat = {
    x = 9 * 8,
    y = 1 * 8,
    delta = 0.9,
    sprite = 17,
    flip_x = false,
    dead = false,
    update_position = function(self)
      if not self.dead then
        update_sprite_position(self, move_cat_x)
        update_sprite_position(self, move_cat_y)
      end
    end,
    draw = function(self)
      spr(self.sprite, self.x, self.y, 1, 1, self.flip_x, self.dead)
    end
  }
  add(characters, cat)
end

function init_energy()
  energy = {
    timer = 3,
    is_timer_running = false
  }
end

function init_camera()
  cam = {
    x = 0
  }
end

function init_tile()
  tile = {
    x_map = nil,
    y_map = nil
  }
end

function init_game()
  game = {
    is_over = false,
    is_won = false,
    is_lost = false,
    is_debug = false
  }
end
-->8
-- update

function update_position()
  update_positions()
  keep_player_inside()
  update_all_frames()
end

function update_orientation()
  update_player_orientation()
  update_cat_orientation()
end

function update_inventory()
  if is_food(player) then
    eat(player)
  end
end

function update_status()
  update_energy_status()
  update_cat_status()
  update_caught_status()
  update_won_status()
end

function update_camera()
  local screen = flr(player.x / 128)
  cam.x = screen * 128
end

-->8
-- update helpers

function update_positions()
  for character in all(characters) do
    character:update_position()
  end
end

function update_sprite_position(obj, move)
  local new_position = move(obj)
  if not is_blocked(new_position) then
    obj.x = new_position.x
    obj.y = new_position.y
  end
end

function move_player(obj)
  local x = obj.x
  local y = obj.y
  local delta = obj.delta
  if (btn(⬅️)) x -= delta
  if (btn(➡️)) x += delta
  if (btn(⬆️)) y -= delta
  if (btn(⬇️)) y += delta
  local new_position = {}
  new_position.x = x
  new_position.y = y
  return new_position
end

function move_cat_x(obj)
  local x = obj.x
  local y = obj.y
  local delta = obj.delta
  if abs(x - player.x) > delta then
    if player.x < x then
      x -= delta
    elseif player.x > x then
      x += delta
    end
  end
  local new_position = {}
  new_position.x = x
  new_position.y = y
  return new_position
end

function move_cat_y(obj)
  local x = obj.x
  local y = obj.y
  local delta = obj.delta
  if (player.y < y) y -= delta
  if (player.y > y) y += delta
  local new_position = {}
  new_position.x = x
  new_position.y = y
  return new_position
end

function keep_player_inside()
  level = player.cheese + 1
  player.x = mid(0, player.x, level * 128 - 8)
  player.y = mid(0, player.y, 128 - 9)
end

function update_all_frames()
  update_player_frame()
  update_cat_frame()
end

function update_player_frame()
  local base_sprite = 1
  if energy.is_timer_running then
    base_sprite = 3
  end
  player.sprite = (player.x + player.y) % 2 + base_sprite
end

function update_cat_frame()
  local base_sprite = 17
  cat.sprite = (cat.x + cat.y) % 2 + base_sprite
end

function update_player_orientation()
  if (btnp(⬅️)) player.flip_x = true
  if (btnp(➡️)) player.flip_x = false
end

function update_cat_orientation()
  cat.flip_x = cat.x > player.x
end

function is_blocked(obj)
  return is_flagged(obj, flag.blocked)
end

function is_food(obj)
  return is_flagged(obj, flag.food)
end

function is_energy(obj)
  return is_flagged(obj, flag.energy)
end

function is_cheese(obj)
  return is_flagged(obj, flag.cheese)
end

function is_flagged(obj, a_flag)
  local x = obj.x
  local y = obj.y
  local x1 = flr((x + 1) / 8)
  local y1 = flr((y + 1) / 8)
  local x2 = flr((x + 7) / 8)
  local y2 = flr((y + 7) / 8)
  if fget(mget(x2, y2), a_flag) then
    tile.x_map = x2
    tile.y_map = y2
    return true
  end
  if fget(mget(x2, y1), a_flag) then
    tile.x_map = x2
    tile.y_map = y1
    return true
  end
  if fget(mget(x1, y2), a_flag) then
    tile.x_map = x1
    tile.y_map = y2
    return true
  end
  if fget(mget(x1, y1), a_flag) then
    tile.x_map = x1
    tile.y_map = y1
    return true
  end
  tile.x_map = nil
  tile.y_map = nil
  return false
end

function eat(obj)
  if is_energy(obj) then
    obj.energy += 1
    energy.time = time()
  elseif is_cheese(obj) then
    obj.cheese += 1
  end
  remove_food()
end

function remove_food()
  mset(tile.x_map, tile.y_map, 0)
end

function update_energy_status()
  if player.energy > 0 then
    energy.is_timer_running = time() - energy.time < energy.timer
    if not energy.is_timer_running then
      player.energy = 0
    end
  end
  player.delta = player.energy + 1
end

function update_caught_status()
  if is_caught() then
    game.is_lost = true
    game.is_over = true
  end
end

function is_caught()
  diff_x = abs(player.x - cat.x)
  diff_y = abs(player.y - cat.y)
  return diff_x < 6 and diff_y < 6 and not cat.dead
end

function update_cat_status()
  if player.cheese == 1 then
    cat.dead = true
  end
end

function update_won_status()
  if player.cheese >= 3 then
    game.is_won = true
    game.is_over = true
  end
end
-->8
-- draw

function draw_map()
  cls(3)
  map()
end

function draw_camera()
  camera(cam.x)
end

function draw_characters()
  for character in all(characters) do
    character:draw()
  end
end

function draw_game_over()
  local x1 = flr(player.x / 128) * 128 + 128 / 2 - 30
  local y1 = flr(player.y / 128) * 128 + 128 / 2 - 20
  local x2 = flr(player.x / 128) * 128 + 128 / 2 + 30
  local y2 = flr(player.y / 128) * 128 + 128 / 2 + 5
  rectfill(x1, y1, x2, y2, 1)
  if game.is_won then
    message = "you won!"
  elseif game.is_lost then
    message = "game over"
  end
  print(message, x1 + 14, y1 + 10, 9)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333333333333333333333333
000000000007770000077700067777000677770000000000000000000000000000000000000000000000000000000000000000003bbb8bb33333333333334333
007007000007e7000007e7000006e7000006e70000000000000000000000000000000000000000000000000000000000000000003b38b3b33a9aa9a333334b33
000770000077777000777770677777706777777000000000000000000000000000000000000000000000000000000000000000003b83b8b33aaaaaa333888883
00077000ee777270ee777270ee776270ee77627000000000000000000000000000000000000000000000000000000000000000003bbb8bb33a9a9aa333888783
00700700007777e0007777e0007777e0007777e000000000000000000000000000000000000000000000000000000000000000003b83b3b33aaaaaa333888883
000000000077777000777770677777706777777000000000000000000000000000000000000000000000000000000000000000003bb8b8b33333333333888883
0000000000e0e0e0000e0e000e0e0e0000e0e0e00000000000000000000000000000000000000000000000000000000000000000333333333333333333333333
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccbccbcc3333333333333333
000000000009009000090090000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccbccbc38883eee33333333
00000000009e99e9009e99e9000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccbccbcc38a83eae33333333
000000000099111900991119000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccbccbc38883eee33333333
000000009999818999998189000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccbccbcc33b333b333333333
0000000000999e9900999e99000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccbccbc3bb33bb333333333
000000000099999900999999000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccbccbcc33bb33bb33333333
000000000090909000090900000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccbccbc33b333b333333333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000042222240422222400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000048222840482228400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000047717740477177400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000474777404747774000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000477747704777477000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000040404000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccc9999ccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cc99919cc3c3333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccc9999cc333331300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccc3c3333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccccccc7c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333339339333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333339e99e933333333333333333a9aa9a333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333399111933333333333333333aaaaaa333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333339999818933333333333333333a9a9aa333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333999e9933333333333333333aaaaaa333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333399999933333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333393939333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333334333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333334b33333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333888883333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333888783333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333888883333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333888883333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333334333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333334b33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333888883333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333888783333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333888883333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333888883333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bbb8bb333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333377733333333333333333333b38b3b333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333337e733333333333333333333b83b8b333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333777773333333333333333333bbb8bb333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333ee777273333333333333333333b83b3b333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333337777e3333333333333333333bb8b8b333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333777773333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333e3e3e3333333333333333333333333333333333333333333333333333333333
33333333333333333bbb8bb333333333333333333bbb8bb333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b38b3b333333333333333333b38b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b83b8b333333333333333333b83b8b333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333bbb8bb333333333333333333bbb8bb333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b83b3b333333333333333333b83b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333bb8b8b333333333333333333bb8b8b333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333433333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333334b3333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333388888333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333388878333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333388888333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333388888333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333bbb8bb3333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333b38b3b3333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333b83b8b3333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333bbb8bb3333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333b83b3b3333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333bb8b8b3333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333bbb8bb333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b38b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b83b8b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333bbb8bb333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333b83b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333bb8b8b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333

__gff__
00000000000000000000000000010a0600000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1f1f1f1f1f1f1f1f1e1e1e1f1f1f1f1f1f1f1f1f1f1f0e1f1f1f11211e1f1f1f1f1f1f1f1f1f0e1f1f1f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1e1f1e1f1f1f0e1f1f1f1f1f1f1f1e1f0f1e1e1e1e1f1f1f1f1f1f1f1e1e1e1e1e0f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1e1f1e1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0d211121111f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0d0d0d0d0d0f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f0f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f0d1f1f0d1f1f1f1f1f1f1f1f0f1f1c311c1c1c1c1c1c1c1c1c311c1c1c311c1c1c321c1c1c1c1c1c1c1c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1c1c1c1c1c311c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c311c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f0d1f1f1f1f1f1f1f1f1f1f1f1f1f1c311c1c1c1c1c1c1c1c1c1c1c1d311d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f0d1f1f1f1f1f1f1c1c1c1c1c1c1c1c1c1c1c1c1c1d1d1d1d1d1d1d1d1d1d1d321d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d1d1d1d1d1d1d1d1d1d1d1d311d1d1d1d1d321d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d1d311d1d1d1d1d311d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d311d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001717171717171700000017000000000000380000000000000000000000000909090909090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0102000002624026410266102625040050500507005090050b005010050300506005080050a0050c0050e0051000511005130051500517005180051a0051c0051df0018d00000000000000000000000000000000
