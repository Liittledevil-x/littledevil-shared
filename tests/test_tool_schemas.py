"""Structural validity of the 9 tool-use schemas (docs/tool-schemas.md).

No agent calls these yet at Stage 0 — the check here is that each JSON file
is well-formed and matches the Anthropic tool-use `input_schema` shape, not
that any agent behaves correctly with them.
"""

from littledevil_shared import tool_schemas

EXPECTED_SCHEMAS = {
    "submit_htf_prior",
    "submit_escalation",
    "submit_verdict",
    "submit_case_against",
    "draft_lesson",
    "request_drilldown",
    "get_candidate_packet",
    "get_htf_prior",
    "promote_to_close_watch",
}


def test_manifest_lists_exactly_the_nine_schemas() -> None:
    assert set(tool_schemas.manifest()["schemas"]) == EXPECTED_SCHEMAS


def test_every_schema_loads_and_matches_tool_use_shape() -> None:
    for name, schema in tool_schemas.all_schemas().items():
        assert schema["name"] == name
        assert isinstance(schema.get("description"), str) and schema["description"]
        input_schema = schema["input_schema"]
        assert input_schema["type"] == "object"
        assert "properties" in input_schema
        assert "required" in input_schema


def test_unknown_schema_name_raises() -> None:
    try:
        tool_schemas.load("not_a_real_tool")
    except KeyError:
        pass
    else:
        raise AssertionError("expected KeyError for unknown schema name")
