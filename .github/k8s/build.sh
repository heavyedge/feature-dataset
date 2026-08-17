if [ "${GITHUB_EVENT_NAME}" = "release" ]; then
    export HEAVYEDGE_TEST_MODE=0
else
    export HEAVYEDGE_TEST_MODE=1
fi
make -j "$MAKE_JOBS"
