.data

.global SHIELD_SPRITE, PLAYER_SPRITE, PLAYER_SPRITE_RESPAWN, NUMBERS, SCORE, ENEMY_BULLET_SPRITE

ENEMY_BULLET_SPRITE:
    .byte 1, 0
    .byte 0, 1
    .byte 1, 0
    .byte 0, 1

    .byte 0, 1
    .byte 1, 0
    .byte 0, 1
    .byte 1, 0
    

# Sprites
SHIELD_SPRITE:
  .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
  .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
  .byte 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1

PLAYER_SPRITE:
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0

PLAYER_SPRITE_RESPAWN:
  .byte 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0
  .byte 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0
  .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1

  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0
  .byte 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0
  .byte 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0
  .byte 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0
  .byte 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0
  .byte 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1
  .byte 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1

NUMBERS:
    # 0
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 1, 1
    .byte 1, 0, 1, 0, 1
    .byte 1, 1, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # 1
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 1, 1, 0

    # 2
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 0, 0, 0, 0, 1
    .byte 0, 0, 1, 1, 0
    .byte 0, 1, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 1, 1, 1, 1

    # 3
    .byte 1, 1, 1, 1, 1
    .byte 0, 0, 0, 0, 1
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 1, 1, 0
    .byte 0, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # 4
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 1, 1, 0
    .byte 0, 1, 0, 1, 0
    .byte 1, 0, 0, 1, 0
    .byte 1, 1, 1, 1, 1
    .byte 0, 0, 0, 1, 1
    .byte 0, 0, 0, 1, 0

    # 5
    .byte 1, 1, 1, 1, 1
    .byte 1, 0, 0, 0, 0
    .byte 1, 1, 1, 1, 0
    .byte 0, 0, 0, 0, 1
    .byte 0, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # 6
    .byte 0, 0, 1, 1, 1
    .byte 1, 1, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # 7
    .byte 1, 1, 1, 1, 1
    .byte 0, 0, 0, 0, 1
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 0, 0, 0
    .byte 0, 1, 0, 0, 0
    .byte 0, 1, 0, 0, 0

    # 8
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # 9
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 1
    .byte 0, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0


SCORE:
    # S
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 0, 1, 1, 1, 0
    .byte 0, 1, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # C
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # O
    .byte 0, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 0, 1, 1, 1, 0

    # R
    .byte 1, 1, 1, 1, 0
    .byte 1, 0, 0, 0, 1
    .byte 1, 0, 0, 0, 1
    .byte 1, 1, 1, 1, 0
    .byte 1, 0, 1, 0, 0
    .byte 1, 0, 0, 1, 0
    .byte 1, 0, 0, 0, 1

    # E
    .byte 1, 1, 1, 1, 1
    .byte 1, 0, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 1, 1, 1, 0
    .byte 1, 1, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 1, 1, 1, 1, 1

    # <
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 0, 0, 0
    .byte 1, 0, 0, 0, 0
    .byte 0, 1, 0, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 0, 1, 0

    # 1
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 1, 1, 0

    # >
    .byte 0, 1, 0, 0, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 0, 0, 1
    .byte 0, 0, 0, 1, 0
    .byte 0, 0, 1, 0, 0
    .byte 0, 1, 0, 0, 0
