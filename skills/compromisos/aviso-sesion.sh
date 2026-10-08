#!/usr/bin/env bash
# Hook SessionStart: avisa si /compromisos lleva más de un día sin correr, lista los
# DEBO que vencen en ≤7 días y, si la config declara radar_externo, resume los DEBO
# de ese otro ledger. Config: Meta/compromisos-config.md (o $COMPROMISOS_CONFIG).
# Solo lee. Nunca escribe ni llama a Calendar. Siempre sale 0.
root="${CLAUDE_PROJECT_DIR:-.}"
cfg_file="${COMPROMISOS_CONFIG:-$root/Meta/compromisos-config.md}"
cfg() { # clave → valor del frontmatter de la config, sin comillas; vacío si no hay
  [[ -f "$cfg_file" ]] || return 0
  awk -v k="$1" 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit}
    index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); gsub(/^["\047]|["\047][ \t]*$/, ""); print; exit }' "$cfg_file" 2>/dev/null
}
debo_rows() { # archivo, límite → "fecha<TAB>qué<TAB>quién" por cada DEBO abierto con fecha ≤ límite
  awk -F'|' -v lim="$2" '
    /^## / { en = ($0 ~ /^## DEBO abiertos/); next }
    !en || NF < 6 { next }
    { for (i = 2; i <= 5; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i) }
    $2 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { next }
    $2 <= lim { print $2 "\t" $3 "\t" $4 }' "$1" 2>/dev/null
}
hoy=$(date +%Y-%m-%d); ayer=$(date -v-1d +%Y-%m-%d); lim=$(date -v+7d +%Y-%m-%d)
ledger_rel="$(cfg ledger)"; ledger_rel="${ledger_rel:-_negocio/operacion/compromisos.md}"
f="${1:-$root/$ledger_rel}"
if [[ -f "$f" ]]; then
  # Solo el frontmatter inicial: la línea 1 debe ser '---'; se corta en el siguiente '---'.
  last=$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^ultima_sincronizacion:/ {sub(/^ultima_sincronizacion:[ \t]*/, ""); gsub(/["\047]/, ""); print substr($0, 1, 10); exit}' "$f" 2>/dev/null)
  # Fechas ISO: la comparación de texto es comparación de fechas.
  if [[ "$last" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$last" < "$ayer" ]]; then
    echo "AVISO PARA SANTIAGO (dilo en tu primera línea): compromisos sin sincronizar desde $last — corre /compromisos"
  fi
  debo=$(debo_rows "$f" "$lim" | awk -F'\t' '{ printf "%s%s (%s, %s)", (n++ ? "; " : ""), $2, $3, $1 }')
  if [[ -n "$debo" ]]; then
    echo "AVISO PARA SANTIAGO (dilo en tu primera línea): DEBO que vencen en ≤7 días: $debo — ofrece desarrollarlos"
  fi
fi
ext="$(cfg radar_externo)"
if [[ -n "$ext" && -f "$ext" ]]; then
  filas=$(debo_rows "$ext" "$lim")
  if [[ -n "$filas" ]]; then
    n=$(printf '%s\n' "$filas" | wc -l | tr -d ' ')
    m=$(printf '%s\n' "$filas" | awk -F'\t' -v h="$hoy" '$1 < h { c++ } END { print c + 0 }')
    nom="$(cfg radar_externo_nombre)"; vau="$(cfg radar_externo_vault)"
    echo "AVISO PARA SANTIAGO (dilo en tu primera línea): ${nom:-Otro vault}: $n DEBO ≤7 días ($m vencidos) — abre ${vau:-el otro vault}"
  fi
fi
exit 0
