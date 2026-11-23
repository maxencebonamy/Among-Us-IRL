# Among Us Discord Bot

A Discord bot that runs games of Among Us on a Discord server.

The bot registers players, assigns roles, colors and tasks, and handles kills, reports, meetings and votes through slash commands and buttons. Administrators and moderators drive the game from Discord. The bot messages are in French.

## Table of contents

- [Among Us Discord Bot](#among-us-discord-bot)
	- [Table of contents](#table-of-contents)
	- [How it works](#how-it-works)
	- [Tech stack](#tech-stack)
	- [Repository structure](#repository-structure)
	- [Prerequisites](#prerequisites)
	- [Installation](#installation)
	- [Configuration](#configuration)
		- [Environment (`.env`)](#environment-env)
		- [Game settings (`Config` table)](#game-settings-config-table)
		- [Discord server (`src/configs/guild/guild.config.ts`)](#discord-server-srcconfigsguildguildconfigts)
	- [Running locally](#running-locally)
	- [Useful scripts](#useful-scripts)
	- [Slash commands](#slash-commands)
	- [Tests and quality](#tests-and-quality)
	- [Deployment](#deployment)
	- [License](#license)

## How it works

1. **Initialization**: `/game init` lists the members holding the `player` role and creates a game in the `WAITING` state once enough players are registered (`NB_PLAYERS`). Impostors are drawn at random, and each player gets a color and a private channel.
2. **Preparation**: `/game prepare` sends the task descriptions to the task channels and assigns each crewmate a number of easy and hard tasks (`NB_TASKS_EASY`, `NB_TASKS_HARD`).
3. **Start**: `/game start` moves the game to `RUNNING`. Players receive their role and tasks, and impostors get a kill cooldown (`KILL_COOLDOWN`).
4. **Tasks**: crewmates complete their tasks in the matching rooms. Task descriptions for players and for moderators are stored in the database.
5. **Kills and reports**: impostors kill through buttons, subject to the cooldown. Players report bodies, and `/meeting` triggers an emergency meeting.
6. **Votes**: `/vote new` opens a vote, players vote with buttons, and `/vote end` eliminates the player with the most votes.
7. **End of game**: the game ends when a win condition is met. A game can also be paused (`/game pause`, `/game unpause`) or canceled (`/game cancel`).

A scheduled task refreshes the vitals channel every 3 seconds with the alive or dead status of each player.

## Tech stack

| Layer | Technologies |
| --- | --- |
| Bot | Node.js, TypeScript, discord.js 14 |
| Data | PostgreSQL, Prisma 5, `zod-prisma` |
| Validation | Zod |
| Scheduling | `cron`, Day.js |
| Tooling | npm, `@swc-node/register`, nodemon, ESLint (`@maxencebonamy/eslint-config`), Vitest |
| Deployment | Docker, GitHub Actions |

## Repository structure

```
.
├── .github/workflows/  CI: Docker build
├── prisma/
│   ├── schema.prisma   Database schema
│   ├── seed.ts         Seed entry point
│   ├── seeders/        Config, colors, rooms and tasks seed data
│   └── zod/            Zod schemas generated from the Prisma schema
├── scripts/            Generators for commands, sub-commands, events and tasks
├── src/
│   ├── client.ts       Bot entry point
│   ├── commands/       Slash commands
│   ├── configs/        Environment, guild, Day.js and global configuration
│   ├── events/         Discord event and interaction handlers
│   ├── lib/            Prisma client
│   ├── tasks/          Scheduled jobs
│   └── utils/          Discord, game, handler and helper functions
├── Dockerfile
└── package.json
```

Commands, events and scheduled tasks are loaded automatically from their folders at startup. A command lives in `src/commands/<name>/` with a `<name>.builder.ts` (definition) and a `<name>.cmd.ts` (execution). Sub-commands go in `[sub-commands]/` and must share the name declared in the builder. An event lives in `src/events/<name>/<name>.event.ts`, and a scheduled task in `src/tasks/<name>/<name>.task.ts` with a cron `interval`. Files exporting `enableInDev` are loaded in dev mode only when it is `true`. The auto-loader comes from [Royaume](https://github.com/Virtual-Royaume/Royaume-Discord-Bot).

## Prerequisites

- [Node.js](https://nodejs.org/) 18 or later (`engines` in `package.json`; the Dockerfile uses Node 19)
- npm (the repository ships a `package-lock.json`)
- A PostgreSQL database
- A Discord application with a bot token, invited to your server with the privileged intents `Server Members` and `Message Content` enabled

## Installation

```bash
git clone git@github.com:maxencebonamy/Among-Us-Discord-Bot.git
cd Among-Us-Discord-Bot
npm install
```

Generate the Prisma client, create the tables and seed the database:

```bash
npm run prisma:generate
npm run prisma:push
npm run prisma:seed
```

## Configuration

The repository has no `.env.example`. Create a `.env` file at the root.

### Environment (`.env`)

| Variable | Description | Example |
| --- | --- | --- |
| `BOT_TOKEN` | Discord bot token | |
| `DATABASE_URL` | PostgreSQL connection URL, read by Prisma | `postgresql://user:password@localhost:5432/among-us` |

### Game settings (`Config` table)

These values are seeded by `npm run prisma:seed` and can be changed with `/config set`.

| Variable | Description | Example |
| --- | --- | --- |
| `NB_PLAYERS` | Number of players required to initialize a game | `12` |
| `NB_TASKS_EASY` | Number of easy tasks per player | `4` |
| `NB_TASKS_HARD` | Number of hard tasks per player | `2` |
| `KILL_COOLDOWN` | Delay between two kills, in seconds | `30` |

### Discord server (`src/configs/guild/guild.config.ts`)

Server, channel and role IDs are hardcoded in this file. Replace them with the IDs of your own server: the channels `admins`, `modos`, `logs`, `vitals`, and the categories `waitingCategory`, `gameCategory`, `playersCategory`, plus the roles `player`, `modo`, `admin` and `dev`.

## Running locally

```bash
npm run dev
```

Dev mode restarts the bot on every change and skips commands, events and tasks that do not export `enableInDev = true`.

To run without nodemon:

```bash
npm run start
```

## Useful scripts

| Command | Effect |
| --- | --- |
| `npm run dev` | Start the bot in dev mode with nodemon |
| `npm run start` | Start the bot |
| `npm run lint` | Lint `src` |
| `npm run lint:fix` | Lint `src` with auto-fix |
| `npm run ts:check` | Type-check without emitting |
| `npm run test:unit` | Run Vitest with its UI |
| `npm run prisma:generate` | Regenerate the Prisma client and Zod schemas |
| `npm run prisma:push` | Push the Prisma schema to the database |
| `npm run prisma:seed` | Seed config, colors, rooms and tasks (existing rows of these tables are deleted first) |
| `npm run create:command <name>` | Generate a command |
| `npm run create:subcommand <commandName> <name>` | Generate a sub-command |
| `npm run create:event <name>` | Generate an event |
| `npm run create:task <name>` | Generate a scheduled task |

## Slash commands

| Command | Description |
| --- | --- |
| `/game init` | Initialize a game |
| `/game prepare` | Prepare a game after initialization |
| `/game start` | Start a prepared game |
| `/game pause` | Pause the game |
| `/game unpause` | Resume a paused game |
| `/game cancel` | Cancel the game |
| `/game status` | Show the game status |
| `/player kill` | Kill a player by color |
| `/meeting` | Trigger an emergency meeting |
| `/vote new` | Create a vote |
| `/vote status` | Show the vote status |
| `/vote end` | End the vote |
| `/info channels`, `users`, `roles`, `progression` | Show server and game information |
| `/update tasks`, `users`, `players` | Sync task channels, users and player channels with the database |
| `/config get`, `get-all`, `set`, `delete` | Read and edit configuration values |
| `/say` | Make the bot send a message |
| `/ping` | Show the bot latency |
| `/test` | Test command |

The `/game` commands and `/vote end` check that the user is an administrator.

## Tests and quality

```bash
npm run lint
npm run ts:check
npm run test:unit
```

Tests use Vitest. The repository contains one test file, `src/utils/function/object/object.test.ts`.

## Deployment

The workflow `.github/workflows/build.yaml` runs on every push. It builds the Docker image and starts a container from it. It does not publish the image.

The [`Dockerfile`](Dockerfile) is based on `node:19`. It installs the dependencies with `npm install`, generates the Prisma client, runs `npx prisma db push` at build time, then starts the bot with `npm run start`. The build therefore needs a reachable `DATABASE_URL`, and `BOT_TOKEN` must be provided at runtime.

## License

This project is licensed under the [MIT License](LICENSE).
