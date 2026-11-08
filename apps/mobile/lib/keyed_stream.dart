import 'package:flutter/widgets.dart';

/// StreamBuilder that re-subscribes only when [streamKey] changes (not on every rebuild).
class KeyedStreamBuilder<T> extends StatefulWidget {
  const KeyedStreamBuilder({super.key, required this.streamKey, required this.stream, required this.builder});

  final Object? streamKey;
  final Stream<T> Function() stream;
  final Widget Function(BuildContext context, T? data) builder;

  @override
  State<KeyedStreamBuilder<T>> createState() => _KeyedStreamBuilderState<T>();
}

class _KeyedStreamBuilderState<T> extends State<KeyedStreamBuilder<T>> {
  late Stream<T> _stream = widget.stream();

  @override
  void didUpdateWidget(KeyedStreamBuilder<T> old) {
    super.didUpdateWidget(old);
    if (old.streamKey != widget.streamKey) _stream = widget.stream();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<T>(stream: _stream, builder: (context, snap) => widget.builder(context, snap.data));
}
