# rules

Versioned rule sets, one JSON file per season (`rules_2026_27.json`).
All balancing numbers live here, never in code. Every file has a version field
and is checked against a schema when loaded (Phase 0, task 6).

`calendar_rules.json` holds the calendar numbers (breaks, vacation, kickoff slots per league group). Weekdays are ISO (1 = Monday), times are on the half hour.
