<p align="center">
  <img width="500" height="500" src="https://raw.githubusercontent.com/robertcorponoi/graphics/master/godot-redux/logo/godot-redux-logo.png">
</p>

<h1 align="center">Godot Redux</h1>

<p align="center">A gdscript implementation of Redux.<p>

Redux is a way to manage and update your application's state using events
called actions. The Redux store serves as a centralized place for data that
can be used across your entire application.

**Table of Contents**

- [Concepts](#concepts)
    - [Initial State](#initial-state)
    - [Actions](#actions)
    - [Reducers](#reducers)
    - [Store](#store)
    - [Dispatching](#dispatching)
    - [Middleware](#middleware)
- [Full Example](#full-example)
- [How To Use the Store In Other Scripts](#how-to-use-the-store-in-other-scripts)
- [API](#api)
    - [new](#new)
    - [state](#state)
    - [dispatch](#dispatch)
    - [subscribe](#subscribe)
    - [add_middleware](#add_middleware)
- [License](#license)

## Concepts

The data in Redux is immutable. While this would be great to be able to
enforce in gdscript, it is not currently possible and so it is up to you to
follow the rules and best practices of how to modify data in your actions as
you'll see further down in the Reducers section.

### Initial State

The state in redux is stored in an object called the store. While this can be
anything, most of the time you'll be using a dictionary of values. Let's take
a look at a simple state that has a counter variable:

```gd
const state = {
    "counter": 0
}
```

### Actions

Actions are the only way to change the state of a Redux application and in
gdscript they are represented by an enum. Let's expand the simple counter
example from above and create actions to increment and decrement the counter.

```gd
enum Action {
    INCREMENT,
    DECREMENT,
}
```

### Reducers

To actually change the values in the state, we need to create reducers. A
reducer is a function that takes the current state and an action and decides
how to update the state if necessary. The example below shows how to create a
reducer for incrementing and decrementing the counter:

```gd
const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }
```

A couple things to keep in mind here. First we have to again stress that the
state is immutable. This means that you MUST return a new state from your
reducer. Second, while you have to return a new state, you can use values from
your old state data to create the new state.

### Store

So far we've discussed the core components and can put them together into the
store. The store must be instanced with the initial state, the current
instance, and the name of the reducer function. The current instance and the
reducer function name must be provided so that we can keep a reference to it.
A full example with the store can look like:

```gd
const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }

func _ready():
    var store = Store.new(state, self, 'reducer')
```

### Dispatching

To actually update the store you have to use the `dispatch` method with the
action you want to run. This will cause the store to run the reducer function
and save the new state value.

```gd
store.dispatch(Action.INCREMENT)
```

This will make the store run the reducer for `INCREMENT` and make the counter
go from 0 to 1.

### Subscriptions

To listen for changes to the state you can use a subscription. The
subscription will be called any time an action is dispatched, and some of the
state might have changed. To create a subscriber, you have to pass the
instance and the name of the function that should be run when the state is
changed like so:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.subscribe(self, 'display_counter')

func display_counter(state):
    print(state.counter)
```

Now whenever the state is changed with dispatch, the `display_counter`
function will be run and the counter will be printed to the console.

### Middleware

Middleware is used to customize the dispatch function. This is done by
providing you a point between dispatching an action and it reaching the
reducer. Each piece of middleware added will use the action returned by the
previous middleware and if nothing is returned then the middleware chain stops
being processed.

Below is an example of a middleware function that will take the current action
and reverse it:

```gd
func reverse_middleware(state, action):
    match action {
        Action::INCREMENT:
            return Action::DECREMENT
        Action::DECREMENT:
            return Action::INCREMENT

func _ready():
    var store = Store.new(state, self, 'reducer')
    store.add_middleware(self, 'reverse_middleware')

    This will actually run the `DECREMENT` action because of our middleware.
    store.dispatch(Action::INCREMENT)
```

## Full Example

In this section we'll go through a full example of how you can add Godot Redux to your project and use it in various ways. While this is a full example, it will still use a basic counter so if you would like to see more complex examples check out the [example projects](./examples)(coming soon).

1. Copy the `store.gd` script to your Godot project.

2. Create a new script to create your store in.

3. In this script, the first thing we need to do is load the `store.gd` script like so:

```gd
var Store = load("res://store.gd")
```

4. Next, we need to create our initial store. Remember that the store is a Dictionary of values and for our simple counter example it will look something like:

```gd
const state = {
    "counter": 0
}
```

5. Next we need to define our actions. Actions are defined as an enum like so:

```gd
enum Action {
    INCREMENT,
    DECREMENT,
}
```

6. Now we have to create the reducer function which will dictate what happens when the `INCREMENT` or `DECREMENT` action is dispatched.

```gd
func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }
```

So the reducer function will always take the state and action being dispatched as its arguments. We use a match statement so taht when `INCREMENT` is used, the counter will increase by 1 and when `DECREMENT` is used, the counter will decrease by 1. Two other things to note here. One, notice that we're returning a new copy of the state in each match arm and two, we can use the previous value of the state to create the new one.

7. Let's put this all together and create the `Store` instance. To create a new store instance, we need to pass in our initial state, the class instance that has the reducer function, and the name of the reducer function like so:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
```

Since our reducer function is just named 'reducer' and it's on the current class instnace, we can just pass `self` and 'reducer` as the last two arguments.

8. Now we're ready to try dispatching and see how it affects our state. Let's try dispatching the `INCREMENT` action twice and then the `DECREMENT` action once like so:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.dispatch(action.INCREMENT)
    store.dispatch(action.INCREMENT)
    store.dispatch(action.DECREMENT)
```

If everything worked correctly, this should put the counter at 1, so let's see:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.dispatch(action.INCREMENT)
    store.dispatch(action.INCREMENT)
    store.dispatch(action.DECREMENT)

    print(store.state()) # { "counter": 1 }
```

The above is a basic example of how to set up and use the store. We didn't go over all of the available methods though so now we're going to do a couple examples of `subscribe` and `add_middleware`.

`subscribe` - The `subscribe` method is used to add a listener to state changes. This means that whenever the state might change, the method that was subscribed will be called and it will be passed the current state as an argument. Below is an example of how you could create a subscriber that would print the counter state whenever it changes:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.subscribe(self, 'counter_printer')

func counter_printer(state):
    print(state.counter)
```

Note that `subscribe` is similar to how the store was initialized in that you have to pass the class instance that contains the subscribe function and then the name of the function.

`add_middleware` - The `add_middleware` method is used to add middleware that can alter the action of a dispatch before it reaches the reducer. The middleware will be passed the current state and the action that was used as arguments. As a simple example, we'll go through creating a middleware that will take the action and return the opposite action:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.add_middleware(self, 'reverse_action')

func reverse_action(state, action):
    if (action == action.INCREMENT):
        return action.DECREMENT
    elif (action == action.DECREMENT):
        return action.INCREMENT
```

Notice that the `add_middleware` is similar to `subscribe` in that it takes the class instance that contains the middleware function and then the name of the middleware function as arguments.

We can test to see if this works by dispatching the same actions we did earlier like so:

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.add_middleware(self, 'reverse_action')

    store.dispatch(action.INCREMENT)
    store.dispatch(action.INCREMENT)
    store.dispatch(action.DECREMENT)

    print(store.state()) # { "counter": -1 }

func reverse_action(state, action):
    if (action == action.INCREMENT):
        return action.DECREMENT
    elif (action == action.DECREMENT):
        return action.INCREMENT
```

Instead of returning 1 as the value of the counter it should now return -1.

## How To Use the Store In Other Scripts

Where you set up the store might not be where you always need to use it. In this case, it might be better to look at autoloading the script where you created your store.

For example let's assume that you want to create a `save.gd` script where you'll set up the store. We'll just use the basic counter example from above:

`save.gd`

```gd
var store

const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }

func _ready():
    store = Store.new(state, self, 'reducer')
```

The only difference here is that we declare `store` at the top level so that we can reference it from outside of this script.

Now you can go to `Project -> AutoLoad` and select your `save.gd` script with a Node name that represents the name of the global variable you'll use to access this script (for this example we'll use `Save`).

Lastly, you can create a new script and use your store instance like so:

```gd
extends Node

func _ready():
    Save.store.dispatch(Save.Action.INCREMENT)
    Save.store.dispatch(Save.Action.DECREMENT)
    
    print(Save.store.state()) # { "counter": 0 }
```

As shown in the example above you can now use your store anywhere by referencing the global `Save` variable.

## API

### new

Creates a new Redux store.

| param               | type       | description                                            |
|---------------------|------------|--------------------------------------------------------|
| state               | Dictionary | The initial state of the application.                  |
| reducer_fn_instance | Object     | The class instance that contains the reducer function. |
| reducer_fn_name     | String     | The name of the reducer function.                      |

**Example:**

```gd
const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }

func _ready():
    var store = Store.new(state, self, 'reducer')
```

### state

Returns the current state.

**Example:**

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    var state = store.state()
```

### dispatch

Runs the reducer function for the specified action.

| param  | type | description                        |
|--------|------|------------------------------------|
| action | Enum | The action to pass to the reducer. |

**Example:**

```gd
const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }

func _ready():
    var store = Store.new(state, self, 'reducer')
    store.dispatch(Action::INCREMENT)
```

### subscribe

Creates a subscriber that gets called whenever the state is changed. The callback function provided will be passed the current state as an argument.

| param                | type   | description                                                        |
|----------------------|--------|--------------------------------------------------------------------|
| callback_fn_instance | Object | The class instance that contains the subscriber callback function. |
| callback_fn_name     | String | The name of the callback function.                                 |

**Example:**

```gd
const state = {
    "counter": 0,
}

enum Action {
    INCREMENT,
    DECREMENT,
}

func reducer(state, action):
    match action:
        Action::INCREMENT:
            return {
                "counter": state.counter + 1,
            }
        Action::DECREMENT:
            return {
                "counter": state.counter - 1,
            }

func _ready():
    var store = Store.new(state, self, 'reducer')
    store.subscribe(self, 'counter_printer')

func counter_printer(state):
    print(state.counter)
```

### add_middleware

Adds a middleware function to intercept dispatches before they reach the reducer. Middleware can be used to change the action to run.

| param                  | type   | description                                               |
|------------------------|--------|-----------------------------------------------------------|
| middleware_fn_instance | Object | The class instance that contains the middleware function. |
| middleware_fn_name     | String | The name of the middleware function.                      |

**Example:**

```gd
func _ready():
    var store = Store.new(state, self, 'reducer')
    store.add_middleware(self, 'reverse_action')

    store.dispatch(action.INCREMENT)
    store.dispatch(action.INCREMENT)
    store.dispatch(action.DECREMENT)

    print(store.state()) # { "counter": -1 }

func reverse_action(state, action):
    if (action == action.INCREMENT):
        return action.DECREMENT
    elif (action == action.DECREMENT):
        return action.INCREMENT
```

## License

[MIT](./LICENSE)