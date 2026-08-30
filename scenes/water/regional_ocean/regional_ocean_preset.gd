class_name RegionalOceanPreset
extends Resource

## Reusable regional parameters for the isolated B+ V3 ocean system.
## The primary Gerstner function and boat coupling remain in the system
## controller; this resource only describes useful regional variation.

@export_category("Identity")
@export var preset_id: String = "regional_ocean"
@export var display_name: String = "Regional Ocean"

@export_category("Graphic color")
@export var trough_color: Color = Color(0.022, 0.115, 0.205, 1.0)
@export var water_color: Color = Color(0.048, 0.245, 0.355, 1.0)
@export var crest_color: Color = Color(0.145, 0.36, 0.415, 1.0)
@export var atmospheric_color: Color = Color(0.205, 0.33, 0.39, 1.0)

@export_category("Regional response")
@export_range(0.60, 1.10, 0.01) var amplitude_multiplier: float = 1.0
@export_range(0.20, 1.10, 0.01) var secondary_strength: float = 1.0
@export_range(0.0, 1.0, 0.01) var surface_contrast: float = 0.42
@export_range(0.60, 1.10, 0.01) var saturation: float = 0.90
@export_range(0.0, 1.0, 0.01) var horizon_response: float = 0.18
@export_range(0.0, 0.10, 0.001) var specular_strength: float = 0.055
@export_range(0.0, 0.06, 0.001) var fresnel_strength: float = 0.018

