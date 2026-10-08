#!/usr/bin/env bash
# Hook SessionStart: avisa si /compromisos lleva más de un día sin correr y
# lista los DEBO que vencen en ≤7 días (incluidos personales) para ofrecer desarrollarlos.
# Solo lee. Nunca escribe ni llama a Calendar. Siempre sale 0.
f="${1:-${CLAUDE_PROJECT_DIR:-.}/_negocio/operacion/compromisos.md}"
[[ -f "$f" ]] || exit 0
# Solo el frontmatter inicial: la línea 1 debe ser '---'; se corta en el siguiente '---'.
last=$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^ultima_sincronizacion:/ {sub(/^ultima_sincronizacion:[ \t]*/, ""); gsub(/["\047]/, ""); print substr($0, 1, 10); exit}' "$f" 2>/dev/null)
ayer=$(date -v-1d +%Y-%m-%d)
# Fechas ISO: la comparación de texto es comparación de fechas.
if [[ "$last" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$last" < "$ayer" ]]; then
  echo "AVISO PARA SANTIAGO (dilo en tu primera línea): compromisos sin sincronizar desde $last — corre /compromisos"
fi
# Tabla bajo '## DEBO abiertos': | Vence | Qué | Quién | Frente | Nota | Posp. | ID |
lim=$(date -v+7d +%Y-%m-%d)
debo=$(awk -F'|' -v lim="$lim" '
  /^## / { en = ($0 ~ /^## DEBO abiertos/); next }
  !en || NF < 6 { next }
  { for (i = 2; i <= 5; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i) }
  $2 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { next }
  $2 <= lim { printf "%s%s (%s, %s)", (n++ ? "; " : ""), $3, $4, $2 }
' "$f" 2>/dev/null)
if [[ -n "$debo" ]]; then
  echo "AVISO PARA SANTIAGO (dilo en tu primera línea): DEBO que vencen en ≤7 días: $debo — ofrece desarrollarlos"
fi
exit 0
