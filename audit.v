module vworkflow_core

const allowed_step_kinds = ['observe', 'analyze', 'ask_ai', 'apply_action', 'verify', 'receipt']

pub fn audit(spec Spec) Audit {
	issues := validate(spec)
	warnings := warnings(spec)
	return Audit{
		flow: spec.name
		decision: if issues.len == 0 { 'ready' } else { 'blocked' }
		issues: issues
		warnings: warnings
		plan: plan(spec)
	}
}

pub fn validate(spec Spec) []string {
	mut issues := []string{}
	if spec.name.trim_space() == '' {
		issues << 'flow name is required'
	}
	if spec.targets.len == 0 {
		issues << 'at least one target is required'
	}
	if spec.steps.len == 0 {
		issues << 'at least one step is required'
	}
	mut targets := map[string]bool{}
	for target in spec.targets {
		if target.id.trim_space() == '' {
			issues << 'target id is required'
			continue
		}
		if target.id in targets {
			issues << 'duplicate target id ' + target.id
			continue
		}
		targets[target.id] = true
	}
	mut regions := map[string]bool{}
	for region in spec.regions {
		if region.id.trim_space() == '' {
			issues << 'region id is required'
			continue
		}
		if region.id in regions {
			issues << 'duplicate region id ' + region.id
			continue
		}
		regions[region.id] = true
		if region.target !in targets {
			issues << 'region ${region.id} references unknown target ${region.target}'
		}
		if !region.rect.valid() {
			issues << 'region ${region.id} has empty rect'
		}
	}
	mut step_ids := map[string]bool{}
	for step in spec.steps {
		if step.id.trim_space() == '' {
			issues << 'step id is required'
		} else if step.id in step_ids {
			issues << 'duplicate step id ' + step.id
		} else {
			step_ids[step.id] = true
		}
		if step.kind !in allowed_step_kinds {
			issues << 'step ${step.id} has unsupported kind ${step.kind}'
		}
		if step.region.trim_space() != '' && step.region !in regions {
			issues << 'step ${step.id} references unknown region ${step.region}'
		}
		if step.target.trim_space() != '' && step.target !in targets {
			issues << 'step ${step.id} references unknown target ${step.target}'
		}
	}
	return issues
}

pub fn warnings(spec Spec) []string {
	mut out := []string{}
	if spec.gates.disclaimer.trim_space() == '' {
		out << 'disclaimer text is empty'
	}
	for step in spec.steps {
		if !step.enabled {
			continue
		}
		cap := capability_for_step(step)
		if cap.requires_confirmation && !spec.gates.require_confirmation {
			out << 'step ${step.id} requires external policy approval'
		}
		if cap.category == 'desktop' && !spec.gates.allow_foreground {
			out << 'step ${step.id} may require foreground access'
		}
	}
	return out
}
