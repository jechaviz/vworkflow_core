module vworkflow_core

import vdirty_regions
import vyaml

pub fn load(path string) !Spec {
	doc := vyaml.load_file(path)!
	return parse(vyaml.as_map(doc.root()))
}

pub fn parse(root map[string]vyaml.Node) !Spec {
	mut spec := Spec{
		name: map_string(root, 'name')
		version: map_string(root, 'version')
		summary: map_string(root, 'summary')
		domain: map_string(root, 'domain')
		mode: first_nonempty(map_string(root, 'mode'), 'debug')
		cadence_ms: map_int(root, 'cadence_ms', 5000)
		output_dir: first_nonempty(map_string(root, 'output_dir'), 'out/workflow')
		adapters: parse_string_array(root['adapters'] or { vyaml.Node('') })
		targets: parse_targets(root['targets'] or { vyaml.Node('') })
		regions: parse_regions(root['regions'] or { vyaml.Node('') })
		steps: parse_steps(root['steps'] or { vyaml.Node('') })
		gates: parse_gates(root['gates'] or { vyaml.Node('') })
	}
	spec = Spec{
		...spec
		adapters: enabled_adapters(spec)
	}
	return spec
}

fn parse_targets(raw vyaml.Node) []Target {
	mut out := []Target{}
	for item in vyaml.as_array(raw) {
		m := vyaml.as_map(item)
		out << Target{
			id: map_string(m, 'id')
			kind: first_nonempty(map_string(m, 'kind'), 'app')
			title: map_string(m, 'title')
			process: map_string(m, 'process')
			url: map_string(m, 'url')
			handle: map_string(m, 'handle')
		}
	}
	return out
}

fn parse_regions(raw vyaml.Node) []Region {
	mut out := []Region{}
	for item in vyaml.as_array(raw) {
		m := vyaml.as_map(item)
		out << Region{
			id: map_string(m, 'id')
			target: map_string(m, 'target')
			label: map_string(m, 'label')
			source: first_nonempty(map_string(m, 'source'), 'manual')
			rect: parse_rect(m['rect'] or { vyaml.Node('') })
			interval_ms: map_int(m, 'interval_ms', 0)
			required: map_bool(m, 'required', true)
		}
	}
	return out
}

fn parse_steps(raw vyaml.Node) []Step {
	mut out := []Step{}
	for item in vyaml.as_array(raw) {
		m := vyaml.as_map(item)
		out << Step{
			id: map_string(m, 'id')
			kind: map_string(m, 'kind')
			adapter: map_string(m, 'adapter')
			action: map_string(m, 'action')
			target: map_string(m, 'target')
			region: map_string(m, 'region')
			prompt: map_string(m, 'prompt')
			data: parse_string_map(m['data'] or { vyaml.Node('') })
			enabled: map_bool(m, 'enabled', true)
		}
	}
	return out
}

fn parse_gates(raw vyaml.Node) Gates {
	m := vyaml.as_map(raw)
	return Gates{
		require_confirmation: map_bool(m, 'require_confirmation', true)
		allow_mouse: map_bool(m, 'allow_mouse', false)
		allow_keyboard: map_bool(m, 'allow_keyboard', false)
		allow_submit: map_bool(m, 'allow_submit', false)
		allow_external_send: map_bool(m, 'allow_external_send', false)
		allow_destructive: map_bool(m, 'allow_destructive', false)
		allow_foreground: map_bool(m, 'allow_foreground', false)
		disclaimer: map_string(m, 'disclaimer')
	}
}

fn parse_rect(raw vyaml.Node) vdirty_regions.Rect {
	m := vyaml.as_map(raw)
	return vdirty_regions.Rect{
		x: map_int(m, 'x', 0)
		y: map_int(m, 'y', 0)
		w: map_int(m, 'w', map_int(m, 'width', 0))
		h: map_int(m, 'h', map_int(m, 'height', 0))
	}
}

fn parse_string_array(raw vyaml.Node) []string {
	mut out := []string{}
	for item in vyaml.as_array(raw) {
		value := vyaml.as_string(item).trim_space()
		if value != '' && value !in out {
			out << value
		}
	}
	return out
}

fn parse_string_map(raw vyaml.Node) map[string]string {
	mut out := map[string]string{}
	for key, value in vyaml.as_map(raw) {
		out[key] = vyaml.as_string(value)
	}
	return out
}

fn map_string(m map[string]vyaml.Node, key string) string {
	if key !in m {
		return ''
	}
	return vyaml.as_string(m[key]).trim_space()
}

fn map_int(m map[string]vyaml.Node, key string, fallback int) int {
	if key !in m {
		return fallback
	}
	return vyaml.as_int(m[key], fallback)
}

fn map_bool(m map[string]vyaml.Node, key string, fallback bool) bool {
	if key !in m {
		return fallback
	}
	return vyaml.as_bool(m[key], fallback)
}
