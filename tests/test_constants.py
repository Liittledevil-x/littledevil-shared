from littledevil_shared import constants


def test_feature_version_is_set() -> None:
    assert constants.FEATURE_VERSION == "0.1.0"


def test_detector_parameters_are_explicitly_unset_pending_trunk_decomposition() -> None:
    # These must not be silently defaulted to a guessed number — see
    # strategy-playbook.md §3 and architecture-review.md §4.4: k and the ATR
    # tolerances are frozen before any study runs, never tuned against results.
    assert constants.PIVOT_LOOKBACK_K is None
    assert constants.ATR_TOLERANCES is None
