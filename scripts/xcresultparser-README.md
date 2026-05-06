The `xcresultparser` executable will parse an `.xcresult` file and generate reports in the specified format.

The [GitHub repository is here](https://github.com/a7ex/xcresultparser)
The bundled release is [2.0.0](https://github.com/a7ex/xcresultparser/releases/tag/2.0.0)

```
USAGE: xcresultparser [<options>] [<xcresult-file>]

ARGUMENTS:
  <xcresult-file>         The path to the .xcresult file.

OPTIONS:
  --coverage-report-format <coverage-report-format>
                          The coverage report format. The Default is 'methods',
                          It can either be 'totals', 'targets', 'classes' or
                          'methods'
  -o, --output-format <output-format>
                          The output format. It can be either 'txt', 'cli',
                          'html', 'md', 'xml', 'junit', 'cobertura',
                          'warnings', 'errors' and 'warnings-and-errors'. In
                          case of 'xml' sonar generic format for test results
                          and generic format (Sonarqube) for coverage data is
                          used. In the case of 'cobertura', --coverage is
                          implied.
  -p, --project-root <project-root>
                          The name of the project root. If present paths and
                          urls are relative to the specified directory.
  -t, --coverage-targets <coverage-targets>
                          Specify which targets to calculate coverage from. You
                          can use more than one -t option to specify a list of
                          targets.
  -e, --excluded-path <excluded-path>
                          Specify which path names to exclude. You can use more
                          than one -e option to specify a list of path patterns
                          to exclude. This option only has effect, if the
                          format is either 'cobertura' or 'xml' with the
                          --coverage (-c) option for a code coverage report or
                          if the format is one of 'warnings', 'errors' or
                          'warnings-and-errors'.
  -s, --summary-fields <summary-fields>
                          The fields in the summary. Default is all:
                          errors|warnings|analyzerWarnings|tests|failed|skipped|duration|date
  -c, --coverage          Whether to print coverage data.
  -x, --exclude-coverage-not-in-project
                          Omit elements with file pathes, which do not contain
                          'projectRoot'.
  -n, --no-test-result    Whether to print test results.
  -f, --failed-tests-only Whether to only print failed tests.
  -q, --quiet             Quiet. Don't print status output.
  -i, --target-info       Just print the targets contained in the xcresult.
  -v, --version           Show version number.
  -h, --help              Show help information.
  
  xcresultparser --summary-fields 'tests|failed|skipped|duration|date' Report.xcresult
```
