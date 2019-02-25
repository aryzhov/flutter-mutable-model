# Mutable Model

A solution for Flutter state management based on mutable models and model attributes.

## Introduction

Some of the most popular state management solutions for Flutter are *BLoC* and *Redux*. 
Both of them promote immutable model objects which requires a change of mindset
for the developers coming from a mutable model background, particularly Java where 
property-based, mutable approach is very common.

A Flutter solution worth mentioning that works well with immutable models is *ScopedModel*,
which has a fundamental limitation -- inability to filter state change propagations to certain
attributes of the model.

This package aims to provide a complete state management solution that addresses the 
deficiencies of ScopedModel and provides base classes for adding persistence to mutable
models.

Here are the main classes of this package:
* `Mutable` - an object that knows if it has been changed.
* `MutableObject` - an object that contains mutables and keeps track of their changes.
* `Attr` - an extension of Mutable that has a value.
* `OrderedMap` - an ordered map that fires events whenever it mutates.
* `OrderedMapList` - a `ListView` that uses `OrderedMap` as its data source.
* `ModelProvider` - makes a mutable model accessible to the child widget and all its children.
* `ModelConsumer` - retrieves the closest model of the specifed class exposed by `ModelProvider`.
Rebuilds itself when the model changes. Allows filtering change events that cause a rebuild.
