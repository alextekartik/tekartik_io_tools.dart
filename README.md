# tekartik_io_tools

Common io tools

    pub global activate -s git git://github.com/alextekartik/tekartik_io_tools.dart

# Commands

## rpubtest

    rpubtest

Recursively run all test in all packages found. Tested are run 1 one at a time (-j 1). However packages are tested simultaneously (number can be configured using the -j option)
default is to test on vm platform, you can define multiple platforms in an env variable

    export TEKARTIK_RPUBTEST_PLATFORMS=content-shell,vm

## rgitpull

    rgitpull

Recursively pull git update

## rscstatus

    rscstatus

Recursively get git or hg status for all source control project found
