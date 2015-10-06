library tekartik_io_tools.args_utils;

String argsToDebugString(List<String> args, [bool addSpaceIfNotEmpty = true]) {
  List<String> sanitized;
  if (args != null && args.isNotEmpty) {
    sanitized = [];
    for (String arg in args) {
      if (arg.contains(' ')) {
        arg = "'$arg'";
      }
      sanitized.add(arg);
    }
  } else {
    return '';
  }
  return '${addSpaceIfNotEmpty == true ? ' ' : ''}${sanitized.join(' ')}';
}
