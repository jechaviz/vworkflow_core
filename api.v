module vworkflow_core

pub fn load_flow(path string) !Spec {
	return load(path)
}

pub fn validate_flow(spec Spec) []string {
	return validate(spec)
}

pub fn audit_issues(spec Spec) []string {
	return validate(spec)
}

pub fn audit_warnings(spec Spec) []string {
	return warnings(spec)
}

pub fn plan_flow(spec Spec) Plan {
	return plan(spec)
}

pub fn audit_flow(spec Spec) Audit {
	return audit(spec)
}

pub fn compile_flow_bundle(spec Spec) Bundle {
	return compile_bundle(spec)
}
