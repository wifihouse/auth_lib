import 'dart:math';

class NetUtils {
  static const int MAX_LENGTH_LOG_INLINE = 150;

  String convertToFbLink(String path) {
    if (path.startsWith("http")) {
      return path;
    } else {
      return "https://firebasestorage.googleapis.com/v0/b/svl-project-6aaee.appspot.com/o/${Uri.encodeComponent(path)}?alt=media";
    }
  }

  static printCustom(Object obj) {
    String str = obj.toString();
    int len = str.length;
    int m = (len*1.0/MAX_LENGTH_LOG_INLINE).ceil();
    for (int i = 0; i < m; ++i) {
      print(str.substring(i*MAX_LENGTH_LOG_INLINE, min((i+1)*MAX_LENGTH_LOG_INLINE, len)));
    }
  }
}
