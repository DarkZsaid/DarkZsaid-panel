#!/bin/bash

echo "===== REVISANDO DARKZSAID PANEL ====="

echo
echo "===== panel.sh ====="
bash -n panel.sh && echo "OK panel.sh" || exit 1

echo
echo "===== install-public.sh ====="
bash -n install-public.sh && echo "OK install-public.sh" || exit 1

echo
echo "===== menus/*.sh ====="
for f in menus/*.sh; do
  bash -n "$f" && echo "OK $f" || exit 1
done

echo
echo "===== REVISION COMPLETA OK ====="
