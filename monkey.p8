pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--mr. monkey's
--boomerang bonanza
--by sfabian/ravertass

function dummy() end

-- states
c_state_menu=0
c_state_game=1
c_state_over=2
c_state_death=3

--- flags
c_flag_walkable=0

--- colors
c_clr_black=0
c_clr_maroon=1
c_clr_blue=12

-- songs
c_song_athletic=00
c_song_theme=24
c_song_over=16
c_song_high_score=17
--c_song_death=18

-- sound effects
c_sfx_hurt=50
c_sfx_boomerang=51
c_sfx_bird=52
c_sfx_teeth=0
c_sfx_panic=53
c_sfx_banana=54
c_sfx_death_1=39
c_sfx_death_2=40

--- misc. sprites
c_spr_wave=072
c_sprs_boomerang={
 036,037,038,039,
 052,053,054,055}

--- player
c_start_x=60
c_start_y=58
c_speed=2

c_max_walk_count=8

--- player sprites
c_spr_pl_down_idle=001
c_spr_pl_up_idle=003
c_spr_pl_right_idle=005

c_spr_pl_down_walk=002
c_spr_pl_up_walk=004
c_spr_pl_right_walk={006,007}

--- directions
c_right=1
c_up=2
c_left=3
c_down=4

---- init ----

function _init()
 menuitem(1,
         "reset high score",
         reset_high_score)
 init_menu()
end

function reset_high_score()
 dset(1,0)
 dset(2,0)
 dset(3,0)
 dset(4,0)
 dset(5,0)
 _init()
end

c_start_credits_x=150
function init_menu()
 state=c_state_menu
 music(c_song_theme)
 menu_count=0
 credits_x=c_start_credits_x
 init_waves()
end

function init_game()
 state=c_state_game
 music(c_song_athletic)
 score=0
 frame_timer=0
 sec_timer=0
 init_player()
 init_boomerang()
 birds={}
 teeths={}
 storks={}
 bananas={}
 particles={}
end

function init_game_over()
 state=c_state_over
 if score>get_high_score() then
  letter_index=1
  alphabet_index={}
  alphabet_index[1]=1
  alphabet_index[2]=1
  alphabet_index[3]=1
  new_high_score=true
  music(c_song_high_score)
  name_marker_count=0
 else
  game_over_count=300
  new_high_score=false
  music(c_song_over)
 end
end

function init_waves()
 waves={}
 for celx=0,15 do
  for cely=0,15 do
   if flr(rnd(10))==0 then
    add(waves,new_wave(celx,
                       cely))
   end
  end
 end
 waves_dx=rnd(1)-0.5
 waves_dy=rnd(1)-0.5
end

function new_wave(celx,cely)
 return {
  x=celx*8+flr(rnd(3)),
  y=cely*8+flr(rnd(3)),
  spr=c_spr_wave+flr(rnd(4))
 }
end

c_max_lives=3
function init_player()
 player={
  x=c_start_x,
  y=c_start_y,
  dir=c_down,
  dx=0,
  dy=0,
  speed=c_speed,
  walk_count=0,
  walking=false,
  lives=c_max_lives,
  invincibility=60
 }
end

function init_boomerang()
 boomerang={
  x=-1,y=-1,
  speed=0,
  acc=0,
  dir=0,--float in (0,1]
  active=false,
  follow=false,
  walk_count=0,
 }
end

---- update ----

function _update()
 if state==c_state_menu then
  update_menu()
 elseif state==c_state_game
 then
  update_game()
 elseif state==c_state_over
 then
  update_game_over()
 elseif state==c_state_death
 then
  update_death()
 end
end

function update_menu()
 update_sea()
 menu_count=
  (menu_count+1)%20
 credits_x-=0.5
 if credits_x<-100 then
  credits_x=c_start_credits_x
 end
 if btnp(4) or btnp(5) then
  init_game()
 end
end

function update_death()
 update_sea()
 update_boomerang(boomerang)
 update_enemies()
 update_storks()
 update_bananas()
 foreach(particles,
         update_particle)
 death_count-=1
 if death_count<1 then
  init_game_over()
 end
end

function update_game()
 update_timers()
 update_sea()
 update_player()
 update_boomerang(boomerang)
 update_enemies()
 update_storks()
 update_bananas()
 foreach(particles,
         update_particle)
 generate_enemies()
 generate_storks()
end

function update_timers()
 frame_timer=
  (frame_timer+1)%30
 if frame_timer==0 then
  score+=1
  sec_timer+=1
 end
end

function update_sea()
 if flr(rnd(120))==0 then
  waves_dx+=rnd(0.25)-0.125
  waves_dy+=rnd(0.25)-0.125
 end
 foreach(waves,update_wave)
end

function update_wave(wave)
 wave.x+=waves_dx
 wave.y+=waves_dy

 if wave.x>127 then
  wave.x=0
 elseif wave.x<0 then
  wave.x=127
 end
 if wave.y>127 then
  wave.y=0
 elseif wave.y<0 then
  wave.y=127
 end
end

function update_player()
 update_invincibility(player)
 inc_walk_count(player)
 input()
 grab()
 enemy_collisions()
end

function
update_invincibility(actor)
 if actor.invincibility>0 then
  actor.invincibility-=1
 end
end

function inc_walk_count(actor)
 actor.walk_count=
  (actor.walk_count+1)
   %c_max_walk_count
end

function input()
 move_input()
 boomerang_input()
end

function move_input()
 reset_movement()

 if btn(1) then
  player.dx=player.speed
  player.dir=c_right
  player.walking=true
 elseif btn(0) then
  player.dx=-player.speed
  player.dir=c_left
  player.walking=true
 end
 if btn(2) then
  player.dy=-player.speed
  player.dir=c_up
  player.walking=true
 elseif btn(3) then
  player.dy=player.speed
  player.dir=c_down
  player.walking=true
 end
 move(player)
end

function reset_movement()
 player.walking=false
 player.dx=0
 player.dy=0
end

function move(player)
 if not
 x_col_with_wall(player,
                 player.dx)
 then
  player.x+=player.dx
 end
 if not
 y_col_with_wall(player,
                 player.dy)
 then
  player.y+=player.dy
 end
end

function
x_col_with_wall(actor,dx)
 if dx>0 then
  x1=actor.x+7; y1=actor.y+4
  x2=actor.x+7; y2=actor.y+9
 else
  x1=actor.x;   y1=actor.y+4
  x2=actor.x;   y2=actor.y+9
 end

 if not
 is_walkable(x1+dx,y1)
 or not
 is_walkable(x2+dx,y2)
 then
  return true
 end
end

function
y_col_with_wall(actor,dy)
 if dy<=0 then
  x1=actor.x;   y1=actor.y+4
  x2=actor.x+7; y2=actor.y+4;
 else
  x1=actor.x;   y1=actor.y+9
  x2=actor.x+7; y2=actor.y+9
 end

 if not
 is_walkable(x1,y1+dy)
 or not
 is_walkable(x2,y2+dy)
 then
  return true
 end
