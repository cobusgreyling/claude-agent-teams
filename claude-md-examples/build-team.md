# CLAUDE.md — Cross-Layer Feature Build Team

## Project Architecture

- `src/frontend/` — React 18 app with TypeScript
  - `src/frontend/components/` — Reusable UI components
  - `src/frontend/pages/` — Route-level page components
  - `src/frontend/hooks/` — Custom React hooks
  - `src/frontend/api/` — API client functions (generated from OpenAPI)
- `src/backend/` — Node.js + Express API server
  - `src/backend/routes/` — Route handlers
  - `src/backend/services/` — Business logic services
  - `src/backend/models/` — Sequelize models
  - `src/backend/middleware/` — Auth, validation, error handling
- `src/shared/` — Shared types and validation schemas (used by both layers)
- `tests/` — All test files mirror the `src/` structure
- `migrations/` — Database migration files

## API Conventions

- All endpoints follow REST: `GET /api/{resource}`, `POST /api/{resource}`, etc.
- Request and response bodies use camelCase JSON.
- Pagination: `?page=1&limit=20` — responses include `{ data, total, page, limit }`.
- Errors return `{ error: string, code: string, details?: object }`.
- Validation uses Zod schemas defined in `src/shared/schemas/`.

## Schema Patterns

- Define the Zod schema once in `src/shared/schemas/{resource}.ts`.
- Backend imports the schema for request validation middleware.
- Frontend imports the same schema for form validation.
- Database model fields must match the schema field names exactly.

## Database Migration Guidelines

- Never modify an existing migration file — always create a new one.
- Run `npm run migrate:create -- --name <description>` to generate a migration.
- Migrations must be reversible: always implement both `up` and `down`.
- Test migrations against a fresh database: `npm run db:reset && npm run migrate`.

## Component Naming Conventions

- React components: PascalCase (`UserProfileCard.tsx`)
- Hooks: camelCase with `use` prefix (`useUserProfile.ts`)
- Backend services: camelCase with `Service` suffix (`userProfileService.ts`)
- Route files: kebab-case (`user-profile.routes.ts`)
- Schema files: kebab-case (`user-profile.schema.ts`)
- Test files: match source file name with `.test` suffix (`UserProfileCard.test.tsx`)

## Test Requirements

- Every API endpoint needs an integration test in `tests/integration/`.
- Every React component needs a unit test in `tests/unit/frontend/`.
- Every service function needs a unit test in `tests/unit/backend/`.
- Shared schemas need validation tests covering valid input, invalid input, and edge cases.
- Run the full suite before declaring your layer complete: `npm test`.
- Minimum coverage threshold: 80% line coverage per new file.

## Coordination Rules

- Frontend teammate must wait for the API contract (schema + route stub) before building.
- Backend teammate publishes the schema and a working stub endpoint first.
- Test teammate begins writing test skeletons as soon as the schema is defined.
- All teammates share progress via the mailbox after completing each milestone.
