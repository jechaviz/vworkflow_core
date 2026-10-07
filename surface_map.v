module vworkflow_core

import vdirty_regions

pub struct SurfaceTarget {
pub:
	id      string
	kind    string
	title   string
	process string
	url     string
	handle  string
}

pub struct SurfaceRegion {
pub:
	id          string
	target      string
	label       string
	source      string
	rect        vdirty_regions.Rect
	interval_ms int
	required    bool
}

pub struct SurfaceMap {
pub:
	schema  string = 'vworkflow.surface_map.v1'
	name    string
	version string
	targets []SurfaceTarget
	regions []SurfaceRegion
}

pub fn surface_map_from_flow(spec Spec) SurfaceMap {
	mut targets := []SurfaceTarget{cap: spec.targets.len}
	for target in spec.targets {
		targets << SurfaceTarget{
			id: target.id
			kind: target.kind
			title: target.title
			process: target.process
			url: target.url
			handle: target.handle
		}
	}
	mut regions := []SurfaceRegion{cap: spec.regions.len}
	for region in spec.regions {
		regions << SurfaceRegion{
			id: region.id
			target: region.target
			label: region.label
			source: region.source
			rect: region.rect
			interval_ms: region.interval_ms
			required: region.required
		}
	}
	return SurfaceMap{
		name: spec.name
		version: spec.version
		targets: targets
		regions: regions
	}
}