end

function is_walkable(x,y)
 return fget(mget(flr(x/8),
                  flr(y/8)),
             c_flag_walkable)
end

function enemy_collisions()
 if player.invincibility==0
 then
  foreach(birds,bird_collision)
  foreach(teeths,
          teeth_collision)
 end
end

function hurt_player()
 player.lives-=1
 player.invincibility=40
 if player.lives==0 then
  init_death()
 else
  sfx(c_sfx_hurt)
 end

 if player.lives==1 then
  sfx(c_sfx_panic)
 end
end

c_max_death_count=60
function init_death()
 sfx(c_sfx_death_1)
 sfx(c_sfx_death_2)
 death_count=c_max_death_count
 state=c_state_death
end

function bird_collision(bird)
 if intersect(
     player_rect(),
     {bird.x+1,bird.y+1,
      bird.x+5,bird.y+6})
 then
  hurt_player()
 end
end

function teeth_collision(teeth)
 if teeth.active and
 intersect(
  player_rect(),
  {teeth.x+1,teeth.y+2,
   teeth.x+6,teeth.y+6})
 then
  hurt_player()
 end
end

function player_rect()
 return {
  player.x+1,player.y+1,
  player.x+6,player.y+9
 }
end

function intersect(rect1,rect2)
 return
  rect_in_rect(rect1,rect2)
  or
  rect_in_rect(rect2,rect1)
end

function
rect_in_rect(rect1,rect2)
 return
  point_intersect(
   rect1[1],rect1[2],rect2)
  or
  point_intersect(
   rect1[1],rect1[4],rect2)
  or
  point_intersect(
   rect1[3],rect1[2],rect2)
  or
  point_intersect(
   rect1[3],rect1[4],rect2)
end

function
point_intersect(x,y,rect2)
 return
  x>=rect2[1] and
  x<=rect2[3] and
  y>=rect2[2] and
  y<=rect2[4]
end

function grab()
 for banana in all(bananas) do
  if intersect(
      player_rect(),
      {banana.x+1,banana.y,
       banana.x+6,banana.y+7})
  and not banana.flying
  and not banana.falling
  then
   grab_banana(banana)
  end
 end
end

function grab_banana(banana)
 if player.lives<c_max_lives
 then
  player.lives+=1
 end
 score+=50
 sfx(c_sfx_banana)
 del(bananas,banana)
end

function boomerang_input()
 if btnp(5)
 and not boomerang.active then
  shoot_boomerang()
 end
end

function shoot_boomerang()
 boomerang.follow=false
 boomerang.active=true
 boomerang.x=player.x
 boomerang.y=player.y
 boomerang.dir=
  get_boomerang_dir()
 boomerang.speed=
  get_boomerang_speed()
 boomerang.acc=-0.2
end

function get_boomerang_dir()
 local p=player
 if p.dx==0 and p.dy==0 then
  if p.dir==c_right then
   return 0
  elseif p.dir==c_up then
   return 0.25
  elseif p.dir==c_left then
   return 0.5
  elseif p.dir==c_down then
   return 0.75
  end
 else
  return atan2(p.dx,p.dy)
 end
end

function get_boomerang_speed()
 local p=player
 if p.dx~=0 or p.dy~=0 then
  return c_max_boomerang_speed
 else
  return c_max_boomerang_speed
         -0.5
 end
end

c_max_boomerang_speed=4
function update_boomerang(b)
 if b.active then
  play_boomerang_sfx()
  inc_walk_count(b)
  acc_boomerang(b)
  boomerang_turning_point(b)
  boomerang_follow(b)
  move_polar(b)
  col_boomerang(b)
 end
end

function play_boomerang_sfx()
 if stat(18)~=c_sfx_boomerang
 then
  sfx(c_sfx_boomerang,2)
 end
end

function acc_boomerang(b)
 b.speed=
  min(b.speed+b.acc,
      c_max_boomerang_speed)
end

function
boomerang_turning_point(b)
 if b.speed<0 then
  b.follow=true
  b.dir=(b.dir+0.5)%1
  b.acc=-b.acc
 end
end

function boomerang_follow(b)
 if b.follow then
  norm_x=(player.x-b.x)/128
  norm_y=(player.y-b.y)/128
  b.dir=atan2(norm_x,norm_y)
 end
end

function move_polar(b)
 dx=cos(b.dir)*b.speed
 dy=sin(b.dir)*b.speed
 b.x+=dx
 b.y+=dy
end

function col_boomerang(b)
 col_boomerang_player(b)
 col_boomerang_enemies()
end

function
col_boomerang_player(b)
 x=b.x+3; y=b.y+3
 if b.follow and
    x<=player.x+7 and
    x>=player.x   and
    y<=player.y+7 and
    y>=player.y
 then
  b.active=false
 end
end

function
col_boomerang_enemies()
 foreach(birds,
  col_boomerang_bird)
 foreach(teeths,
  col_boomerang_teeth)
end

function
col_boomerang_bird(bird)
 local b=boomerang
 rect1=get_boomerang_rect()
 if intersect(
     rect1,
     {bird.x,bird.y,
      bird.x+6,bird.y+7})
 then
  kill_bird(bird)
 end
end

function
col_boomerang_teeth(teeth)
 if not teeth.active then
  return
 end
 local b=boomerang
 rect1=get_boomerang_rect()
 if intersect(
     rect1,
     {teeth.x,teeth.y,
      teeth.x+6,teeth.y+6})
 then
  kill_teeth(teeth)
 end
end

function kill_bird(bird)
 sfx(c_sfx_bird)
 del(birds,bird)
 score+=2
 create_bird_particles(bird)
end

c_cols_bird={7,8,9}
function
create_bird_particles(bird)
 x=bird.x+3
 y=bird.y+3
 dxoffs=bird.dx+
  cos(boomerang.dir)
  *boomerang.speed
 dyoffs=bird.dy+
  sin(boomerang.dir)
  *boomerang.speed
 for i=1,5 do
  add(particles,
   create_particle(x,y,
    dxoffs,dyoffs,
    c_cols_bird[flr(
                rnd(3))+1]))
 end
end

function create_particle(
x,y,dxoffs,dyoffs,col)
 return {
  x=x,y=y,
  col=col,
  dx=rnd(2)-1+dxoffs,
  dy=-rnd(1)+dyoffs,
  ddy=0.1,
  count=30
 }
end

function kill_teeth(teeth)
 sfx(c_sfx_teeth)
 del(teeths,teeth)
 score+=5
 create_teeth_particles(teeth)
end

