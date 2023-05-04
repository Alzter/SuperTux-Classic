# User Worlds Data
Data for user-made worlds (contrib packs) follows a specified format.<br>
```
[contrib]
name="name"
author="author"
worldmap="worldmap.tscn"
initial_scene="worldmap.tscn"
```
`name` is the name of the world shown in-game.<br>
`author` is the name of the world's creator.<br>
`worldmap` is the scene for the world's worldmap.<br>
`initial_scene` is the initial scene of the world. Players will be brought to this scene if they don't have an existing save file for the world. Typically this scene is used for intro text scrolls.