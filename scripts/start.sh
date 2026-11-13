#!/bin/sh
set -eu

: "${NEXT_PUBLIC_WEBAPP_URL:?Set NEXT_PUBLIC_WEBAPP_URL}"
: "${NEXTAUTH_SECRET:?Set NEXTAUTH_SECRET}"
: "${CALENDSO_ENCRYPTION_KEY:?Set CALENDSO_ENCRYPTION_KEY}"
: "${DATABASE_URL:?Set DATABASE_URL}"

if [ "${#NEXTAUTH_SECRET}" -lt 32 ] || [ "${#CALENDSO_ENCRYPTION_KEY}" -ne 32 ]; then
    echo "NEXTAUTH_SECRET must have at least 32 characters and CALENDSO_ENCRYPTION_KEY exactly 32 ASCII characters." >&2
    exit 1
fi

export DATABASE_DIRECT_URL="${DATABASE_DIRECT_URL:-$DATABASE_URL}"
export NEXTAUTH_URL="${NEXTAUTH_URL:-$NEXT_PUBLIC_WEBAPP_URL/api/auth}"

scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

if [ -n "${DATABASE_HOST:-}" ]; then
    scripts/wait-for-it.sh "$DATABASE_HOST" -t 60
fi

yarn prisma migrate deploy --schema /calcom/packages/prisma/schema.prisma
yarn workspace @calcom/prisma run seed-app-store
cd /calcom/apps/web
exec /calcom/node_modules/.bin/next start --hostname 0.0.0.0
