module vworkflow_core

import vjson_scalar

pub fn compile_bundle(spec Spec) Bundle {
	flow_plan := plan(spec)
	flow_audit := audit(spec)
	slug := artifact_slug(spec.name)
	mut artifacts := []Artifact{}
	artifacts << Artifact{
		kind: 'workflow_plan'
		path: 'plan/${slug}.json'
		summary: 'normalized workflow plan'
		body: plan_json(flow_plan)
	}
	artifacts << Artifact{
		kind: 'action_manifest'
		path: 'actions/${slug}.json'
		summary: 'action contracts and gates'
		body: action_manifest_json(flow_plan)
	}
	if spec.regions.len > 0 {
		artifacts << Artifact{
			kind: 'region_manifest'
			path: 'regions/${slug}.json'
			summary: 'observed workflow regions'
			body: region_manifest_json(spec)
		}
	}
	return Bundle{
		flow: spec.name
		version: spec.version
		decision: if flow_audit.issues.len == 0 { 'compiled' } else { 'blocked' }
		risk: flow_plan.risk
		plan: flow_plan
		audit: flow_audit
		artifacts: artifacts
	}
}

pub fn artifact_slug(value string) string {
	mut out := []u8{}
	for ch in value.to_lower().bytes() {
		if (ch >= `a` && ch <= `z`) || (ch >= `0` && ch <= `9`) {
			out << ch
		} else if ch in [u8(`_`), u8(`-`), u8(`.`)] {
			out << ch
		} else {
			out << `_`
		}
	}
	slug := out.bytestr().trim('_')
	return if slug == '' { 'workflow' } else { slug }
}

fn plan_json(flow_plan Plan) string {
	mut lines := ['{']
	lines << '  "schema": ${json(flow_plan.schema)},'
	lines << '  "flow": ${json(flow_plan.flow)},'
	lines << '  "version": ${json(flow_plan.version)},'
	lines << '  "decision": ${json(flow_plan.decision)},'
	lines << '  "risk": ${json(flow_plan.risk)},'
	lines << '  "adapters": ${json_array(flow_plan.adapters)},'
	lines << '  "gates": ${json_array(flow_plan.gates)},'
	lines << '  "items": ['
	for i, item in flow_plan.items {
		lines << '    {"step_id":${json(item.step_id)},"kind":${json(item.kind)},"adapter":${json(item.adapter)},"action":${json(item.action)},"risk":${json(item.risk)},"gate":${json(item.gate)},"evidence":${json_array(item.evidence)}}' + if i + 1 < flow_plan.items.len { ',' } else { '' }
	}
	lines << '  ]'
	lines << '}'
	return lines.join('\n') + '\n'
}

fn action_manifest_json(flow_plan Plan) string {
	mut lines := ['{', '  "schema": "vworkflow.action_manifest.v1",', '  "capabilities": [']
	for i, cap in flow_plan.capabilities {
		lines << '    {"action":${json(cap.action)},"adapter":${json(cap.adapter)},"category":${json(cap.category)},"risk":${json(cap.risk)},"effects":${json_array(cap.effects)},"evidence":${json_array(cap.evidence)},"mockable":${cap.mockable},"requires_confirmation":${cap.requires_confirmation}}' + if i + 1 < flow_plan.capabilities.len { ',' } else { '' }
	}
	lines << '  ]'
	lines << '}'
	return lines.join('\n') + '\n'
}

fn region_manifest_json(spec Spec) string {
	mut lines := ['{', '  "schema": "vworkflow.region_manifest.v1",', '  "regions": [']
	for i, region in spec.regions {
		lines << '    {"id":${json(region.id)},"target":${json(region.target)},"label":${json(region.label)},"source":${json(region.source)},"interval_ms":${region.interval_ms},"required":${region.required},"rect":{"x":${region.rect.x},"y":${region.rect.y},"w":${region.rect.w},"h":${region.rect.h}}}' + if i + 1 < spec.regions.len { ',' } else { '' }
	}
	lines << '  ]'
	lines << '}'
	return lines.join('\n') + '\n'
}

fn json(value string) string {
	return vjson_scalar.quote_string(value)
}

fn json_array(values []string) string {
	return vjson_scalar.string_array_with_options(values, vjson_scalar.StringArrayOptions{
		separator: ', '
	})
}