c_cols_teeth={7,8,2}
function
create_teeth_particles(teeth)
 x=teeth.x+4
 y=teeth.y+4
 dxoffs=cos(boomerang.dir)
  *boomerang.speed
 dyoffs=sin(boomerang.dir)
  *boomerang.speed
 for i=1,5 do
  add(particles,
   create_particle(x,y,
    dxoffs,dyoffs,
    c_cols_teeth[flr(
                 rnd(3))+1]))
 end
end

function get_boomerang_rect()
 return {
  boomerang.x,
  boomerang.y,
  boomerang.x+7,
  boomerang.y+7,
 }
end

function update_storks()
 foreach(storks,update_stork)
end

function update_bananas()
 foreach(bananas,update_banana)
end

function update_stork(stork)
 stork.x+=stork.dx
 inc_walk_count(stork)
 if is_outside(stork) then
  del(storks,stork)
 end
end

function update_banana(banana)
 if banana.flying then
  banana.x+=banana.dx
  inc_walk_count(stork)
  if banana.x==60 then
   banana.flying=false
   banana.falling=true
  end
 elseif banana.falling then
  banana.y+=banana.dy
  banana.fall_count-=1
  if banana.fall_count==0 then
   banana.falling=false
  end
 end
end

function
update_particle(particle)
 particle.x+=particle.dx
 particle.y+=particle.dy
 particle.dy+=particle.ddy
 particle.count-=1
 if particle.count<1 then
  del(particles,particle)
 end
end

function update_enemies()
 foreach(birds,update_bird)
 foreach(teeths,update_teeth)
end

function update_bird(bird)
 bird.x+=bird.dx
 bird.y+=bird.dy
 inc_walk_count(bird)
 if is_outside(bird) then
  del(birds,bird)
 end
end

function update_teeth(teeth)
 if not teeth.active then
  dig(teeth)
  return
 end
 inc_walk_count(teeth)

 norm_x=(player.x-teeth.x)/128
 norm_y=(player.y-teeth.y)/128
 teeth.dir=atan2(norm_x,norm_y)

 move_polar(teeth)
end

function dig(teeth)
 teeth.dig_count-=1
 create_dig_particle(
  teeth.x,teeth.y)
 if teeth.dig_count==0 then
  teeth.active=true
 end
end

c_cols_dig={4,5,0,15}
function
create_dig_particle(x,y)
 particle=
  create_particle(x+4,y+4,0,0,
   c_cols_dig[flr(
              rnd(4))+1])
 particle.count=10
 add(particles,particle)
end

function is_outside(actor)
 return actor.x>127
     or actor.x<-7
     or actor.y>127
     or actor.y<-7
end

function generate_storks()
 d=get_difficulty()
 if flr(rnd(1200+(d/10)))
    >=1199
 and #bananas==0
 then
  stork=create_stork()
  banana=create_banana(stork)
  add(storks,stork)
  add(bananas,banana)
 end
end

c_stork_dx=1
function create_stork()
 --dir is right or left
 dir=1+flr(rnd(2))*2
 if dir==c_left then
  x=128
  dx=-c_stork_dx
 elseif dir==c_right then
  x=-8
  dx=c_stork_dx
 end
 y=8+rnd(64)

 return {
  x=x,y=y,
  dir=dir,
  dx=dx,
  walk_count=0
 }
end

function create_banana(stork)
 if stork.dir==c_left then
  xoffs=9
 elseif stork.dir==c_right then
  xoffs=-1
 end
 yoffs=13
 return {
  x=stork.x+xoffs,
  y=stork.y+yoffs,
  dx=stork.dx,
  dy=1,
  walk_count=0,
  fall_count=16,
  flying=true,
  falling=false
 }
end

