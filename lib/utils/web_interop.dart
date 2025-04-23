@JS()
library web_interop;

import 'package:js/js.dart';

@JS('dartify')
external dynamic dartify(dynamic jsObject);

@JS('jsify')
external dynamic jsify(dynamic dartObject);
