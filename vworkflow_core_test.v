module vworkflow_core

import vyaml

fn fixture() Spec {
	text := '
name: browser_feedback
version: 0.1.0
mode: debug
adapters:
  - capture
  - automation
gates:
  require_confirmation: true
  allow_keyboard: true
  disclaimer: authorized local workflow
targets:
  - id: webapp
    kind: browser
    url: https://example.com
regions:
  - id: preview
    target: webapp
    label: App preview
    rect:
      x: 10
      y: 20
      width: 800
      height: 600
steps:
  - id: observe
    kind: observe
    adapter: capture
    region: preview
  - id: act
    kind: apply_action
    adapter: automation
    action: AppDrive.SendKeys
    target: webapp
'
	doc := vyaml.parse_text(text) or { panic(err.msg()) }
	return parse(vyaml.as_map(doc.root())) or { panic(err.msg()) }
}

fn test_plan_uses_neutral_action_contracts() {
	spec := fixture()
	flow_plan := plan(spec)
	assert flow_plan.decision == 'ready'
	assert flow_plan.risk == 'high'
	assert flow_plan.items.len == 2
	assert flow_plan.items[1].gate == 'confirmation'
}

fn test_audit_and_bundle_are_product_neutral() {
	spec := fixture()
	flow_audit := audit(spec)
	assert flow_audit.decision == 'ready'
	bundle := compile_bundle(spec)
	assert bundle.decision == 'compiled'
	assert bundle.artifacts.any(it.kind == 'workflow_plan')
	assert bundle.artifacts.any(it.kind == 'action_manifest')
	assert bundle.artifacts.any(it.kind == 'region_manifest')
}

fn test_validation_rejects_unknown_region_target() {
	mut spec := fixture()
	spec = Spec{
		...spec
		regions: [
			Region{
				id: 'bad'
				target: 'missing'
				rect: spec.regions[0].rect
			},
		]
	}
	assert validate(spec).any(it.contains('unknown target'))
}


fn test_boolean_adapter_map_is_accepted() {
	text := '
name: legacy_adapters
version: 1
adapters:
  vshot: true
  waibav: true
  disabled: false
targets:
  - id: app
    kind: browser
regions:
  - id: view
    target: app
    rect:
      x: 0
      y: 0
      width: 100
      height: 100
steps:
  - id: observe
    kind: observe
    adapter: vshot
    region: view
'
	doc := vyaml.parse_text(text) or { panic(err.msg()) }
	spec := parse(vyaml.as_map(doc.root())) or { panic(err.msg()) }
	assert 'vshot' in spec.adapters
	assert 'waibav' in spec.adapters
	assert 'disabled' !in spec.adapters
	assert plan_flow(spec).items[0].manual_hint.contains('vshot')
	assert surface_map_from_flow(spec).regions.len == 1
}
