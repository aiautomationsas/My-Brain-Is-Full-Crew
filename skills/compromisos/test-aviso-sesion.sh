#!/usr/bin/env bash
# Pruebas de aviso-sesion.sh. Uso: bash .claude/skills/compromisos/test-aviso-sesion.sh
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
S="$DIR/aviso-sesion.sh"
T="$(mktemp -d)"
fail=0
# Aísla las pruebas de la config real del vault.
export COMPROMISOS_CONFIG="$T/sin-config.md"

check() { # nombre, archivo, esperado: aviso|vacio
  local out code
  out="$(bash "$S" "$2")"; code=$?
  if [[ $code -ne 0 ]]; then echo "FAIL $1: exit $code"; fail=1; return; fi
  if [[ "$3" == aviso && "$out" != *"corre /compromisos"* ]]; then
    echo "FAIL $1: esperaba aviso, salió '$out'"; fail=1; return
  fi
  if [[ "$3" == vacio && -n "$out" ]]; then
    echo "FAIL $1: esperaba silencio, salió '$out'"; fail=1; return
  fi
  echo "ok $1"
}

hace2=$(date -v-2d +%Y-%m-%d)
ayer=$(date -v-1d +%Y-%m-%d)
hoy=$(date +%Y-%m-%d)
printf -- '---\ncreado_por: x\nultima_sincronizacion: %s 09:00\n---\n# x\n' "$hace2" > "$T/viejo.md"
printf -- '---\nultima_sincronizacion: %s 09:00\n---\n' "$ayer" > "$T/ayer.md"
printf -- '---\nultima_sincronizacion: %s 09:00\n---\n' "$hoy" > "$T/hoy.md"
printf '# sin frontmatter\n\n---\nultima_sincronizacion: 2020-01-01 09:00\n---\n' > "$T/regla.md"
printf -- '---\nultima_sincronizacion: pronto\n---\n' > "$T/basura.md"
printf -- '---\nultima_sincronizacion: "%s 09:00"\n---\n' "$hace2" > "$T/comillas.md"
printf -- '---\nultima_sincronizacion: %sT09:00\n---\n' "$hace2" > "$T/iso.md"
mkdir -p "$T/proy/_negocio/operacion"
cp "$T/viejo.md" "$T/proy/_negocio/operacion/compromisos.md"

check "hace 2 días avisa" "$T/viejo.md" aviso
check "ayer calla" "$T/ayer.md" vacio
check "hoy calla" "$T/hoy.md" vacio
check "regla horizontal en el cuerpo calla" "$T/regla.md" vacio
check "fecha basura calla" "$T/basura.md" vacio
check "archivo inexistente calla" "$T/no-existe.md" vacio
check "fecha entre comillas avisa" "$T/comillas.md" aviso
check "fecha ISO con T avisa" "$T/iso.md" aviso
# Sin argumento y desde otro directorio: usa CLAUDE_PROJECT_DIR.
out="$(cd / && CLAUDE_PROJECT_DIR="$T/proy" bash "$S")"
if [[ "$out" == *"corre /compromisos"* ]]; then echo "ok CLAUDE_PROJECT_DIR fuera de la raíz avisa"; else echo "FAIL CLAUDE_PROJECT_DIR: salió '$out'"; fail=1; fi

