import 'package:grinder/grinder.dart';
import 'package:tekartik_build_utils/cmd_run.dart';

main(args) => grind(args);

@Task()
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() async {
  // Pub.build();
  // await dartdocArgs();
  var dartAnalyzeCmd = dartanalyzerCmd(["."]);
  await runCmd(dartAnalyzeCmd);

  var dartFmtCmd = dartfmtCmd(["-w", "lib", "bin"]);
  await runCmd(dartFmtCmd);
}

@Task()
clean() => defaultClean();
