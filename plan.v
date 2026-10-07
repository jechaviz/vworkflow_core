module vworkflow_core

import vaction_contracts

pub fn plan(spec Spec) Plan {
	mut items := []PlanItem{}
	mut capabilities := []StepCapability{}
	mut overall := vaction_contracts.Risk.low
	for step in spec.steps {
		if !step.enabled {
			continue
		}
		cap := capability_for_step(step)
		capabilities << cap
		risk := risk_from_string(cap.risk)
		overall = vaction_contracts.max_risk(overall, risk)
		items << PlanItem{
			step_id: step.id
			kind: step.kind
			adapter: effective_adapter(step)
			action: cap.action
			risk: cap.risk
			gate: gate_for_step(spec.gates, step, cap)
			evidence: cap.evidence
			compile_hint: compile_hint(spec, step, cap)
			manual_hint: manual_hint(spec, step, cap)
		}
	}
	return Plan{
		flow: spec.name
		version: spec.version
		decision: if validate(spec).len == 0 { 'ready' } else { 'blocked' }
		risk: overall.str()
		adapters: enabled_adapters(spec)
		gates: enabled_gates(spec.gates)
		capabilities: capabilities
		items: items
	}
}

pub fn capability_for_step(step Step) StepCapability {
	action := first_nonempty(step.action, default_action_for_kind(step.kind))
	adapter := effective_adapter(step)
	if step.kind == 'observe' || adapter in ['capture', 'vshot'] {
		return StepCapability{
			action: action
			adapter: adapter
			category: 'capture'
			risk: 'low'
			effects: ['read']
			evidence: ['region', 'image']
			mockable: true
		}
	}
	contract := vaction_contracts.contract_for_action(action)
	mut effects := []string{}
	for effect in contract.effects {
		effects << effect.str()
	}
	return StepCapability{
		action: action
		adapter: effective_adapter(step)
		category: contract.category
		risk: contract.risk.str()
		effects: effects
		evidence: contract.evidence.clone()
		mockable: contract.mockable
		requires_confirmation: contract.confirmation_required()
	}
}

pub fn default_action_for_kind(kind string) string {
	return match kind {
		'observe' { 'Capture.Region' }
		'analyze' { 'Vision.Analyze' }
		'ask_ai' { 'LLM.Complete' }
		'apply_action' { 'AppDrive.SendKeys' }
		'verify' { 'Trace.Event' }
		'receipt' { 'Trace.Event' }
		else { 'Note' }
	}
}

pub fn effective_adapter(step Step) string {
	if step.adapter.trim_space() != '' {
		return step.adapter.trim_space()
	}
	return match step.kind {
		'observe' { 'capture' }
		'analyze', 'ask_ai' { 'analysis' }
		'apply_action' { 'automation' }
		'verify', 'receipt' { 'trace' }
		else { 'local' }
	}
}

pub fn enabled_adapters(spec Spec) []string {
	mut out := spec.adapters.clone()
	for step in spec.steps {
		if !step.enabled {
			continue
		}
		adapter := effective_adapter(step)
		if adapter != '' && adapter !in out {
			out << adapter
		}
	}
	out.sort()
	return out
}

pub fn enabled_gates(gates Gates) []string {
	mut out := []string{}
	if gates.require_confirmation { out << 'require_confirmation' }
	if gates.allow_mouse { out << 'allow_mouse' }
	if gates.allow_keyboard { out << 'allow_keyboard' }
	if gates.allow_submit { out << 'allow_submit' }
	if gates.allow_external_send { out << 'allow_external_send' }
	if gates.allow_destructive { out << 'allow_destructive' }
	if gates.allow_foreground { out << 'allow_foreground' }
	return out
}

pub fn region_by_id(spec Spec, id string) ?Region {
	for region in spec.regions {
		if region.id == id {
			return region
		}
	}
	return none
}

fn gate_for_step(gates Gates, step Step, cap StepCapability) string {
	if gates.require_confirmation
		&& (cap.requires_confirmation || cap.effects.any(it != 'read')) {
		return 'confirmation'
	}
	if step.kind == 'observe' && !gates.allow_foreground {
		return 'background_only'
	}
	return 'open'
}

fn compile_hint(spec Spec, step Step, cap StepCapability) string {
	adapter := effective_adapter(step)
	if step.region.trim_space() != '' {
		region := region_by_id(spec, step.region) or { return '${adapter}:${cap.action}' }
		return '${adapter}:${cap.action} rect=${region.rect.x},${region.rect.y},${region.rect.w},${region.rect.h}'
	}
	return '${adapter}:${cap.action}'
}

fn manual_hint(spec Spec, step Step, cap StepCapability) string {
	adapter := effective_adapter(step)
	if adapter == 'vshot' && step.region.trim_space() != '' {
		region := region_by_id(spec, step.region) or { return '' }
		out := '${spec.output_dir}/${spec.name}/${region.id}.png'
		return 'v run vshot -- capture --x ${region.rect.x} --y ${region.rect.y} --width ${region.rect.w} --height ${region.rect.h} --out ${out}'
	}
	return ''
}

fn risk_from_string(value string) vaction_contracts.Risk {
	return match value {
		'critical' { .critical }
		'high' { .high }
		'medium' { .medium }
		else { .low }
	}
}

fn first_nonempty(value string, fallback string) string {
	clean := value.trim_space()
	return if clean == '' { fallback } else { clean }
}