# --- Aviso de DEBO por vencer ---
tiene() { # nombre, archivo, texto esperado ("" = silencio), texto prohibido (opcional)
  local out code
  out="$(bash "$S" "$2")"; code=$?
  if [[ $code -ne 0 ]]; then echo "FAIL $1: exit $code"; fail=1; return; fi
  if [[ -z "$3" && -n "$out" ]]; then echo "FAIL $1: esperaba silencio, salió '$out'"; fail=1; return; fi
  if [[ -n "$3" && "$out" != *"$3"* ]]; then echo "FAIL $1: esperaba '$3', salió '$out'"; fail=1; return; fi
  if [[ -n "${4:-}" && "$out" == *"$4"* ]]; then echo "FAIL $1: no esperaba '$4', salió '$out'"; fail=1; return; fi
  echo "ok $1"
}
man=$(date -v+1d +%Y-%m-%d)
en5=$(date -v+5d +%Y-%m-%d)
en10=$(date -v+10d +%Y-%m-%d)
ledger() { # sync, filas DEBO...; siempre trae un ESPERO y un Cumplido de mañana
  local sync="$1"; shift
  printf -- '---\nultima_sincronizacion: %s 09:00\n---\n# Compromisos\n\n## DEBO abiertos\n\n' "$sync"
  printf '| Vence | Qué | Quién | Frente | Nota | Posp. | ID |\n|---|---|---|---|---|---|---|\n'
  [[ $# -gt 0 ]] && printf '%s\n' "$@"
  printf '\n## ESPERO abiertos\n\n| Vence | Qué | Quién | Frente | Nota | Posp. | ID |\n|---|---|---|---|---|---|---|\n'
  printf '| %s | firma | Juan | _negocio | — | 0 | e1 |\n' "$man"
  printf '\n## Cumplidos\n\n| Fecha | Tipo | Qué | Quién |\n|---|---|---|---|\n| %s | DEBO | viejo | Nadie |\n' "$man"
}
ledger "$hoy" "| $man | propuesta | IPC | _negocio | — | 0 | a |" > "$T/d-man.md"
ledger "$hoy" "| $en5 | contrato | Host | clientes | — | 0 | a |" > "$T/d-5.md"
ledger "$hoy" "| $en10 | estudio | Lote | _negocio | — | 0 | a |" > "$T/d-10.md"
ledger "$hoy" "| $ayer | vencido | BASA | clientes | — | 0 | a |" > "$T/d-vencido.md"
ledger "$hoy" "| $man | pagar | Colegio | personal | — | 0 | a |" > "$T/d-personal.md"
ledger "$hoy" "| $man | pagar | Colegio |  personal  | — | 0 | a |" > "$T/d-personal-esp.md"
ledger "$hoy" > "$T/d-solo-espero.md"
ledger "$hoy" "| $man | uno | A | _negocio | — | 0 | a |" "| $man | dos | B | _negocio | — | 0 | b |" \
  "| $man | tres | C | _negocio | — | 0 | c |" "| $man | cuatro | D | _negocio | — | 0 | d |" \
  "| $man | cinco | E | _negocio | — | 0 | e |" "| $man | seis | F | _negocio | — | 0 | f |" > "$T/d-seis.md"
ledger "$hace2" "| $man | propuesta | IPC | _negocio | — | 0 | a |" > "$T/d-sync-vieja.md"
ledger "pronto" "| $man | propuesta | IPC | _negocio | — | 0 | a |" > "$T/d-basura.md"

tiene "DEBO mañana avisa" "$T/d-man.md" "propuesta (IPC, $man)"
tiene "DEBO en 5 días avisa" "$T/d-5.md" "contrato (Host, $en5)"
tiene "DEBO en 10 días calla" "$T/d-10.md" ""
tiene "DEBO vencido avisa" "$T/d-vencido.md" "vencido (BASA, $ayer)"
tiene "personal mañana avisa" "$T/d-personal.md" "pagar (Colegio, $man)"
tiene "personal con espacios avisa" "$T/d-personal-esp.md" "pagar (Colegio, $man)"
tiene "ESPERO mañana calla" "$T/d-solo-espero.md" ""
tiene "seis DEBO los lista todos" "$T/d-seis.md" "seis (F, $man)"
tiene "texto del aviso" "$T/d-man.md" "DEBO que vencen en ≤7 días: propuesta (IPC, $man) — ofrece desarrollarlos"
tiene "sync vieja y DEBO: aviso de sync" "$T/d-sync-vieja.md" "corre /compromisos"
tiene "sync vieja y DEBO: aviso de DEBO" "$T/d-sync-vieja.md" "ofrece desarrollarlos"
tiene "fecha basura con DEBO avisa DEBO" "$T/d-basura.md" "ofrece desarrollarlos" "corre /compromisos"

# --- Config y radar externo ---
mkdir -p "$T/cfgv/Meta" "$T/cfgv/operacion"
ledger "$hoy" "| $man | propuesta | WFE | cuentas | — | 0 | s1 |" "| $ayer | cotización | Bionica | cuentas | — | 0 | s2 |" > "$T/externo.md"
ledger "$hoy" "| $en10 | lejano | X | cuentas | — | 0 | s3 |" > "$T/externo-lejano.md"
ledger "$hoy" "| $man | ptee | WFE | cuentas | — | 0 | s4 |" > "$T/cfgv/operacion/compromisos.md"
cfg() { # ledger, radar_externo
  printf -- '---\nledger: %s\nradar_externo: %s\nradar_externo_nombre: Sumalaft\nradar_externo_vault: vault-sumalaft\n---\n' "$1" "$2"
}
cfg "_negocio/operacion/compromisos.md" "$T/externo.md" > "$T/cfg-radar.md"
cfg "_negocio/operacion/compromisos.md" "$T/externo-lejano.md" > "$T/cfg-lejano.md"
cfg "_negocio/operacion/compromisos.md" "$T/no-existe.md" > "$T/cfg-roto.md"
cfg "operacion/compromisos.md" "" > "$T/cfgv/Meta/compromisos-config.md"
radar() { # nombre, config, esperado ("" = silencio sobre Sumalaft)
  local out; out="$(COMPROMISOS_CONFIG="$2" bash "$S" "$T/d-solo-espero.md")"
  if [[ -z "$3" && "$out" == *"Sumalaft:"* ]]; then echo "FAIL $1: salió '$out'"; fail=1; return; fi
  if [[ -n "$3" && "$out" != *"$3"* ]]; then echo "FAIL $1: esperaba '$3', salió '$out'"; fail=1; return; fi
  echo "ok $1"
}
radar "radar externo cuenta y vencidos" "$T/cfg-radar.md" "Sumalaft: 2 DEBO ≤7 días (1 vencidos) — abre vault-sumalaft"
radar "radar externo lejano calla" "$T/cfg-lejano.md" ""
radar "radar externo inexistente calla" "$T/cfg-roto.md" ""
radar "sin config calla" "$T/sin-config.md" ""
out="$(cd / && CLAUDE_PROJECT_DIR="$T/cfgv" COMPROMISOS_CONFIG="$T/cfgv/Meta/compromisos-config.md" bash "$S")"
if [[ "$out" == *"ptee (WFE, $man)"* ]]; then echo "ok ledger desde config"; else echo "FAIL ledger desde config: '$out'"; fail=1; fi

rm -rf "$T"
exit $fail
