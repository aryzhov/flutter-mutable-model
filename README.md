# Mutable Model

A solution for Flutter state management based on mutable objects and mutable collections.

## Introduction

Some of the most popular state management solutions for Flutter are *BLoC* and *Redux*. 
Both of them promote immutable model objects which requires a change of mindset
for the developers coming from a mutable model background, particularly Java where 
property-based, mutable approach is very common. 

A Flutter solution worth mentioning that works well with immutable models is *ScopedModel*,
which has a fundamental limitation -- inability to limit the scope of change propagation based 
on certain parts of the model.

This package aims to provide a state management solution that addresses the 
deficiencies of ScopedModel and provides base classes for adding persistence to mutable
models.

Here are the main classes of this package:
* `Model` - an object that contains properties and keeps track of their changes.
* `Property` - a data element of a model.
* `MetaModel` - an object that describes model properties. 
* `StoredModel` - a model that supports serialization.
* `StoredProperty` - a property that has a name used for serialization.
* `OrderedMap` - an ordered map that fires events whenever it changes.
* `OrderedMapList` - a `ListView` that uses `OrderedMap` as its data source.
* `ModelProvider` - makes a model accessible to the child widget and all its children.
* `ModelConsumer` - retrieves the closest model of the specifed class exposed by `ModelProvider`.
Rebuilds itself when the model changes. Allows filtering change events that cause a rebuild.
