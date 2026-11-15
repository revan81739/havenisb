class_name Layers
extends RefCounted
## 2D physics layer numbers (1-based, exactly as shown in the Inspector).
## Every script sets its own layer/mask in _ready() using these constants,
## so you do NOT have to tick any Layer/Mask boxes in the editor.

const PLAYER := 1
const ENEMY := 2
const ASTEROID := 3
const PLAYER_BULLET := 4
const ENEMY_BULLET := 5
const PAD := 6
const GOAL := 7
