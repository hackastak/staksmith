# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

The red → green loop is the default when `tdd-workflow`'s skip gate says the path is clear and cheap. Skip a new test when the path is unclear, expensive, integration-heavy, or not requested. Prefer no new test over a bad test. 80% is a target, not a reason to add a test that would be deleted after proving the point. `tdd` is not a skill.

When the gate says write a test:
1. Write test first (RED) — name the check and the failure it produced
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Treat 80% as a target, not a mandate

A passing suite is not proof the change works. Before claiming done, follow [Prove It Works](./development-workflow.md#prove-it-works): check the real artifact, and do not fabricate a `file:line`.

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)
5. Fix the fault, not the assertion or the symptom ([Fix Root Causes](./development-workflow.md#fix-root-causes)). After two or more fixes that share a premise and fail the same gate, [Attack the Premise](./development-workflow.md#attack-the-premise) before the next patch. Neither is a skill.

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features. It follows `tdd-workflow`'s skip gate. It does not force a bad test to hit 80%.
