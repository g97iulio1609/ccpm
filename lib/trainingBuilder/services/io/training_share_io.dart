// Conditional export of platform-specific implementation
export 'training_share_io_stub.dart'
    if (dart.library.html) 'training_share_io_web.dart';

