# User Worlds Data
Every user-made world has a `contrib.data` file inside its world folder which contains information about the world.<br>

The `contrib.data` file follows the following format:<br>

```
[contrib]
name="name"
author="author"
worldmap_scene="worldmap.tscn"
initial_scene="worldmap.tscn"
```
`name` is the name of the world shown in-game.<br>
`author` is the name of the world's creator.<br>
`worldmap_scene` is the relative path for the scene of the world's worldmap.<br>
`initial_scene` is the relative path for the for the initial scene of the world. Players will be brought to this scene if they don't have an existing save file for the world. Typically this scene is used for intro text scrolls.
