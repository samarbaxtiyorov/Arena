# Arena — Flutter ishga tushirish skripti (lokal)
# Foydalanish: bash run_local.sh

#!/usr/bin/env bash
set -a
source "$(dirname "$0")/.env"
set +a

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_KEY="$SUPABASE_KEY" \
  "$@"
