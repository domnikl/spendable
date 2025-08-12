# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies

- `mix setup` - Install and setup dependencies, create database, run migrations, setup and build assets
- `mix deps.get` - Install Elixir dependencies
- `mix ecto.setup` - Create database, run migrations, and seed data
- `mix ecto.reset` - Drop database and recreate from scratch

### Running the Application

- `mix phx.server` - Start Phoenix server (visit http://localhost:4001)
- `iex -S mix phx.server` - Start server in interactive Elixir shell

### Testing and Quality

- `mix test` - Run all tests (automatically creates test database and runs migrations)
- `mix ecto.create --quiet && mix ecto.migrate --quiet && mix test` - Full test setup and execution

### Assets and Frontend

- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build Tailwind CSS and JavaScript assets
- `mix assets.deploy` - Build and minify assets for production deployment

### Database Operations

- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.drop` - Drop database
- `run priv/repo/seeds.exs` - Seed database with initial data

### Custom Tasks

- `mix spendable.transactions` - Import transactions from connected bank accounts
- `mix spendable.balances` - Import account balances from connected bank accounts

## Application Architecture

### Core Application Structure

This is a Phoenix LiveView application for personal finance management with bank account integration via GoCardless API.

**Main Contexts:**

- `Spendable.Accounts` - Bank account management
- `Spendable.Budgets` - Budget creation and tracking with usage calculations
- `Spendable.Payments` - Payment/expense tracking
- `Spendable.Transactions` - Financial transaction management (includes finalized/unfinalized states)
- `Spendable.Users` - User authentication and management
- `Spendable.Requisitions` - GoCardless bank connection management

**Key External Integration:**

- `Gocardless` module - Handles all bank API interactions using Knigge for behavior contracts
- API client with structured request/response modules in `lib/gocardless/gocardless_api/`

### Web Layer (SpendableWeb)

**LiveView Pages:**

- `DashboardLive.Index` - Main dashboard with transaction overview
- `AccountsLive.Index` - Bank account management
- `BudgetsLive.Index` - Budget management with form components
- `PaymentLive.*` - Payment CRUD operations
- `InstitutionLive.Index` - Bank institution setup

**Controllers:**

- `PageController` - Static pages
- `UserSessionController` - Authentication
- `InstitutionController` - GoCardless bank setup callbacks

**Authentication:**

- User authentication built on Phoenix's generated auth system
- Route-level protection with pipelines (`:require_authenticated_user`, `:redirect_if_user_is_authenticated`)
- LiveView session management with `SpendableWeb.UserAuth` module

### Database Schema Highlights

- Users have requisitions (bank connections)
- Accounts belong to users and link to external bank accounts
- Transactions can be finalized/unfinalized
- Budgets have valid date ranges and can have parent/child relationships
- Payments track manual expenses

### Key Dependencies and Tools

- **Phoenix LiveView** - Real-time UI
- **Ecto** with PostgreSQL - Database ORM
- **Tailwind CSS** + **esbuild** - Frontend styling and JS bundling
- **SaladUI** - UI component library
- **Number** library - Currency formatting helpers
- **Heroicons** - Icon library
- **Knigge** - Behavior delegation for GoCardless API mocking
- **Mox** - Testing mocks

### Development Environment

- Uses **Bandit** as HTTP server adapter
- **Swoosh** for email with local development preview at `/dev/mailbox`
- **Phoenix LiveDashboard** available at `/dev/dashboard` in development
- API documentation and testing via Bruno requests in `requests/` directory

### Testing Strategy

- Test database automatically created and migrated before test runs
- Fixtures available in `test/support/fixtures/`
- LiveView testing for UI components
- API integration tests for GoCardless module

## Important Implementation Notes

### GoCardless Integration

The application heavily relies on GoCardless for bank data. All API interactions go through the `Gocardless` module which uses behavior contracts for testing. The integration handles:

- Institution discovery and selection
- User consent and requisition management
- Account details and transaction synchronization
- Token management (access and refresh tokens)

### Budget System

Budgets support hierarchical relationships (parent/child) and include usage calculations. They have validity date ranges and can be marked active/inactive.

### Transaction Finalization

Transactions have a finalized state - unfinalized transactions appear prominently on the dashboard for user review.

### Currency Handling

Uses the `Number` library for consistent currency formatting across the application with `Number.Currency.number_to_currency/2`.
