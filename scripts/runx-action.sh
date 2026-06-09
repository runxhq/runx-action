#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${INPUT_SKILL:-}" ]]; then
  echo "runx-action: input 'skill' is required" >&2
  exit 64
fi

runx_bin="${INPUT_RUNX_BINARY:-runx}"
working_directory="${INPUT_WORKING_DIRECTORY:-.}"
json="${INPUT_JSON:-true}"
receipt_dir="${INPUT_RECEIPT_DIR:-}"

args=()

if [[ -n "$receipt_dir" ]]; then
  mkdir -p "$receipt_dir"
  args+=("--receipt-dir" "$receipt_dir")
fi

if [[ "$json" == "true" ]]; then
  args+=("--json")
elif [[ "$json" != "false" ]]; then
  echo "runx-action: input 'json' must be true or false" >&2
  exit 64
fi

while IFS= read -r token || [[ -n "$token" ]]; do
  [[ -z "$token" ]] && continue
  args+=("$token")
done <<< "${INPUT_ARGS:-}"

stdout_file="$(mktemp)"
stderr_file="$(mktemp)"
cleanup() {
  rm -f "$stdout_file" "$stderr_file"
}
trap cleanup EXIT

pushd "$working_directory" >/dev/null
set +e
"$runx_bin" skill "$INPUT_SKILL" "${args[@]}" \
  > >(tee "$stdout_file") \
  2> >(tee "$stderr_file" >&2)
exit_code=$?
set -e
popd >/dev/null

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "exit-code=$exit_code"
    echo "stdout<<RUNX_ACTION_STDOUT"
    cat "$stdout_file"
    echo "RUNX_ACTION_STDOUT"
    echo "stderr<<RUNX_ACTION_STDERR"
    cat "$stderr_file"
    echo "RUNX_ACTION_STDERR"
  } >> "$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## runx"
    echo
    echo "- skill: \`$INPUT_SKILL\`"
    echo "- exit code: \`$exit_code\`"
  } >> "$GITHUB_STEP_SUMMARY"
fi

exit "$exit_code"
