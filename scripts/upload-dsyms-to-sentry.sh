#!/usr/bin/env bash

TEST_WORDS=("TEST" "PROD")
CONTAINS_PROD_TEST=false
BUILD_TYPE=""
echo "Swift Active Compilation Conditions: $SWIFT_ACTIVE_COMPILATION_CONDITIONS"

# Convert line into an array of words (split by whitespace)
WORDS=($SWIFT_ACTIVE_COMPILATION_CONDITIONS)
for WORD in "${WORDS[@]}"; do
    for TEST in "${TEST_WORDS[@]}"; do
        if [[ "$WORD" == "$TEST" ]]; then
            CONTAINS_PROD_TEST=true
            BUILD_TYPE=$WORD
            break
        fi
    done
done

if [[ "$CONTAINS_PROD_TEST" == false ]]; then
    >&2 echo "Do not upload dsyms. Not TEST or PROD build."
    exit 0
else
    echo "✅ Should upload dsyms. $BUILD_TYPE build"
fi

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which sentry-cli >/dev/null; then
    ERROR=$(sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
    if [ ! $? -eq 0 ]; then
        >&2 echo "warning: sentry-cli - $ERROR"
    else
        >&2 echo "Sentry Debug Files Upload Success"
    fi
else
    curl -sL https://sentry.io/get-cli/ | SENTRY_CLI_VERSION=2.50.2 bash
    echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
    ERROR=$(sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
    if [ ! $? -eq 0 ]; then
        echo "warning: sentry-cli - $ERROR"
    fi
fi