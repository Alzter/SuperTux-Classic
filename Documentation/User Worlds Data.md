# User Worlds Data
Every user-made world has a `world.data` file inside its world folder which contains information about the world.<br>

The `world.data` file stores a Dictionary of variables in the following format:<br>

```
world_name="name"
author_name="author"
worldmap_scene="worldmap.tscn"
initial_scene="worldmap.tscn"
```
`world_name` is the name of the world shown in-game.<br>
`author_name` is the name of the world's creator.<br>
`worldmap_scene` is the relative path for the scene of the world's worldmap.<br>
`initial_scene` is the relative path for the for the initial scene of the world. Players will be brought to this scene if they don't have an existing save file for the world. Typically this scene is used for intro text scrolls.