function generate_enemies()
 d=get_difficulty()
 if flr(rnd(50+(d/5)))>=49 then
  add(birds,create_bird())
 end
 if flr(rnd(88+
            (d/2)-
            #teeths)+
        min(flr(d),3))
    >=89
 then
  add(teeths,create_teeth())
 end
end

function get_difficulty()
 return sec_timer/10
end

c_bird_base_speed=1
c_bird_xtra_speed=1
c_bird_side_speed=0.5
function create_bird()
 d=get_difficulty()
 dirz=flr(rnd(4))+1
 main_speed=
  c_bird_base_speed
  +rnd(c_bird_xtra_speed
       +(d/20))
 side_speed=
  -c_bird_side_speed
  +rnd(2*c_bird_side_speed)
 if dirz==c_left then
  x=128
  y=rnd(128)
  dx=-main_speed
  dy=side_speed
 elseif dirz==c_right then
  x=-8
  y=rnd(128)
  dx=main_speed
  dy=side_speed
 elseif dirz==c_down then
  x=rnd(128)
  y=8
  dx=side_speed
  dy=main_speed
 elseif dirz==c_up then
  x=rnd(128)
  y=128
  dx=side_speed
  dy=-main_speed
 end

 return {
  x=x,y=y,
  dx=dx,dy=dy,
  walk_count=0,
  dir=dirz
 }
end

function create_teeth()
 repeat
  celx=flr(rnd(15))
  cely=flr(rnd(15))
 until
  is_cell_walkable(celx,cely)
 d=get_difficulty()
 return {
  x=celx*8,
  y=cely*8,
  speed=0.2+min(d/15,0.8),
  active=false,
  dig_count=60,
  walk_count=0,
  dir=0.75
 }
end

function
is_cell_walkable(celx,cely)
 return
  fget(mget(celx,cely),
       c_flag_walkable)
end

function update_game_over()
 update_sea()
 if new_high_score then
  update_name_marker()
 else
  game_over_count-=1
  if btnp(4) or btnp(5)
  or game_over_count<1 then
   init_menu()
  end
 end
end

function update_name_marker()
 name_marker_count=
  (name_marker_count+1)%30
 name_input()
end

function name_input()
 if letter_index<4 and
 (btnp(1) or btnp(4)
 or btnp(5))
 then
  letter_index=
   min(letter_index+1,4)
 elseif btnp(0) then
  letter_index=
   max(letter_index-1,1)
 elseif btnp(2)
 and letter_index<4 then
  alphabet_index[letter_index]=
  ((alphabet_index[letter_index]
  -2)
   %#alphabet)+1
 elseif btnp(3)
 and letter_index<4 then
  alphabet_index[letter_index]=
  (alphabet_index[letter_index]
   %#alphabet)+1
 elseif (btnp(4) or btnp(5))
 and letter_index==4 then
  set_best_player()
  set_high_score(score)
  init_menu()
 end
end

alphabet={
 "a","b","c","d","e","f","g",
 "h","i","j","k","l","m","n",
 "o","p","q","r","s","t","u",
 "v","w","x","y","z"," ","&",
 "-","_","!","?","$","0","1",
 "3","4","5","6","7","8","9"
}

function set_best_player()
 dset(1,alphabet_index[1])
 dset(2,alphabet_index[2])
 dset(3,alphabet_index[3])
end

function set_high_score(score)
 dset(4,score)
 dset(5,1)
end

---- draw ----

function _draw()
 cls()
 if state==c_state_menu then
  draw_menu()
 elseif state==c_state_game
 then
  draw_game()
 elseif state==c_state_over
 then
  draw_game_over()
 elseif state==c_state_death
 then
  draw_death()
 end
end

c_spr_button=076
function draw_menu()
 draw_sea()
 draw_logo()
 draw_press()
 draw_high_score()
 draw_credits()
end

function draw_logo()
 print("mr. monkey's",22,24,9)
 print("mr. monkey's",22,23,10)
 sspr(0,96,96,32,22,29)
end

function draw_press()
 print("press",43,82,9)
 print("press",43,81,10)
 draw_menu_button()
 print("!",83,82,9)
 print("!",83,81,10)
end

function draw_menu_button()
 yoffs=0
 if flr(menu_count/10)==0 then
  palt(2,true)
  yoffs=1
 end
 spr(c_spr_button,66,76+yoffs,
     2,2)
 if flr(menu_count/10)==0 then
  palt(2,false)
 end
end

function draw_high_score()
 if dget(5)==1 then
  print("high score by "
        ..get_best_player()
        ..": "
        ..get_high_score(),
        credits_x-12,2)
 end
end

function get_best_player()
 return
  alphabet[dget(1)]..
  alphabet[dget(2)]..
  alphabet[dget(3)]
end

function get_high_score()
 return dget(4)
end

function draw_credits()
 print("made by sfabian",
       credits_x,120)
 spr(001,credits_x+62,117,1,2)
end

function draw_death()
 draw_sea()
 draw_map()
 foreach(teeths,draw_teeth)
 foreach(bananas,draw_banana)
 draw_tree_trunk()
 draw_dead_player()
 foreach(particles,
         draw_particle)
 draw_tree()
 foreach(birds,draw_bird)
 foreach(storks,draw_stork)
 draw_boomerang()
 draw_score()
end

c_sprs_death={{48,64},
              {48,80}}
function draw_dead_player()
 death_time=
  flr((death_count
       /c_max_death_count)*4)
 dx=0
 flipx=false; flipy=false
 if death_time>=3 then
  sxy=c_sprs_death[1]
  sw=8; sh=10
 elseif death_time==2 then
  sxy=c_sprs_death[2]
  sw=10; sh=8
  dx=-1
 elseif death_time==1 then
  sxy=c_sprs_death[1]
  sw=8; sh=10
  flipy=true
 elseif death_time==0 then
  sxy=c_sprs_death[2]
  sw=10; sh=8
  dx=-1
  flipx=true
 end

 sspr(sxy[1],sxy[2],sw,sh,
      player.x+dx,player.y,
      sw,sh,flipx,flipy)

end

function draw_game()
 draw_sea()
 draw_map()
 foreach(teeths,draw_teeth)
 foreach(bananas,draw_banana)
 draw_tree_trunk()
 draw_player()
 foreach(particles,
         draw_particle)
 draw_tree()
 foreach(birds,draw_bird)
 foreach(storks,draw_stork)
 draw_boomerang()
 draw_lives()
 draw_score()
end

function draw_sea()
 palt(c_clr_black,true)
 palt(c_clr_maroon,false)

 rectfill(0,0,127,127,
          c_clr_blue)
 foreach(waves,draw_wave)

 set_transparency()
end

function set_transparency()
 palt(c_clr_black,false)
 palt(c_clr_maroon,true)
end

function draw_wave(wave)
 spr(wave.spr,wave.x,wave.y)
end

function draw_map()
 map(0,0,0,0,16,16)
end

function
draw_particle(particle)
 circ(particle.x,particle.y,0,
      particle.col)
end

function draw_player()
 if not player.walking then
  spr_info=
   get_pl_idle_spr_info()
 else
  spr_info=
   get_pl_walk_spr_info()
 end
 sprite=spr_info[1]
 flipz=spr_info[2]

 draw_pl_sprite(sprite,flipz)
end

function get_pl_idle_spr_info()
 if player.dir==c_right then
  return {
   c_spr_pl_right_idle,
   false
  }
 elseif player.dir==c_up then
  return {
   c_spr_pl_up_idle,
   false
  }
 elseif player.dir==c_left then
  return {
   c_spr_pl_right_idle,
   true
  }
 elseif player.dir==c_down then
  return {
   c_spr_pl_down_idle,
   false
  }
 end
end

function get_pl_walk_spr_info()
 n=animation_no(player)
 flipz=n==2
 if player.dir==c_right then
  return {
   c_spr_pl_right_walk[n],
   false
  }
 elseif player.dir==c_up then
  return {
   c_spr_pl_up_walk,
   flipz
  }
 elseif player.dir==c_left then
  return {
   c_spr_pl_right_walk[n],
   true
  }
 elseif player.dir==c_down then
  return {
   c_spr_pl_down_walk,
   flipz
  }
 end
end

function animation_no(player)
 if player.walk_count
    < c_max_walk_count/2
 then
  return 1
 else
  return 2
 end
end

function
draw_pl_sprite(sprite,flipz)
 if should_blink() then
  pal(4,8)
  pal(15,14)
 end
 sspr(sprite*8,0,
      8,10,
      player.x,player.y,
      8,10,
      flipz)
 pal()
 set_transparency()
end

function should_blink()
 return
  player.invincibility>0
  and player.walk_count%4==0
end

c_spr_tree_1=132
c_spr_tree_2=133
c_spr_tree_3=148
c_spr_tree_4=149
c_spr_tree_5=164
function draw_tree()
 spr(c_spr_tree_1,32,40)
 spr(c_spr_tree_2,40,40)
 spr(c_spr_tree_3,32,48)
 spr(c_spr_tree_4,40,48)
end

function draw_tree_trunk()
 spr(c_spr_tree_5,32,56)
end

c_sprs_bird_right={104,120}
c_sprs_bird_down={105,121}
c_sprs_bird_up={106,122}
function draw_bird(bird)
 if bird.dir==c_right then
  sprs=c_sprs_bird_right
  flipz=false
  sw=8
 elseif bird.dir==c_left then
  sprs=c_sprs_bird_right
  flipz=true
  sw=8
 elseif bird.dir==c_up then
  sprs=c_sprs_bird_up
  flipz=false
  sw=9
 elseif bird.dir==c_down then
  sprs=c_sprs_bird_down
  flipz=false
  sw=9
 end

 if bird.walk_count<
  c_max_walk_count/2
 then
  sprite=sprs[1]
 else
  sprite=sprs[2]
 end

 sx=(sprite%16)*8
 sy=flr(sprite/16)*8

 sspr(sx,sy,sw,8,
      bird.x,bird.y,sw,8,
      flipz)
end

c_sprs_stork_right={128,160}
function draw_stork(stork)
 sprs=c_sprs_stork_right
 if stork.dir==c_right then
  flipz=false
 elseif stork.dir==c_left then
  flipz=true
 end

 if stork.walk_count<
  c_max_walk_count/2
 then
  sprite=sprs[1]
 else
  sprite=sprs[2]
 end

 yoffs=
  -flr(stork.walk_count/4)*2

 spr(sprite,
     stork.x,stork.y+yoffs,
     2,2,
     flipz)
end

c_spr_banana=030
function draw_banana(banana)
 sprite=c_spr_banana

 if banana.flying then
  yoffs=
   -flr(banana.walk_count/4)*2
 else
  yoffs=0
 end

 spr(sprite,
     banana.x,banana.y)
end

c_sprs_teeth_right={008,024}
c_sprs_teeth_up={041,057}
c_sprs_teeth_down={009,025}
function draw_teeth(teeth)
 if not teeth.active then
  draw_crack(teeth)
  return
 end

 if teeth.dir<0.125 or
    teeth.dir>=0.875
 then
  sprs=c_sprs_teeth_right
  flipz=false
 elseif teeth.dir>=0.125 and
        teeth.dir<0.375
 then
  sprs=c_sprs_teeth_up
  flipz=false
 elseif teeth.dir>=0.375 and
        teeth.dir<0.625
 then
  sprs=c_sprs_teeth_right
  flipz=true
 elseif teeth.dir>=0.625 and
        teeth.dir<0.875
 then
  sprs=c_sprs_teeth_down
  flipz=false
 end

 if teeth.walk_count<
  c_max_walk_count/2
 then
  sprite=sprs[1]
 else
  sprite=sprs[2]
 end

 yoffs=-flr(teeth.walk_count/2)

 spr(sprite,
     teeth.x,teeth.y+yoffs,
     1,1,flipz)
end

c_spr_crack=085
function draw_crack(crack)
 xoffs=flr(rnd(2))-2
 yoffs=flr(rnd(2))-2
 spr(c_spr_crack,
     crack.x+xoffs,
     crack.y+yoffs)
end

function draw_boomerang()
 local b=boomerang
 if b.active then
  spr_i=b.walk_count+1
  spr(c_sprs_boomerang[spr_i],
      b.x,b.y)
 end
end

c_spr_heart=056
function draw_lives()
 x=106
 y=1
 for i=1,player.lives do
  spr(c_spr_heart,x,y)
  x+=7
 end
end

function draw_score()
 x=2
 y=2
 print("score: "..score,
       x,y+1,9)
 print("score: "..score,
       x,y,10)
end

function draw_game_over()
 draw_sea()
 if score<=get_high_score()
 then
  draw_worse_score()
 else
  draw_new_high_score()
 end
end

function draw_worse_score()
 print("your score",44,31,9)
 print("your score",44,30,10)
 xoffs=get_score_xoffs(score)
 print(score,63+xoffs,40,9)
 print(score,63+xoffs,39,10)

 print("high score by "
       ..get_best_player(),
       30,65,9)
 print("high score by "
       ..get_best_player(),
       30,64,10)
 xoffs=get_score_xoffs(
       get_high_score())
 print(get_high_score(),
       63+xoffs,74,9)
 print(get_high_score(),
       63+xoffs,73,10)
end

function draw_new_high_score()
 print("new high score!",
       34,31,9)
 print("new high score!",
       34,30,10)
 xoffs=get_score_xoffs(score)
 print(score,63+xoffs,40,9)
 print(score,63+xoffs,39,10)

 print("enter your name:",
       32,65,9)
 print("enter your name:",
       32,64,10)
 print(get_name(),
       58,74,2)
 print(get_name(),
       58,73,8)
 draw_name_marker()
end

function get_name()
 return
  alphabet[alphabet_index[1]]
 ..alphabet[alphabet_index[2]]
 ..alphabet[alphabet_index[3]]
end

c_spr_marker=061
c_spr_ok=060
function draw_name_marker()
 if name_marker_count<=10 then
  if letter_index<4 then
   spr(c_spr_marker,
       53+letter_index*4,
       73)
  end
 elseif letter_index==4 then
  spr(c_spr_ok,
      54+letter_index*4,
      74)
 end
end

function get_score_xoffs(score)
 xoffs=0
 temp_score=score
 while temp_score>1 do
  temp_score/=10
  xoffs-=2
 end
 return xoffs
end
__gfx__
000000001111411111114111111411111114111111114111111114111111411111118881118888111111e1eeee1e1111111121eeee1211111113011111111111
000000001114441111144411114441111144411111144411111444411114441111188271182172811112ee0ee0ee21111112eeeeeeee211111ba111111111111
00700700114fff41114fff4114444411144444111144fff111444ff1114fff4111827111187111811112e270072e21111112eeeeeeee21111ba1111111111111
0007700014f0f0f414f0f0f44444444144444441144f0f0f1444f0f114f0f0f4187111118111117811112e0ee0e211111111eeeeeeee11111ba1111111111111
0007700014f0f0f414f0f0f44444444144444441144f0f0f1444f0ff14f0f0f418711111871111181111eeeeeeee11111111eeeeeeee11111bba111111111111
00700700414fff41414fff4114444414144444144144fff141444ff1414fff4118887111821117281111e20ee02e11111111eeeeeeee111113bbaa1111111111
000000000444444104444441144444401444444041444441414444410444444111288171182712811111120ee021111111111eeeeee11111113bbb3111111111
0000000010444441104444411444440114444401044444410494444110444441111128811188881111111e2222e11111111112eeee2111111113331111111111
11111111114444411144444914440011944400111044444110994441114444491111111111111111111eeeeeeeeee111111eeeeeeeeee1111114011111111111
1111111111911191119111911911191119111911119111911119191111911191111188811181181111eeee2222eeee1111eeeeeeeeeeee1111a9111111110011
111111111111111111111111111111111111111111111111111111111111111111888288188888811eee22eeee22eee11eeeeeeeeeeeeee11aa1111111114111
1111111111111111111111111111111111111111111111111111111111111111181717178171717812e2eee22eee2e2112e2eeeee22e2e211aa11111111a9111
111111111111111111111111111111111111111111111111111111111111111118717171881717881121eeeeeeee12111121eeee22ee121119aa111111aaa111
111111111111111111111111111111111111111111111111111111111111111118888888288888821111eeeeeeee11111111eeee2eee1111149aaa11a1a9aa1a
111111111111111111111111111111111111111111111111111111111111111111288821128888211111eeeeeeee11111111eeeeeeee1111114999419a949aa9
111111111111111111111111111111111111111111111111111111111111111111111111111111111111ee1111ee11111111ee1111ee11111114441111111111
11111111111141111114111111111111111111111111111111111111111111111111111111888811111222111122211111122211112221111110011111111111
11111111111444111144411111111111111182111118822111111111111111111111111118861881111111111111111111111111111111111194111111110011
11111111114fff411444441111111111111821111188211111188111112288111111111118211681111111111111111111111111111111111941111111110111
1111111114f0f0f44444444111111111118211111182111111822811111128811111111186111118111111111111111111111111111111111941111111194111
1111111114f0f0f44444444111111111118211111121111118211281111112811111111182111168111111111111111111111111111111111494111111999111
11111111114fff411444441111111111111821111121111112111121111111211111111188611288111111111111111111111111111111111049491191949919
11111111144444411444444111111111111182111111111111111111111111211111111118816881111111111111111111111111111111111104440149404994
11111111144444411444444111111111111111111111111111111111111111111111111111888811111111111111111111111111111111111110001111111111
111111111044444114440401111111111111111111111111111111111111111111111111111111111111111111111111222111111eee11111111111111111111
111111111191119119111011111111111128111111111111111111111211111111e18111118118111111111111111111212111111eee11111140111111111111
11111111111111111111111111111111111281111111121112111121121111111e7e8811188888811111111111111111228181111eee11111401011111114111
111111111111111111111111111111111111281111111211182112811821111118e88811822222281719171111191111118811111eee11111401111111144011
111111111111111111111111111111111111281111112811118228111882111111888111882222881199791111997911118181111eee11111440111111444001
111111111111111111111111111111111112811111128811111881111188221111181111288888821119911117199711111111111eee11111044041141404414
11111111111111111111111111111111112811111228811111111111111111111111111112888821111111111111111111111111111111111104440104000440
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110001111111111
14444411444414444411444444444111144444444111444444414444444444440100000001010000070000000707000011111111111111111111111661111111
44ff6444fff444fff4444fffffff444444ffffff44444fffff444fffffffff411d1000001d1d1000707000007070700011111888888111111111111661111111
4ffffffff6fffffffffffffff6ffff6446fff6fff6fffff6ffffff6ff6ffff44d0d00000d0d0d000000000000000000011188888888881111111116666111111
4ffffffffffffffffffffffffffffff44fffffffffffffffff6ffffffffffff40000000000000000000000000000000011888888888888111111116666111111
4ffffffffffffffffffff6fffffffff44fff6fffffff6fffffffffffffff6ff40000000000000000000000000000000018888888888888811111166666611111
4fffff6fffffffffffffffffffffff444ffffffffffffffffffffffffffffff40000000000000000000000000000000018888888888888811111166666611111
46fffffff6fff6fff6ffffffffff6f4144ff444fffff4444f46fffffffffff440000000000000000000000000000000088888888888888881111666666661111
4fffffffffffffffffffffffffffff44144441444444411444444444444444410000000000000000000000000000000088888888888888881111666666661111
4f6ffffff6ffffffffffffffffffff44144444441101111111111111111111111111111111111111111111111111111188888888888888881116666666666111
4fffffffffffff6f6fffffffff6fff4144fff6f4115111111111111111111111111111111111111111111111111111112888888888888882111ddd6666ddd111
44ffffffffffffffffffff6fffffff444ffffff4114411111110511111115011111111111111111111111111111111112888888888888882111ddd6666ddd111
14fffffffffffffffffffffffffffff44ffffff41114945011115411111551111111111111111111111111111111111112888888888888211111116666111111
14fffffffffffffffffffffffffffff44fff6ff41549941111111441114451111111111111111111111111111111111112288888888882211111116666111111
44fffff6ffffff6ffffffffffffffff446fffff40511141111111144144511111111111111111111111111111111111111222888888222111111116666111111
46ffffffff6ffffffff6fffffffff6f44ffffff4111115511111144949411111111111111111111111111111111111111112222222222111111111dddd111111
4ffffffffffffffffffffff6fffffff44ffffff4111111011111119494941111111111111111111111111111111111111111122222211111111111dddd111111
4ffffffffffffffffffffffffffffff44ffffff41111111111111445444511111100001110001000100010001111111111111111111111111111116666111111
4ffffffffffffffffffffffffff6fff44ffffff41111111111114551554111117710000171000001710000011111111111111111111111111111116666111111
4fffff6ff6fffffffff6ffffffffff4444fffff411111111111551111155111117717e01777e0e77777666777111111111111161111111111111116666111111
44ffffffffffffffffffff6fffffff4114f6fff41111111111551111111551111676779917679767177666777111111111111166611111111111116666111111
14ffffffffffffffffffffffffffff4144ffff441111111111011111111110116666699111199911117666711111111111111166666111111111116666111111
44fffffffffffffffffffffff6ffff414fffff411111111111111111111111111161111111169611111666111111111116666666666661111116666666666111
4ff6ffffff6fffffffffffffffffff444ffff641111111111111111111111111111911111191119111916191111111111666666666666661111d66666666d111
4fffffffffffffffff6ffffffffff6f44fffff44111111111111111111111111111111111111111111111111111111111666666666666661111d66666666d111
4ffffffffffffffffffffffff6fffff44ffffff4ff6666ffff6666ff11111111110000111000100010001000111111111666666666666dd11111d666666d1111
4fffffffff6ffffffffffffffffffff44fffff64f666666ff666666f11111111111000011100000111000001111111111ddddd66666dddd11111d666666d1111
4ff6fffffffff6ffffffff6ffffff6f44fffff446666666ff66656661111111111117e01117e0e7111766671111111111ddddd666dddd11111111d6666d11111
4ffffffffffffffffffffffffffffff44ffffff4666666666666665611111111166677991767976717766677111111111111116dddd1111111111d6666d11111
4fffffffff6ffffff6ffffffff6ffff44ffffff465666656656666661111111167766991771999177776667711111111111111ddd1111111111111d66d111111
44ff6ffffffffffffffff6fffffffff446fff6f456665665566666551111111177611111711696117116661171111111111111d111111111111111d66d111111
14ffff4fffff4444444ffffffff4444444ffff440556655005566550111111117119111111911191119161917111111111111111111111111111111dd1111111
1444444444444114414444444444114114444441f055550ff055550f111111111111111111111111111111111111111111111111111111111111111dd1111111
111111111111111111111111111111111bbbbb1111bbbbb111114111111111110000000011111111111111110000000000000000000000000000000000000000
11111111117771111117771111111111bb333bb11bb333bb11144411111111110000000011111111111111110000000000000000000000000000000000000000
115551111777e711117e777111155511b31153bbbb35113b114fff41111111110000000011111111111111110000000000000000000000000000000000000000
11155771177e27111172e771177551115111133bbb3111151400f004111111110000000011111111111111110000000000000000000000000000000000000000
11555577177769111196777177555511111113bbbbbb111114fffff4111111110000000011111111111111110000000000000000000000000000000000000000
11155777117799911999771177755111111bbb3333bbb111414fff41111111110000000011111111111111110000000000000000000000000000000000000000
1111177776711149941117677771111111b333525333bb1104444441111111110000000011111111111111110000000000000000000000000000000000000000
111111776666111441116666771111111b33522211133b1110444441111111110000000011111111111111110000000000000000000000000000000000000000
11111666666611111111666666611111133124451111331119444449111111110000000000000000000000000000000000000000000000000000000000000000
11111166665111111111156666111111131944411111151111911191111111110000000000000000000000000000000000000000000000000000000000000000
11911916651111111111115661911911151944511111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
19999141111111111111111114199991119444111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111411111111111111111111411111119445111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11994111111111111111111111149911119445111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11141111111111111111111111114111119445111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111119445111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111944411ff9444ff11104111111111110000000000000000000000000000000000000000000000000000000000000000
1111111111777111111111111111111111994411ff9944ff19041441111111110000000000000000000000000000000000000000000000000000000000000000
111111111777e711111111111111111111194411fff944ff94444f04111111110000000000000000000000000000000000000000000000000000000000000000
11111111177e2711111111111111111111194451fff9445f1444ff0f411111110000000000000000000000000000000000000000000000000000000000000000
1111111117776911111111111111111111194441fff944461444ffff441111110000000000000000000000000000000000000000000000000000000000000000
1111111111779991111111111111111111194441fff9444f1444ff0f411111110000000000000000000000000000000000000000000000000000000000000000
11111177767111491111111111111111111944516ff9445f94444f04111111110000000000000000000000000000000000000000000000000000000000000000
1111177776661114111111111111111111114511ffff45ff19111441111111110000000000000000000000000000000000000000000000000000000000000000
11155777666611111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11155577665111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11555776651111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
19555141111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11115411111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11994111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11141111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88881111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88288811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88122888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88111228811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88111888211111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000
88188822111111888111118881118181118111188811181881111888111118188811118881181111111111111111111111111111111111110000000000000000
88882211111118222811182228118828182811822281188228118222811118822281182228821111111111111111111111111111111111110000000000000000
88288811111182111281821112818212821818211128182112182111281118211181821112811111111111111111111111111111111111110000000000000000
88122888111181111181811111818111811818888882181111181111181118111181811111811111111111111111111111111111111111110000000000000000
88111228881181111181811111818111811818222221181111181111181118111181811111811111111111111111111111111111111111110000000000000000
88111112288128111821281118218111211812811118181111128111881818111181281118811111111111111111111111111111111111110000000000000000
88111118882112888211128882118111111811288882181111112888228218111181128882811111111111111111111111111111111111110000000000000000
88111888221111222111112221112111111211122221121111111222112112111121112221811111111111111111111111111111111111110000000000000000
88188822111111111111111111111111111111111111111111111111111111111111811111811111111111111111111111111111111111110000000000000000
88882211111111111111111111111111111111111111111111111111111111111111281118211111111111111111111111111111111111110000000000000000
8822111111aaaaa11111111111111111111111111111111111111111111111111111181118111111111111111111111111111111111111110000000000000000
2211111111aaaaaaa111111111111111111111111111111111111111111111111111128182111111111111111111111111111111111111110000000000000000
1111111111aa999aaa111111111111111111111111111111111111111111111111111128211111aaa11111111111111111111111111111110000000000000000
1111111111aa1119aa11111111111111111111111111111111111111111111111111111211111aaaaa1111111111111111111111111111110000000000000000
1111111111aa1111aa11111111111111111111111111111111111111111111111111111111111aaaaa1111111111111111111111111111110000000000000000
1111111111aa111aa111111111111111111111111111111111111111111111111111111111111aaaaa1111111111111111111111111111110000000000000000
1111111111aaaaaaa11111aaaa111aa11111aa11aaaaaa11aa11111aa1aaaaaaaa111aaaa1111aaaaa1111111111111111111111111111110000000000000000
1111111111aaaaaaaa111aaaaaa11aaa1111aa1aaaaaaaa1aaa1111aa1aaaaaaaa11aaaaaa111aaaaa1111111111111111111111111111110000000000000000
1111111111aa9999aaa1aaa99aaa1aaaa111aa1aaa99aaa1aaaa111aa199999aa91aaa99aaa119aaa91111111111111111111111111111110000000000000000
1111111111aa11119aa1aa9119aa1aa9aa11aa1aa9119aa1aa9aa11aa1111aaa911aa9119aa1119a911111111111111111111111111111110000000000000000
1111111111aa11111aa1aa1111aa1aa19aa1aa1aa1111aa1aa19aa1aa111aaa9111aa1111aa11119111111111111111111111111111111110000000000000000
1111111111aa1111aaa1aaa11aaa1aa119aaaa1aaaaaaaa1aa119aaaa11aa991111aaaaaaaa1111a111111111111111111111111111111110000000000000000
1111111111aaaaaaaa919aaaaaa91aa1119aaa1aaaaaaaa1aa1119aaa1aaaaaaaa1aaaaaaaa111aaa11111111111111111111111111111110000000000000000
1111111111aaaaaaa91119aaaa911aa11119aa1aa9999aa1aa11119aa1aaaaaaaa1aa9999aa1119a911111111111111111111111111111110000000000000000
11111111119999999111119999111991111199199111199199111119919999999919911119911119111111111111111111111111111111110000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010000000000000000010101010101000000000000000000000101010101000000000000000000000001010101010000000000000000000000
0000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000054004043000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040414251415151430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000444151625151515251514300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044415151515251517652515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000505162615151615151515141470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000605161515151515252615253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005062a5516261515152755263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000705152515251615152515173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006062625151515262516300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044465162625162625151515300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006051755151515151515143000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000405151515151625152515253000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000705252517271515171725173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000007072730000707300007400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0102000031054330523404232042300322a0322502222022180121801522002180050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01140000281542815427154271542615426154251541c1541e1542115421150211542115021150211501c1501e150211502115021154211502315023150251522515225152251522515228150251502815025150
01140000281542815427154271542615426154251541e154251542115421150211542115021150211501e15025150211502115021154211502315023150211522115221152211522115220151201521f1511f152
011400001e1511e1521e1551e1502115023150231552315024150251502415025150241502315023150211501e1521e1521e1551e150211502315023155231501c1521c1521c1521c1521e1511e1521e1521e152
011400001e1521e1521e1551e1502115023150231552315024150251502415025150241502315023150211501e1521e1521e1551e150211502315023155231501c1521c1521c1521c1521e1511e1522115121152
011400001e1521e1521e1551e1502115023150231552515225142251322512225132251422515225162251721e1521e1521e1551e15021150231502315023150251501c1501c1501e1501e1501e1501c1501c150
011400001e1521e1521e1551e1502115023150231502315025152251522515228152281522815225152251522a1522a15228152281522515225152231522315221152211521e1521e1521c1521c1521e1521e152
011400002a0622a0722a0722a0622a0622a0322a0422a0522a0622a0722a0722a0622a0622a0522a0522a0422a0322a0222a0322a0422a0522a0622a0722a0752100221002210022100221004210022100221002
01140000281542815427154271542615426154251541e154251542115421150211542115021150211501e15025150211502115021154211502315023150211522115221152211522115521150211552115021155
011400002d105001000000002003266052660526605020032a0052a0252a0052a0452a0052a0652a0052a075253052810427104271042610426104251041c1042a005280252a005280452a005280652a00528075
0114000009033000003e6150903309003090333e6151501309033000003e6150903309003090333e6153e61509033000003e6150903309003090333e6151501309033000003e6150903309003090333e61500000
0114000009033000003e6150903309003090333e6151501309033000003e6150903309003090333e6153e61509033000003e6150903309003090333e6151501309033000003e615090333e6153e6153e6153e615
0114000009033090333e6150903309033090033e6151500309033000003e6150903309003090333e6153e60509033090333e6150903309033090033e6151500309033000003e6150903309003090333e6153e615
0114000009033090333e6153e61509033090333e6153e61509033000003e6150903309003090333e6151501309033000003e6150903309003090333e6153e60509033000003e61509033090333e6153e6153e615
0014000009033090333e6153e61509033090333e6153e61509033000003e6150903309003090333e6151501309033000003e6150903309003090333e6153e60509033000003e615090333e615090033e6153e605
0114000009033090333e6153e61509033090333e6153e61509033000003e6150903309003090333e6151501309033000003e6150903309003090333e6153e60509033090333e6153e61508033080333e6153e615
011a00000e1300e1350e1050e1300b1300b1350b1050b13007130071350710507130091300913509100091300e1300e1350e1050e1300b1300b1350b1050b1300713007135071050713009130091350910009130
011a00001e7401e7401e7401c7401c7401c7401c7401c7401a7401a7401a7401c7401c7401c7401c7401c7401e7401e7401e7401c7401c7401c7401c7401c7401a7401a7401a7401774017740177401774017740
011a000021740217402174023740237402374023740237401e7401e7401e740217402174021740217402174521740217402174023740237402374023740237401e7401e7401e7401c7401c7401c7401c7401c740
011a0000020330000000000020333e615000000000002033020330000000000020333e615210063e61525006020330000000000020333e615000000000002033020330000000000090433e615000003e61500000
011a0000020330000000000020333e61526605266050203302033000003e005020333e6153e6153e615250060203300000000003e0253e6153e0050000002033020330000000000090433e6153e6153e6153e615
011a0000020333e6053e61502033266053e615266050203302033000003e6150203302033020333e6153e605020333e6053e615020333e0053e02509033020333e6143e6103e615020533e6143e6103e61502053
011400002d2352a0252a0052a0452a0052a0652a0052a0752853428534275342753426534265342553425534255352a0252a0052a0452a0052a0652a0052a0752513425134231342313420134201342113421134
001400002a0052a0252a0052a0452a0052a0652a0052a0752a0052a0252a0052a0452a0052a0652a0052a0752a0052a0252a0052a0452a0052a0652a0052a0752a005280252a005280452a005280652a00528075
011400002d205000000000002003266052660526605020032d2052a0252a0052a0452a0052a0652a0052a0752a0052a0052a0052a0052d0052d0052d0052d0052a0052a0252a0052a0452d0052d0652d0652d075
001400000915000000000000915006150041000000006150091500000000000091500615000000000000615002150000000000002150041500000000000041500215000000000000215004150000000415002100
011400000915000000000000915006150041000000006150091500000000000091500615000000000000615002150000000000002150041500000000000041500815000000081500210009150000000915002100
011400000915000000000000915006150041000000006150021500215009150091500615006150000000615002150000000215002100041500000004150041500915009155091500915508150081550715007155
00140000061500000000000061500d150041000000006150091500000000000091500d150000000d15006100021500910000000021500615000000000000215004150000000b1000415008150000000815002100
01140000061500000000000061500d150041000000006150091500000000000091500d150000000d1500610009154091540815408154071540715406154061540215402150021500215404154041500415404150
00140000061500000000000061500d100061500000006100021500000000000041500d100041500d10006100061500910000000061500610006150051500415002150000000b1000415008100041500810002100
01140000061500000000000061500d100061500000006100021500000000000041500d100041500d1000610006150091000000006150061000615005150041500215000000021500410009152091520915209152
011400002a0052a0252a0052a0452a0052a0652a0052a0752833428334273342733426334263342533425334253352a0252a0052a0452a0052a0652a0052a0752523425234262342623427234272342d2342d234
011200000b0730b013050030b0630b013231050b0530b013231502315023155231502315523155231502315023155261502615525155251502515523155231502315522155231502315023140231302312023115
0112000023000230002300526000260052600526000260002303023030230352603026035260352603026030260352a0302a03528035280302803526035260302603525035260302603026020260202601026015
011200000b0000b0000b005000000b0000b00006000060000b0500b0500b055000000b0000b050060500605006055060000b000060500b0500b0550b0000605006055000000b0500b05500000000000000000000
011000001a7551a7551a7551e7551e7551e7551f7551f7551f7552175021750217502675126750267502675026750247502675026750267552600026000000000000000000000000000000000000000000000000
011000000e1500e1550e1000915009155091000e1500e1550e10009150091550910009150091500915009150091500c1500e1500e1500e1550000000000000000000000000000000000000000000000000000000
011000002605526005260252a0552a0052a0252b0552b0052b0252d0552d0052d0052a0342a0302a0302a0302a0302d0302a0302a0302a0350000000000000000000000000000000000000000000000000000000
011000002626225262242522325222242212422023220232202252020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002c2522b2522a2422924228232272322622226222262152020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000e7511f751261512b1512c1512c1512c1512c0512a05129051250512205120051130510c051010510a000060000400001000000000000000000000000000000000000000000000000000000000000000
000500001a624136320b6220261500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000312243a2323522232212312522f2522e2522e255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003034636346303463634600000000003200033000303563635630356363563400034000340000000030366363663036636366000000000000000000003037636376303763637600000000000000000000
010d00001a3441e3502136026350263662a3562d3463232632316323062d306263062a3062a3062d3063230600000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0119430d
00 081a430e
00 0119430d
00 021b430f
00 031c430c
00 041c430c
00 051c430c
00 061d430c
00 071e430a
00 171e570a
00 201e090a
02 161f180b
00 43424344
00 44424344
00 47424344
00 47424344
04 21222344
04 24252644
04 27284344
00 41424344
00 41424344
00 50424344
00 41424344
00 41424344
01 10424313
00 10114313
00 10111214
02 10111215
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

