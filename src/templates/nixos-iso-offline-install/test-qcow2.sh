#!/usr/bin/env bash
# test-qcow2.sh — Testa o sistema NixOS instalado no qcow2
# Uso: test-qcow2.sh [caminho/para/disco.qcow2]
#
# Variáveis de ambiente:
#   DISK            — caminho para o .qcow2 (default: mydisk.qcow2)
#   SSH_TEST_PORT   — porta SSH no host (default: 2222)
#   NIXUSER_PASS    — senha do nixuser (default: 1)
#   SSH_TIMEOUT     — segundos para aguardar SSH (default: 120)

set -euo pipefail

DISK="${1:-${DISK:-mydisk.qcow2}}"
SSH_PORT="${SSH_TEST_PORT:-2222}"
NIXUSER_PASS="${NIXUSER_PASS:-1}"
TIMEOUT="${SSH_TIMEOUT:-180}"

# OVMF paths são substituídos pelo nix durante o build do derivation
OVMF_AARCH64="OVMF_PLACEHOLDER_AARCH64"
OVMF_X86_64="OVMF_PLACEHOLDER_X86_64"

# ────────────────────────────────────────────────────────────
echo "=== test-qcow2: $DISK ==="

if [ ! -f "$DISK" ]; then
    echo "ERRO: arquivo não encontrado: $DISK"
    echo "Execute 'nix run .#' primeiro para criar o disco."
    exit 1
fi

# Detecta arquitetura e monta parâmetros QEMU
_HOST_ARCH=$(uname -m)
case "$_HOST_ARCH" in
    aarch64)
        QEMU_BIN="qemu-system-aarch64"
        QEMU_MACHINE=(-enable-kvm -machine "virt,gic-version=max" -cpu host)
        QEMU_DISK=(-drive "file=$DISK,if=virtio,format=qcow2")
        OVMF_PATH="$OVMF_AARCH64"
        ;;
    x86_64)
        QEMU_BIN="qemu-system-x86_64"
        QEMU_MACHINE=(-enable-kvm -cpu "Haswell-noTSX-IBRS,vmx=on")
        QEMU_DISK=(-hda "$DISK")
        OVMF_PATH="$OVMF_X86_64"
        ;;
    *)
        echo "ERRO: arquitetura não suportada: $_HOST_ARCH"
        exit 1
        ;;
esac

# ────────────────────────────────────────────────────────────
# Inicia QEMU em background com port-forward SSH
QEMU_LOG="${TMPDIR:-/tmp}/test-qcow2-qemu-$$.log"
echo "Log QEMU: $QEMU_LOG"

"$QEMU_BIN" \
    "${QEMU_MACHINE[@]}" \
    -m 2G \
    -boot c \
    "${QEMU_DISK[@]}" \
    -bios "$OVMF_PATH" \
    -net nic,model=virtio \
    -net "user,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22,hostfwd=tcp:127.0.0.1:10000-:10000" \
    -nographic \
    >"$QEMU_LOG" 2>&1 &

QEMU_PID=$!

cleanup() {
    local _exit=$?
    echo ""
    echo "Encerrando QEMU (pid=$QEMU_PID)..."
    kill "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
    if [ "$_exit" -ne 0 ] && [ -f "$QEMU_LOG" ]; then
        echo "--- últimas 30 linhas do log QEMU ($QEMU_LOG) ---"
        tail -30 "$QEMU_LOG"
    fi
    exit $_exit
}
trap cleanup EXIT INT TERM

# Verifica se QEMU iniciou (falha imediata = path errado de OVMF, etc.)
sleep 1
if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    echo "ERRO: QEMU encerrou imediatamente. Log:"
    cat "$QEMU_LOG"
    exit 1
fi

# ────────────────────────────────────────────────────────────
# Aguarda SSH ficar disponível
echo "Aguardando SSH na porta $SSH_PORT (máx ${TIMEOUT}s)..."

SSH_OPTS=(
    -p "$SSH_PORT"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o ConnectTimeout=3
    -o PasswordAuthentication=yes
    -o PubkeyAuthentication=no
    -o LogLevel=ERROR
)

CONNECTED=0
for _i in $(seq 1 "$TIMEOUT"); do
    sleep 1
    if sshpass -p "$NIXUSER_PASS" ssh "${SSH_OPTS[@]}" nixuser@127.0.0.1 "exit 0" 2>/dev/null; then
        echo "SSH conectado após ${_i}s"
        CONNECTED=1
        break
    fi
done

if [ "$CONNECTED" -eq 0 ]; then
    echo "FALHA: SSH não ficou disponível após ${TIMEOUT}s"
    exit 1
fi

# ────────────────────────────────────────────────────────────
# Suite de testes
PASS=0
FAIL=0

_run() {
    local name="$1"
    local cmd="$2"
    printf "  %-45s" "$name"
    local out
    if out=$(sshpass -p "$NIXUSER_PASS" ssh "${SSH_OPTS[@]}" nixuser@127.0.0.1 "$cmd" 2>&1); then
        echo "PASS"
        (( PASS++ )) || true
    else
        echo "FAIL  ← $out"
        (( FAIL++ )) || true
    fi
}

echo ""
echo "=== Suite de testes ==="
_run "login nixuser"                  "true"
_run "nixos-version"                  "nixos-version"
_run "/ montado"                      "mountpoint -q /"
_run "/boot montado"                  "mountpoint -q /boot"
_run "/boot é vfat"                   "findmnt -n -o FSTYPE /boot | grep -q vfat"
_run "/ é ext4"                       "findmnt -n -o FSTYPE / | grep -q ext4"
_run "multi-user.target ativo"        "systemctl is-active multi-user.target"
_run "nixuser uid=1234"               "[ \"\$(id -u nixuser)\" = '1234' ]"
_run "nixuser no grupo wheel"         "id nixuser | grep -q wheel"
_run "sudo sem senha"                 "sudo -n true"
_run "bash disponível"                "bash --version | grep -q bash"
_run "git disponível"                 "git --version | grep -q git"

echo ""
echo "=== Resultado: ${PASS} ok, ${FAIL} falhou ==="

# Desliga via SSH antes do cleanup matar o QEMU
sshpass -p "$NIXUSER_PASS" ssh "${SSH_OPTS[@]}" nixuser@127.0.0.1 "sudo poweroff" 2>/dev/null || true
sleep 3   # dá tempo ao guest para desligar graciosamente

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
