import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ModelProvider<M extends Listenable> extends InheritedNotifier<M> {

  ModelProvider({
    Key key,
    @required
    M model,
    @required
    Widget child,
  }):super(
      key: key,
      notifier: model,
      child: child,
    );

  static M of<M extends Listenable>(BuildContext context, {bool rebuildOnChange = true}) {

    final type = _type<ModelProvider<M>>();

    final notifier = rebuildOnChange ?
        context.inheritFromWidgetOfExactType(type) :
        context.ancestorWidgetOfExactType(type);
    assert(notifier != null);
    return (notifier as ModelProvider<M>).notifier;
  }

  static Type _type<T>() => T;

}

typedef bool NotificationFilter<M extends Listenable>(m);
typedef Widget ModelBuilder<M>(BuildContext context, M model);

class ModelConsumer<M extends Listenable> extends StatefulWidget {

  M model;
  final NotificationFilter<M> filter;
  final ModelBuilder<M> builder;

  ModelConsumer({
    this.model,
    @required
    this.filter,
    @required
    this.builder});

  @override
  State<StatefulWidget> createState() {
    return ModelConsumerState<M>();
  }

}

class ModelConsumerState<M extends Listenable> extends State<ModelConsumer<M>> {

  M model;

  @override
  void initState() {
    super.initState();
    model = widget.model ?? ModelProvider.of<M>(context, rebuildOnChange: false);
    model.addListener(_modelChanged);
  }

  @override
  void didUpdateWidget(ModelConsumer<M> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != null && widget.model != model) {
      model.removeListener(_modelChanged);
      model = widget.model;
      model.addListener(_modelChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, model);
  }

  _modelChanged() {
    if(widget.filter(model)) {
      setState(() {
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    model.removeListener(_modelChanged);
  }

}

