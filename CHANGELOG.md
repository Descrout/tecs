## 1.0.9

* Zero allocation ``queryEach`` function introduced.

## 1.0.8

* Big performance boost !

## 1.0.7

* ``clearEntities`` function now invalidates ``QueryParams`` with world versioning. (** BUG FIX **)

## 1.0.4

* Querying will return the list of rows directly instead of capsulating them in a class.
* Ability to query with parameters has been added. ``queryWithParams``, ``queryCountWithParams`` 
* Helper functions added for creating custom queries. ``componentID``, ``componentColumn``, ``archetypesWith``

## 1.0.3

* Ability to create entities with multiple components, in bulk.

## 1.0.2

* BitHash to SetHash so you can have more than 32 components.

## 1.0.1

* Ability to add and remove components in bulk.

## 1.0.0

* Initial release.