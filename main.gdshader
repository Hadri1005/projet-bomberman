shader_type sky;

uniform samplerCube source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure : hint_range(0, 128) = 1.0;

void sky() {
    // Si l'image paraît retournée/en miroir, essaie de remplacer un des axes par son opposé (ex: -EYEDIR.z)
    vec3 eyedir = vec3(EYEDIR.x, EYEDIR.y, EYEDIR.z);
    COLOR = texture(source_panorama, eyedir).rgb * exposure;
}