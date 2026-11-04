# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

MANDATORY workflow:
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

A passing suite is not proof the change works. Before claiming done, follow [Prove It Works](./development-workflow.md#prove-it-works): check the real artifact, and do not fabricate a `file:line`.

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)
5. Fix the fault, not the assertion or the symptom ([Fix Root Causes](./development-workflow.md#fix-root-causes)). After two or more fixes that share a premise and fail the same gate, [Attack the Premise](./development-workflow.md#attack-the-premise) before the next patch. Neither is a skill.

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first
