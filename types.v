module vworkflow_core

import vdirty_regions

pub const flow_schema = 'vworkflow.flow.v1'
pub const plan_schema = 'vworkflow.plan.v1'
pub const audit_schema = 'vworkflow.audit.v1'
pub const receipt_schema = 'vworkflow.receipt.v1'

pub struct Target {
pub:
	id      string
	kind    string
	title   string
	process string
	url     string
	handle  string
}

pub struct Region {
pub:
	id          string
	target      string
	label       string
	source      string
	rect        vdirty_regions.Rect
	interval_ms int
	required    bool
}

pub struct Step {
pub:
	id      string
	kind    string
	adapter string
	action  string
	target  string
	region  string
	prompt  string
	data    map[string]string
	enabled bool = true
}

pub struct Gates {
pub:
	require_confirmation bool
	allow_mouse          bool = true
	allow_keyboard       bool = true
	allow_submit         bool = true
	allow_external_send  bool = true
	allow_destructive    bool = true
	allow_foreground     bool = true
	disclaimer           string
}

pub struct Spec {
pub:
	schema     string = flow_schema
	name       string
	version    string
	summary    string
	domain     string
	mode       string
	cadence_ms int
	output_dir string
	adapters   []string
	targets    []Target
	regions    []Region
	steps      []Step
	gates      Gates
}

pub struct StepCapability {
pub:
	action                string
	adapter               string
	category              string
	risk                  string
	effects               []string
	evidence              []string
	mockable              bool
	requires_confirmation bool
}

pub struct PlanItem {
pub:
	step_id      string
	kind         string
	adapter      string
	action       string
	risk         string
	gate         string
	evidence     []string
	compile_hint string
	manual_hint  string
}

pub struct Plan {
pub:
	schema       string = plan_schema
	flow         string
	version      string
	decision     string
	risk         string
	adapters     []string
	gates        []string
	capabilities []StepCapability
	items        []PlanItem
}

pub struct Audit {
pub:
	schema   string = audit_schema
	flow     string
	decision string
	issues   []string
	warnings []string
	plan     Plan
}

pub struct Receipt {
pub:
	schema          string = receipt_schema
	flow            string
	mode            string
	decision        string
	steps_planned   int
	steps_executed  int
	mock            bool
	evidence        []string
	blocked_actions []string
	message         string
}

pub struct Artifact {
pub:
	kind    string
	path    string
	summary string
	body    string
}

pub struct Bundle {
pub:
	schema    string = 'vworkflow.bundle.v1'
	flow      string
	version   string
	decision  string
	risk      string
	plan      Plan
	audit     Audit
	artifacts []Artifact
}
