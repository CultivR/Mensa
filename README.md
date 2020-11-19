# Mensa: Smart Tables

Shows three simple techniques for modern table views and collection views. The three techniques are each separate in concept but are combined in this demo project; you can use each independently.

## Computation of row height or item size via auto layout

The table or collection view controller’s data mediator keeps a extra metrics cell property that is used to populate and layout cells for height calculation purposes.

This is primarily useful for cells that use Auto Layout. You no longer have to perform clumsy and awkward height calculation - just use Auto Layout and you get height calculation for free.

The downside of this is that your cells are laid out twice and Auto Layout is potentially expensive. You could mitigate this by caching the results of the first lay out and then reusing it for the second. But caching metrics is somewhat tricky to get right. The cache needs to be abandoned or updated if the view is editable or size changes, rotations, dynamic text size changes (iOS 7) and probably under many other situations too. 

In practice with the typical view you’d see in a table view (e.g. a complex tweet view) the double layout isn’t expensive.

## View controllers as cell prototypes

Use of `UIViewController` instances in table or collection view cells and runtime generation of cell classes for specific view controllers

This is useful because table cells aren’t usable outside of tables. By hosting content inside a view controller and then hosting that view controller inside a cell you can reuse that UI in other parts of your app very easily. This is often handy. We show this here by hosting the same `UIViewController` class in both a table view and a collection view.

The technique generates at runtime a subclass of `MNSHostingTableViewCell` or `MNSHostingCollectionViewCell` that hosts a specific view controller class. This allows you to register a cell class with your table or collection view as needed. This technique works very well with cell reuse.

## View controller registration for backing objects

To populate their table or collection view’s content, `MNSTableViewController` and ``MNSCollectionViewController` instances define a `sections` array populated with `MNSTableViewSection` (to include a section header or footer) or `NSArray` instances, along with a data mediator between the view and the data. To display the objects in each section, the table or collection view controller registers a `MNSHostedViewController` subclass to use with each model object class. The view controller references a view (or multiple views if needed, to customize the display of the object based on its properties) whose contents are updated based on the model object to display.

This allows developers to consolidate display logic to a separate view controller for a view displaying that object and populating its contents and selecting it in a table or collection view. **More importantly, it provides a simple but robust way to display arbitrary lists of heterogeneous objects in a table or collection view and process user input around them.** Table and collection view controller subclasses can customize this behavior further based on their own state or behavior specified wherever necessary.

## Example

The demo example shows these three techniques in action. Our table view controller subclass maintains an array of objects to display in the table view. It displays `MNSNumber` instances with values from 1 to 100 and an `MNSPrimeFlag` instance below any prime number. Tapping on a number will display its factors. We register each model object class to use the appropriate view controller whose view will display instances of it and handle selection behavior. (Note that these view controllers are usable anywhere, not just in our table view cells, but we take advantage of cell height being automatically calculated through the view’s layout constraints.) In the table view controller, we use custom logic to shrink the font size of the label used to display the number as it increases.

![Screenshot 1](https://dl.dropboxusercontent.com/u/11479646/iOS%20Simulator%20Screen%20shot%20Dec%208%2C%202013%2C%2010.53.09%20AM.png)
![Screenshot 2](https://dl.dropboxusercontent.com/u/11479646/iOS%20Simulator%20Screen%20shot%20Dec%208%2C%202013%2C%2010.53.38%20AM.png)

We also demonstrate this technique within a collection view, using a flow layout and providing the ability to show or hide the prime flags following each number.

![Screenshot 3](https://dl.dropboxusercontent.com/u/11479646/iOS%20Simulator%20Screen%20shot%20Jan%2014%2C%202014%2C%207.17.34%20PM.png)

## Requirements

Project uses Xcode 5 (specifically the nibs), but the techniques used work fine on iOS 6+.

## License

MIT
