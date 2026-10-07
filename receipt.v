module vworkflow_core

pub fn dry_run_receipt(spec Spec, mock bool) Receipt {
	flow_plan := plan(spec)
	flow_audit := audit(spec)
	mut evidence := []string{}
	for item in flow_plan.items {
		evidence << item.compile_hint
	}
	return Receipt{
		flow: spec.name
		mode: spec.mode
		decision: if flow_audit.issues.len == 0 { 'ready' } else { 'blocked' }
		steps_planned: flow_plan.items.len
		steps_executed: if flow_audit.issues.len == 0 { flow_plan.items.len } else { 0 }
		mock: mock
		evidence: evidence
		blocked_actions: flow_audit.issues.clone()
		message: if flow_audit.issues.len == 0 {
			'all steps compiled to dry-run receipts'
		} else {
			'flow has blocking issues'
		}
	}
}
