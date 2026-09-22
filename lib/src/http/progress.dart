/// Reports upload progress as bytes are sent.
///
/// [sent] counts bytes written so far and [total] is the full encoded body
/// length, so `sent / total` is a usable fraction. This typedef is owned by
/// this package rather than borrowed from the HTTP client, so swapping the
/// transport never changes your call sites.
typedef CloudinaryProgressCallback = void Function(int sent, int total);
