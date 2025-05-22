#!/bin/sh
set -e

echo "Press s to sync, g to generate, or Enter to generate then sync:"
read -r choice

if [ "$choice" = "s" ]; then
  echo "Syncing schema to remote database..."
  pnpm prisma db push
elif [ "$choice" = "g" ]; then
  echo "Generating Prisma client..."
  pnpm prisma generate
else
  echo "Generating Prisma client..."
  pnpm prisma generate
  echo "Syncing schema to remote database..."
  pnpm prisma db push
fi

echo "Done!" 